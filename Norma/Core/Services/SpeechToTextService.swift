//
//  SpeechToTextService.swift
//  Norma
//
//  Created by Claude on 8/5/25.
//

import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechToTextService: ObservableObject {
    static let shared = SpeechToTextService()
    
    @Published var isTranscribing = false
    @Published var hasPermission = false
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    
    // Error deduplication to prevent console spam
    private var loggedErrors = Set<String>()
    
    private init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        // Disable system-level speech recognition logging
        self.configureSpeechRecognitionLogging()
        
        checkSpeechPermission()
    }
    
    private func configureSpeechRecognitionLogging() {
        // Set environment variable to suppress Speech framework logging
        setenv("OS_ACTIVITY_MODE", "disable", 1)
        
        // Alternative: Set specific speech recognition logging to minimal
        if #available(iOS 14.0, *) {
            // Configure speech recognizer to minimize system logging
            speechRecognizer?.supportsOnDeviceRecognition
        }
    }
    
    deinit {
        // Clean up synchronously in deinit
        recognitionTask?.cancel()
        recognitionRequest?.endAudio()
        recognitionTask = nil
        recognitionRequest = nil
    }
    
    // MARK: - Permission Management
    
    func checkSpeechPermission() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            hasPermission = true
        case .denied, .restricted, .notDetermined:
            hasPermission = false
        @unknown default:
            hasPermission = false
        }
    }
    
    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.hasPermission = (status == .authorized)
            }
        }
    }
    
    // MARK: - Transcription Methods
    
    func transcribeAudioFile(at url: URL) async throws -> String {
        print("SpeechToText: Starting transcription for file: \(url)")
        
        guard hasPermission else {
            print("SpeechToText: No speech recognition permission!")
            throw SpeechToTextError.noPermission
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("SpeechToText: Speech recognizer unavailable!")
            throw SpeechToTextError.recognizerUnavailable
        }
        
        // Check if file exists and has content
        do {
            let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
            print("SpeechToText: Audio file size: \(fileSize) bytes")
            
            if fileSize == 0 {
                print("SpeechToText: Warning - audio file is empty!")
            }
        } catch {
            print("SpeechToText: Could not check file: \(error)")
        }
        
        print("SpeechToText: Creating recognition request...")
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            request.taskHint = .dictation
            
            // Add timeout to prevent endless processing
            request.contextualStrings = []
            if #available(iOS 16.0, *) {
                request.addsPunctuation = true
                request.requiresOnDeviceRecognition = false
            }
            
            print("SpeechToText: Starting recognition task...")
            
            // Set a timeout to prevent endless processing
            var hasCompleted = false
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 8_000_000_000) // 8 seconds timeout
                if !hasCompleted {
                    print("SpeechToText: Recognition timed out")
                    self.recognitionTask?.cancel()
                    continuation.resume(throwing: SpeechToTextError.noSpeechDetected)
                    hasCompleted = true
                }
            }
            
            recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
                guard !hasCompleted else { return }
                
                if let error = error {
                    hasCompleted = true
                    timeoutTask.cancel()
                    
                    let nsError = error as NSError
                    let errorKey = "\(nsError.domain)-\(nsError.code)"
                    
                    // Log each unique error only once to prevent spam
                    if !self.loggedErrors.contains(errorKey) {
                        self.loggedErrors.insert(errorKey)
                        print("SpeechToText: Recognition error (first occurrence): \(error.localizedDescription)")
                        print("SpeechToText: Error domain: \(nsError.domain), code: \(nsError.code)")
                    }
                    
                    // Handle specific error types for no speech detected
                    if nsError.domain == "kAFAssistantErrorDomain" && (nsError.code == 1101 || nsError.code == 1110) {
                        continuation.resume(throwing: SpeechToTextError.noSpeechDetected)
                    } else {
                        continuation.resume(throwing: SpeechToTextError.transcriptionFailed(error.localizedDescription))
                    }
                    return
                }
                
                if let result = result {
                    print("SpeechToText: Got result - isFinal: \(result.isFinal), confidence: \(result.bestTranscription.segments.first?.confidence ?? 0)")
                    
                    if result.isFinal {
                        hasCompleted = true
                        timeoutTask.cancel()
                        
                        let transcription = result.bestTranscription.formattedString
                        print("SpeechToText: Final transcription: '\(transcription)'")
                        
                        // Check for empty transcription
                        if transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            print("SpeechToText: Transcription is empty - no speech detected")
                            continuation.resume(throwing: SpeechToTextError.noSpeechDetected)
                        } else {
                            continuation.resume(returning: transcription)
                        }
                    } else {
                        print("SpeechToText: Partial result: '\(result.bestTranscription.formattedString)'")
                    }
                }
            }
        }
    }
    
    func startLiveTranscription(
        audioEngine: AVAudioEngine,
        onPartialResult: @escaping (String) -> Void,
        onFinalResult: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) throws {
        guard hasPermission else {
            throw SpeechToTextError.noPermission
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechToTextError.recognizerUnavailable
        }
        
        guard !isTranscribing else {
            throw SpeechToTextError.alreadyTranscribing
        }
        
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechToTextError.requestCreationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isTranscribing = true
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.stopTranscription()
                    onError(SpeechToTextError.transcriptionFailed(error.localizedDescription))
                    return
                }
                
                if let result = result {
                    let transcription = result.bestTranscription.formattedString
                    if result.isFinal {
                        onFinalResult(transcription)
                        self?.stopTranscription()
                    } else {
                        onPartialResult(transcription)
                    }
                }
            }
        }
    }
    
    func stopTranscription() {
        isTranscribing = false
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }
    
    func clearErrorLog() {
        loggedErrors.removeAll()
        print("SpeechToText: Error log cleared")
    }
    
    // MARK: - Alternative Services (OpenAI Whisper)
    
    func transcribeWithWhisper(audioURL: URL, apiKey: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let httpBody = try createMultipartBody(
            audioURL: audioURL,
            boundary: boundary
        )
        request.httpBody = httpBody
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpeechToTextError.apiError("Whisper API request failed")
        }
        
        struct WhisperResponse: Codable {
            let text: String
        }
        
        let whisperResponse = try JSONDecoder().decode(WhisperResponse.self, from: data)
        return whisperResponse.text
    }
    
    private func createMultipartBody(audioURL: URL, boundary: String) throws -> Data {
        var body = Data()
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mp4\r\n\r\n".data(using: .utf8)!)
        
        let audioData = try Data(contentsOf: audioURL)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
}

// MARK: - Error Types

enum SpeechToTextError: LocalizedError, Equatable {
    case noPermission
    case recognizerUnavailable
    case alreadyTranscribing
    case requestCreationFailed
    case transcriptionFailed(String)
    case noSpeechDetected
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .noPermission:
            return "Speech recognition permission is required"
        case .recognizerUnavailable:
            return "Speech recognizer is not available"
        case .alreadyTranscribing:
            return "Transcription is already in progress"
        case .requestCreationFailed:
            return "Failed to create recognition request"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        case .noSpeechDetected:
            return "No speech detected. Please speak clearly and try again."
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}