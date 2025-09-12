//
//  AudioPlaybackService.swift
//  Norma
//
//  Created by Claude on 8/5/25.
//

import Foundation
import AVFoundation

@MainActor
class AudioPlaybackService: NSObject, ObservableObject {
    static let shared = AudioPlaybackService()
    
    @Published var isPlaying = false
    @Published var playbackProgress: Float = 0.0
    @Published var currentTime: TimeInterval = 0.0
    @Published var duration: TimeInterval = 0.0
    
    private var audioPlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession
    private var progressTimer: Timer?
    
    // Audio queue for streaming playback
    private var audioQueue: [Data] = []
    private var isProcessingQueue = false
    
    override init() {
        self.audioSession = AVAudioSession.sharedInstance()
        super.init()
    }
    
    deinit {
        // Clean up timer synchronously
        progressTimer?.invalidate()
        // Audio player cleanup happens automatically
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // MARK: - Playback Control Methods
    
    func playAudio(from data: Data) async throws {
        print("AudioPlayback: Starting playback - audio data size: \(data.count) bytes")
        
        // Stop any current playback
        stopPlayback()
        
        // Configure audio session for playback
        print("AudioPlayback: Configuring audio session...")
        try audioSession.setCategory(.playback, mode: .default, options: [])
        try audioSession.setActive(true)
        
        // Create audio player from data
        print("AudioPlayback: Creating audio player from data...")
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        
        // Update duration
        duration = audioPlayer?.duration ?? 0.0
        print("AudioPlayback: Audio duration: \(duration) seconds")
        
        // Start playback
        print("AudioPlayback: Starting playback...")
        guard audioPlayer?.play() == true else {
            print("AudioPlayback: Failed to start playback!")
            throw AudioPlaybackError.playbackFailed
        }
        
        isPlaying = true
        startProgressTimer()
        print("AudioPlayback: Playback started successfully")
    }
    
    func playAudio(from url: URL) async throws {
        // Stop any current playback
        stopPlayback()
        
        // Configure audio session for playback
        try audioSession.setCategory(.playback, mode: .default, options: [])
        try audioSession.setActive(true)
        
        // Create audio player from URL
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        
        // Update duration
        duration = audioPlayer?.duration ?? 0.0
        
        // Start playback
        guard audioPlayer?.play() == true else {
            throw AudioPlaybackError.playbackFailed
        }
        
        isPlaying = true
        startProgressTimer()
    }
    
    func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
    }
    
    func resumePlayback() {
        guard let player = audioPlayer else { return }
        
        if player.play() {
            isPlaying = true
            startProgressTimer()
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0.0
        playbackProgress = 0.0
        stopProgressTimer()
        
        // Deactivate audio session
        try? audioSession.setActive(false)
    }
    
    func seekTo(time: TimeInterval) {
        guard let player = audioPlayer else { return }
        
        if time >= 0 && time <= duration {
            player.currentTime = time
            currentTime = time
            playbackProgress = duration > 0 ? Float(time / duration) : 0.0
        }
    }
    
    func seekToProgress(_ progress: Float) {
        let time = TimeInterval(progress) * duration
        seekTo(time: time)
    }
    
    // MARK: - Volume Control
    
    func setVolume(_ volume: Float) {
        audioPlayer?.volume = max(0.0, min(1.0, volume))
    }
    
    func getVolume() -> Float {
        return audioPlayer?.volume ?? 1.0
    }
    
    // MARK: - Audio Information
    
    func getCurrentTime() -> TimeInterval {
        return audioPlayer?.currentTime ?? 0.0
    }
    
    func getDuration() -> TimeInterval {
        return audioPlayer?.duration ?? 0.0
    }
    
    func isAudioPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    // MARK: - Progress Monitoring
    
    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func updateProgress() {
        guard let player = audioPlayer else { return }
        
        currentTime = player.currentTime
        playbackProgress = duration > 0 ? Float(currentTime / duration) : 0.0
    }
    
    // MARK: - Audio Session Management
    
    func configureAudioSession() throws {
        try audioSession.setCategory(.playback, mode: .default, options: [])
        try audioSession.setActive(true)
    }
    
    func deactivateAudioSession() {
        try? audioSession.setActive(false)
    }
    
    // MARK: - Utility Methods
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func getFormattedCurrentTime() -> String {
        return formatTime(currentTime)
    }
    
    func getFormattedDuration() -> String {
        return formatTime(duration)
    }
    
    func getFormattedTimeRemaining() -> String {
        let remaining = duration - currentTime
        return formatTime(remaining)
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlaybackService: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("AudioPlayback: Finished playing - success: \(flag)")
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentTime = 0.0
            self.playbackProgress = 0.0
            self.stopProgressTimer()
            
            // Deactivate audio session
            try? self.audioSession.setActive(false)
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.stopProgressTimer()
            
            // You might want to emit an error event here
            print("Audio playback decode error: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        DispatchQueue.main.async {
            self.pausePlayback()
        }
    }
    
    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        DispatchQueue.main.async {
            // Optionally resume playback after interruption
            // For voice responses, we might not want to auto-resume
            try? self.audioSession.setActive(true)
        }
    }
}

