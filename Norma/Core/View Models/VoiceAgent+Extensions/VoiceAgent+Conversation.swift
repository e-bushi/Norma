//
//  VoiceAgent+Conversation.swift
//  Norma
//
//  Created by Assistant on 12/6/25.
//

import Foundation
import AVFoundation
import Speech

// MARK: - Conversation Flow and State Management
extension VoiceAgentViewModel {
    
    // MARK: - Main Conversation Flows
    
    func runUnifiedVoiceInteraction(userName: String? = nil) async {
        do {
            // Step 0: Play initial greeting and add to conversation history
            print("VoiceAgent: Step 0 - Playing unified greeting...")
            await setState(.generatingSpeech)
            let greeting = generateUnifiedGreeting(userName: userName)
            
            // Add greeting to conversation history so Claude knows it already greeted the user
            conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(greeting)))
            
            let greetingAudioData = try await generateSpeech(from: greeting)
            
            await setState(.playingResponse)
            try await playResponse(audioData: greetingAudioData)
            
            // Continuous conversation loop
            var conversationActive = true
            var turnCount = 0
            let maxTurns = 10 // Safety limit
            let maxNoAudioRetries = 2 // Maximum attempts when no audio detected
            
            while conversationActive && turnCount < maxTurns && !isConversationCancelled {
                // Check for cancellation
                if Task.isCancelled || isConversationCancelled {
                    print("VoiceAgent: Conversation cancelled by user")
                    break
                }
                turnCount += 1
                print("VoiceAgent: Conversation turn \(turnCount)")
                
                var noAudioRetryCount = 0
                var turnCompleted = false
                
                while !turnCompleted && noAudioRetryCount <= maxNoAudioRetries && !isConversationCancelled {
                    // Check for cancellation before each step
                    if Task.isCancelled || isConversationCancelled {
                        print("VoiceAgent: Conversation cancelled - stopping immediately")
                        turnCompleted = true
                        conversationActive = false
                        break
                    }
                    
                    do {
                        // Step 1: Record audio with retry logic
                        print("VoiceAgent: Step 1 - Recording audio...")
                        guard !isConversationCancelled else { break }
                        await setState(.recording)
                        // Use longer timeout for first turn or after retries, normal timeout otherwise
                        let timeoutDuration: TimeInterval = (turnCount == 1 || noAudioRetryCount > 0) ? 15 : 10
                        let audioURL = try await startRecording(timeoutSeconds: timeoutDuration)
                        
                        // Check for cancellation after recording
                        guard !isConversationCancelled else { break }
                        
                        // Step 2: Transcribe audio
                        print("VoiceAgent: Step 2 - Transcribing audio...")
                        await setState(.transcribing)
                        let transcription = try await transcribeAudio(url: audioURL)
                        
                        // Check for cancellation after transcription
                        guard !isConversationCancelled else { break }
                        
                        // Check if transcription is meaningful
                        if transcription.count < 2 {
                            print("VoiceAgent: Very short transcription detected, might be just noise")
                            noAudioRetryCount += 1
                            if noAudioRetryCount <= maxNoAudioRetries && !isConversationCancelled {
                                print("VoiceAgent: Retrying... (attempt \(noAudioRetryCount + 1))")
                                let retryMessage = noAudioRetryCount == 1 ? 
                                    "I didn't catch that. Could you please repeat?" :
                                    "I'm still having trouble hearing you. Could you speak a bit louder?"
                                
                                let retryAudioData = try await generateSpeech(from: retryMessage)
                                await setState(.playingResponse)
                                try await playResponse(audioData: retryAudioData)
                                continue
                            }
                        }
                        
                        // Step 3: Process with Claude using unified tools and prompt
                        print("VoiceAgent: Step 3 - Processing with Claude...")
                        await setState(.processing)
                        let (responseText, toolWasUsed) = try await processUnifiedTranscription(transcription)
                        
                        // Check for cancellation after processing
                        guard !isConversationCancelled else { break }
                        
                        // Check for conversation end markers
                        let lowercasedResponse = responseText.lowercased()
                        if lowercasedResponse.contains("goodbye") || 
                           lowercasedResponse.contains("take care") ||
                           lowercasedResponse.contains("have a great") ||
                           lowercasedResponse.contains("have a good") ||
                           lowercasedResponse.contains("have a nice") {
                            conversationActive = false
                            print("VoiceAgent: Detected conversation ending")
                        }
                        
                        // Step 4: Generate speech from response
                        print("VoiceAgent: Step 4 - Generating speech...")
                        guard !isConversationCancelled else { break }
                        await setState(.generatingSpeech)
                        let audioData = try await generateSpeech(from: responseText)
                        
                        // Step 5: Play response
                        print("VoiceAgent: Step 5 - Playing response...")
                        guard !isConversationCancelled else { break }
                        await setState(.playingResponse)
                        try await playResponse(audioData: audioData)
                        
                        // Turn completed successfully
                        turnCompleted = true
                        
                    } catch {
                        noAudioRetryCount += 1
                        print("VoiceAgent: No audio detected (attempt \(noAudioRetryCount))")
                        
                        if noAudioRetryCount <= maxNoAudioRetries && !isConversationCancelled {
                            // Play a retry message
                            let retryMessage = noAudioRetryCount == 1 ? 
                                "I didn't hear anything. Please try speaking again." :
                                "Still no audio detected. Please make sure your microphone is working and try again."
                            
                            let retryAudioData = try await generateSpeech(from: retryMessage)
                            await setState(.playingResponse)
                            try await playResponse(audioData: retryAudioData)
                        } else if !isConversationCancelled {
                            // Max retries reached - pause conversation
                            await pauseConversation(reason: "No audio detected after multiple attempts")
                            conversationActive = false
                            turnCompleted = true
                        }
                    }
                }
            }
            
