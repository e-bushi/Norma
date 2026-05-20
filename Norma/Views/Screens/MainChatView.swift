//
//  MainChatView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI
import AVFoundation

struct MainChatView: View {
    @Binding var isMenuOpen: Bool

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var conversationManager: ConversationManager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var deepgramService = DeepgramService.shared
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var scrollViewProxy: ScrollViewProxy?

    // Paywall state - commented out for later
    // @State private var showPaywall = false

    @State private var showIncomeEdit = false
    @State private var showArcDetail = false
    @State private var showRemindersSheet = false
    @State private var reminderCount: Int = 0
    @State private var navBarCapsulesVisible = false
    @State private var showIncomeDropdown = false
    @State private var inputGlowColor: Color? = nil
    @State private var backgroundOpacity: Double = 0

    // Voice input state
    @State private var isRecording = false
    @State private var transcribedText = ""
    @State private var audioEngine = AVAudioEngine()

    // Auto-scroll state
    @State private var dynamicSpacerHeight: CGFloat = 180
    @State private var viewportHeight: CGFloat = 0
    @State private var lastMessagePosition: CGFloat = 0
    @GestureState private var isUserScrolling = false

    // Tool chain depth limit to prevent infinite loops
    private let maxToolChainDepth: Int = 3

    // Use conversationManager for messages
    private var messages: [ChatMessage] {
        conversationManager.currentMessages
    }

    // Computed financial context for nav bar
    private var monthlyIncome: Double {
        sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
    }

