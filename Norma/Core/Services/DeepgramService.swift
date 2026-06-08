//
//  DeepgramService.swift
//  Norma
//
//  Created by Claude on 3/1/26.
//

import Foundation
@preconcurrency import AVFoundation

// MARK: - Deepgram Response Models

private struct DeepgramResponse: Codable {
    let type: String?
    let channel: DeepgramChannel?
    let isFinal: Bool?
    let speechFinal: Bool?

    enum CodingKeys: String, CodingKey {
        case type
        case channel
        case isFinal = "is_final"
        case speechFinal = "speech_final"
    }
}

private struct DeepgramChannel: Codable {
    let alternatives: [DeepgramAlternative]
}

private struct DeepgramAlternative: Codable {
    let transcript: String
    let confidence: Double
}

// MARK: - Deepgram Error Types

enum DeepgramError: LocalizedError {
    case connectionFailed(String)
    case alreadyTranscribing
    case audioFormatError
    case webSocketError(String)

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            return "Deepgram connection failed: \(message)"
        case .alreadyTranscribing:
            return "Transcription is already in progress"
        case .audioFormatError:
            return "Failed to configure audio format"
        case .webSocketError(let message):
            return "WebSocket error: \(message)"
        }
    }
}

// MARK: - DeepgramService

@MainActor
class DeepgramService: ObservableObject {
    static let shared = DeepgramService()

    @Published var isTranscribing = false

    private let tokenURL = "https://tafoviioqavefsyxskpo.supabase.co/functions/v1/deepgram-token"

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var audioEngine: AVAudioEngine?
    private var keepAliveTimer: Timer?
    private var accumulatedTranscript = ""

    private var onPartialResult: ((String) -> Void)?
    private var onFinalResult: ((String) -> Void)?
    private var onError: ((Error) -> Void)?

    private init() {}

    // MARK: - Public Interface

    func startLiveTranscription(
        audioEngine: AVAudioEngine,
        onPartialResult: @escaping (String) -> Void,
        onFinalResult: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) async throws {
        guard !isTranscribing else {
            throw DeepgramError.alreadyTranscribing
        }

        // Fetch a short-lived Deepgram token from the edge function. The
        // long-lived Deepgram key lives server-side and never ships in the app.
        let token = try await fetchTemporaryToken()

        self.audioEngine = audioEngine
        self.onPartialResult = onPartialResult
        self.onFinalResult = onFinalResult
        self.onError = onError
        self.accumulatedTranscript = ""

        // Connect WebSocket
        connectWebSocket(token: token)

        // Configure and start audio
        try startAudioStreaming(audioEngine: audioEngine)

        isTranscribing = true

        // Start keep-alive timer
        startKeepAliveTimer()
    }

    func stopTranscription() {
        isTranscribing = false

        // Stop keep-alive
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil

        // Send close stream message
        sendCloseStream()

        // Stop audio tap
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil

        // Close WebSocket
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil

        // Clear callbacks
        onPartialResult = nil
        onFinalResult = nil
        onError = nil
    }

    // MARK: - Temporary Token