            print("VoiceAgent: Unified voice interaction completed successfully!")
            if !isConversationCancelled {
                await setState(.idle)
            }
            
        } catch {
            print("VoiceAgent: Error in unified voice interaction: \(error.localizedDescription)")
            if !isConversationCancelled {
                await setError(error.localizedDescription)
            }
        }
    }
    
    func runVoiceInteraction(userName: String? = nil) async {
        do {
            // Step 0: Play initial greeting and add to conversation history
            print("VoiceAgent: Step 0 - Playing initial greeting...")
            await setState(.generatingSpeech)
            let greeting = generateBillsGreeting(userName: userName)
            
            // Add greeting to conversation history so Claude knows it already greeted the user
            conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(greeting)))
            
            let greetingAudioData = try await generateSpeech(from: greeting)
            
            await setState(.playingResponse)
            try await playResponse(audioData: greetingAudioData)
            
            // Continuous conversation loop
            var conversationActive = true
            var turnCount = 0
            let maxTurns = 10 // Safety limit
            let maxNoAudioRetries = 2 // Maximum attempts when no audio detected
            
            while conversationActive && turnCount < maxTurns && !isConversationCancelled {
                // Check for cancellation
                if Task.isCancelled || isConversationCancelled {
                    print("VoiceAgent: Conversation cancelled by user")
                    break
                }
                turnCount += 1
                print("VoiceAgent: Conversation turn \(turnCount)")
                
                var noAudioRetryCount = 0
                var turnCompleted = false
                
                while !turnCompleted && noAudioRetryCount <= maxNoAudioRetries && !isConversationCancelled {
                    // Check for cancellation before each step
                    if Task.isCancelled || isConversationCancelled {
                        print("VoiceAgent: Conversation cancelled - stopping immediately")
                        turnCompleted = true
                        conversationActive = false
                        break
                    }
                    
                    do {
                        // Step 1: Record audio with retry logic
                        print("VoiceAgent: Step 1 - Recording audio...")
                        guard !isConversationCancelled else { break }
                        await setState(.recording)
                        // Use longer timeout for first turn or after retries, normal timeout otherwise
                        let timeoutDuration: TimeInterval = (turnCount == 1 || noAudioRetryCount > 0) ? 15 : 10
                        let audioURL = try await startRecording(timeoutSeconds: timeoutDuration)
                        
                        // Check for cancellation after recording
                        guard !isConversationCancelled else { break }
                        
                        // Step 2: Transcribe audio
                        print("VoiceAgent: Step 2 - Transcribing audio...")
                        await setState(.transcribing)
                        let transcription = try await transcribeAudio(url: audioURL)
                        
                        // Check for cancellation after transcription
                        guard !isConversationCancelled else { break }
                        
                        // Check if transcription is meaningful
                        if transcription.count < 2 {
                            print("VoiceAgent: Very short transcription detected, might be just noise")
                            noAudioRetryCount += 1
                            if noAudioRetryCount <= maxNoAudioRetries && !isConversationCancelled {
                                print("VoiceAgent: Retrying... (attempt \(noAudioRetryCount + 1))")
                                let retryMessage = noAudioRetryCount == 1 ? 
                                    "I didn't catch that. Could you please repeat?" :
                                    "I'm still having trouble hearing you. Could you speak a bit louder?"
                                
                                let retryAudioData = try await generateSpeech(from: retryMessage)
                                await setState(.playingResponse)
                                try await playResponse(audioData: retryAudioData)
                                continue
                            }
                        }
                        
                        // Step 3: Process with Claude
                        print("VoiceAgent: Step 3 - Processing with Claude...")
                        await setState(.processing)
                        let aiResponse = try await processUserMessage(transcription)
                        
                        // Check for cancellation after AI processing
                        guard !isConversationCancelled else { break }
                        
                        // Step 4: Generate speech
                        print("VoiceAgent: Step 4 - Generating speech...")
                        await setState(.generatingSpeech)
                        let audioData = try await generateSpeech(from: aiResponse)
                        
                        // Check for cancellation after speech generation
                        guard !isConversationCancelled else { break }
                        
                        // Step 5: Play response
                        print("VoiceAgent: Step 5 - Playing response...")
                        await setState(.playingResponse)
                        try await playResponse(audioData: audioData)
                        
                        // Check if conversation should end
                        if shouldEndConversation(transcription) {
                            print("VoiceAgent: User indicated they are done")
                            conversationActive = false
                        }
                        
                        // Check if conversation should end (tool was used successfully)
                        if shouldEndAfterToolUse(aiResponse) {
                            print("VoiceAgent: Tool completed successfully, ending conversation")
                            conversationActive = false
                        }
                        
                        turnCompleted = true
                        
                    } catch VoiceAgentError.noAudioDetected {
                        noAudioRetryCount += 1
                        print("VoiceAgent: No audio detected (attempt \(noAudioRetryCount))")
                        
                        if noAudioRetryCount <= maxNoAudioRetries && !isConversationCancelled {
                            // Play a retry message
                            let retryMessage = noAudioRetryCount == 1 ? 
                                "I didn't hear anything. Please try speaking again." :
                                "Still no audio detected. Please make sure your microphone is working and try again."
                            
                            let retryAudioData = try await generateSpeech(from: retryMessage)
                            await setState(.playingResponse)
                            try await playResponse(audioData: retryAudioData)
                        } else if !isConversationCancelled {
                            // Max retries reached - pause conversation
                            await pauseConversation(reason: "No audio detected after multiple attempts")
                            conversationActive = false
                            turnCompleted = true
                        }
                    } catch {
                        // Other errors - handle gracefully and end conversation
                        print("VoiceAgent: Unhandled error in conversation: \(error)")
                        if !isConversationCancelled {
                            await setError("Something went wrong: \(error.localizedDescription)")
                        }
                        conversationActive = false
                        turnCompleted = true
                    }
                }
            }
            
            print("VoiceAgent: Voice interaction completed successfully!")
            if !isConversationCancelled {
                await setState(.idle)
            }
            
        } catch {
            print("VoiceAgent: Error in voice interaction: \(error.localizedDescription)")
            if !isConversationCancelled {
                await setError(error.localizedDescription)
            }
        }
    }
    
    func runExpenseVoiceInteraction(userName: String? = nil) async {
        do {
            // Step 0: Play initial greeting for expenses
            print("VoiceAgent: Step 0 - Playing expense greeting...")
            await setState(.generatingSpeech)
            let greeting = generateExpenseGreeting(userName: userName)
            
            // Add greeting to conversation history
            conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(greeting)))
            
            let greetingAudioData = try await generateSpeech(from: greeting)
            
            await setState(.playingResponse)
            try await playResponse(audioData: greetingAudioData)
            
            // Continuous conversation loop (similar to bills)
            var conversationActive = true
            var turnCount = 0
            let maxTurns = 10
            let maxNoAudioRetries = 2
            
            while conversationActive && turnCount < maxTurns && !isConversationCancelled {
                if Task.isCancelled || isConversationCancelled {
                    print("VoiceAgent: Conversation cancelled by user")
                    break
                }
                turnCount += 1
                print("VoiceAgent: Expense conversation turn \(turnCount)")
                
                var noAudioRetryCount = 0
                var turnCompleted = false
                
                while !turnCompleted && noAudioRetryCount <= maxNoAudioRetries && !isConversationCancelled {
                    if Task.isCancelled || isConversationCancelled {
                        print("VoiceAgent: Conversation cancelled - stopping immediately")
                        turnCompleted = true
                        conversationActive = false
                        break
                    }
                    
                    do {
                        // Step 1: Record audio
                        print("VoiceAgent: Step 1 - Recording audio...")
                        guard !isConversationCancelled else { break }
                        await setState(.recording)
                        // Use longer timeout for first turn or after retries, normal timeout otherwise
                        let timeoutDuration: TimeInterval = (turnCount == 1 || noAudioRetryCount > 0) ? 15 : 10
                        let audioURL = try await startRecording(timeoutSeconds: timeoutDuration)
                        
                        guard !isConversationCancelled else { break }
                        
                        // Step 2: Transcribe audio
                        print("VoiceAgent: Step 2 - Transcribing audio...")
                        await setState(.transcribing)
                        let transcription = try await transcribeAudio(url: audioURL)
                        
                        guard !isConversationCancelled else { break }
                        
                        // Check if transcription is meaningful
                        if transcription.count < 2 {
                            print("VoiceAgent: Very short transcription detected")
                            noAudioRetryCount += 1
                            if noAudioRetryCount <= maxNoAudioRetries && !isConversationCancelled {
                                print("VoiceAgent: Retrying... (attempt \(noAudioRetryCount + 1))")
                                let retryMessage = noAudioRetryCount == 1 ? 
                                    "I didn't catch that. Could you please repeat?" :
                                    "I'm still having trouble hearing you. Could you speak a bit louder?"
                                
                                let retryAudioData = try await generateSpeech(from: retryMessage)
                                await setState(.playingResponse)
                                try await playResponse(audioData: retryAudioData)
                                continue
                            }
                        }
                        
                        // Step 3: Process with expense context
                        print("VoiceAgent: Step 3 - Processing expense transcription...")
                        await setState(.processing)
                        let aiResponse = try await processExpenseUserMessage(transcription)
                        
                        guard !isConversationCancelled else { break }
                        
                        // Step 4: Generate speech
                        print("VoiceAgent: Step 4 - Generating speech...")
                        await setState(.generatingSpeech)
                        let audioData = try await generateSpeech(from: aiResponse)
                        
                        guard !isConversationCancelled else { break }
                        
                        // Step 5: Play response
                        print("VoiceAgent: Step 5 - Playing response...")
                        await setState(.playingResponse)
                        try await playResponse(audioData: audioData)
                        
                        // Check if conversation should end
                        if shouldEndAfterToolUse(aiResponse) {
                            print("VoiceAgent: Tool completed successfully, ending conversation")
                            conversationActive = false
                        }
                        
                        turnCompleted = true
                        
                    } catch {
                        // Handle errors similar to bills flow
                        guard !isConversationCancelled else {
                            print("VoiceAgent: Error handling skipped - conversation cancelled")
                            break
                        }
                        
                        if error is VoiceAgentError {
                            noAudioRetryCount += 1
                            print("VoiceAgent: No audio detected (attempt \(noAudioRetryCount))")
                            
                            if noAudioRetryCount <= maxNoAudioRetries && !isConversationCancelled {
                                let retryMessage = noAudioRetryCount == 1 ? 
                                    "I didn't hear anything. Please try speaking again." :
                                    "Still no audio detected. Please make sure your microphone is working."
                                
                                let retryAudioData = try await generateSpeech(from: retryMessage)
                                await setState(.playingResponse)
                                try await playResponse(audioData: retryAudioData)
                            } else if !isConversationCancelled {
                                await pauseConversation(reason: "No audio detected after multiple attempts")
                                conversationActive = false
                                turnCompleted = true
                            }
                        } else {
                            print("VoiceAgent: Unhandled error in conversation: \(error)")
                            if !isConversationCancelled {
                                await setError("Something went wrong: \(error.localizedDescription)")
                            }
                            conversationActive = false
                            turnCompleted = true
                        }
                    }
                }
            }
            
            print("VoiceAgent: Expense voice interaction completed successfully!")
            if !isConversationCancelled {
                await setState(.idle)
            }
            
        } catch {
            print("VoiceAgent: Error in expense voice interaction: \(error.localizedDescription)")
            if !isConversationCancelled {
                await setError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Conversation Pause/Resume
    
    func pauseConversation(reason: String) async {
        print("VoiceAgent: Pausing conversation - \(reason)")
        await setState(.paused)
        conversationPaused = true
        pauseReason = reason
        
        // Play pause message
        let pauseMessage = "I'll pause here for now. Double-tap and hold again anytime to continue our conversation where we left off."
        
        do {
            await setState(.generatingSpeech)
            let pauseAudioData = try await generateSpeech(from: pauseMessage)
            await setState(.playingResponse)
            try await playResponse(audioData: pauseAudioData)
        } catch {
            print("VoiceAgent: Failed to play pause message: \(error)")
        }
        
        await setState(.waitingForResume)
    }
    
    func resumeConversation() async {
        guard conversationPaused else {
            print("VoiceAgent: No paused conversation to resume")
            return
        }
        
        print("VoiceAgent: Resuming paused conversation")
        conversationPaused = false
        pauseReason = nil
        isConversationCancelled = false
        
        // Cancel any existing conversation task
        conversationTask?.cancel()
        
        // Create a new conversation task for resuming
        conversationTask = Task {
            await runResumeConversation()
        }
        
        await conversationTask?.value
    }
    
    func runResumeConversation() async {
        // Play resume message
        let resumeMessage = getResumeMessage()
        
        do {
            guard !isConversationCancelled else { return }
            await setState(.generatingSpeech)
            let resumeAudioData = try await generateSpeech(from: resumeMessage)
            
            guard !isConversationCancelled else { return }
            await setState(.playingResponse)
            try await playResponse(audioData: resumeAudioData)
            
            guard !isConversationCancelled else { return }
            // Continue the conversation loop
            await continueConversation()
            
        } catch {
            print("VoiceAgent: Error resuming conversation: \(error)")
            if !isConversationCancelled {
                await setError(error.localizedDescription)
            }
        }
    }
    
    func continueConversation() async {
        // Resume conversation loop from where we left off
        var conversationActive = true
        var turnCount = conversationHistory.count / 2 // Estimate current turn
        let maxTurns = 10
        let maxNoAudioRetries = 2
        
        while conversationActive && turnCount < maxTurns && !isConversationCancelled {
            // Check for cancellation at the start of each turn
            if Task.isCancelled || isConversationCancelled {
                print("VoiceAgent: Conversation cancelled - stopping immediately")
                break
            }
            turnCount += 1
            print("VoiceAgent: Resumed conversation turn \(turnCount)")
            
            var noAudioRetryCount = 0
            var turnCompleted = false
            
            while !turnCompleted && noAudioRetryCount <= maxNoAudioRetries && !isConversationCancelled {
                do {
                    // Record audio
                    guard !isConversationCancelled else { break }
                    await setState(.recording)
                    // Use appropriate timeout for resumed conversation
                    let timeoutDuration: TimeInterval = noAudioRetryCount > 0 ? 15 : 10
                    let audioURL = try await startRecording(timeoutSeconds: timeoutDuration)
                    
                    // Transcribe
                    guard !isConversationCancelled else { break }
                    await setState(.transcribing)
                    let transcription = try await transcribeAudio(url: audioURL)
                    
                    // Process
                    guard !isConversationCancelled else { break }
                    await setState(.processing)
                    let aiResponse = try await processUserMessage(transcription)
                    
                    // Generate speech
                    guard !isConversationCancelled else { break }
                    await setState(.generatingSpeech)
                    let audioData = try await generateSpeech(from: aiResponse)
                    
                    // Play response
                    guard !isConversationCancelled else { break }
                    await setState(.playingResponse)
                    try await playResponse(audioData: audioData)
                    
                    // Check if conversation should end
                    if shouldEndConversation(transcription) || shouldEndAfterToolUse(aiResponse) {
                        print("VoiceAgent: Conversation ending detected")
                        conversationActive = false
                    }
                    
                    turnCompleted = true
                    
                } catch {
                    // Handle errors
                    if !isConversationCancelled {
                        noAudioRetryCount += 1
                        if noAudioRetryCount <= maxNoAudioRetries {
                            let retryMessage = "I didn't catch that. Could you please repeat?"
                            let retryAudioData = try? await generateSpeech(from: retryMessage)
                            if let audioData = retryAudioData {
                                await setState(.playingResponse)
                                try? await playResponse(audioData: audioData)
                            }
                        } else {
                            await pauseConversation(reason: "Connection issue")
                            conversationActive = false
                            turnCompleted = true
                        }
                    }
                }
            }
        }
        
        if !isConversationCancelled {
            await setState(.idle)
        }
    }
    
    func getResumeMessage() -> String {
        if conversationHistory.isEmpty {
            return "Welcome back! How can I help you with your bills?"
        } else {
            return "Welcome back! We were working on your bills. Where would you like to continue?"
        }
    }
    
    // MARK: - Conversation End
    
    func endConversation() async {
        print("VoiceAgent: User requested to end conversation - terminating immediately")
        
        // Set cancellation flag immediately
        isConversationCancelled = true
        
        // Cancel the conversation task
        conversationTask?.cancel()
        conversationTask = nil
        
        // Immediately stop ALL operations
        voiceRecordingService.stopRecording()
        speechToTextService.stopTranscription()
        audioPlaybackService.stopPlayback()
        
        // Cancel any ongoing tasks
        recognitionTask?.cancel()
        
        // Clear conversation state immediately
        await clearConversationHistory()
        conversationPaused = false
        pauseReason = nil
        
        // Reset all published properties
        isRecording = false
        isTranscribing = false
        isProcessing = false
        isGeneratingSpeech = false
        isPlayingResponse = false
        transcriptionText = ""
        responseText = ""
        errorMessage = nil
        recordingLevel = 0.0
        
        await setState(.idle)
        
        print("VoiceAgent: Conversation ended and all operations terminated")
    }
    
    func stopVoiceInteraction() {
        voiceRecordingService.stopRecording()
        speechToTextService.stopTranscription()
        audioPlaybackService.stopPlayback()
        
        Task {
            await setState(.idle)
        }
    }
    
    // MARK: - Message Processing
    
    func processUserMessage(_ message: String) async throws -> String {
        print("VoiceAgent: Processing user message: '\(message)'")
        
        // Add user message to conversation history
        conversationHistory.append(AnthropicMessage(role: "user", content: .text(message)))
        
        // Get tools for bill context (since this is triggered from bill screen)
        let tools = getBillsTools()
        let systemPrompt = getBillsSystemPrompt()
        
        // Get response from Anthropic with conversational context
        let response = try await anthropicService.sendMessageWithTools(
            messages: conversationHistory,
            systemPrompt: systemPrompt,
            tools: tools
        )
        
        // Handle the response content
        switch response {
        case .text(let text):
            print("VoiceAgent: Got text response: '\(text)'")
            // Add AI response to conversation history
            conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(text)))
            return text
            
        case .toolUse(let id, let name, let input):
            print("VoiceAgent: Tool use requested: \(name)")
            print("VoiceAgent: Tool input: \(input)")
            
            // Execute the tool and get result
            let toolResult = await executeToolAndGetResult(toolId: id, name: name, input: input)
            print("VoiceAgent: Tool result: \(toolResult)")
            
            // Add tool use and result to conversation history
            conversationHistory.append(AnthropicMessage(
                role: "assistant",
                content: .toolUse(id: id, name: name, input: input)
            ))
            conversationHistory.append(AnthropicMessage(
                role: "user",
                content: .toolResult(toolUseId: id, content: toolResult)
            ))
            
            // Get Claude's response after tool execution
            let followUpResponse = try await anthropicService.sendMessageWithTools(
                messages: conversationHistory,
                systemPrompt: systemPrompt,
                tools: tools
            )
            
            switch followUpResponse {
            case .text(let text):
                print("VoiceAgent: Got follow-up response: '\(text)'")
                // Add AI response to conversation history
                conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(text)))
                return text
            case .toolUse:
                // If Claude wants to use another tool, just return a message
                return "I've completed that action for you."
            case .toolResult:
                // Unexpected - shouldn't happen
                return "I've processed that information."
            }
            
        case .toolResult:
            // Unexpected - shouldn't happen here
            return "Something went wrong with the request."
        }
    }
    
    func processExpenseUserMessage(_ message: String) async throws -> String {
        print("VoiceAgent: Processing expense user message: '\(message)'")
        
        // Add user message to conversation history
        conversationHistory.append(AnthropicMessage(role: "user", content: .text(message)))
        
        // Get tools for expense context
        let tools = getExpenseTools()
        let systemPrompt = getExpenseSystemPrompt()
        
        // Get response from Anthropic with conversational context
        let response = try await anthropicService.sendMessageWithTools(
            messages: conversationHistory,
            systemPrompt: systemPrompt,
            tools: tools
        )
        
        // Handle the response content
        switch response {
        case .text(let text):
            print("VoiceAgent: Got text response: '\(text)'")
            // Add AI response to conversation history
            conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(text)))
            return text
            
        case .toolUse(let id, let name, let input):
            print("VoiceAgent: Tool use requested: \(name)")
            print("VoiceAgent: Tool input: \(input)")
            
            // Execute the tool and get result
            let toolResult = await executeExpenseToolAndGetResult(toolId: id, name: name, input: input)
            print("VoiceAgent: Tool result: \(toolResult)")
            
            // Add tool use and result to conversation history
            conversationHistory.append(AnthropicMessage(
                role: "assistant",
                content: .toolUse(id: id, name: name, input: input)
            ))
            conversationHistory.append(AnthropicMessage(
                role: "user",
                content: .toolResult(toolUseId: id, content: toolResult)
            ))
            
            // Get Claude's response after tool execution
            let followUpResponse = try await anthropicService.sendMessageWithTools(
                messages: conversationHistory,
                systemPrompt: systemPrompt,
                tools: tools
            )
            
            switch followUpResponse {
            case .text(let text):
                print("VoiceAgent: Got follow-up response: '\(text)'")
                // Add AI response to conversation history
                conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(text)))
                return text
            case .toolUse:
                // If Claude wants to use another tool, just return a message
                return "I've added that expense for you."
            case .toolResult:
                // Unexpected
                return "I've processed that information."
            }
            
        case .toolResult:
            // Unexpected
            return "Something went wrong with the request."
        }
    }
    
    // MARK: - Quick Actions
    
    func processTextDirectly(_ text: String) async {
        do {
            await setState(.processing)
            let aiResponse = try await processUserMessage(text)
            
            await setState(.generatingSpeech)
            let audioData = try await generateSpeech(from: aiResponse)
            
            await setState(.playingResponse)
            try await playResponse(audioData: audioData)
            
            
            await setState(.idle)
            
        } catch {
            await setError(error.localizedDescription)
        }
    }
    
    // MARK: - Conversation Helpers
    
    func shouldEndConversation(_ transcription: String) -> Bool {
        let lowerText = transcription.lowercased()
        let endPhrases = ["done", "that's all", "goodbye", "bye", "thank you", "thanks", "stop", "exit", "quit"]
        return endPhrases.contains { lowerText.contains($0) }
    }
    
    func shouldEndAfterToolUse(_ response: String) -> Bool {
        // End conversation if the response indicates a tool was used successfully
        let lowerResponse = response.lowercased()
        let successPhrases = ["successfully created", "i've created", "bill has been added", "added to your bills"]
        return successPhrases.contains { lowerResponse.contains($0) }
    }
    
    // MARK: - Greeting Generation
    
    func generateUnifiedGreeting(userName: String?) -> String {
        let greeting = userName != nil ? "Hi \(userName!), " : "Hi there, "
        return greeting + "I'm Norma, your financial assistant. I can help you manage bills, track expenses, or check your income. What would you like to do?"
    }
    
    // MARK: - State Management
    
    func setState(_ state: VoiceAgentState) async {
        currentState = state
        
        // Update individual state flags
        isRecording = (state == .recording)
        isTranscribing = (state == .transcribing)
        isProcessing = (state == .processing)
        isGeneratingSpeech = (state == .generatingSpeech)
        isPlayingResponse = (state == .playingResponse)
        
        if case .error(let message) = state {
            errorMessage = message
        } else {
            errorMessage = nil
        }
    }
    
    func setError(_ message: String) async {
        await setState(.error(message))
        audioPlaybackService.playErrorSound()
    }
    
    func resetState() async {
        transcriptionText = ""
        responseText = ""
        errorMessage = nil
        // Only clear conversation history if not paused
        if !conversationPaused {
            conversationHistory.removeAll()
        }
        await setState(.idle)
    }
    
    func clearConversationHistory() async {
        conversationHistory.removeAll()
        conversationPaused = false
        pauseReason = nil
    }
    
    // MARK: - Intent Recognition
    
    func determineIntent(from transcription: String) -> VoiceIntent {
        let lowerText = transcription.lowercased()
        
        // Simple keyword-based intent recognition
        let expenseKeywords = ["spent", "bought", "paid", "cost", "expense", "purchase", "money for"]
        let billKeywords = ["bill", "due", "monthly", "quarterly", "yearly", "recurring", "remind me"]
        
        if expenseKeywords.contains(where: { lowerText.contains($0) }) {
            return .expense
        } else if billKeywords.contains(where: { lowerText.contains($0) }) {
            return .bill
        } else {
            return .general
        }
    }
    
    enum VoiceIntent {
        case expense
        case bill
        case general
    }
}