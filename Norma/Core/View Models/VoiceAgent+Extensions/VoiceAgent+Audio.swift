//
//  VoiceAgent+Audio.swift
//  Norma
//
//  Created by Assistant on 12/6/25.
//

import Foundation
import AVFoundation
import Speech

// MARK: - Audio Recording, Transcription, Speech Generation, and Playback
extension VoiceAgentViewModel {
    
    // MARK: - Recording
    
    func startRecording() async throws -> URL {
        print("VoiceAgent: Starting reactive recording...")
        
        // Start recording - the service will handle speech detection and auto-completion
        currentRecordingURL = try await voiceRecordingService.startRecording()
        print("VoiceAgent: Recording started successfully")
        
        // Wait for either recording completion or timeout
        // Increased timeout from 10 to 15 seconds for initial response
        return try await withTimeout(seconds: 15) { [self] in
            // Listen for automatic recording completion
            for await recordingURL in self.voiceRecordingService.recordingCompletionStream.values {
                print("VoiceAgent: Recording completed reactively at: \(recordingURL)")
                return recordingURL
            }
            
            // This should never be reached due to timeout, but provide fallback
            throw VoiceAgentError.recordingFailed
        }
    }
    
    func startRecordingManually() async throws {
        guard hasPermissions else {
            throw VoiceAgentError.noPermissions
        }
        
        await setState(.recording)
        currentRecordingURL = try await voiceRecordingService.startRecording()
    }
    
    func stopRecording() {
        voiceRecordingService.stopRecording()
    }
    
    func stopRecordingAndProcess() async {
        guard let audioURL = currentRecordingURL else { return }
        
        voiceRecordingService.stopRecording()
        
        do {
            // Continue with transcription and processing
            await setState(.transcribing)
            let transcription = try await transcribeAudio(url: audioURL)
            
            await setState(.processing)
            let aiResponse = try await processUserMessage(transcription)
            
            await setState(.generatingSpeech)
            let audioData = try await generateSpeech(from: aiResponse)
            
            await setState(.playingResponse)
            try await playResponse(audioData: audioData)
            
            
            await setState(.idle)
            
        } catch {
            await setError(error.localizedDescription)
        }
    }
    
    // MARK: - Transcription
    
    func transcribeAudio(url: URL) async throws -> String {
        print("VoiceAgent: Transcribing audio file at: \(url)")
        
        // Check if audio has minimum content before attempting transcription
        if !voiceRecordingService.hasMinimumAudioContent(at: url) {
            print("VoiceAgent: Audio file has insufficient content, treating as no speech detected")
            voiceRecordingService.deleteRecording(at: url)
            throw SpeechToTextError.noSpeechDetected
        }
        
        let transcription = try await speechToTextService.transcribeAudioFile(at: url)
        transcriptionText = transcription
        
        print("VoiceAgent: Transcription result: '\(transcription)'")
        
        // Clean up audio file
        voiceRecordingService.deleteRecording(at: url)
        
        return transcription
    }
    
    // MARK: - Speech Generation
    
    func generateSpeech(from text: String) async throws -> Data {
        return try await elevenLabsService.generateSpeech(text: text)
    }
    
    // MARK: - Audio Playback
    
    func playResponse(audioData: Data) async throws {
        try await audioPlaybackService.playVoiceResponse(audioData: audioData)
        
        // Wait for playback to complete
        while audioPlaybackService.isPlaying {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    
    // MARK: - Timeout Helper
    
    func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw VoiceAgentError.recordingFailed // Timeout
            }
            
            // Return the first result (either completion or timeout)
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Service Observation
    
    func observeServiceStates() {
        // Observe recording service state
        voiceRecordingService.$isRecording
            .receive(on: RunLoop.main)
            .assign(to: &$isRecording)
        
        voiceRecordingService.$recordingLevel
            .receive(on: RunLoop.main)
            .assign(to: &$recordingLevel)
        
        // Observe transcription service state
        speechToTextService.$isTranscribing
            .receive(on: RunLoop.main)
            .assign(to: &$isTranscribing)
        
        // Observe playback service state
        audioPlaybackService.$isPlaying
            .receive(on: RunLoop.main)
            .assign(to: &$isPlayingResponse)
    }
    
    // MARK: - Sentence Processing for Streaming
    
    func splitIntoSentences(_ text: String) -> [String] {
        // Simple sentence splitting (can be improved)
        var result: [String] = []
        let components = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let punctuation = text.filter { ".!?".contains($0) }
        
        for (index, component) in components.enumerated() {
            let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                // Add back the punctuation if available
                if index < punctuation.count {
                    let punctuationIndex = punctuation.index(punctuation.startIndex, offsetBy: index)
                    result.append(trimmed + String(punctuation[punctuationIndex]))
                } else {
                    result.append(trimmed)
                }
            }
        }
        
        return result
    }
    
    // MARK: - Streaming TTS Processing
    
    // NOTE: These methods are placeholders for future streaming TTS implementation
    // They require additional methods in AudioPlaybackService (queueAudioData, isPlayingQueue, startQueuePlayback)
    