    private var freedomFund: Double {
        // Use linked account balance if set, otherwise manual value
        if let arcAccountId = sessionViewModel.currentUser?.settings.arcAccountId,
           let account = PlaidService.shared.connectedAccounts.first(where: { $0.accountId == arcAccountId }),
           let balance = account.balances.current {
            return balance
        }
        return sessionViewModel.currentUser?.settings.freedomFund ?? 0
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private var totalMonthlyBills: Double {
        billViewModel.bills.reduce(0.0) { $0 + $1.amount }
    }

    private var arcCount: Int {
        let largestBill = billViewModel.bills.map { $0.amount }.max() ?? 0
        if freedomFund < largestBill {
            return 0
        } else if totalMonthlyBills > 0 {
            return Int(floor(freedomFund / totalMonthlyBills))
        } else {
            return 0
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(Int(amount))"
    }

    private func loadReminderCount() async {
        let reminders = await NotificationService.shared.getPendingAIReminders()
        await MainActor.run {
            reminderCount = reminders.count
        }
    }

    private var toolExecutor: ChatToolExecutor {
        ChatToolExecutor(dataManager: dataManager)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Chat content fills entire space
                chatContent
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                        // Dropdown dismiss — commented out for later
                        // if showIncomeDropdown {
                        //     withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        //         showIncomeDropdown = false
                        //     }
                        // }
                    }

                // Input area overlays at bottom
                inputArea
            }
            .background {
                let coinColor = CoinTierService.currentCoinTier(for: arcCount).glowColor

                ZStack {
                    Color.black

                    CoinGradientBackground(coinColor: coinColor, colorScheme: colorScheme)
                        .opacity(backgroundOpacity)

                    DotPatternView()
                        .opacity(backgroundOpacity)
                }
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeIn(duration: 1.0)) {
                        backgroundOpacity = 1
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        // Sliding haptic that fades over animation duration
                        let impactMedium = UIImpactFeedbackGenerator(style: .medium)
                        impactMedium.impactOccurred()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            let impactLight = UIImpactFeedbackGenerator(style: .light)
                            impactLight.impactOccurred()
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            let impactLight = UIImpactFeedbackGenerator(style: .light)
                            impactLight.impactOccurred()
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            let selectionGenerator = UISelectionFeedbackGenerator()
                            selectionGenerator.selectionChanged()
                        }

                        // Open the menu
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isMenuOpen = true
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    // Title row — dropdown trigger commented out for later
                    HStack(spacing: 8) {
                        Text("Norma")
                            .font(.custom(FontFamily.Rubik.medium, size: 22))
                            .foregroundColor(.primary)

                        Text("Pro")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color("NormaPastelPurple").opacity(0.8))
                            )
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        // Coin capsule — shows when chat has messages
                        if !messages.isEmpty {
                            Button {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                showArcDetail = true
                            } label: {
                                HStack(spacing: 4) {
                                    NavBarCoin3DView(fileName: CoinTierService.currentCoinFileName(for: arcCount))
                                        .id(CoinTierService.currentCoinFileName(for: arcCount))
                                        .frame(width: 20, height: 20)

                                    Text("x \(arcCount)")
                                        .font(.normaFinancial(12))
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(.clear)
                                        .glassEffect(in: Capsule())
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .sharedBackgroundVisibility(.hidden)

            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        // Paywall sheet - commented out for later
        // .sheet(isPresented: $showPaywall) {
        //     PaywallView()
        //         .presentationDetents([.large])
        //         .presentationDragIndicator(.visible)
        // }
        .sheet(isPresented: $showIncomeEdit) {
            IncomeEditSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRemindersSheet) {
            RemindersSheet(isPresented: $showRemindersSheet)
        }
        .onChange(of: showRemindersSheet) { _, isShowing in
            if !isShowing {
                // Refresh count after sheet closes (user may have deleted reminders)
                Task {
                    await loadReminderCount()
                }
            }
        }
        .task {
            await loadReminderCount()
            // Trigger first-chat welcome after conversations have loaded
            if conversationManager.conversations.isEmpty,
               sessionViewModel.currentUser?.settings.hasReceivedWelcome == false {
                await triggerFirstChatWelcome()
            }
        }
        .sheet(isPresented: $showArcDetail) {
            ArcCountView(
                arcCount: arcCount,
                freedomFund: freedomFund,
                totalMonthlyBills: totalMonthlyBills,
                currency: currency
            )
            .environmentObject(sessionViewModel)
            .environmentObject(billViewModel)
            .environmentObject(profileViewModel)
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    
    @ViewBuilder
    private var chatContent: some View {
        if messages.isEmpty && !isLoading {
            ChatEmptyStateView(
                arcCount: arcCount,
                onCoinTapped: { showArcDetail = true }
            )
        } else {
            ScrollViewReader { proxy in
                GeometryReader { outerGeometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            LazyVStack(spacing: 20) {
                                ForEach(messages) { message in
                                    ChatBubbleView(
                                        message: message,
                                        shouldAnimate: conversationManager.newlyAddedMessageIds.contains(message.id),
                                        accentColor: CoinTierService.currentCoinTier(for: arcCount).glowColor
                                    )
                                        .id(message.id)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }

                                if isLoading {
                                    ThinkingIndicator()
                                        .id("typing")
                                        .background(
                                            GeometryReader { geo in
                                                Color.clear.preference(
                                                    key: LastMessagePositionKey.self,
                                                    value: geo.frame(in: .named("scroll")).minY
                                                )
                                            }
                                        )
                                        .transition(.scale.combined(with: .opacity))
                                } else if let _ = messages.last {
                                    Color.clear
                                        .frame(height: 0)
                                        .background(
                                            GeometryReader { geo in
                                                Color.clear.preference(
                                                    key: LastMessagePositionKey.self,
                                                    value: geo.frame(in: .named("scroll")).minY
                                                )
                                            }
                                        )
                                        .id("lastMessageTracker")
                                }
                            }
                            .padding()

                            // Dynamic spacer to push content up and leave room for input
                            Color.clear
                                .frame(height: dynamicSpacerHeight)
                                .id("bottomSpacer")
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: messages.count)
                    }
                    .coordinateSpace(name: "scroll")
                    .background(Color.clear)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 4)
                            .updating($isUserScrolling) { _, state, _ in
                                state = true
                            }
                    )
                    .onPreferenceChange(LastMessagePositionKey.self) { value in
                        lastMessagePosition = value
                        // Continuously adjust as position changes during animation
                        adjustSpacerAndScroll(proxy: proxy)
                    }
                    .onChange(of: messages.count) {
                        // Initial adjustment when new message is added
                        adjustSpacerAndScroll(proxy: proxy)
                    }
                    .onChange(of: isLoading) {
                        // Adjustment when loading state changes
                        adjustSpacerAndScroll(proxy: proxy)
                    }
                    .onAppear {
                        self.scrollViewProxy = proxy
                        viewportHeight = outerGeometry.size.height
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var inputArea: some View {
        VStack(spacing: 0) {
            // Transcription view appears when recording
            if isRecording {
                TranscriptionView(
                    transcribedText: $transcribedText,
                    isRecording: Binding(
                        get: { isRecording },
                        set: { newValue in
                            if !newValue {
                                stopVoiceInput()
                            }
                        }
                    ),
                    onInsert: { text in
                        stopVoiceInput()
                        inputText = text
                        transcribedText = ""
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            ChatInputView(
                text: $inputText,
                isLoading: isLoading,
                onSend: sendMessage,
                onVoiceInput: startVoiceInput,
                glowColor: inputGlowColor
            )
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isRecording)
    }

    private func startVoiceInput() {
        // Request microphone permission if needed
        AVAudioApplication.requestRecordPermission { granted in
            guard granted else {
                print("Microphone permission denied")
                return
            }

            DispatchQueue.main.async {
                self.isRecording = true
                self.transcribedText = ""

                do {
                    // Configure audio session
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

                    // Start live transcription via Deepgram
                    try self.deepgramService.startLiveTranscription(
                        audioEngine: self.audioEngine,
                        onPartialResult: { partialText in
                            self.transcribedText = partialText
                        },
                        onFinalResult: { finalText in
                            self.transcribedText = finalText
                        },
                        onError: { error in
                            print("Transcription error: \(error)")
                            self.stopVoiceInput()
                        }
                    )
                } catch {
                    print("Failed to start voice input: \(error)")
                    self.isRecording = false
                }
            }
        }
    }

    private func stopVoiceInput() {
        deepgramService.stopTranscription()
        isRecording = false

        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    

    private func sendMessage() {
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }

        let chatMessage = ChatMessage(role: .user, content: userMessage)

        inputText = ""
        hideKeyboard()

        Task {
            // First append the message and wait for it to complete
            await conversationManager.appendMessage(chatMessage)

            // Delay showing loading indicator to make fast responses feel instant
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            if !Task.isCancelled {
                isLoading = true
            }
            await processUserMessage(userMessage)
        }
    }
    
    private func processUserMessage(_ message: String) async {
        do {
            let conversationHistory = createConversationHistory()
            let tools = getAllTools()
            let currency = sessionViewModel.currentUser?.settings.currency ?? "USD"
            let monthlyIncome = sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
            let freedomFund = sessionViewModel.currentUser?.settings.freedomFund ?? 0

            let systemPrompt = NormaSystemPrompts.generalChatPrompt(
                currency: currency,
                monthlyIncome: monthlyIncome,
                freedomFund: freedomFund,
                bills: billViewModel.bills
            )

            print("📋 System Prompt:")
            print(systemPrompt)
            print("---")

            let response = try await AnthropicService.shared.sendMessageWithTools(
                messages: conversationHistory,
                systemPrompt: systemPrompt,
                tools: tools
            )
            
            switch response {
            case .text(let text):
                await MainActor.run {
                    isLoading = false
                    let aiMessage = ChatMessage(role: .assistant, content: text)
                    Task {
                        await conversationManager.appendMessage(aiMessage)
                        await conversationManager.saveCurrentConversation()
                        // Generate title after first exchange if not set
                        if conversationManager.currentConversation?.title == nil {
                            await conversationManager.generateTitle()
                        }
                    }
                }
                
            case .toolUse(let id, let name, let input):
                print("🔧 Tool use requested: \(name)")
                print("📥 Tool input: \(input)")

                let (toolResult, uiComponent) = await executeToolAndGetResult(toolId: id, name: name, input: input)

                print("📤 Tool result: \(toolResult)")
                print("🎨 UI Component: \(String(describing: uiComponent))")

                var updatedHistory = conversationHistory
                updatedHistory.append(AnthropicMessage(
                    role: "assistant",
                    content: .toolUse(id: id, name: name, input: input)
                ))
                updatedHistory.append(AnthropicMessage(
                    role: "user",
                    content: .toolResult(toolUseId: id, content: toolResult)
                ))

                let finalSystemPrompt = NormaSystemPrompts.generalChatPrompt(
                    currency: currency,
                    monthlyIncome: monthlyIncome,
                    freedomFund: freedomFund,
                    bills: billViewModel.bills
                )

                print("🤖 Requesting final AI response...")

                let finalResponse = try await AnthropicService.shared.sendMessageWithTools(
                    messages: updatedHistory,
                    systemPrompt: finalSystemPrompt,
                    tools: tools
                )

                print("✅ Final response received: \(finalResponse)")

                // Handle chained tool calls
                if case .toolUse(let nextId, let nextName, let nextInput) = finalResponse {
                    print("🔧 Chained tool use detected: \(nextName) (will be depth 1)")
                    await processToolUse(
                        id: nextId,
                        name: nextName,
                        input: nextInput,
                        history: updatedHistory,
                        previousUIComponent: uiComponent,
                        depth: 1
                    )
                } else if case .text(let text) = finalResponse {
                    await MainActor.run {
                        isLoading = false
                        print("💬 Creating AI message with text: \(text)")
                        print("🎨 Attaching UI component: \(String(describing: uiComponent))")
                        let aiMessage = ChatMessage(role: .assistant, content: text, uiComponent: uiComponent)
                        Task {
                            await conversationManager.appendMessage(aiMessage)
                            await conversationManager.saveCurrentConversation()
                            if conversationManager.currentConversation?.title == nil {
                                await conversationManager.generateTitle()
                            }
                        }
                        print("✅ Message appended to chat")
                    }
                } else {
                    print("⚠️ Unexpected final response type (not .text or .toolUse): \(finalResponse)")
                    await MainActor.run {
                        isLoading = false
                        // Still show the UI component if we have one from the tool
                        if let component = uiComponent {
                            print("🎨 Appending message with UI component despite unexpected response")
                            let aiMessage = ChatMessage(role: .assistant, content: "", uiComponent: component)
                            Task {
                                await conversationManager.appendMessage(aiMessage)
                                await conversationManager.saveCurrentConversation()
                            }
                        }
                    }
                }

            case .toolResult:
                print("⚠️ Received .toolResult as response (unexpected)")
                await MainActor.run {
                    isLoading = false
                }
            }
            
        } catch {
            await MainActor.run {
                isLoading = false
                showError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - First Chat Welcome

    private func triggerFirstChatWelcome() async {
        guard let user = sessionViewModel.currentUser else { return }
        guard !user.settings.hasReceivedWelcome else { return }
        guard conversationManager.conversations.isEmpty else { return }

        // Optimistic local update to prevent re-entry
        var updatedUser = user
        updatedUser.settings.hasReceivedWelcome = true
        sessionViewModel.currentUser = updatedUser

        let userName = user.name
        let currency = user.settings.currency
        let painPoint = user.settings.painPoint

        let systemPrompt = NormaSystemPrompts.firstChatPrompt(
            userName: userName,
            currency: currency,
            painPoint: painPoint
        )

        // Invisible user message to kick off the conversation
        let triggerMessage = ChatMessage(
            role: .user,
            content: "[System: This is the user's first time opening the app after onboarding. Send your welcome message.]",
            isVisible: false
        )

        let conversationHistory = [
            AnthropicMessage(role: "user", content: .text(triggerMessage.content))
        ]

        do {
            isLoading = true

            let response = try await AnthropicService.shared.sendMessageWithTools(
                messages: conversationHistory,
                systemPrompt: systemPrompt,
                tools: []
            )

            switch response {
            case .text(let text):
                let welcomeImages: UIComponent = .instructionalImages([
                    "welcome-bank-screenshot",
                    "welcome-share-sheet",
                    "welcome-norma-icon",
                    "welcome-review-transactions"
                ])

                let aiMessage = ChatMessage(
                    role: .assistant,
                    content: text,
                    uiComponent: welcomeImages
                )

                await conversationManager.appendMessage(triggerMessage)
                await conversationManager.appendMessage(aiMessage)
                conversationManager.currentConversation?.title = "Welcome"
                await conversationManager.saveCurrentConversation()

                // Persist hasReceivedWelcome to Supabase
                await sessionViewModel.updateUserProfile(updatedUser)

            default:
                // Tool use shouldn't happen (no tools passed), but handle gracefully
                let fallbackMessage = ChatMessage(
                    role: .assistant,
                    content: "Welcome to Norma! Share a bank screenshot to get started — it's the fastest way to track expenses."
                )
                await conversationManager.appendMessage(triggerMessage)
                await conversationManager.appendMessage(fallbackMessage)
                conversationManager.currentConversation?.title = "Welcome"
                await conversationManager.saveCurrentConversation()
                await sessionViewModel.updateUserProfile(updatedUser)
            }

            isLoading = false
        } catch {
            print("❌ Failed to generate welcome message: \(error)")
            isLoading = false
            // Still mark as received so we don't retry on failure
            await sessionViewModel.updateUserProfile(updatedUser)
        }
    }

    private func createConversationHistory() -> [AnthropicMessage] {
        return messages.map { chatMessage in
            AnthropicMessage(
                role: chatMessage.role == .user ? "user" : "assistant",
                content: .text(chatMessage.content)
            )
        }
    }
    
    private func getAllTools() -> [AnthropicTool] {
        return ChatToolsProvider.getAllTools()
    }

    private func executeToolAndGetResult(toolId: String, name: String, input: [String: Any]) async -> (String, UIComponent?) {
        return await toolExecutor.executeToolAndGetResult(toolId: toolId, name: name, input: input)
    }

    private func processToolUse(id: String, name: String, input: [String: Any], history: [AnthropicMessage], previousUIComponent: UIComponent?, depth: Int = 0) async {
        print("🔧 Processing tool: \(name) (depth: \(depth))")
        print("📥 Tool input: \(input)")

        // Prevent infinite tool call loops - recover gracefully
        if depth >= maxToolChainDepth {
            print("⚠️ Maximum tool chain depth reached (\(maxToolChainDepth)). Recovering gracefully.")
            await MainActor.run {
                isLoading = false
                // If we have a UI component from earlier tools, display it
                if let component = previousUIComponent {
                    let aiMessage = ChatMessage(role: .assistant, content: "Here's what I found:", uiComponent: component)
                    Task {
                        await conversationManager.appendMessage(aiMessage)
                        await conversationManager.saveCurrentConversation()
                    }
                } else {
                    // No component available - give helpful message instead of generic error
                    let helpfulMessage = ChatMessage(role: .assistant, content: "I had trouble completing that request. Could you try asking in a different way?")
                    Task {
                        await conversationManager.appendMessage(helpfulMessage)
                        await conversationManager.saveCurrentConversation()
                    }
                }
            }
            return
        }

        let (toolResult, uiComponent) = await executeToolAndGetResult(toolId: id, name: name, input: input)

        print("📤 Tool result: \(toolResult)")
        print("🎨 UI Component: \(String(describing: uiComponent))")

        var updatedHistory = history
        updatedHistory.append(AnthropicMessage(
            role: "assistant",
            content: .toolUse(id: id, name: name, input: input)
        ))
        updatedHistory.append(AnthropicMessage(
            role: "user",
            content: .toolResult(toolUseId: id, content: toolResult)
        ))

        let currency = sessionViewModel.currentUser?.settings.currency ?? "USD"
        let monthlyIncome = sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
        let freedomFund = sessionViewModel.currentUser?.settings.freedomFund ?? 0

        let systemPrompt = NormaSystemPrompts.generalChatPrompt(
            currency: currency,
            monthlyIncome: monthlyIncome,
            freedomFund: freedomFund,
            bills: billViewModel.bills
        )

        do {
            let response = try await AnthropicService.shared.sendMessageWithTools(
                messages: updatedHistory,
                systemPrompt: systemPrompt,
                tools: getAllTools()
            )

            print("✅ Response received: \(response)")

            // Handle chained tool calls recursively
            if case .toolUse(let nextId, let nextName, let nextInput) = response {
                print("🔧 Another chained tool detected: \(nextName) (will be depth \(depth + 1))")
                await processToolUse(
                    id: nextId,
                    name: nextName,
                    input: nextInput,
                    history: updatedHistory,
                    previousUIComponent: uiComponent ?? previousUIComponent,
                    depth: depth + 1
                )
            } else if case .text(let text) = response {
                await MainActor.run {
                    isLoading = false
                    print("💬 Creating AI message with text: \(text)")
                    print("🎨 Attaching UI component: \(String(describing: uiComponent ?? previousUIComponent))")
                    let aiMessage = ChatMessage(role: .assistant, content: text, uiComponent: uiComponent ?? previousUIComponent)
                    Task {
                        await conversationManager.appendMessage(aiMessage)
                        await conversationManager.saveCurrentConversation()
                        if conversationManager.currentConversation?.title == nil {
                            await conversationManager.generateTitle()
                        }
                    }
                    print("✅ Message appended to chat")
                }
            } else {
                print("⚠️ Unexpected response type received (not .text or .toolUse): \(response)")
                await MainActor.run {
                    isLoading = false
                    // Still append a message if we have a UI component from previous tools
                    if let component = uiComponent ?? previousUIComponent {
                        print("🎨 Appending message with previous UI component despite unexpected response")
                        let aiMessage = ChatMessage(role: .assistant, content: "", uiComponent: component)
                        Task {
                            await conversationManager.appendMessage(aiMessage)
                            await conversationManager.saveCurrentConversation()
                        }
                    }
                }
            }
        } catch {
            print("❌ Error in processToolUse: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
                showError(error.localizedDescription)
            }
        }
    }

    private func adjustSpacerAndScroll(proxy: ScrollViewProxy) {
        // Scroll to bottom only if user is NOT manually scrolling
        if !isUserScrolling {
            scrollToBottom(proxy: proxy)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            // Scroll to the bottom spacer to ensure we can see the full message
            proxy.scrollTo("bottomSpacer", anchor: .bottom)
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Coin Gradient Background

/// Full-screen gradient tinted by the user's coin color.
/// Uses the same pattern as LandingPageView — two explicit colors of the same hue at different brightness.
struct CoinGradientBackground: View {
    let coinColor: Color
    let colorScheme: ColorScheme

    private var rgb: (r: CGFloat, g: CGFloat, b: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(coinColor).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }

    var body: some View {
        let c = rgb

        LinearGradient(
            stops: colorScheme == .dark
                ? [
                    .init(color: Color(red: c.r * 0.22, green: c.g * 0.22, blue: c.b * 0.22), location: 0),
                    .init(color: Color(red: c.r * 0.18, green: c.g * 0.18, blue: c.b * 0.18), location: 0.35),
                    .init(color: Color(red: c.r * 0.14, green: c.g * 0.14, blue: c.b * 0.14), location: 0.65),
                    .init(color: Color(red: c.r * 0.12, green: c.g * 0.12, blue: c.b * 0.12), location: 1.0)
                ]
                : [
                    .init(color: Color(red: 1 - (1 - c.r) * 0.22, green: 1 - (1 - c.g) * 0.22, blue: 1 - (1 - c.b) * 0.22), location: 0),
                    .init(color: Color(red: 1 - (1 - c.r) * 0.16, green: 1 - (1 - c.g) * 0.16, blue: 1 - (1 - c.b) * 0.16), location: 0.35),
                    .init(color: Color(red: 1 - (1 - c.r) * 0.12, green: 1 - (1 - c.g) * 0.12, blue: 1 - (1 - c.b) * 0.12), location: 0.65),
                    .init(color: Color(red: 1 - (1 - c.r) * 0.08, green: 1 - (1 - c.g) * 0.08, blue: 1 - (1 - c.b) * 0.08), location: 1.0)
                ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct LastMessagePositionKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let conversationManager = ConversationManager(dataManager: dataManager, sessionViewModel: sessionViewModel)

    MainChatView(isMenuOpen: .constant(false))
        .environmentObject(dataManager)
        .environmentObject(sessionViewModel)
        .environmentObject(conversationManager)
        .environmentObject(BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        .preferredColorScheme(.dark)
}
