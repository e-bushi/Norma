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
    
    let voiceRecordingService: VoiceRecordingService
    let speechToTextService: SpeechToTextService
    let anthropicService: AnthropicService
    let elevenLabsService: ElevenLabsService
    let audioPlaybackService: AudioPlaybackService
    let billViewModel: BillViewModel?
    let expenseViewModel: ExpenseViewModel?
    let incomeViewModel: IncomeViewModel?
    let sessionViewModel: SessionViewModel?
    
    // MARK: - Configuration
    
    var currentRecordingURL: URL?
    let userId: String
    
    // MARK: - Cancellation Management
    
    var conversationTask: Task<Void, Never>?
    var isConversationCancelled = false
    
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
    
    func startExpenseVoiceInteraction(userName: String? = nil) async {
        print("VoiceAgent: Starting expense voice interaction (redirecting to unified)...")
        // Redirect to the unified voice interaction
        await startVoiceInteraction(userName: userName)
    }
    
    // MARK: - Quick Actions (for Widget)
    
    func performQuickAction(_ action: QuickAction) async {
        switch action {
        case .addBill:
            await quickAddBill()
        case .checkBills:
            await quickCheckBills()
        case .addExpense:
            await quickAddExpense()
        }
    }
    
    private func quickAddBill() async {
        // Simplified flow for quick actions
        await startVoiceInteraction(userName: sessionViewModel?.currentUser?.name)
    }
    
    private func quickCheckBills() async {
        guard let billViewModel = billViewModel else { return }
        
        let overdueCount = billViewModel.activeBills.filter { $0.status == .overdue }.count
        let upcomingCount = billViewModel.activeBills.filter { $0.status == .scheduled }.count
        
        let message: String
        if overdueCount > 0 {
            message = "You have \(overdueCount) overdue bill\(overdueCount > 1 ? "s" : ""). Would you like to review them?"
        } else if upcomingCount > 0 {
            message = "You have \(upcomingCount) upcoming bill\(upcomingCount > 1 ? "s" : ""). Everything looks on track!"
        } else {
            message = "You have no bills due at the moment. Great job staying on top of things!"
        }
        
        // Generate and play the response
        do {
            let audioData = try await generateSpeech(from: message)
            try await playResponse(audioData: audioData)
        } catch {
            print("VoiceAgent: Failed to generate quick action response: \(error)")
        }
    }
    
    private func quickAddExpense() async {
        // Start voice interaction in expense mode
        await startVoiceInteraction(userName: sessionViewModel?.currentUser?.name)
    }
}

// MARK: - Quick Action Types

enum QuickAction {
    case addBill
    case checkBills
    case addExpense
}

// MARK: - Voice Agent Errors

enum VoiceAgentError: Error {
    case noPermissions
    case recordingFailed
    case noAudioDetected
    case transcriptionFailed
    case processingFailed
    case speechGenerationFailed
    case playbackFailed
    case cancelled
}

// MARK: - Speech Recognition Task Access

extension VoiceAgentViewModel {
    var recognitionTask: SFSpeechRecognitionTask? {
        get { speechToTextService.recognitionTask }
        set { speechToTextService.recognitionTask = newValue }
    }
}

// Note: All the implementation details have been moved to extension files:
// - VoiceAgent+Audio.swift: Recording, transcription, speech generation, playback
// - VoiceAgent+Bills.swift: Bill-related tools and methods
// - VoiceAgent+Conversation.swift: Conversation flow and state management
// - VoiceAgent+DataHelpers.swift: Data fetching helpers
// - VoiceAgent+Expenses.swift: Expense-related tools and methods
// - VoiceAgent+SystemPrompts.swift: System prompts
// - VoiceAgent+Tools.swift: Common tools and tool execution