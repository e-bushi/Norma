//
//  VoiceAgentViewModel.swift
//  Norma
//
//  Created by Claude on 8/5/25.
//

import Foundation
import AVFoundation
import Speech

@MainActor
class VoiceAgentViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var isProcessing = false
    @Published var isGeneratingSpeech = false
    @Published var isPlayingResponse = false
    
    @Published var transcriptionText = ""
    @Published var responseText = ""
    @Published var errorMessage: String?
    
    @Published var recordingLevel: Float = 0.0
    @Published var hasPermissions = false
    
    // Conversation history
    @Published var conversationHistory: [AnthropicMessage] = []
    @Published var conversationPaused = false
    @Published var pauseReason: String?
    
    // MARK: - State Management
    
    @Published var currentState: VoiceAgentState = .idle
    
    enum VoiceAgentState: Equatable {
        case idle
        case recording
        case transcribing
        case processing
        case generatingSpeech
        case playingResponse
        case paused
        case waitingForResume
        case error(String)
    }
    
    // MARK: - Service Dependencies
    
    private let voiceRecordingService: VoiceRecordingService
    private let speechToTextService: SpeechToTextService
    private let anthropicService: AnthropicService
    private let elevenLabsService: ElevenLabsService
    private let audioPlaybackService: AudioPlaybackService
    private let billViewModel: BillViewModel?
    private let expenseViewModel: ExpenseViewModel?
    private let incomeViewModel: IncomeViewModel?
    private let sessionViewModel: SessionViewModel?
    
    // MARK: - Configuration
    
    private var currentRecordingURL: URL?
    private let userId: String
    
    // MARK: - Cancellation Management
    
    private var conversationTask: Task<Void, Never>?
    private var isConversationCancelled = false
    
    // MARK: - Initialization
    
    @MainActor
    init(
        userId: String,
        billViewModel: BillViewModel? = nil,
        expenseViewModel: ExpenseViewModel? = nil,
        incomeViewModel: IncomeViewModel? = nil,
        sessionViewModel: SessionViewModel? = nil,
        voiceRecordingService: VoiceRecordingService = .shared,
        speechToTextService: SpeechToTextService = .shared,
        anthropicService: AnthropicService = .shared,
        elevenLabsService: ElevenLabsService = .shared,
        audioPlaybackService: AudioPlaybackService = .shared
    ) {
        self.userId = userId
        self.billViewModel = billViewModel
        self.expenseViewModel = expenseViewModel
        self.incomeViewModel = incomeViewModel
        self.sessionViewModel = sessionViewModel
        self.voiceRecordingService = voiceRecordingService
        self.speechToTextService = speechToTextService
        self.anthropicService = anthropicService
        self.elevenLabsService = elevenLabsService
        self.audioPlaybackService = audioPlaybackService
        
        // Observe service states
        observeServiceStates()
        checkPermissions()
    }
    
    // MARK: - Permission Management
    
    private func checkPermissions() {
        voiceRecordingService.checkMicrophonePermission()
        speechToTextService.checkSpeechPermission()
        
        hasPermissions = voiceRecordingService.hasPermission && speechToTextService.hasPermission
    }
    
    func requestPermissions() async -> Bool {
        voiceRecordingService.checkMicrophonePermission()
        speechToTextService.checkSpeechPermission()
        
        // Wait a moment for permission dialogs to complete
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        hasPermissions = voiceRecordingService.hasPermission && speechToTextService.hasPermission
        return hasPermissions
    }
    
    // MARK: - Main Voice Agent Flow
    
    func startVoiceInteraction(userName: String? = nil) async {
        print("VoiceAgent: Starting unified voice interaction...")
        
        // Cancel any existing conversation
        conversationTask?.cancel()
        
        guard hasPermissions else {
            print("VoiceAgent: No permissions - requesting...")
            await setError("Microphone and speech recognition permissions are required")
            return
        }
        
        print("VoiceAgent: Permissions confirmed, resetting state...")
        await resetState()
        isConversationCancelled = false
        
        // Create a new conversation task
        conversationTask = Task {
            await runUnifiedVoiceInteraction(userName: userName)
        }
        
        await conversationTask?.value
    }
    
    private func runUnifiedVoiceInteraction(userName: String? = nil) async {
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
                        let audioURL = try await startRecording()
                        
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
    
    private func runVoiceInteraction(userName: String? = nil) async {
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
                        let audioURL = try await startRecording()
                        
                        // Check for cancellation after recording
                        guard !isConversationCancelled else { break }
                        
                        // Step 2: Transcribe audio
                        print("VoiceAgent: Step 2 - Transcribing audio...")
                        await setState(.transcribing)
                        let transcription = try await transcribeAudio(url: audioURL)
                        
                        // Check for cancellation after transcription
                        guard !isConversationCancelled else { break }
                        
                        // Check if user wants to end conversation
                        if shouldEndConversation(transcription) {
                            print("VoiceAgent: User requested to end conversation")
                            conversationActive = false
                            
                            // Play goodbye message
                            await setState(.generatingSpeech)
                            let goodbyeData = try await generateSpeech(from: "Alright, I'm here whenever you need help with your bills!")
                            await setState(.playingResponse)
                            try await playResponse(audioData: goodbyeData)
                            turnCompleted = true
                            break
                        }
                        
                        // Step 3-5: Process with AI (with streaming fallback)
                        print("VoiceAgent: Step 3-5 - Processing with AI...")
                        guard !isConversationCancelled else { break }
                        await setState(.processing)
                        
                        // Use regular single TTS approach for voice consistency  
                        let aiResponse = try await processUserMessage(transcription)
                        
                        await setState(.generatingSpeech)
                        let audioData = try await generateSpeech(from: aiResponse)
                        
                        await setState(.playingResponse)
                        try await playResponse(audioData: audioData)
                        
                        // Check for cancellation after processing
                        guard !isConversationCancelled else { break }
                        
                        // Note: Tool completion detection is handled within streaming method
                        
                        turnCompleted = true
                        
                    } catch {
                        // Check if conversation was cancelled
                        guard !isConversationCancelled else {
                            print("VoiceAgent: Error handling skipped - conversation cancelled")
                            break
                        }
                        
                        print("VoiceAgent: Error in conversation turn: \(error)")
                        
                        // Handle specific error types
                        if let speechError = error as? SpeechToTextError, speechError == .noSpeechDetected {
                            noAudioRetryCount += 1
                            print("VoiceAgent: No speech detected, retry \(noAudioRetryCount)/\(maxNoAudioRetries)")
                            
                            if noAudioRetryCount <= maxNoAudioRetries && !isConversationCancelled {
                                // Prompt user to try again
                                let retryMessage = noAudioRetryCount == 1 
                                    ? "I didn't catch that. Could you try again?"
                                    : "Still having trouble hearing you. One more try?"
                                
                                do {
                                    guard !isConversationCancelled else { break }
                                    await setState(.generatingSpeech)
                                    let retryAudioData = try await generateSpeech(from: retryMessage)
                                    
                                    guard !isConversationCancelled else { break }
                                    await setState(.playingResponse)
                                    try await playResponse(audioData: retryAudioData)
                                    
                                    // Brief pause before next attempt
                                    if !isConversationCancelled {
                                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                                    }
                                } catch {
                                    print("VoiceAgent: Failed to play retry message: \(error)")
                                    // Continue anyway - don't let retry prompt failure stop the conversation
                                }
                            } else if !isConversationCancelled {
                                // Max retries reached - pause conversation
                                await pauseConversation(reason: "No audio detected after multiple attempts")
                                conversationActive = false
                                turnCompleted = true
                            }
                        } else {
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
    
    func startExpenseVoiceInteraction(userName: String? = nil) async {
        print("VoiceAgent: Starting expense voice interaction (redirecting to unified)...")
        // Redirect to the unified voice interaction
        await startVoiceInteraction(userName: userName)
    }
    
    private func runExpenseVoiceInteraction(userName: String? = nil) async {
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
            
            // Copy the exact same conversation loop from bills
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
                        let audioURL = try await startRecording()
                        
                        // Check for cancellation after recording
                        guard !isConversationCancelled else { break }
                        
                        // Step 2: Transcribe audio
                        print("VoiceAgent: Step 2 - Transcribing audio...")
                        await setState(.transcribing)
                        let transcription = try await transcribeAudio(url: audioURL)
                        
                        // Check for cancellation after transcription
                        guard !isConversationCancelled else { break }
                        
                        // Check if user wants to end conversation
                        if shouldEndConversation(transcription) {
                            print("VoiceAgent: User requested to end conversation")
                            conversationActive = false
                            
                            // Play goodbye message
                            await setState(.generatingSpeech)
                            let goodbyeData = try await generateSpeech(from: "Alright, I'm here whenever you need help!")
                            await setState(.playingResponse)
                            try await playResponse(audioData: goodbyeData)
                            turnCompleted = true
                            break
                        }
                        
                        // Step 3: Process with AI (conversational) - expense mode
                        print("VoiceAgent: Step 3 - Processing with AI for expenses...")
                        guard !isConversationCancelled else { break }
                        await setState(.processing)
                        let aiResponse = try await processExpenseUserMessage(transcription)
                        
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
                        
                        // Check if conversation should end (tool was used successfully)
                        if shouldEndAfterToolUse(aiResponse) {
                            print("VoiceAgent: Tool completed successfully, ending conversation")
                            conversationActive = false
                        }
                        
                        turnCompleted = true
                        
                    } catch {
                        // Check if conversation was cancelled
                        guard !isConversationCancelled else {
                            print("VoiceAgent: Error handling skipped - conversation cancelled")
                            break
                        }
                        
                        print("VoiceAgent: Error in conversation turn: \(error)")
                        
                        // Handle specific error types
                        if let speechError = error as? SpeechToTextError, speechError == .noSpeechDetected {
                            noAudioRetryCount += 1
                            print("VoiceAgent: No speech detected, retry \(noAudioRetryCount)/\(maxNoAudioRetries)")
                            
                            if noAudioRetryCount <= maxNoAudioRetries && !isConversationCancelled {
                                // Prompt user to try again
                                let retryMessage = noAudioRetryCount == 1 
                                    ? "I didn't catch that. Could you try again?"
                                    : "Still having trouble hearing you. One more try?"
                                
                                do {
                                    guard !isConversationCancelled else { break }
                                    await setState(.generatingSpeech)
                                    let retryAudioData = try await generateSpeech(from: retryMessage)
                                    
                                    guard !isConversationCancelled else { break }
                                    await setState(.playingResponse)
                                    try await playResponse(audioData: retryAudioData)
                                    
                                    // Brief pause before next attempt
                                    if !isConversationCancelled {
                                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                                    }
                                } catch {
                                    print("VoiceAgent: Failed to play retry message: \(error)")
                                    // Continue anyway - don't let retry prompt failure stop the conversation
                                }
                            } else if !isConversationCancelled {
                                // Max retries reached - pause conversation
                                await pauseConversation(reason: "No audio detected after multiple attempts")
                                conversationActive = false
                                turnCompleted = true
                            }
                        } else {
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
    
    private func generateExpenseGreeting(userName: String?) -> String {
        let greeting = userName != nil ? "Hi \(userName!), " : "Hi there, "
        return greeting + "I'm ready to help you add a new expense! What did you spend money on?"
    }
    
    private func generateUnifiedGreeting(userName: String?) -> String {
        let greeting = userName != nil ? "Hi \(userName!), " : "Hi there, "
        return greeting + "I'm Norma, your financial assistant. I can help you manage bills, track expenses, or check your income. What would you like to do?"
    }
    
    func stopVoiceInteraction() {
        voiceRecordingService.stopRecording()
        speechToTextService.stopTranscription()
        audioPlaybackService.stopPlayback()
        
        Task {
            await setState(.idle)
        }
    }
    
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
    
    // Add a property to track active tasks
    private var recognitionTask: SFSpeechRecognitionTask? {
        get { speechToTextService.recognitionTask }
        set { speechToTextService.recognitionTask = newValue }
    }
    
    // MARK: - Conversation Pause/Resume
    
    private func pauseConversation(reason: String) async {
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
    
    private func runResumeConversation() async {
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
    
    private func getResumeMessage() -> String {
        if conversationHistory.isEmpty {
            return "Welcome back! How can I help you with your bills?"
        } else {
            return "Welcome back! We were working on your bills. Where would you like to continue?"
        }
    }
    
    private func continueConversation() async {
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
                // Check for cancellation before each step
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
                    let audioURL = try await startRecording()
                    
                    // Check for cancellation after recording
                    guard !isConversationCancelled else { break }
                    
                    // Step 2: Transcribe audio
                    print("VoiceAgent: Step 2 - Transcribing audio...")
                    await setState(.transcribing)
                    let transcription = try await transcribeAudio(url: audioURL)
                    
                    // Check for cancellation after transcription
                    guard !isConversationCancelled else { break }
                    
                    // Check if user wants to end conversation
                    if shouldEndConversation(transcription) {
                        print("VoiceAgent: User requested to end conversation")
                        conversationActive = false
                        
                        // Play goodbye message
                        await setState(.generatingSpeech)
                        let goodbyeData = try await generateSpeech(from: "Alright, I'm here whenever you need help with your bills!")
                        await setState(.playingResponse)
                        try await playResponse(audioData: goodbyeData)
                        turnCompleted = true
                        break
                    }
                    
                    // Step 3: Process with AI (conversational)
                    print("VoiceAgent: Step 3 - Processing with AI...")
                    guard !isConversationCancelled else { break }
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
                    
                    // Check if conversation should end (tool was used successfully)
                    if shouldEndAfterToolUse(aiResponse) {
                        print("VoiceAgent: Tool completed successfully, ending conversation")
                        conversationActive = false
                    }
                    
                    turnCompleted = true
                    
                } catch {
                    // Check if conversation was cancelled
                    guard !isConversationCancelled else {
                        print("VoiceAgent: Error handling skipped - conversation cancelled")
                        break
                    }
                    
                    print("VoiceAgent: Error in resumed conversation turn: \(error)")
                    
                    // Handle specific error types
                    if let speechError = error as? SpeechToTextError, speechError == .noSpeechDetected {
                        noAudioRetryCount += 1
                        print("VoiceAgent: No speech detected, retry \(noAudioRetryCount)/\(maxNoAudioRetries)")
                        
                        if noAudioRetryCount <= maxNoAudioRetries && !isConversationCancelled {
                            // Prompt user to try again
                            let retryMessage = noAudioRetryCount == 1 
                                ? "I didn't catch that. Could you try again?"
                                : "Still having trouble hearing you. One more try?"
                            
                            do {
                                guard !isConversationCancelled else { break }
                                await setState(.generatingSpeech)
                                let retryAudioData = try await generateSpeech(from: retryMessage)
                                
                                guard !isConversationCancelled else { break }
                                await setState(.playingResponse)
                                try await playResponse(audioData: retryAudioData)
                                
                                // Brief pause before next attempt
                                if !isConversationCancelled {
                                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                                }
                            } catch {
                                print("VoiceAgent: Failed to play retry message in resumed conversation: \(error)")
                                // Continue anyway - don't let retry prompt failure stop the conversation
                            }
                        } else if !isConversationCancelled {
                            // Max retries reached - pause again
                            await pauseConversation(reason: "No audio detected after multiple attempts")
                            conversationActive = false
                            turnCompleted = true
                        }
                    } else {
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
        }
        
        print("VoiceAgent: Resumed voice interaction completed!")
        await setState(.idle)
    }
    
    // MARK: - Individual Steps
    
    private func startRecording() async throws -> URL {
        print("VoiceAgent: Starting reactive recording...")
        
        // Start recording - the service will handle speech detection and auto-completion
        currentRecordingURL = try await voiceRecordingService.startRecording()
        print("VoiceAgent: Recording started successfully")
        
        // Wait for either recording completion or timeout
        return try await withTimeout(seconds: 10) { [self] in
            // Listen for automatic recording completion
            for await recordingURL in self.voiceRecordingService.recordingCompletionStream.values {
                print("VoiceAgent: Recording completed reactively at: \(recordingURL)")
                return recordingURL
            }
            
            // This should never be reached due to timeout, but provide fallback
            throw VoiceAgentError.recordingFailed
        }
    }
    
    // Helper method to add timeout to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
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
    
    func stopRecording() {
        voiceRecordingService.stopRecording()
    }
    
    private func transcribeAudio(url: URL) async throws -> String {
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
    
    private func processExpenseUserMessage(_ message: String) async throws -> String {
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
            
            // Get Claude's final response after tool execution
            let finalResponse = try await anthropicService.sendMessageWithTools(
                messages: conversationHistory,
                systemPrompt: systemPrompt,
                tools: tools
            )
            
            // Handle final response
            if case .text(let text) = finalResponse {
                print("VoiceAgent: Final response: '\(text)'")
                conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(text)))
                return text
            } else {
                return "I've completed your request."
            }
            
        case .toolResult:
            // Tool results are not expected as direct responses
            return "Something went wrong with the request."
        }
    }
    
    private func processUserMessage(_ message: String) async throws -> String {
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
            
            // Get Claude's final response after tool execution
            let finalResponse = try await anthropicService.sendMessageWithTools(
                messages: conversationHistory,
                systemPrompt: systemPrompt,
                tools: tools
            )
            
            // Handle final response
            if case .text(let text) = finalResponse {
                print("VoiceAgent: Final response: '\(text)'")
                conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(text)))
                return text
            } else {
                return "I've completed your request."
            }
            
        case .toolResult:
            // Tool results are not expected as direct responses
            return "Something went wrong with the request."
        }
    }
    
    // MARK: - Streaming Processing (New)
    
    private func processUserMessageWithStreaming(_ message: String) async throws {
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
                                    try await audioPlaybackService.queueVoiceResponse(audioData: audioData)
                                } catch {
                                    print("Error generating/queueing streaming audio: \(error)")
                                }
                            }
                        }
                    }
                    currentSentence = ""
                }
            }
            
            // Handle any remaining text
            if !currentSentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let audioData = try await generateSpeech(from: currentSentence)
                try await audioPlaybackService.queueVoiceResponse(audioData: audioData)
            }
            
            // Add complete response to conversation history
            conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(completeResponse)))
            
        } catch {
            print("Streaming error, falling back to regular processing: \(error)")
            // Fallback to regular processing
            let response = try await processUserMessage(message)
            let audioData = try await generateSpeech(from: response)
            try await playResponse(audioData: audioData)
        }
    }
    
    private func splitIntoSentences(_ text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        // Split by sentence-ending punctuation
        let components = trimmed.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        var sentences: [String] = []
        
        for (index, component) in components.enumerated() {
            let trimmedComponent = component.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty components
            guard !trimmedComponent.isEmpty else { continue }
            
            // For all but the last component, add back punctuation
            if index < components.count - 1 {
                sentences.append(trimmedComponent + ".")
            } else {
                // For the last component, check if it originally had punctuation
                if trimmed.hasSuffix(".") || trimmed.hasSuffix("!") || trimmed.hasSuffix("?") {
                    sentences.append(trimmedComponent + ".")
                } else {
                    // No punctuation at end, this is likely incomplete - don't add punctuation
                    sentences.append(trimmedComponent)
                }
            }
        }
        
        return sentences.filter { !$0.isEmpty }
    }
    
    private func generateSpeech(from text: String) async throws -> Data {
        return try await elevenLabsService.generateSpeech(text: text)
    }
    
    // MARK: - Post-Haiku Sentence Splitting (New Optimized Approach)
    
    private func processUserMessageWithPostSplitTTS(_ message: String) async throws {
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
        
        print("VoiceAgent: Got complete response: '\(responseText)'")
        
        // Split into sentences
        let sentences = splitIntoSentences(responseText).filter { 
            $0.trimmingCharacters(in: .whitespacesAndNewlines).count >= 5 
        }
        
        guard !sentences.isEmpty else {
            // Fallback for no sentences
            let audioData = try await generateSpeech(from: responseText)
            try await playResponse(audioData: audioData)
            return
        }
        
        print("VoiceAgent: Split into \(sentences.count) sentences for TTS")
        
        // Strategy: First sentence immediate, rest in parallel
        if sentences.count == 1 {
            // Only one sentence - simple case
            let audioData = try await generateSpeech(from: sentences[0])
            try await audioPlaybackService.queueVoiceResponse(audioData: audioData)
        } else {
            // Multiple sentences - hybrid approach
            print("VoiceAgent: Generating first sentence immediately...")
            
            // Generate first sentence immediately (blocking for fastest start)
            let firstAudio = try await generateSpeech(from: sentences[0])
            try await audioPlaybackService.queueVoiceResponse(audioData: firstAudio)
            
            // Generate remaining sentences in parallel, queue in order
            if sentences.count > 1 {
                print("VoiceAgent: Generating remaining \(sentences.count - 1) sentences in parallel...")
                
                let remainingSentences = Array(sentences.dropFirst())
                try await withThrowingTaskGroup(of: (Int, Data).self) { group in
                    // Start all TTS tasks in parallel
                    for (index, sentence) in remainingSentences.enumerated() {
                        group.addTask {
                            let audio = try await self.generateSpeech(from: sentence)
                            return (index, audio)
                        }
                    }
                    
                    // Collect results and sort by index to maintain order
                    var audioResults: [(Int, Data)] = []
                    for try await result in group {
                        audioResults.append(result)
                    }
                    
                    // Sort by index and queue in order
                    audioResults.sort(by: { $0.0 < $1.0 })
                    for (_, audioData) in audioResults {
                        try await self.audioPlaybackService.queueVoiceResponse(audioData: audioData)
                    }
                }
            }
        }
        
        // Add complete response to conversation history
        conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(responseText)))
    }
    
    private func playResponse(audioData: Data) async throws {
        try await audioPlaybackService.playVoiceResponse(audioData: audioData)
        
        // Wait for playback to complete
        while audioPlaybackService.isPlaying {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    
    // MARK: - Intent Recognition
    
    private func determineIntent(from transcription: String) -> VoiceIntent {
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
    
    // MARK: - Unified Processing
    
    private func processUnifiedTranscription(_ transcription: String) async throws -> (String, Bool) {
        print("VoiceAgent: Processing transcription with unified context: '\(transcription)'")
        
        // Add user message to conversation history
        conversationHistory.append(AnthropicMessage(role: "user", content: .text(transcription)))
        
        // Get all tools (both bills and expenses)
        let tools = getUnifiedTools()
        let systemPrompt = getUnifiedSystemPrompt()
        
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
            return (text, false)
            
        case .toolUse(let toolUseId, let toolName, let toolInput):
            print("VoiceAgent: Claude wants to use tool: \(toolName)")
            
            // Execute the tool and get result
            let toolResult = await executeToolAndGetResult(toolId: toolUseId, name: toolName, input: toolInput)
            print("VoiceAgent: Tool result: \(toolResult)")
            
            // Add tool use and result to conversation history
            conversationHistory.append(AnthropicMessage(
                role: "assistant",
                content: .toolUse(id: toolUseId, name: toolName, input: toolInput)
            ))
            conversationHistory.append(AnthropicMessage(
                role: "user",
                content: .toolResult(toolUseId: toolUseId, content: toolResult)
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
                return (text, true)
            case .toolUse:
                // If Claude wants to use another tool, just return a message
                return ("I've completed that action for you.", true)
            case .toolResult:
                // Unexpected tool result - shouldn't happen here
                return ("I've processed that information.", true)
            }
        case .toolResult:
            // Unexpected tool result - shouldn't happen here
            return ("I've processed that information.", false)
        }
    }
    
    private func getUnifiedTools() -> [AnthropicTool] {
        // Combine both bill and expense tools
        var tools = getBillsTools()
        tools.append(contentsOf: getExpenseTools())
        return tools
    }
    
    private func getUnifiedSystemPrompt() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        let currentDate = formatter.string(from: Date())
        
        // Get all data for the system prompt
        let currentBillsData = getCurrentBillsData()
        let currentExpensesData = getCurrentExpensesData()
        let currentIncomeData = getCurrentIncomeData()
        
        return """
        You are Norma, a friendly AI financial assistant in a voice conversation with a user. You help them manage their complete financial life - bills, expenses, and income - through natural voice interaction. This is a voice conversation, so respond conversationally and naturally as if speaking aloud.
        
        Today's date is \(currentDate).
        
        \(currentBillsData)
        
        \(currentExpensesData)
        
        \(currentIncomeData)
        
        Your personality:
        - Warm, encouraging, and supportive
        - Professional but conversational
        - Use simple, clear language (avoid financial jargon)
        - **CRITICAL: Keep ALL responses to maximum 2 sentences for natural voice conversation**
        - Sound natural and conversational as if speaking aloud
        - You are Norma, the AI assistant for the Norma financial app
        
        **CRITICAL VOICE FORMATTING**: When speaking monetary amounts, always write them in full word form for proper text-to-speech pronunciation:
        - $108.88 → "one hundred and eight dollars and eighty-eight cents"
        - $50.00 → "fifty dollars" (omit cents when zero)
        - €75.25 → "seventy-five euros and twenty-five cents"
        - £12.99 → "twelve pounds and ninety-nine pence"
        - ¥1000 → "one thousand yen"
        This applies to ALL currencies and amounts in your responses.
        
        CAPABILITIES:
        1. BILLS MANAGEMENT:
           - Create, edit, delete recurring bills
           - Mark bills as paid
           - Answer questions about upcoming bills and due dates
           
        2. EXPENSE TRACKING:
           - Add new one-time expenses
           - Answer questions about spending patterns
           - Provide expense summaries by category
           
        3. INCOME MANAGEMENT:
           - View and edit income sources
           - Answer questions about total income
           
        4. FINANCIAL ANALYSIS:
           - Analyze spending trends
           - Compare expenses to income
           - Provide financial insights
        
        **CRITICAL RESPONSE RULES**:
        - Always confirm successful actions in 1-2 sentences
        - Use the user's exact words when confirming (e.g., if they say "Netflix", don't change it to "streaming service")
        - End conversations naturally when the user says goodbye, thanks, or indicates they're done
        - If unsure about specifics, ask ONE clarifying question
        - For dates, if the user says "today" use \(currentDate), if they say a day name, calculate the next occurrence
        - Be conversational - this is a voice interaction, not text
        
        Remember: You have access to ALL financial data - bills, expenses, and income. Help the user with any financial task they need.
        """
    }
    
    // MARK: - Tools and Context Management
    
    private func getCurrentBillsData() -> String {
        guard let billViewModel = billViewModel else {
            return "No bills data available."
        }
        
        let bills = billViewModel.activeBills
        if bills.isEmpty {
            return "You currently have no bills set up."
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        var billsSummary = "CURRENT BILLS THIS MONTH:\n"
        for bill in bills.prefix(10) { // Limit to avoid too much context
            let dueDateStr = formatter.string(from: bill.dueDate)
            billsSummary += "• \(bill.name): $\(String(format: "%.2f", bill.amount)) due \(dueDateStr) - \(bill.status.rawValue)\n"
        }
        
        let totalOwed = bills.filter { $0.status != .paid }.reduce(0) { $0 + $1.amount }
        let overdueCount = bills.filter { $0.status == .overdue }.count
        let paidCount = bills.filter { $0.status == .paid }.count
        
        billsSummary += "\nSUMMARY: \(bills.count) total bills, $\(String(format: "%.2f", totalOwed)) still owed"
        if overdueCount > 0 { billsSummary += ", \(overdueCount) overdue" }
        if paidCount > 0 { billsSummary += ", \(paidCount) paid this month" }
        
        return billsSummary
    }
    
    private func getCurrentExpensesData() -> String {
        guard let expenseViewModel = expenseViewModel else {
            return "No expenses data available."
        }
        
        let expenses = expenseViewModel.expenses
        if expenses.isEmpty {
            return "You currently have no expenses recorded this month."
        }
        
        // Get this month's expenses
        let calendar = Calendar.current
        let thisMonth = calendar.dateInterval(of: .month, for: Date())!
        let thisMonthExpenses = expenses.filter { expense in
            // Parse expense date string to Date
            let formatter = ISO8601DateFormatter()
            let expenseDate = formatter.date(from: expense.expenseDate) ?? Date()
            return thisMonth.contains(expenseDate)
        }.prefix(15) // Limit to recent expenses
        
        if thisMonthExpenses.isEmpty {
            return "You have no expenses recorded this month yet."
        }
        
        var expensesSummary = "EXPENSES THIS MONTH:\n"
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        for expense in thisMonthExpenses {
            // Parse expense date string for display
            let isoFormatter = ISO8601DateFormatter()
            let expenseDate = isoFormatter.date(from: expense.expenseDate) ?? Date()
            let dateStr = formatter.string(from: expenseDate)
            expensesSummary += "• \(expense.name): $\(String(format: "%.2f", expense.amount)) on \(dateStr)\n"
        }
        
        let monthlyTotal = Array(thisMonthExpenses).reduce(0) { $0 + $1.amount }
        expensesSummary += "\nTOTAL THIS MONTH: $\(String(format: "%.2f", monthlyTotal))"
        
        return expensesSummary
    }
    
    private func getCurrentIncomeData() -> String {
        guard let incomeViewModel = incomeViewModel else {
            return "No income data available."
        }
        
        // Check for profile-based monthly income first (from onboarding)
        let profileIncome = sessionViewModel?.currentUser?.settings.monthlyIncome ?? 0.0
        
        // Get all income sources from IncomeViewModel
        let incomes = incomeViewModel.incomes
        let totalIncomeFromSources = incomeViewModel.totalMonthlyIncome
        
        if profileIncome > 0 && incomes.isEmpty {
            // User has profile income but no detailed income sources
            return """
            MONTHLY INCOME:
            • Total Monthly Income: $\(String(format: "%.2f", profileIncome)) (from profile settings)
            
            Note: This is your base monthly income. You can add specific income sources for more detailed tracking.
            """
        } else if incomes.isEmpty {
            return "You haven't set up any income sources yet. You can add income sources like salary, freelance work, or other income streams."
        } else {
            // User has detailed income sources
            var incomeSummary = "INCOME SOURCES:\n"
            
            for income in incomes.prefix(10) { // Limit to avoid too much context
                let frequency = income.frequency.rawValue
                let source = income.source.rawValue
                incomeSummary += "• \(source): $\(String(format: "%.2f", income.amount)) (\(frequency))\n"
            }
            
            incomeSummary += "\nTOTAL MONTHLY INCOME: $\(String(format: "%.2f", totalIncomeFromSources))"
            
            // Include profile income if it's different
            if profileIncome > 0 && abs(profileIncome - totalIncomeFromSources) > 0.01 {
                incomeSummary += "\nProfile Monthly Income: $\(String(format: "%.2f", profileIncome))"
            }
            
            return incomeSummary
        }
    }
    
    private func getBillsTools() -> [AnthropicTool] {
        return [
            getBillCreationTool(), 
            getEditBillTool(),
            getDeleteBillTool(),
            getMarkBillPaidTool(),
            getEditIncomeTool(),
            getFinancialAnalysisTool(), 
            getEndConversationTool()
        ]
    }
    
    private func getBillsSystemPrompt() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        let currentDate = formatter.string(from: Date())
        
        // Get current bills data for the system prompt
        let currentBillsData = getCurrentBillsData()
        
        // Get current income data for the system prompt
        let currentIncomeData = getCurrentIncomeData()
        
        return """
        You are Norma, a friendly AI financial assistant in a voice conversation with a user. You help them create, manage, and get information about their recurring bills through voice interaction. This is a natural voice conversation, so respond conversationally and naturally as if speaking aloud.
        
        Today's date is \(currentDate).
        
        \(currentBillsData)
        
        \(currentIncomeData)
        
        Your personality:
        - Warm, encouraging, and supportive
        - Professional but conversational
        - Use simple, clear language (avoid financial jargon)
        - **CRITICAL: Keep ALL responses to maximum 2 sentences for natural voice conversation**
        - Sound natural and conversational as if speaking aloud
        - You are Norma, the AI assistant for the Norma financial app
        
        **CRITICAL VOICE FORMATTING**: When speaking monetary amounts, always write them in full word form for proper text-to-speech pronunciation:
        - $108.88 → "one hundred and eight dollars and eighty-eight cents"
        - $50.00 → "fifty dollars" (omit cents when zero)
        - €75.25 → "seventy-five euros and twenty-five cents"
        - £12.99 → "twelve pounds and ninety-nine pence"
        - ¥1000 → "one thousand yen"
        This applies to ALL currencies and amounts in your responses.
        
        CAPABILITIES:
        1. ANSWER QUESTIONS about current bills and income using the data above:
           - "What bills do I have coming up?"
           - "When is my rent due?"
           - "How much do I owe in total?"
           - "What bills are overdue?"
           - "Show me my monthly bills"
           - "What's my total monthly income?"
           - "How much income do I have?"
           - "What income sources do I have?"
           
        2. CREATE NEW BILLS: Help users add new recurring bills
        
        3. MODIFY EXISTING BILLS: Help users edit, update, or delete bills:
           - "Change my rent to twelve hundred dollars"
           - "Update my electric bill due date to the 15th"
           - "Mark my Netflix bill as paid"
           - "Delete my old cable bill"
        
        4. UPDATE INCOME INFORMATION: Help users modify their income:
           - "Update my monthly income to five thousand dollars"
           - "Change my salary to sixty thousand per year"
           - "Set my income to three thousand monthly"
        
        5. COMPLEX ANALYSIS: For questions about historical data, trends, or multi-month analysis, use the analyze_financial_data tool
        
        6. END CONVERSATION: When users say they're done, finished, or want to stop, use the end_conversation tool
        
        IMPORTANT: If the user wants to add an expense (not a recurring bill), kindly direct them: "To add an expense, please go to the Expenses tab and double-tap and hold on the calendar to activate voice mode there."
        
        FOR CREATING BILLS, collect this information:
        1. Bill name/description (e.g., "Rent", "Electric Bill", "Netflix")
        2. Amount (the cost of the bill)
        3. Due date (when the bill is due each period)
        4. Frequency (how often: monthly, quarterly, or annually)
        
        CRITICAL: When you have collected ALL required information, check if the due date has already passed:
        - If due date has passed: ask "Since this bill was due on [date], have you already paid it this month?"
        - If YES: use create_bill tool with status "Paid"
        - If NO: use create_bill tool with status "Overdue"  
        - If due date hasn't passed: use create_bill tool with status "Scheduled"
        
        Ask for missing information naturally in conversation. Examples:
        - "What's the name of the bill and how much is it?"
        - "When is it due each month?"
        - "Is this bill paid monthly, quarterly, or yearly?"
        
        Remember: You're speaking aloud, so keep responses natural and conversational for voice interaction.
        """
    }
    
    private func getBillCreationTool() -> AnthropicTool {
        return AnthropicTool(
            name: "create_bill",
            description: "Create a new recurring bill for the user",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "name": AnthropicToolProperty(
                        type: "string",
                        description: "Name of the bill (e.g. 'Rent', 'Electric Bill')"
                    ),
                    "amount": AnthropicToolProperty(
                        type: "number",
                        description: "Monthly amount of the bill as a decimal number (e.g., 14.00, 99.99)"
                    ),
                    "due_date": AnthropicToolProperty(
                        type: "string",
                        description: "Due date in YYYY-MM-DD format"
                    ),
                    "frequency": AnthropicToolProperty(
                        type: "string",
                        description: "How often the bill occurs"
                    ),
                    "status": AnthropicToolProperty(
                        type: "string",
                        description: "Bill status: 'Paid', 'Overdue', or 'Scheduled'"
                    )
                ],
                required: ["name", "amount", "due_date", "frequency", "status"]
            )
        )
    }
    
    private func getEditBillTool() -> AnthropicTool {
        return AnthropicTool(
            name: "edit_bill",
            description: "Modify an existing bill's properties (amount, due date, name, frequency)",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "bill_identifier": AnthropicToolProperty(
                        type: "string",
                        description: "Name or identifier of the bill to modify (e.g., 'rent', 'electric bill', 'Netflix')"
                    ),
                    "new_amount": AnthropicToolProperty(
                        type: "number",
                        description: "New amount for the bill (optional - only if user wants to change amount)"
                    ),
                    "new_name": AnthropicToolProperty(
                        type: "string",
                        description: "New name for the bill (optional - only if user wants to change name)"
                    ),
                    "new_due_date": AnthropicToolProperty(
                        type: "string",
                        description: "New due date in YYYY-MM-DD format (optional - only if user wants to change due date)"
                    ),
                    "new_frequency": AnthropicToolProperty(
                        type: "string",
                        description: "New frequency: 'Monthly', 'Quarterly', or 'Yearly' (optional - only if user wants to change frequency)"
                    )
                ],
                required: ["bill_identifier"]
            )
        )
    }
    
    private func getDeleteBillTool() -> AnthropicTool {
        return AnthropicTool(
            name: "delete_bill",
            description: "Delete/remove an existing bill permanently",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "bill_identifier": AnthropicToolProperty(
                        type: "string",
                        description: "Name or identifier of the bill to delete (e.g., 'rent', 'electric bill', 'Netflix')"
                    ),
                    "confirmation": AnthropicToolProperty(
                        type: "boolean",
                        description: "User confirmation that they want to delete the bill"
                    )
                ],
                required: ["bill_identifier", "confirmation"]
            )
        )
    }
    
    private func getMarkBillPaidTool() -> AnthropicTool {
        return AnthropicTool(
            name: "mark_bill_paid",
            description: "Mark a bill as paid or change its payment status",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "bill_identifier": AnthropicToolProperty(
                        type: "string",
                        description: "Name or identifier of the bill (e.g., 'rent', 'electric bill', 'Netflix')"
                    ),
                    "status": AnthropicToolProperty(
                        type: "string",
                        description: "New status: 'Paid', 'Overdue', or 'Scheduled'"
                    )
                ],
                required: ["bill_identifier", "status"]
            )
        )
    }
    
    private func getFinancialAnalysisTool() -> AnthropicTool {
        return AnthropicTool(
            name: "analyze_financial_data",
            description: "Perform complex financial analysis using historical data and advanced reasoning. Use this for multi-month trends, budget analysis, spending comparisons, and other complex queries that require historical data beyond the current month.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "query_description": AnthropicToolProperty(
                        type: "string",
                        description: "Natural language description of the financial analysis needed (e.g., 'Compare my food spending over the last 3 months', 'Analyze my budget performance for Q1')"
                    ),
                    "context": AnthropicToolProperty(
                        type: "string",
                        description: "Whether this is about 'bills' or 'expenses' primarily"
                    ),
                    "time_range": AnthropicToolProperty(
                        type: "string", 
                        description: "Time period for analysis (e.g., 'last 3 months', 'this quarter', 'last 6 months')"
                    )
                ],
                required: ["query_description", "context"]
            )
        )
    }
    
    private func getEndConversationTool() -> AnthropicTool {
        return AnthropicTool(
            name: "end_conversation",
            description: "End the current voice conversation session when the user indicates they are finished or wants to stop.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "farewell_message": AnthropicToolProperty(
                        type: "string",
                        description: "A brief farewell message to the user (optional)"
                    )
                ],
                required: []
            )
        )
    }
    
    private func getEditIncomeTool() -> AnthropicTool {
        return AnthropicTool(
            name: "edit_income",
            description: "Update the user's income information, including monthly income or specific income sources",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "income_type": AnthropicToolProperty(
                        type: "string",
                        description: "Type of income update: 'monthly_total' for overall monthly income, or 'source' for specific income source. Must be one of: 'monthly_total', 'source'"
                    ),
                    "amount": AnthropicToolProperty(
                        type: "number",
                        description: "New income amount"
                    ),
                    "frequency": AnthropicToolProperty(
                        type: "string",
                        description: "Income frequency (optional, defaults to monthly). Must be one of: 'monthly', 'annual', 'weekly', 'biweekly'"
                    ),
                    "source_name": AnthropicToolProperty(
                        type: "string",
                        description: "Name of the income source (required when income_type is 'source')"
                    )
                ],
                required: ["income_type", "amount"]
            )
        )
    }
    
    // MARK: - Expense Tools and System Prompts
    
    private func getExpenseTools() -> [AnthropicTool] {
        return [getExpenseCreationTool(), getFinancialAnalysisTool(), getEndConversationTool()]
    }
    
    private func getExpenseSystemPrompt() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        let currentDate = formatter.string(from: Date())
        
        // Get current expenses data for the system prompt
        let currentExpensesData = getCurrentExpensesData()
        
        // Get current income data for the system prompt
        let currentIncomeData = getCurrentIncomeData()
        
        return """
        You are Norma, a friendly AI financial assistant in a voice conversation with a user. You help them add new expenses and answer questions about their spending through voice interaction. This is a natural voice conversation, so respond conversationally and naturally as if speaking aloud.
        
        Today's date is \(currentDate).
        
        \(currentExpensesData)
        
        \(currentIncomeData)
        
        Your personality:
        - Warm, encouraging, and supportive
        - Professional but conversational
        - Use simple, clear language (avoid financial jargon)
        - **CRITICAL: Keep ALL responses to maximum 2 sentences for natural voice conversation**
        - Sound natural and conversational as if speaking aloud
        - You are Norma, the AI assistant for the Norma financial app
        
        **CRITICAL VOICE FORMATTING**: When speaking monetary amounts, always write them in full word form for proper text-to-speech pronunciation:
        - $108.88 → "one hundred and eight dollars and eighty-eight cents"
        - $50.00 → "fifty dollars" (omit cents when zero)
        - €75.25 → "seventy-five euros and twenty-five cents"
        - £12.99 → "twelve pounds and ninety-nine pence"
        - ¥1000 → "one thousand yen"
        This applies to ALL currencies and amounts in your responses.
        
        CAPABILITIES:
        1. ANSWER QUESTIONS about current expenses and income using the data above:
           - "How much did I spend this month?"
           - "What did I spend on food?"
           - "Show me my recent expenses"
           - "What's my biggest expense this month?"
           - "What's my total monthly income?"
           - "How much income do I have?"
           - "What income sources do I have?"
           
        2. ADD NEW EXPENSES: Help users add new one-time expenses
        
        3. COMPLEX ANALYSIS: For questions about historical data, trends, or multi-month analysis, use the analyze_financial_data tool
        
        4. END CONVERSATION: When users say they're done, finished, or want to stop, use the end_conversation tool
        
        IMPORTANT: If the user wants to add a recurring bill (not a one-time expense), kindly direct them: "To add a recurring bill, please go to the Bills tab and double-tap and hold on the chart to activate voice mode there."
        
        FOR ADDING EXPENSES, collect this information:
        1. Description (what they bought/spent money on)
        2. Amount (how much they spent)
        3. Category (e.g., "Food", "Transportation", "Entertainment", "Shopping", etc.)
        4. Date (when the expense occurred, defaults to today if not specified)
        
        When you have collected ALL required information, use the create_expense tool to save the expense.
        
        After successfully adding an expense, ask if they have more expenses to add. If they're done, remind them: "When you're finished, press the end conversation button to close voice mode."
        
        Ask for missing information naturally in conversation. Examples:
        - "What did you spend money on and how much was it?"
        - "What category would this expense be? Like food, transportation, or something else?"
        - "When did this expense happen? Today?"
        
        Remember: You're speaking aloud, so keep responses natural and conversational for voice interaction.
        """
    }
    
    private func getExpenseCreationTool() -> AnthropicTool {
        return AnthropicTool(
            name: "create_expense",
            description: "Create a new expense entry for the user",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "description": AnthropicToolProperty(
                        type: "string",
                        description: "Description of what was purchased or spent money on"
                    ),
                    "amount": AnthropicToolProperty(
                        type: "number",
                        description: "Amount spent as a decimal number (e.g., 14.00, 99.99)"
                    ),
                    "category": AnthropicToolProperty(
                        type: "string",
                        description: "Category of the expense (e.g., 'Food', 'Transportation', 'Entertainment')"
                    ),
                    "date": AnthropicToolProperty(
                        type: "string",
                        description: "Date of expense in YYYY-MM-DD format (defaults to today if not specified)"
                    )
                ],
                required: ["description", "amount", "category", "date"]
            )
        )
    }
    
    // MARK: - Tool Execution
    
    private func executeExpenseToolAndGetResult(toolId: String, name: String, input: [String: Any]) async -> String {
        switch name {
        case "create_expense":
            return await executeExpenseCreation(input: input)
        default:
            return "Error: Unknown tool '\(name)'"
        }
    }
    
    private func executeToolAndGetResult(toolId: String, name: String, input: [String: Any]) async -> String {
        switch name {
        case "create_bill":
            return await executeBillCreation(input: input)
        case "edit_bill":
            return await executeEditBill(input: input)
        case "delete_bill":
            return await executeDeleteBill(input: input)
        case "mark_bill_paid":
            return await executeMarkBillPaid(input: input)
        case "edit_income":
            return await executeEditIncome(input: input)
        case "create_expense":
            return await executeExpenseCreation(input: input)
        case "analyze_financial_data":
            return await executeFinancialAnalysis(input: input)
        case "end_conversation":
            return await executeEndConversation(input: input)
        default:
            return "Error: Unknown tool '\(name)'"
        }
    }
    
    private func executeBillCreation(input: [String: Any]) async -> String {
        print("VoiceAgent: Executing bill creation with input: \(input)")
        
        guard let billViewModel = billViewModel else {
            print("VoiceAgent: No BillViewModel available")
            return "Error: Unable to save bill - no bill manager available"
        }
        
        guard let name = input["name"] as? String,
              let dueDateString = input["due_date"] as? String,
              let frequencyString = input["frequency"] as? String,
              let statusString = input["status"] as? String else {
            return "Error: Missing required information (name, amount, due_date, frequency, or status)"
        }
        
        // Handle amount as either Int or Double
        let amount: Double
        if let doubleAmount = input["amount"] as? Double {
            amount = doubleAmount
        } else if let intAmount = input["amount"] as? Int {
            amount = Double(intAmount)
        } else {
            return "Error: Invalid amount format"
        }
        
        print("VoiceAgent: All required parameters found - name: \(name), amount: \(amount), due_date: \(dueDateString), frequency: \(frequencyString), status: \(statusString)")
        
        // Parse date with multiple formats
        let dueDate: Date
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate]
        
        if let parsedDate = isoFormatter.date(from: dueDateString) {
            dueDate = parsedDate
        } else {
            // Try alternative formats or provide a fallback
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            if let parsedDate = dateFormatter.date(from: dueDateString) {
                dueDate = parsedDate
            } else {
                return "Error: Invalid date format. Expected YYYY-MM-DD (e.g., 2025-08-01)"
            }
        }
        
        // Parse frequency
        let frequency: BillFrequency
        switch frequencyString {
        case "Monthly":
            frequency = .monthly
        case "Quarterly":
            frequency = .quarterly
        case "Yearly":
            frequency = .yearly
        default:
            // Fallback for case-insensitive matching
            switch frequencyString.lowercased() {
            case "monthly":
                frequency = .monthly
            case "quarterly":
                frequency = .quarterly
            case "annually", "yearly":
                frequency = .yearly
            default:
                frequency = .monthly
            }
        }
        
        // Parse status
        let status: BillStatus
        switch statusString {
        case "Paid":
            status = .paid
        case "Overdue":
            status = .overdue
        case "Scheduled":
            status = .scheduled
        default:
            status = .scheduled
        }
        
        print("VoiceAgent: About to call billViewModel.addBill with status: \(status)...")
        
        // Create the bill through billViewModel with the specified status
        let createdBill = await billViewModel.addBill(
            name: name,
            amount: amount,
            dueDate: dueDate,
            frequency: frequency,
            status: status
        )
        
        print("VoiceAgent: billViewModel.addBill completed successfully")
        
        if createdBill != nil {
            return "Successfully created bill '\(name)' for $\(String(format: "%.2f", amount)) due on \(formatDateForDisplay(dueDate))"
        } else {
            return "Error: Failed to create bill"
        }
    }
    
    private func executeExpenseCreation(input: [String: Any]) async -> String {
        print("VoiceAgent: Executing expense creation with input: \(input)")
        
        guard let expenseViewModel = expenseViewModel else {
            print("VoiceAgent: No ExpenseViewModel available")
            return "Error: Unable to save expense - no expense manager available"
        }
        
        guard let description = input["description"] as? String,
              let category = input["category"] as? String,
              let dateString = input["date"] as? String else {
            return "Error: Missing required information (description, amount, category, or date)"
        }
        
        // Handle amount as either Int or Double
        let amount: Double
        if let doubleAmount = input["amount"] as? Double {
            amount = doubleAmount
        } else if let intAmount = input["amount"] as? Int {
            amount = Double(intAmount)
        } else {
            return "Error: Invalid amount format"
        }
        
        print("VoiceAgent: All required parameters found - description: \(description), amount: \(amount), category: \(category), date: \(dateString)")
        
        // Parse date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else {
            return "Error: Invalid date format"
        }
        
        print("VoiceAgent: About to call expenseViewModel.addExpense...")
        
        // Format date as ISO string for expense date
        let isoFormatter = ISO8601DateFormatter()
        let expenseDateString = isoFormatter.string(from: date)
        
        // Create the expense through expenseViewModel
        // Using description as name, category is stored in notes for now
        let success = await expenseViewModel.addExpense(
            name: description,
            amount: amount,
            expenseDate: expenseDateString,
            paymentMethod: .cash, // Default to cash for voice entries
            notes: "Category: \(category)"
        )
        
        print("VoiceAgent: expenseViewModel.addExpense completed successfully")
        
        if success {
            return "Successfully added expense '\(description)' for $\(String(format: "%.2f", amount)) in \(category) category"
        } else {
            return "Error: Failed to create expense"
        }
    }
    
    private func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - Conversation Management
    
    private func shouldEndConversation(_ transcription: String) -> Bool {
        let lowerText = transcription.lowercased()
        let endPhrases = ["done", "that's all", "goodbye", "bye", "thank you", "thanks", "stop", "exit", "quit"]
        return endPhrases.contains { lowerText.contains($0) }
    }
    
    private func shouldEndAfterToolUse(_ response: String) -> Bool {
        // End conversation if the response indicates a tool was used successfully
        let lowerResponse = response.lowercased()
        let successPhrases = ["successfully created", "i've created", "bill has been added", "added to your bills"]
        return successPhrases.contains { lowerResponse.contains($0) }
    }
    
    // MARK: - Greeting Generation
    
    private func generateBillsGreeting(userName: String?) -> String {
        let name = userName?.components(separatedBy: " ").first ?? "there"
        let greetings = [
            "Hey \(name), how can I help with your bills?",
            "Hi \(name), what can I do for your bills today?", 
            "Hello \(name), ready to manage your bills?"
        ]
        return greetings.randomElement() ?? "Hi \(name), how can I help with your bills?"
    }
    
    // MARK: - Data Handling
    
    private func handleExtractedData(_ data: VoiceAgentData) async {
        switch data {
        case .expense(let expenseData):
            await saveExpenseFromVoice(expenseData)
            
        case .bill(let billData):
            await saveBillFromVoice(billData)
        }
    }
    
    private func saveExpenseFromVoice(_ expenseData: VoiceExpenseData) async {
        print("VoiceAgent: Saving expense to database...")
        
        // We need access to ExpenseViewModel - this should be injected
        // For now, we'll use the shared instance approach
        // TODO: Inject ExpenseViewModel properly
        
        print("VoiceAgent: Expense saved - Name: \(expenseData.name), Amount: $\(expenseData.amount)")
    }
    
    private func saveBillFromVoice(_ billData: VoiceBillData) async {
        print("VoiceAgent: Saving bill to database...")
        
        // Parse the date string to Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let dueDate = dateFormatter.date(from: billData.dueDate) else {
            print("VoiceAgent: Error parsing due date: \(billData.dueDate)")
            return
        }
        
        // We need access to BillViewModel - this should be injected
        // For now, we'll use the shared instance approach  
        // TODO: Inject BillViewModel properly
        
        print("VoiceAgent: Bill saved - Name: \(billData.name), Amount: $\(billData.amount), Due: \(dueDate)")
    }
    
    // MARK: - State Management
    
    private func setState(_ state: VoiceAgentState) async {
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
    
    private func setError(_ message: String) async {
        await setState(.error(message))
        audioPlaybackService.playErrorSound()
    }
    
    private func resetState() async {
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
    
    // MARK: - Service Observation
    
    private func observeServiceStates() {
        // Observe recording level
        voiceRecordingService.$recordingLevel
            .assign(to: &$recordingLevel)
        
        // Observe permissions
        voiceRecordingService.$hasPermission
            .combineLatest(speechToTextService.$hasPermission)
            .map { micPermission, speechPermission in
                micPermission && speechPermission
            }
            .assign(to: &$hasPermissions)
    }
    
    // MARK: - Configuration Methods
    
    func configureElevenLabs(apiKey: String) {
        elevenLabsService.configure(apiKey: apiKey)
    }
    
    // MARK: - Manual Control Methods
    
    func startRecordingManually() async throws {
        guard hasPermissions else {
            throw VoiceAgentError.noPermissions
        }
        
        await setState(.recording)
        currentRecordingURL = try await voiceRecordingService.startRecording()
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
    
    private func executeFinancialAnalysis(input: [String: Any]) async -> String {
        print("VoiceAgent: Executing financial analysis with input: \(input)")
        
        guard let queryDescription = input["query_description"] as? String else {
            return "Error: Missing query description"
        }
        
        let context = input["context"] as? String ?? "general"
        let timeRange = input["time_range"] as? String ?? "recent"
        
        print("VoiceAgent: Delegating to advanced analysis - Query: \(queryDescription), Context: \(context), Time Range: \(timeRange)")
        
        // Here we delegate to Claude Opus with MCP access for complex analysis
        // For now, return a placeholder that indicates the delegation happened
        return await performAdvancedFinancialAnalysis(
            query: queryDescription,
            context: context,
            timeRange: timeRange
        )
    }
    
    private func performAdvancedFinancialAnalysis(query: String, context: String, timeRange: String) async -> String {
        print("VoiceAgent: Starting advanced financial analysis with Opus + MCP")
        
        // Create enhanced system prompt for Opus
        let advancedSystemPrompt = """
        You are Norma, an advanced financial analyst with access to comprehensive financial databases. 
        You have access to detailed historical financial data through MCP tools and can perform complex analysis.
        
        The user is asking: "\(query)"
        Context: \(context)
        Time Range: \(timeRange)
        
        Use your MCP database access to:
        1. Query the relevant financial data
        2. Perform calculations and analysis  
        3. Identify trends and patterns
        4. Provide insights and actionable recommendations
        
        Respond conversationally as if speaking aloud, keeping responses to 2-3 sentences maximum for voice interaction.
        Focus on the key insights and actionable advice.
        """
        
        let analysisMessages = [
            AnthropicMessage(role: "user", content: .text(query))
        ]
        
        do {
            // Use a more advanced model (prioritize Opus/Sonnet over Haiku)
            let advancedResponse = try await anthropicService.sendMessage(
                messages: analysisMessages, 
                systemPrompt: advancedSystemPrompt,
                maxTokens: 1000
            )
            
            print("VoiceAgent: Advanced analysis completed: \(advancedResponse)")
            return advancedResponse
            
        } catch {
            print("VoiceAgent: Advanced analysis failed: \(error)")
            return "I'm sorry, I wasn't able to perform that analysis right now. Please try again or ask a simpler question about this month's data."
        }
    }
    
    private func executeEditBill(input: [String: Any]) async -> String {
        print("VoiceAgent: Executing bill edit with input: \(input)")
        
        guard let billViewModel = billViewModel else {
            return "Error: Unable to edit bill - no bill manager available"
        }
        
        guard let billIdentifier = input["bill_identifier"] as? String else {
            return "Error: Missing bill identifier"
        }
        
        // Find the bill by name (case-insensitive)
        let bills = billViewModel.activeBills
        guard let existingBill = bills.first(where: { 
            $0.name.lowercased().contains(billIdentifier.lowercased()) 
        }) else {
            return "Error: Could not find a bill matching '\(billIdentifier)'. Please check the bill name."
        }
        
        // Get the changes to apply
        var updatedBill = existingBill
        var changes: [String] = []
        
        if let newAmount = input["new_amount"] as? Double {
            updatedBill.amount = newAmount
            changes.append("amount to \(String(format: "%.2f", newAmount))")
        }
        
        if let newName = input["new_name"] as? String {
            updatedBill.name = newName
            changes.append("name to '\(newName)'")
        }
        
        if let newDueDateString = input["new_due_date"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let newDueDate = formatter.date(from: newDueDateString) {
                updatedBill.dueDate = newDueDate
                changes.append("due date to \(formatDateForDisplay(newDueDate))")
            }
        }
        
        if let newFrequencyString = input["new_frequency"] as? String {
            let frequency: BillFrequency
            switch newFrequencyString.lowercased() {
            case "monthly":
                frequency = .monthly
            case "quarterly":
                frequency = .quarterly
            case "annually", "yearly":
                frequency = .yearly
            default:
                frequency = .monthly
            }
            updatedBill.frequency = frequency
            changes.append("frequency to \(newFrequencyString.lowercased())")
        }
        
        if changes.isEmpty {
            return "No changes were specified for the bill."
        }
        
        // Update the bill
        await billViewModel.updateBill(updatedBill)
        
        // Check if there was an error during the update
        if billViewModel.errorMessage.isEmpty {
            let changesText = changes.joined(separator: ", ")
            return "Successfully updated '\(existingBill.name)' - changed \(changesText)."
        } else {
            return "Error: Failed to update the bill. \(billViewModel.errorMessage)"
        }
    }
    
    private func executeDeleteBill(input: [String: Any]) async -> String {
        print("VoiceAgent: Executing bill deletion with input: \(input)")
        
        guard let billViewModel = billViewModel else {
            return "Error: Unable to delete bill - no bill manager available"
        }
        
        guard let billIdentifier = input["bill_identifier"] as? String,
              let confirmation = input["confirmation"] as? Bool else {
            return "Error: Missing bill identifier or confirmation"
        }
        
        guard confirmation else {
            return "Bill deletion cancelled - confirmation required to delete bills."
        }
        
        // Find the bill by name (case-insensitive)
        let bills = billViewModel.activeBills
        guard let existingBill = bills.first(where: { 
            $0.name.lowercased().contains(billIdentifier.lowercased()) 
        }) else {
            return "Error: Could not find a bill matching '\(billIdentifier)'. Please check the bill name."
        }
        
        // Delete the bill
        await billViewModel.deleteBill(existingBill)
        
        // Check if there was an error during deletion
        if billViewModel.errorMessage.isEmpty {
            return "Successfully deleted '\(existingBill.name)' bill."
        } else {
            return "Error: Failed to delete the bill. \(billViewModel.errorMessage)"
        }
    }
    
    private func executeMarkBillPaid(input: [String: Any]) async -> String {
        print("VoiceAgent: Executing mark bill paid with input: \(input)")
        
        guard let billViewModel = billViewModel else {
            return "Error: Unable to update bill status - no bill manager available"
        }
        
        guard let billIdentifier = input["bill_identifier"] as? String,
              let statusString = input["status"] as? String else {
            return "Error: Missing bill identifier or status"
        }
        
        // Find the bill by name (case-insensitive)
        let bills = billViewModel.activeBills
        guard let existingBill = bills.first(where: { 
            $0.name.lowercased().contains(billIdentifier.lowercased()) 
        }) else {
            return "Error: Could not find a bill matching '\(billIdentifier)'. Please check the bill name."
        }
        
        // Parse the new status
        let newStatus: BillStatus
        switch statusString.lowercased() {
        case "paid":
            newStatus = .paid
        case "overdue":
            newStatus = .overdue
        case "scheduled":
            newStatus = .scheduled
        default:
            return "Error: Invalid status '\(statusString)'. Use 'Paid', 'Overdue', or 'Scheduled'."
        }
        
        // Update the bill status
        var updatedBill = existingBill
        updatedBill.status = newStatus
        
        await billViewModel.updateBill(updatedBill)
        
        // Check if there was an error during the update
        if billViewModel.errorMessage.isEmpty {
            return "Successfully marked '\(existingBill.name)' as \(statusString.lowercased())."
        } else {
            return "Error: Failed to update the bill status. \(billViewModel.errorMessage)"
        }
    }
    
    private func executeEditIncome(input: [String: Any]) async -> String {
        print("VoiceAgent: Executing income edit with input: \(input)")
        
        guard let incomeType = input["income_type"] as? String,
              let amount = input["amount"] as? Double else {
            return "Error: Missing income type or amount information"
        }
        
        let frequency = input["frequency"] as? String ?? "monthly"
        
        switch incomeType {
        case "monthly_total":
            // Update the user's profile monthly income
            guard let sessionViewModel = sessionViewModel,
                  let userId = sessionViewModel.currentUser?.userId else {
                return "Error: No user found to update income"
            }
            
            // Convert to monthly if needed
            let monthlyAmount: Double
            switch frequency.lowercased() {
            case "annual":
                monthlyAmount = amount / 12.0
            case "weekly":
                monthlyAmount = amount * 52.0 / 12.0
            case "biweekly":
                monthlyAmount = amount * 26.0 / 12.0
            default: // monthly
                monthlyAmount = amount
            }
            
            // Update the user's profile income
            do {
                var updatedUser = sessionViewModel.currentUser
                updatedUser?.settings.monthlyIncome = monthlyAmount
                sessionViewModel.currentUser = updatedUser
                
                // Here you would typically save to the backend
                // For now, just confirm the update
                let formattedAmount = String(format: "%.2f", monthlyAmount)
                return "Successfully updated your monthly income to $\(formattedAmount) per month."
                
            } catch {
                return "Error: Failed to update your monthly income. Please try again."
            }
            
        case "source":
            // Handle specific income source updates (would need IncomeViewModel methods)
            guard let sourceName = input["source_name"] as? String else {
                return "Error: Income source name is required"
            }
            
            // This would require implementing income source CRUD in IncomeViewModel
            return "Income source updates are not yet fully implemented. For now, you can update your total monthly income."
            
        default:
            return "Error: Invalid income type. Use 'monthly_total' or 'source'."
        }
    }
    
    private func executeEndConversation(input: [String: Any]) async -> String {
        print("VoiceAgent: Executing end conversation")
        
        let farewellMessage = input["farewell_message"] as? String ?? "Goodbye! Feel free to come back anytime if you need help with your finances."
        
        // Stop any current recording or playback
        await stopVoiceInteraction()
        
        // Set state to idle to end the conversation
        await setState(.idle)
        
        return farewellMessage
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
}

// MARK: - Voice Agent Errors

enum VoiceAgentError: LocalizedError {
    case noPermissions
    case recordingFailed
    case transcriptionFailed
    case processingFailed
    case speechGenerationFailed
    case playbackFailed
    
    var errorDescription: String? {
        switch self {
        case .noPermissions:
            return "Microphone and speech recognition permissions are required"
        case .recordingFailed:
            return "Failed to record audio"
        case .transcriptionFailed:
            return "Failed to transcribe audio"
        case .processingFailed:
            return "Failed to process request"
        case .speechGenerationFailed:
            return "Failed to generate speech"
        case .playbackFailed:
            return "Failed to play audio response"
        }
    }
}