    private struct TemporaryToken: Decodable {
        let accessToken: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
        }
    }

    /// Requests a short-lived Deepgram grant token from the edge function,
    /// authenticated with the user's Supabase JWT.
    private func fetchTemporaryToken() async throws -> String {
        guard let url = URL(string: tokenURL) else {
            throw DeepgramError.connectionFailed("Invalid token URL")
        }

        let session = try await SupabaseService.shared.getSession()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseService.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.httpBody = Data("{}".utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DeepgramError.connectionFailed("Could not obtain Deepgram token")
        }

        return try JSONDecoder().decode(TemporaryToken.self, from: data).accessToken
    }

    // MARK: - WebSocket Connection

    private func connectWebSocket(token: String) {
        let params = [
            "model=nova-3",
            "encoding=linear16",
            "sample_rate=16000",
            "interim_results=true",
            "endpointing=true",
            "punctuate=true",
            "smart_format=true"
        ].joined(separator: "&")

        guard let url = URL(string: "wss://api.deepgram.com/v1/listen?\(params)") else {
            onError?(DeepgramError.connectionFailed("Invalid URL"))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let session = URLSession(configuration: .default)
        self.urlSession = session

        let task = session.webSocketTask(with: request)
        self.webSocketTask = task
        task.resume()

        receiveMessages()
    }

    // MARK: - Message Receiving

    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor in
                guard let self = self, self.isTranscribing else { return }

                switch result {
                case .success(let message):
                    self.handleWebSocketMessage(message)
                    // Continue listening
                    self.receiveMessages()

                case .failure(let error):
                    print("DeepgramService: WebSocket receive error: \(error.localizedDescription)")
                    self.onError?(DeepgramError.webSocketError(error.localizedDescription))
                    self.stopTranscription()
                }
            }
        }
    }

    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseTranscriptionResponse(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseTranscriptionResponse(text)
            }
        @unknown default:
            break
        }
    }

    private func parseTranscriptionResponse(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else { return }

        do {
            let response = try JSONDecoder().decode(DeepgramResponse.self, from: data)

            guard let channel = response.channel,
                  let alternative = channel.alternatives.first else {
                return
            }

            let transcript = alternative.transcript

            if response.isFinal == true {
                // Accumulate final segments (including after speech_final pauses)
                if !transcript.isEmpty {
                    if !accumulatedTranscript.isEmpty {
                        accumulatedTranscript += " "
                    }
                    accumulatedTranscript += transcript
                }
                // Always show accumulated text as partial — user stops manually
                onPartialResult?(accumulatedTranscript)
            } else {
                // Interim result — show accumulated + current interim
                if !transcript.isEmpty {
                    let display = accumulatedTranscript.isEmpty
                        ? transcript
                        : accumulatedTranscript + " " + transcript
                    onPartialResult?(display)
                }
            }
        } catch {
            print("DeepgramService: Failed to parse response: \(error)")
        }
    }

    // MARK: - Audio Streaming

    private func startAudioStreaming(audioEngine: AVAudioEngine) throws {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Target format: 16-bit PCM at 16kHz mono
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: true
        ) else {
            throw DeepgramError.audioFormatError
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw DeepgramError.audioFormatError
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.convertAndSendAudio(buffer: buffer, converter: converter, targetFormat: targetFormat)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func convertAndSendAudio(
        buffer: AVAudioPCMBuffer,
        converter: AVAudioConverter,
        targetFormat: AVAudioFormat
    ) {
        let frameCount = AVAudioFrameCount(
            Double(buffer.frameLength) * targetFormat.sampleRate / buffer.format.sampleRate
        )

        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCount) else {
            return
        }

        var error: NSError?
        var inputConsumed = false
        nonisolated(unsafe) let inputBuffer = buffer

        converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
            if inputConsumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            inputConsumed = true
            outStatus.pointee = .haveData
            return inputBuffer
        }

        if let error = error {
            print("DeepgramService: Audio conversion error: \(error)")
            return
        }

        // Extract raw bytes from Int16 buffer
        guard let channelData = convertedBuffer.int16ChannelData else { return }
        let frameLength = Int(convertedBuffer.frameLength)
        let data = Data(bytes: channelData[0], count: frameLength * MemoryLayout<Int16>.size)

        // Send as binary WebSocket message
        webSocketTask?.send(.data(data)) { error in
            if let error = error {
                print("DeepgramService: Send error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Keep Alive

    private func startKeepAliveTimer() {
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sendKeepAlive()
            }
        }
    }

    private func sendKeepAlive() {
        guard let webSocketTask = webSocketTask else { return }
        let message = "{\"type\": \"KeepAlive\"}"
        webSocketTask.send(.string(message)) { error in
            if let error = error {
                print("DeepgramService: KeepAlive error: \(error.localizedDescription)")
            }
        }
    }

    private func sendCloseStream() {
        guard let webSocketTask = webSocketTask else { return }
        let message = "{\"type\": \"CloseStream\"}"
        webSocketTask.send(.string(message)) { _ in }
    }
}