    /*
    func processUserMessageWithStreaming(_ message: String) async throws {
        print("VoiceAgent: Processing user message with streaming: '\(message)'")
        
        // Add user message to conversation history
        conversationHistory.append(AnthropicMessage(role: "user", content: .text(message)))
        
        // Get tools for bill context
        let tools = getBillsTools()
        let systemPrompt = getBillsSystemPrompt()
        
        // Start streaming response
        var completeResponse = ""
        var currentSentence = ""
        
        do {
            let stream = anthropicService.streamMessageWithTools(
                messages: conversationHistory,
                systemPrompt: systemPrompt,
                tools: tools
            )
            
            for try await chunk in stream {
                completeResponse += chunk
                currentSentence += chunk
                
                // Check if we have a complete sentence
                if currentSentence.contains(".") || currentSentence.contains("!") || currentSentence.contains("?") {
                    print("VoiceAgent: Processing complete sentence: '\(currentSentence)'")
                    
                    let sentences = splitIntoSentences(currentSentence)
                    print("VoiceAgent: Split into \(sentences.count) sentences: \(sentences)")
                    
                    for sentence in sentences {
                        let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedSentence.isEmpty && trimmedSentence.count > 2 { // Avoid very short fragments
                            print("VoiceAgent: Queueing sentence: '\(trimmedSentence)'")
                            
                            // Generate and queue audio for this sentence immediately
                            Task {
                                do {
                                    let audioData = try await generateSpeech(from: trimmedSentence)
                                    audioPlaybackService.queueAudioData(audioData)
                                    
                                    // Start playback if not already playing
                                    if !audioPlaybackService.isPlayingQueue {
                                        audioPlaybackService.startQueuePlayback()
                                    }
                                } catch {
                                    print("VoiceAgent: Failed to generate speech for sentence: \(error)")
                                }
                            }
                        }
                    }
                    
                    // Clear the current sentence buffer after processing
                    currentSentence = ""
                }
            }
            
            // Process any remaining text that didn't end with punctuation
            if !currentSentence.isEmpty {
                let trimmedSentence = currentSentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedSentence.isEmpty {
                    print("VoiceAgent: Processing final fragment: '\(trimmedSentence)'")
                    
                    Task {
                        do {
                            let audioData = try await generateSpeech(from: trimmedSentence)
                            audioPlaybackService.queueAudioData(audioData)
                            
                            if !audioPlaybackService.isPlayingQueue {
                                audioPlaybackService.startQueuePlayback()
                            }
                        } catch {
                            print("VoiceAgent: Failed to generate speech for final fragment: \(error)")
                        }
                    }
                }
            }
            
            // Add complete response to conversation history
            conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(completeResponse)))
            responseText = completeResponse
            
            // Wait for all audio to finish playing
            while audioPlaybackService.isPlayingQueue {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
        } catch {
            print("VoiceAgent: Error in streaming response: \(error)")
            throw error
        }
    }
    
    // MARK: - Post-Split TTS Processing
    
    func processUserMessageWithPostSplitTTS(_ message: String) async throws {
        print("VoiceAgent: Processing user message with post-split TTS: '\(message)'")
        
        // Add user message to conversation history
        conversationHistory.append(AnthropicMessage(role: "user", content: .text(message)))
        
        // Get tools for bill context
        let tools = getBillsTools()
        let systemPrompt = getBillsSystemPrompt()
        
        // Get complete response from Claude (fast with Haiku)
        let response = try await anthropicService.sendMessageWithTools(
            messages: conversationHistory,
            systemPrompt: systemPrompt,
            tools: tools
        )
        
        let responseText: String
        switch response {
        case .text(let text):
            responseText = text
        case .toolUse(let id, let name, let input):
            // Handle tool use (simplified for now)
            let toolResult = await executeToolAndGetResult(toolId: id, name: name, input: input)
            conversationHistory.append(AnthropicMessage(role: "assistant", content: .toolUse(id: id, name: name, input: input)))
            conversationHistory.append(AnthropicMessage(role: "user", content: .toolResult(toolUseId: id, content: toolResult)))
            
            let finalResponse = try await anthropicService.sendMessageWithTools(
                messages: conversationHistory,
                systemPrompt: systemPrompt,
                tools: tools
            )
            
            if case .text(let text) = finalResponse {
                responseText = text
            } else {
                responseText = "I've completed your request."
            }
        case .toolResult:
            responseText = "Something went wrong with the request."
        }
        
        // Add response to conversation history
        conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(responseText)))
        self.responseText = responseText
        
        // Now split the complete response into sentences and generate TTS
        print("VoiceAgent: Complete response received, splitting into sentences...")
        let sentences = splitIntoSentences(responseText)
        print("VoiceAgent: Split into \(sentences.count) sentences")
        
        // Generate and play audio for each sentence sequentially
        for (index, sentence) in sentences.enumerated() {
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedSentence.isEmpty && trimmedSentence.count > 2 {
                print("VoiceAgent: Processing sentence \(index + 1)/\(sentences.count): '\(trimmedSentence)'")
                
                // Generate speech for this sentence
                await setState(.generatingSpeech)
                let audioData = try await generateSpeech(from: trimmedSentence)
                
                // Play this sentence
                await setState(.playingResponse)
                try await playResponse(audioData: audioData)
            }
        }
        
        print("VoiceAgent: Completed post-split TTS playback")
    }
    */
}