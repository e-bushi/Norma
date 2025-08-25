//
//  ElevenLabsService.swift
//  Norma
//
//  Created by Claude on 8/5/25.
//

import Foundation
import AVFoundation

@MainActor
class ElevenLabsService: ObservableObject {
    static let shared = ElevenLabsService()
    
    @Published var isGenerating = false
    
    private let baseURL = "https://api.elevenlabs.io/v1"
    private var apiKey: String? = "sk_03b8e001e204ab0633f5a17c428822d29b05058acf80fcc8"
    
    // Default voice ID (you can customize this)
    private let defaultVoiceId = "yj30vwTGJxSHezdAGsv9" // Rachel voice
    
    private init() {}
    
    // MARK: - Configuration
    
    func configure(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Text-to-Speech Methods
    
    func generateSpeech(
        text: String,
        voiceId: String? = nil,
        stability: Float = 0.5,
        similarityBoost: Float = 0.8,
        style: Float = 0.0
    ) async throws -> Data {
        print("ElevenLabs: Generating speech for text: '\(text)'")
        
        guard let apiKey = apiKey else {
            print("ElevenLabs: No API key configured!")
            throw ElevenLabsError.noAPIKey
        }
        
        guard !text.isEmpty else {
            print("ElevenLabs: Text is empty!")
            throw ElevenLabsError.emptyText
        }
        
        let selectedVoiceId = voiceId ?? defaultVoiceId
        let url = URL(string: "\(baseURL)/text-to-speech/\(selectedVoiceId)")!
        print("ElevenLabs: Using voice ID: \(selectedVoiceId)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        
        let requestBody = ElevenLabsRequest(
            text: text,
            modelId: "eleven_turbo_v2_5", // Turbo model for speed
            voiceSettings: VoiceSettings(
                stability: 0.75, // Higher for consistent tone
                similarityBoost: 0.8, // Higher for consistent voice
                style: 0.0, // Lower for faster processing
                useSpeakerBoost: false // Disable for speed
            ),
            optimizeStreamingLatency: 4, // Max speed optimization
            outputFormat: "mp3_22050_32" // Lower quality for speed
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        print("ElevenLabs: Making API request...")
        isGenerating = true
        defer { isGenerating = false }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("ElevenLabs: Network error - no HTTP response")
            throw ElevenLabsError.networkError
        }
        
        print("ElevenLabs: API response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200 {
            print("ElevenLabs: Successfully generated speech - audio data size: \(data.count) bytes")
            return data
        } else {
            print("ElevenLabs: API error - status code: \(httpResponse.statusCode)")
            if let errorData = try? JSONDecoder().decode(ElevenLabsErrorResponse.self, from: data) {
                let errorMessage = errorData.detail?.message ?? "Unknown API error"
                print("ElevenLabs: Error message: \(errorMessage)")
                throw ElevenLabsError.apiError(errorMessage)
            } else {
                let errorString = String(data: data, encoding: .utf8) ?? "No error details"
                print("ElevenLabs: Raw error response: \(errorString)")
                throw ElevenLabsError.unknownError(httpResponse.statusCode)
            }
        }
    }
    
    func generateSpeechToFile(
        text: String,
        voiceId: String? = nil,
        stability: Float = 0.5,
        similarityBoost: Float = 0.8,
        style: Float = 0.0
    ) async throws -> URL {
        let audioData = try await generateSpeech(
            text: text,
            voiceId: voiceId,
            stability: stability,
            similarityBoost: similarityBoost,
            style: style
        )
        
        // Create temporary file URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("tts_audio_\(Date().timeIntervalSince1970).mp3")
        
        try audioData.write(to: audioURL)
        
        return audioURL
    }
    
    // MARK: - Voice Management
    
    func getAvailableVoices() async throws -> [ElevenLabsVoice] {
        guard let apiKey = apiKey else {
            throw ElevenLabsError.noAPIKey
        }
        
        let url = URL(string: "\(baseURL)/voices")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ElevenLabsError.networkError
        }
        
        if httpResponse.statusCode == 200 {
            let voicesResponse = try JSONDecoder().decode(ElevenLabsVoicesResponse.self, from: data)
            return voicesResponse.voices
        } else {
            throw ElevenLabsError.unknownError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Utility Methods
    
    func deleteAudioFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    func getAudioDuration(from data: Data) -> TimeInterval {
        // Create temporary file to get duration
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_audio.mp3")
        
        do {
            try data.write(to: tempURL)
            let asset = AVURLAsset(url: tempURL)
            let duration = CMTimeGetSeconds(asset.duration)
            try? FileManager.default.removeItem(at: tempURL)
            return duration
        } catch {
            return 0
        }
    }
}

// MARK: - ElevenLabs Models

struct ElevenLabsRequest: Codable {
    let text: String
    let modelId: String?
    let voiceSettings: VoiceSettings
    let optimizeStreamingLatency: Int?
    let outputFormat: String?
    
    enum CodingKeys: String, CodingKey {
        case text
        case modelId = "model_id"
        case voiceSettings = "voice_settings"
        case optimizeStreamingLatency = "optimize_streaming_latency"
        case outputFormat = "output_format"
    }
}

struct VoiceSettings: Codable {
    let stability: Float
    let similarityBoost: Float
    let style: Float
    let useSpeakerBoost: Bool
    
    enum CodingKeys: String, CodingKey {
        case stability
        case similarityBoost = "similarity_boost"
        case style
        case useSpeakerBoost = "use_speaker_boost"
    }
}

struct ElevenLabsVoicesResponse: Codable {
    let voices: [ElevenLabsVoice]
}

struct ElevenLabsVoice: Codable, Identifiable {
    let voiceId: String
    let name: String
    let samples: [VoiceSample]?
    let category: String?
    let previewUrl: String?
    let availableForTiers: [String]?
    
    var id: String { voiceId }
    
    enum CodingKeys: String, CodingKey {
        case voiceId = "voice_id"
        case name
        case samples
        case category
        case previewUrl = "preview_url"
        case availableForTiers = "available_for_tiers"
    }
}

struct VoiceSample: Codable {
    let sampleId: String
    let fileName: String
    let mimeType: String
    let sizeBytes: Int
    let hash: String
    
    enum CodingKeys: String, CodingKey {
        case sampleId = "sample_id"
        case fileName = "file_name"
        case mimeType = "mime_type"
        case sizeBytes = "size_bytes"
        case hash
    }
}

struct ElevenLabsErrorResponse: Codable {
    let detail: ErrorDetail?
}

struct ErrorDetail: Codable {
    let message: String
}

// MARK: - Error Types

enum ElevenLabsError: LocalizedError {
    case noAPIKey
    case emptyText
    case networkError
    case apiError(String)
    case unknownError(Int)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "ElevenLabs API key is required"
        case .emptyText:
            return "Text cannot be empty"
        case .networkError:
            return "Network connection error"
        case .apiError(let message):
            return "ElevenLabs API error: \(message)"
        case .unknownError(let statusCode):
            return "Unknown error occurred. Status code: \(statusCode)"
        }
    }
}

// MARK: - Predefined Voices

extension ElevenLabsService {
    
    struct PredefinedVoices {
        static let rachel = "21m00Tcm4TlvDq8ikWAM"
        static let domi = "AZnzlk1XvdvUeBnXmlld"
        static let bella = "EXAVITQu4vr4xnSDxMaL"
        static let antoni = "ErXwobaYiN019PkySvjV"
        static let elli = "MF3mGyEYCl7XYWbV9V6O"
        static let josh = "TxGEqnHWrfWFTfGW9XjX"
        static let arnold = "VR6AewLTigWG4xSOukaG"
        static let adam = "pNInz6obpgDQGcFmaJgB"
        static let sam = "yoZ06aMxZJJ28mfd3POQ"
    }
    
    func setVoice(to voiceId: String) {
        // This could be used to change the default voice
        // For now, we pass voiceId to individual methods
    }
}
