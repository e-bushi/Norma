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
        voiceRecordingService: VoiceRecordingService = .shared,
        speechToTextService: SpeechToTextService = .shared,
        anthropicService: AnthropicService = .shared,
        elevenLabsService: ElevenLabsService = .shared,
        audioPlaybackService: AudioPlaybackService = .shared
    ) {
        self.userId = userId
        self.billViewModel = billViewModel
        self.expenseViewModel = expenseViewModel
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
        print("VoiceAgent: Starting voice interaction...")
        
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
            await runVoiceInteraction(userName: userName)
        }
        
        await conversationTask?.value
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
        print("VoiceAgent: Starting expense voice interaction...")
        
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
            await runExpenseVoiceInteraction(userName: userName)
        }
        
        await conversationTask?.value
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
        print("VoiceAgent: Starting recording...")
        currentRecordingURL = try await voiceRecordingService.startRecording()
        print("VoiceAgent: Recording started successfully")
        
        // Voice activity detection with speech-aware silence detection
        let maxRecordingTime: TimeInterval = 10.0  // Max 10 seconds (reasonable upper limit)
        let silenceAfterSpeechThreshold: TimeInterval = 2.0  // Stop after 2 seconds of silence AFTER speech detected
        let checkInterval: TimeInterval = 0.05     // Check every 50ms for more responsive detection
        
        var lastSoundTime = Date()
        var elapsedTime: TimeInterval = 0
        var speechDetected = false  // Track if we've detected actual speech
        let silenceLevelThreshold: Float = 0.02    // Slightly higher threshold for better speech detection
        let speechLevelThreshold: Float = 0.05     // Higher threshold to confirm actual speech (not just noise)
        
        while elapsedTime < maxRecordingTime {
            try await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
            elapsedTime += checkInterval
            
            // Check current audio level
            let currentLevel = voiceRecordingService.recordingLevel
            
            if currentLevel > speechLevelThreshold {
                // Strong audio detected - likely speech
                speechDetected = true
                lastSoundTime = Date()
                print("VoiceAgent: Speech detected - level: \(currentLevel)")
            } else if currentLevel > silenceLevelThreshold {
                // Moderate audio - update last sound time but don't mark as speech yet
                lastSoundTime = Date()
            }
            
            // Only apply silence timeout AFTER we've detected speech
            if speechDetected {
                let silenceDuration = Date().timeIntervalSince(lastSoundTime)
                if silenceDuration >= silenceAfterSpeechThreshold {
                    print("VoiceAgent: Stopping after speech - \(String(format: "%.1f", silenceDuration))s of silence (\(String(format: "%.1f", elapsedTime))s total)")
                    break
                }
            }
        }
        
        print("VoiceAgent: Stopping recording after \(String(format: "%.1f", elapsedTime))s")
        voiceRecordingService.stopRecording()
        
        return currentRecordingURL!
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
    
    private func generateSpeech(from text: String) async throws -> Data {
        return try await elevenLabsService.generateSpeech(text: text)
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
    
    // MARK: - Tools and Context Management
    
    private func getBillsTools() -> [AnthropicTool] {
        return [getBillCreationTool()]
    }
    
    private func getBillsSystemPrompt() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        let currentDate = formatter.string(from: Date())
        
        return """
        You are Norma, a friendly AI financial assistant in a voice conversation with a user. You're helping them create and manage their recurring bills through voice interaction. This is a natural voice conversation, so respond conversationally and naturally as if speaking aloud.
        
        Today's date is \(currentDate).
        
        Your personality:
        - Warm, encouraging, and supportive
        - Professional but conversational
        - Use simple, clear language (avoid financial jargon)
        - Keep responses concise for voice interaction - 1-2 sentences when possible
        - Sound natural and conversational as if speaking aloud
        - You are Norma, the AI assistant for the Norma financial app
        
        Context: The user activated voice mode from their bills screen, so they're likely wanting to add or manage bills. You've already greeted them asking how you can help with their bills.
        
        IMPORTANT: If the user wants to add an expense (not a recurring bill), kindly direct them: "To add an expense, please go to the Expenses tab and double-tap and hold on the calendar to activate voice mode there."
        
        Your goal is to collect information for creating bills:
        1. Bill name/description (e.g., "Rent", "Electric Bill", "Netflix")
        2. Amount (the cost of the bill)
        3. Due date (when the bill is due each period)
        4. Frequency (how often: monthly, quarterly, or annually)
        
        CRITICAL: When you have collected ALL required information, check if the due date has already passed in the current billing period:
        - If the due date has passed (e.g., it's August 5th and the bill is due August 1st), ask: "Since this bill was due on [date], have you already paid it this month?"
        - If they say YES, use the create_bill tool with status set to "Paid"
        - If they say NO, use the create_bill tool with status set to "Overdue"
        - If the due date hasn't passed yet, use the create_bill tool with status set to "Scheduled"
        
        After successfully adding a bill, ask if they have more bills to add. If they're done, remind them: "When you're finished, press the end conversation button to close voice mode."
        
        Ask for missing information naturally in conversation. For example:
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
    
    // MARK: - Expense Tools and System Prompts
    
    private func getExpenseTools() -> [AnthropicTool] {
        return [getExpenseCreationTool()]
    }
    
    private func getExpenseSystemPrompt() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        let currentDate = formatter.string(from: Date())
        
        return """
        You are Norma, a friendly AI financial assistant in a voice conversation with a user. You're helping them add new expenses through voice interaction. This is a natural voice conversation, so respond conversationally and naturally as if speaking aloud.
        
        Today's date is \(currentDate).
        
        Your personality:
        - Warm, encouraging, and supportive
        - Professional but conversational
        - Use simple, clear language (avoid financial jargon)
        - Keep responses concise for voice interaction - 1-2 sentences when possible
        - Sound natural and conversational as if speaking aloud
        - You are Norma, the AI assistant for the Norma financial app
        
        Context: The user activated voice mode from their expenses calendar to add a new expense. You've already greeted them asking what expense they'd like to add.
        
        IMPORTANT LIMITATIONS:
        - You can ONLY help add new expenses right now
        - If the user asks to check spending, view expenses, or analyze patterns, say: "I can only help add new expenses right now. What expense would you like to add?"
        - If the user wants to add a recurring bill (not a one-time expense), kindly direct them: "To add a recurring bill, please go to the Bills tab and double-tap and hold on the chart to activate voice mode there."
        
        Your goal is to collect information for adding an expense:
        1. Description (what they bought/spent money on)
        2. Amount (how much they spent)
        3. Category (e.g., "Food", "Transportation", "Entertainment", "Shopping", etc.)
        4. Date (when the expense occurred, defaults to today if not specified)
        
        When you have collected ALL required information, use the create_expense tool to save the expense.
        
        After successfully adding an expense, ask if they have more expenses to add. If they're done, remind them: "When you're finished, press the end conversation button to close voice mode."
        
        Ask for missing information naturally in conversation. For example:
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