// MARK: - Audio Playback Extensions

extension AudioPlaybackService {
    
    // Convenience method for playing text-to-speech responses
    func playVoiceResponse(audioData: Data) async throws {
        try await playAudio(from: audioData)
    }
    
    // Convenience method for playing text-to-speech responses from file
    func playVoiceResponse(from url: URL) async throws {
        try await playAudio(from: url)
        
        // Clean up the temporary file after playback starts
        // (The file will be deleted when playback completes)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // Method to play a quick notification sound
    func playNotificationSound() {
        // This could play a short system sound or custom notification
        // For now, we'll use a system sound
        AudioServicesPlaySystemSound(1016) // Text message received sound
    }
    
    // Method to play an error sound
    func playErrorSound() {
        AudioServicesPlaySystemSound(1102) // Camera shutter sound (as error indicator)
    }
    
    // Method to play a success sound
    func playSuccessSound() {
        AudioServicesPlaySystemSound(1013) // Voicemail received sound
    }
    
    // MARK: - Streaming Audio Queue Methods
    
    func queueVoiceResponse(audioData: Data) async throws {
        print("AudioPlayback: Queueing audio chunk (\(audioData.count) bytes)")
        
        // Add to queue
        audioQueue.append(audioData)
        
        // Start processing queue if not already processing
        if !isProcessingQueue {
            await processAudioQueue()
        }
    }
    
    private func processAudioQueue() async {
        guard !isProcessingQueue else { return }
        isProcessingQueue = true
        
        print("AudioPlayback: Starting to process audio queue (\(audioQueue.count) items)")
        
        while !audioQueue.isEmpty {
            let audioData = audioQueue.removeFirst()
            
            do {
                print("AudioPlayback: Playing queued audio chunk")
                try await playAudio(from: audioData)
                
                // Wait for current audio to finish before playing next
                while isPlaying {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }
                
            } catch {
                print("AudioPlayback: Error playing queued audio: \(error)")
                // Continue processing queue even if one item fails
            }
        }
        
        isProcessingQueue = false
        print("AudioPlayback: Finished processing audio queue")
    }
    
    func clearAudioQueue() {
        print("AudioPlayback: Clearing audio queue")
        audioQueue.removeAll()
        isProcessingQueue = false
    }
}

// MARK: - Error Types

enum AudioPlaybackError: LocalizedError {
    case playbackFailed
    case fileNotFound
    case audioSessionError
    case invalidAudioData
    
    var errorDescription: String? {
        switch self {
        case .playbackFailed:
            return "Failed to start audio playback"
        case .fileNotFound:
            return "Audio file not found"
        case .audioSessionError:
            return "Audio session configuration failed"
        case .invalidAudioData:
            return "Invalid audio data format"
        }
    }
}

// MARK: - Audio Services Import

import AudioToolbox
