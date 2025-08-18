//
//  VoiceRecordingService.swift
//  Norma
//
//  Created by Claude on 8/5/25.
//

import Foundation
import AVFoundation

@MainActor
class VoiceRecordingService: ObservableObject {
    static let shared = VoiceRecordingService()
    
    @Published var isRecording = false
    @Published var recordingLevel: Float = 0.0
    @Published var hasPermission = false
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession
    private var levelTimer: Timer?
    private var currentRecordingURL: URL?
    private var levelUpdateCount = 0
    
    private init() {
        self.audioSession = AVAudioSession.sharedInstance()
        checkMicrophonePermission()
    }
    
    deinit {
        // Clean up synchronously in deinit
        audioRecorder?.stop()
        audioRecorder = nil
        levelTimer?.invalidate()
        levelTimer = nil
        // Deactivate audio session
        try? audioSession.setActive(false)
    }
    
    // MARK: - Permission Management
    
    func checkMicrophonePermission() {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                hasPermission = true
            case .denied:
                hasPermission = false
            case .undetermined:
                requestMicrophonePermission()
            @unknown default:
                hasPermission = false
            }
        } else {
            switch audioSession.recordPermission {
            case .granted:
                hasPermission = true
            case .denied:
                hasPermission = false
            case .undetermined:
                requestMicrophonePermission()
            @unknown default:
                hasPermission = false
            }
        }
    }
    
    private func requestMicrophonePermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                }
            }
        } else {
            audioSession.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                }
            }
        }
    }
    
    // MARK: - Recording Management
    
    func startRecording() async throws -> URL {
        print("VoiceRecording: Checking permissions...")
        guard hasPermission else {
            print("VoiceRecording: No permission!")
            throw VoiceRecordingError.noPermission
        }
        
        guard !isRecording else {
            print("VoiceRecording: Already recording!")
            throw VoiceRecordingError.alreadyRecording
        }
        
        print("VoiceRecording: Configuring audio session...")
        // Configure audio session
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
        
        // Create temporary file URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("voice_recording_\(Date().timeIntervalSince1970).m4a")
        print("VoiceRecording: Will record to: \(audioURL)")
        
        // Configure recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        print("VoiceRecording: Creating recorder with settings: \(settings)")
        // Create and start recorder
        audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
        currentRecordingURL = audioURL
        
        print("VoiceRecording: Starting recording...")
        guard audioRecorder?.record() == true else {
            print("VoiceRecording: Failed to start recording!")
            throw VoiceRecordingError.recordingFailed
        }
        
        isRecording = true
        startLevelMonitoring()
        print("VoiceRecording: Recording started successfully")
        
        return audioURL
    }
    
    func stopRecording() {
        guard isRecording else { 
            print("VoiceRecording: stopRecording called but not currently recording")
            return 
        }
        
        print("VoiceRecording: Stopping recording...")
        audioRecorder?.stop()
        
        // Check file size if we have a recording URL
        if let fileURL = currentRecordingURL {
            do {
                let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0
                print("VoiceRecording: Recorded file size: \(fileSize) bytes at \(fileURL)")
            } catch {
                print("VoiceRecording: Could not check file size: \(error)")
            }
        }
        
        audioRecorder = nil
        currentRecordingURL = nil
        isRecording = false
        recordingLevel = 0.0
        
        stopLevelMonitoring()
        
        // Deactivate audio session
        try? audioSession.setActive(false)
        print("VoiceRecording: Recording stopped successfully")
    }
    
    // MARK: - Audio Level Monitoring
    
    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateRecordingLevel()
        }
    }
    
    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
    }
    
    private func updateRecordingLevel() {
        guard let recorder = audioRecorder else { return }
        
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        let normalizedLevel = pow(10, averagePower / 20)
        recordingLevel = normalizedLevel
        
        // Log audio levels periodically (every 10 updates to avoid spam)
        levelUpdateCount += 1
        if levelUpdateCount % 10 == 0 {
            print("VoiceRecording: Audio level - Power: \(averagePower)dB, Normalized: \(normalizedLevel)")
        }
    }
    
    // MARK: - Utility Methods
    
    func deleteRecording(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    func getRecordingDuration(at url: URL) -> TimeInterval {
        let asset = AVURLAsset(url: url)
        return CMTimeGetSeconds(asset.duration)
    }
    
    func hasMinimumAudioContent(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("VoiceRecording: Audio file does not exist")
            return false
        }
        
        do {
            let fileData = try Data(contentsOf: url)
            let fileSize = fileData.count
            let duration = getRecordingDuration(at: url)
            
            print("VoiceRecording: Audio file size: \(fileSize) bytes, duration: \(duration)s")
            
            // Check minimum file size (at least 1KB) and duration (at least 0.3 seconds)
            let hasMinimumSize = fileSize > 1024
            let hasMinimumDuration = duration > 0.3
            
            let hasContent = hasMinimumSize && hasMinimumDuration
            print("VoiceRecording: Has minimum content: \(hasContent) (size: \(hasMinimumSize), duration: \(hasMinimumDuration))")
            
            return hasContent
        } catch {
            print("VoiceRecording: Error checking audio content: \(error)")
            return false
        }
    }
}

// MARK: - Error Types

enum VoiceRecordingError: LocalizedError {
    case noPermission
    case alreadyRecording
    case recordingFailed
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .noPermission:
            return "Microphone permission is required to record audio"
        case .alreadyRecording:
            return "Recording is already in progress"
        case .recordingFailed:
            return "Failed to start audio recording"
        case .fileNotFound:
            return "Audio file not found"
        }
    }
}
