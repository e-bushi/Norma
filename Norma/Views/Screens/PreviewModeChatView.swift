//
//  PreviewModeChatView.swift
//  Norma
//
//  Created by Claude on 10/25/25.
//

import SwiftUI

struct PreviewModeChatView: View {
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel

    // Access the shared preview mode view model from onboarding
    private var previewModeViewModel: PreviewModeViewModel {
        onboardingViewModel.previewModeViewModel
    }

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var scrollViewProxy: ScrollViewProxy?
    @State private var showCapsules = false
    @State private var userMessageCount = 0
    @State private var showReadyModal = false
    @State private var hasClickedReady = false
    @State private var showSaveButton = false
    @State private var dynamicSpacerHeight: CGFloat = 180
    @State private var viewportHeight: CGFloat = 0
    @State private var lastMessagePosition: CGFloat = 0
    @GestureState private var isUserScrolling = false
    @State private var flowState: String? = nil // "In flow", "Stagnant", or "Drifting"
    @State private var visibleNavCapsules: Int = 0

    private let maxSpacerHeight: CGFloat = 600

    // Currency formatter for nav bar capsules
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = previewModeViewModel.userCurrency ?? "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    // Animate nav bar capsules with staggered timing and haptics
    private func animateNavCapsules() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()

        // Animate capsules appearing with staggered delays + haptics
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4)) {
            visibleNavCapsules = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            impactFeedback.impactOccurred(intensity: 0.6)
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6)) {
            visibleNavCapsules = 2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            impactFeedback.impactOccurred(intensity: 0.6)
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.8)) {
            visibleNavCapsules = 3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            impactFeedback.impactOccurred(intensity: 0.6)
        }
    }

    // Calculate arc count for display
    private var arcCount: Int {
        guard let freedomFund = previewModeViewModel.userFreedomFund else { return 0 }
        return ArcCalculationService.calculateArcs(
            freedomFund: freedomFund,
            bills: previewModeViewModel.bills,
            budgets: previewModeViewModel.budgets
        )
    }

    private var toolExecutor: PreviewModeToolExecutor {
        PreviewModeToolExecutor(previewModeViewModel: previewModeViewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Chat content fills entire space
                chatContent
                    .background(Color("NormaBackground").ignoresSafeArea())
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }

                // Input area overlays at bottom
                inputArea
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        onboardingViewModel.currentStep = .landing
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Norma")
                                .font(.normaHeadline(20))

                            Text("Preview Mode")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color("NormaPastelTeal").opacity(0.8))
                                )
                        }

                        // Three capsules row (Income, Spending Flow, Arcs)
                        if flowState != nil {
                            HStack(spacing: 6) {
                                // Income capsule
                                if let income = previewModeViewModel.userIncome {
                                    Text("Income: \(formatCurrency(income))")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule()
                                                .fill(Color("NormaPastelTeal"))
                                        )
                                        .opacity(visibleNavCapsules > 0 ? 1 : 0)
                                        .scaleEffect(visibleNavCapsules > 0 ? 1.0 : 0.3)
                                }

                                // Spending Flow capsule
                                if let flowState = flowState {
                                    Text(flowState)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule()
                                                .fill(flowStateColor(for: flowState))
                                        )
                                        .opacity(visibleNavCapsules > 1 ? 1 : 0)
                                        .scaleEffect(visibleNavCapsules > 1 ? 1.0 : 0.3)
                                }

                                // Arcs capsule
                                Text("\(arcCount) arc\(arcCount == 1 ? "" : "s")")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color("NormaPastelPurple"))
                                    )
                                    .opacity(visibleNavCapsules > 2 ? 1 : 0)
                                    .scaleEffect(visibleNavCapsules > 2 ? 1.0 : 0.3)
                            }
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: flowState)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: visibleNavCapsules)
                }

                if showSaveButton {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            previewModeViewModel.showSaveProgressModal = true
                        }) {
                            Text("Save")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color("NormaPastelTeal"))
                        }
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $onboardingViewModel.previewModeViewModel.showCompletionModal) {
            PreviewModeCompletionModal(
                onSaveProgress: {
                    // Handle save progress action - transition to authentication
                    previewModeViewModel.showCompletionModal = false
                },
                onContinueWithoutSaving: {
                    // Handle continue without saving
                    previewModeViewModel.showCompletionModal = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $onboardingViewModel.previewModeViewModel.showSaveProgressModal) {
            SaveProgressModal(
                userName: previewModeViewModel.userName ?? "there",
                onSignUpWithEmail: {
                    previewModeViewModel.showSaveProgressModal = false
                    onboardingViewModel.showSignUp = true
                    onboardingViewModel.currentStep = .authentication
                },
                onSignUpWithApple: {
                    previewModeViewModel.showSaveProgressModal = false
                    handleAppleSignIn()
                },
                onContinueChatting: {
                    handleKeepChatting()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showReadyModal) {
            ReadyToStartModal(
                onReady: {
                    handleReadyToStart()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled()
        }
        .onAppear {
            showInitialGreeting()
        }
        .onChange(of: previewModeViewModel.bills) { _, newValue in
            if newValue.count > 0 {
                // Trigger capsule animation when currency is set
                showCapsules = true
            }
        }
        .onChange(of: flowState) { oldValue, newValue in
            // Trigger nav bar capsule animation when flow state is set
            if oldValue == nil && newValue != nil {
                animateNavCapsules()
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    @ViewBuilder
    private var chatContent: some View {
        ScrollViewReader { proxy in
            GeometryReader { outerGeometry in
                ScrollView {
                    VStack(spacing: 0) {
                        LazyVStack(spacing: 20) {
                            ForEach(messages.filter { $0.isVisible }) { message in
                                ChatBubbleView(message: message)
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
                            } else if let lastMessage = messages.last {
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
                .background(Color("NormaBackground"))
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

    @ViewBuilder
    private var inputArea: some View {
        PreviewChatInputView(
            text: $inputText,
            showCapsules: $showCapsules,
            isLoading: isLoading,
            onSend: sendMessage,
            viewModel: previewModeViewModel
        )
    }

    private func sendMessage() {
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }

        // Always add message to chat and dismiss keyboard
        let chatMessage = ChatMessage(role: .user, content: userMessage)
        messages.append(chatMessage)

        inputText = ""
        hideKeyboard()

        // Track message count
        if !hasClickedReady {
            userMessageCount += 1
        }

        Task {
            // Delay showing loading indicator to make fast responses feel instant
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            if !Task.isCancelled {
                // Check if we should show the ready modal
                if !hasClickedReady && userMessageCount >= 3 {
                    await MainActor.run {
                        showReadyModal = true
                        isLoading = false
                    }
                    return // Don't process the message
                }

                await MainActor.run {
                    isLoading = true
                    // Haptic feedback is now handled by ThinkingIndicator
                }
            }
            await processUserMessage(userMessage)
        }
    }

    private func processUserMessage(_ message: String) async {
        do {
            let conversationHistory = createConversationHistory()
            let tools = getAllTools()
            print("Convo history:\n\n\n\(conversationHistory)\n\n\n")
            // Choose prompt based on whether user has clicked "I'm Ready"
            let systemPrompt: String
            if hasClickedReady {
                // Real onboarding - 3 questions flow
                systemPrompt = NormaSystemPrompts.realOnboardingPrompt(
                    userName: previewModeViewModel.userName ?? "there",
                    currency: previewModeViewModel.userCurrency ?? "USD",
                    hasIncome: previewModeViewModel.userIncome != nil,
                    hasBill: !previewModeViewModel.bills.isEmpty,
                    hasFreedomFund: previewModeViewModel.userFreedomFund != nil,
                    hasChallenge: previewModeViewModel.userChallenge != nil
                )
            } else {
                // Preview mode with mock data
                systemPrompt = NormaSystemPrompts.previewModePrompt(
                    userName: previewModeViewModel.userName,
                    currency: previewModeViewModel.userCurrency,
                    bills: previewModeViewModel.bills,
                    expenses: previewModeViewModel.expenses,
                    budgets: previewModeViewModel.budgets
                )
            }

//            print("📋 System Prompt:")
//            print(systemPrompt)
            print("---\n\n")

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
                    messages.append(aiMessage)
                }

            case .toolUse(let id, let name, let input):
                print("🔧 Tool use requested: \(name)")
                print("📥 Tool input: \(input)")

                let (toolResult, uiComponent) = await executeToolAndGetResult(toolId: id, name: name, input: input)

                print("📤 Tool result: \(toolResult)")
                print("🎨 UI Component: \(String(describing: uiComponent))")

                // Save tool use and tool result to messages array
                await MainActor.run {
                    // Save tool use message (visible as activity indicator)
                    let activityMessage = createToolActivityMessage(name: name, input: input)
                    let toolUseMessage = ChatMessage(
                        role: .assistant,
                        content: activityMessage,
                        uiComponent: .toolActivity(activityMessage),
                        isVisible: true,
                        anthropicContent: .toolUse(id: id, name: name, input: input)
                    )
                    messages.append(toolUseMessage)

                    // Save tool result message (hidden from UI, only for API conversation history)
                    let toolResultMessage = ChatMessage(
                        role: .user,
                        content: "",  // Empty content, not displayed
                        isVisible: false,
                        anthropicContent: .toolResult(toolUseId: id, content: toolResult)
                    )
                    messages.append(toolResultMessage)
                }

                var updatedHistory = conversationHistory
                updatedHistory.append(AnthropicMessage(
                    role: "assistant",
                    content: .toolUse(id: id, name: name, input: input)
                ))
                updatedHistory.append(AnthropicMessage(
                    role: "user",
                    content: .toolResult(toolUseId: id, content: toolResult)
                ))

                // Use appropriate prompt based on onboarding state
                let finalSystemPrompt: String
                if hasClickedReady {
                    finalSystemPrompt = NormaSystemPrompts.realOnboardingPrompt(
                        userName: previewModeViewModel.userName ?? "there",
                        currency: previewModeViewModel.userCurrency ?? "USD",
                        hasIncome: previewModeViewModel.userIncome != nil,
                        hasBill: !previewModeViewModel.bills.isEmpty,
                        hasFreedomFund: previewModeViewModel.userFreedomFund != nil,
                        hasChallenge: previewModeViewModel.userChallenge != nil
                    )
                } else {
                    finalSystemPrompt = NormaSystemPrompts.previewModePrompt(
                        userName: previewModeViewModel.userName,
                        currency: previewModeViewModel.userCurrency,
                        bills: previewModeViewModel.bills,
                        expenses: previewModeViewModel.expenses,
                        budgets: previewModeViewModel.budgets
                    )
                }

                print("🤖 Requesting final AI response...")

                let finalResponse = try await AnthropicService.shared.sendMessageWithTools(
                    messages: updatedHistory,
                    systemPrompt: finalSystemPrompt,
                    tools: tools
                )

                print("✅ Final response received: \(finalResponse)")

                // Handle chained tool calls
                if case .toolUse(let nextId, let nextName, let nextInput) = finalResponse {
                    print("🔧 Chained tool use detected: \(nextName)")
                    // Process the chained tool call recursively
                    await processToolUse(id: nextId, name: nextName, input: nextInput, history: updatedHistory, previousUIComponent: uiComponent)
                } else if case .text(let text) = finalResponse {
                    await MainActor.run {
                        isLoading = false
                        print("💬 Creating AI message with text: \(text)")

                        // Handle flow state capsule specially - set nav bar state
                        if let component = uiComponent,
                           case .flowStateCapsule(let state) = component {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                flowState = state
                            }
                            print("🎨 Flow state set in nav bar: \(state)")
                            // Don't attach to message - it's shown in nav bar only
                            let aiMessage = ChatMessage(role: .assistant, content: text, uiComponent: nil)
                            messages.append(aiMessage)
                        } else {
                            // Normal UI components attach to message
                            print("🎨 Attaching UI component: \(String(describing: uiComponent))")
                            let aiMessage = ChatMessage(role: .assistant, content: text, uiComponent: uiComponent)
                            messages.append(aiMessage)
                        }
                        print("✅ Message appended to chat")
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                    }
                }

            case .toolResult:
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

    private func createConversationHistory() -> [AnthropicMessage] {
        return messages.map { chatMessage in
            AnthropicMessage(
                role: chatMessage.role == .user ? "user" : "assistant",
                content: chatMessage.anthropicContent ?? .text(chatMessage.content)
            )
        }
    }

    private func createToolActivityMessage(name: String, input: [String: Any]) -> String {
        switch name {
        case "save_user_name":
            if let userName = input["name"] as? String {
                return "Saving your name: \(userName)..."
            }
            return "Saving your name..."
        case "save_user_currency":
            if let currency = input["currency"] as? String {
                return "Setting currency to \(currency.uppercased())..."
            }
            return "Setting your currency..."
        case "save_user_income":
            return "Saving your income..."
        case "save_user_savings":
            return "Saving your savings..."
        case "save_user_challenge":
            return "Noting your financial goal..."
        case "create_bill":
            if let billName = input["name"] as? String {
                return "Creating bill: \(billName)..."
            }
            return "Creating bill..."
        case "create_expense":
            if let expenseName = input["name"] as? String {
                return "Creating expense: \(expenseName)..."
            }
            return "Creating expense..."
        case "create_budget":
            if let budgetName = input["name"] as? String {
                return "Creating budget: \(budgetName)..."
            }
            return "Creating budget..."
        default:
            return "Processing..."
        }
    }

    private func getAllTools() -> [AnthropicTool] {
        return ChatToolsProvider.getAllTools()
    }

    private func executeToolAndGetResult(toolId: String, name: String, input: [String: Any]) async -> (String, UIComponent?) {
        return await toolExecutor.executeToolAndGetResult(toolId: toolId, name: name, input: input)
    }

    private func processToolUse(id: String, name: String, input: [String: Any], history: [AnthropicMessage], previousUIComponent: UIComponent?) async {
        print("🔧 Processing tool: \(name)")
        print("📥 Tool input: \(input)")

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

        // Use appropriate prompt based on onboarding state
        let systemPrompt: String
        if hasClickedReady {
            systemPrompt = NormaSystemPrompts.realOnboardingPrompt(
                userName: previewModeViewModel.userName ?? "there",
                currency: previewModeViewModel.userCurrency ?? "USD",
                hasIncome: previewModeViewModel.userIncome != nil,
                hasBill: !previewModeViewModel.bills.isEmpty,
                hasFreedomFund: previewModeViewModel.userFreedomFund != nil,
                hasChallenge: previewModeViewModel.userChallenge != nil
            )
        } else {
            systemPrompt = NormaSystemPrompts.previewModePrompt(
                userName: previewModeViewModel.userName,
                currency: previewModeViewModel.userCurrency,
                bills: previewModeViewModel.bills,
                expenses: previewModeViewModel.expenses,
                budgets: previewModeViewModel.budgets
            )
        }

        do {
            let response = try await AnthropicService.shared.sendMessageWithTools(
                messages: updatedHistory,
                systemPrompt: systemPrompt,
                tools: getAllTools()
            )

            print("✅ Response received: \(response)")

            // Handle chained tool calls recursively
            if case .toolUse(let nextId, let nextName, let nextInput) = response {
                print("🔧 Another chained tool detected: \(nextName)")
                await processToolUse(id: nextId, name: nextName, input: nextInput, history: updatedHistory, previousUIComponent: uiComponent ?? previousUIComponent)
            } else if case .text(let text) = response {
                await MainActor.run {
                    isLoading = false
                    print("💬 Creating AI message with text: \(text)")

                    // Handle flow state capsule specially - set nav bar state
                    if let component = uiComponent ?? previousUIComponent,
                       case .flowStateCapsule(let state) = component {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            flowState = state
                        }
                        print("🎨 Flow state set in nav bar: \(state)")
                        // Don't attach to message - it's shown in nav bar only
                        let aiMessage = ChatMessage(role: .assistant, content: text, uiComponent: nil)
                        messages.append(aiMessage)
                    } else {
                        // Normal UI components attach to message
                        print("🎨 Attaching UI component: \(String(describing: uiComponent ?? previousUIComponent))")
                        let aiMessage = ChatMessage(role: .assistant, content: text, uiComponent: uiComponent ?? previousUIComponent)
                        messages.append(aiMessage)
                    }
                    print("✅ Message appended to chat")
                }
            } else {
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

    private func showInitialGreeting() {
        // Only show greeting if messages are empty (first time)
        guard messages.isEmpty else { return }

        Task {
            // Add a small delay for a natural feel
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds

            await MainActor.run {
                isLoading = true
            }

            do {
                // Get the initial greeting from Norma - use appropriate prompt
                let systemPrompt: String
                if hasClickedReady {
                    systemPrompt = NormaSystemPrompts.realOnboardingPrompt(
                        userName: previewModeViewModel.userName ?? "there",
                        currency: previewModeViewModel.userCurrency ?? "USD",
                        hasIncome: previewModeViewModel.userIncome != nil,
                        hasBill: !previewModeViewModel.bills.isEmpty,
                        hasFreedomFund: previewModeViewModel.userFreedomFund != nil,
                        hasChallenge: previewModeViewModel.userChallenge != nil
                    )
                } else {
                    systemPrompt = NormaSystemPrompts.previewModePrompt(
                        userName: previewModeViewModel.userName,
                        currency: previewModeViewModel.userCurrency,
                        bills: previewModeViewModel.bills,
                        expenses: previewModeViewModel.expenses,
                        budgets: previewModeViewModel.budgets
                    )
                }

                // Create an empty conversation history for the initial greeting
                let initialMessage = AnthropicMessage(
                    role: "user",
                    content: .text("Start the conversation")
                )

                let response = try await AnthropicService.shared.sendMessageWithTools(
                    messages: [initialMessage],
                    systemPrompt: systemPrompt,
                    tools: []
                )

                await MainActor.run {
                    isLoading = false

                    if case .text(let text) = response {
                        let greetingMessage = ChatMessage(role: .assistant, content: text)
                        messages.append(greetingMessage)
                    }
                }

            } catch {
                await MainActor.run {
                    isLoading = false
                    showError(error.localizedDescription)
                }
            }
        }
    }

    private func handleReadyToStart() {
        // Clear mock data but keep name and currency
        previewModeViewModel.clearMockData()

        // Hide capsules when transitioning to real onboarding
        showCapsules = false

        // Clear messages
        messages.removeAll()

        // Reset message counter and mark as ready
        userMessageCount = 0
        hasClickedReady = true
        showReadyModal = false

        // Show new greeting for real onboarding
        showInitialGreeting()
    }

    private func handleKeepChatting() {
        // Close the modal
        previewModeViewModel.showSaveProgressModal = false

        // Show the save button in the toolbar with animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showSaveButton = true
        }
    }

    private func handleAppleSignIn() {
        // TODO: Implement Apple Sign In
        // For now, just navigate to authentication
        onboardingViewModel.currentStep = .authentication
    }

    private func flowStateColor(for state: String) -> Color {
        switch state {
        case "In flow":
            return Color.green.opacity(0.8)
        case "Stagnant":
            return Color.orange.opacity(0.8)
        case "Drifting":
            return Color.red.opacity(0.8)
        default:
            return Color.gray.opacity(0.8)
        }
    }

}

struct ReadyToStartModal: View {
    let onReady: () -> Void

    @State private var animateArrow = false
    @State private var animateTitle = false
    @State private var animateContent = false
    @State private var animateButton = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 3D Arrow
            Arrow3DView()
                .frame(width: 180, height: 180)
                .scaleEffect(animateArrow ? 1.0 : 0.3)
                .opacity(animateArrow ? 1.0 : 0.0)

            Text("Let's Make This Real")
                .font(.normaHeadline(24))
                .multilineTextAlignment(.center)
                .scaleEffect(animateTitle ? 1.0 : 0.8)
                .opacity(animateTitle ? 1.0 : 0.0)

            VStack(alignment: .leading, spacing: 12) {
                Text("You've seen how I work with sample data. Now let's personalize it for you:")
                    .normaBody()
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .normaBody()
                    Text("Just a few short questions about your finances")
                        .normaBody()
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .normaBody()
                    Text("Get advice tailored specifically to you")
                        .normaBody()
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .normaBody()
                    Text("Your data is fully encrypted and private")
                        .normaBody()
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
            .background(Color("NormaSurface"))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .offset(y: animateContent ? 0 : 20)
            .opacity(animateContent ? 1.0 : 0.0)

            Button(action: {
                onReady()
            }) {
                Text("I'm Ready")
                    .font(.normaHeadline(16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("NormaPastelTeal"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .scaleEffect(animateButton ? 1.0 : 0.8)
            .opacity(animateButton ? 1.0 : 0.0)

            Spacer()
        }
        .padding(.vertical, 32)
        .onAppear {
            // Staggered animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateArrow = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                animateTitle = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                animateContent = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4)) {
                animateButton = true
            }
        }
    }
}

struct PreviewModeCompletionModal: View {
    let onSaveProgress: () -> Void
    let onContinueWithoutSaving: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Congratulations!")
                .font(.title)
                .fontWeight(.bold)

            Text("You've completed preview mode by adding a bill, budget, and expense!")
                .normaBody()
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Text("Save Your Progress")
                    .font(.normaFinancial(16))

                Text("Add an email to save your data. If you logout without saving, your conversation and data will be erased.")
                    .normaBody()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .padding()
            .background(Color("NormaSurface"))
            .cornerRadius(12)
            .padding(.horizontal)

            VStack(spacing: 12) {
                Button(action: onSaveProgress) {
                    Text("Save Progress")
                        .font(.normaFinancial(16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                }

                Button(action: onContinueWithoutSaving) {
                    Text("Continue Without Saving")
                        .normaBody()
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 32)
    }
}

struct SaveProgressModal: View {
    let userName: String
    let onSignUpWithEmail: () -> Void
    let onSignUpWithApple: () -> Void
    let onContinueChatting: () -> Void

    @State private var animateArrow = false
    @State private var animateTitle = false
    @State private var animateContent = false
    @State private var animateButtons = false
    @State private var animateDivider = false
    @State private var animateKeepChatting = false

    var body: some View {
        VStack(spacing: 24) {
            // 3D Arrow
            Arrow3DView()
                .frame(width: 180, height: 180)
                .scaleEffect(animateArrow ? 1.0 : 0.3)
                .opacity(animateArrow ? 1.0 : 0.0)

            Text("Nice Work, \(userName)!")
                .font(.normaHeadline(24))
                .multilineTextAlignment(.center)
                .scaleEffect(animateTitle ? 1.0 : 0.8)
                .opacity(animateTitle ? 1.0 : 0.0)

            VStack(alignment: .leading, spacing: 12) {
                Text("You're all set up! To save your progress, create an account:")
                    .normaBody()
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .normaBody()
                    Text("Your data is fully encrypted and private")
                        .normaBody()
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
            .background(Color("NormaSurface"))
            .cornerRadius(12)
            .padding(.horizontal)
            .offset(y: animateContent ? 0 : 20)
            .opacity(animateContent ? 1.0 : 0.0)

            // Authentication buttons
            VStack(spacing: 16) {
                // Sign up with Apple button
                Button(action: onSignUpWithApple) {
                    HStack(spacing: 12) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Sign up with Apple")
                            .font(.normaHeadline(16))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black)
                    .cornerRadius(12)
                }

                // Sign up with Email button
                Button(action: onSignUpWithEmail) {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Sign up with Email")
                            .font(.normaHeadline(16))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("NormaPastelTeal"))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .scaleEffect(animateButtons ? 1.0 : 0.8)
            .opacity(animateButtons ? 1.0 : 0.0)

            // Divider with "or"
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                Text("or")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.horizontal, 24)
            .opacity(animateDivider ? 1.0 : 0.0)

            // Keep chatting button with warning
            VStack(spacing: 8) {
                Button(action: onContinueChatting) {
                    Text("Keep Chatting")
                        .font(.normaHeadline(14))
                        .foregroundColor(Color("NormaPastelTeal"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color("NormaPastelTeal").opacity(0.15))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 24)

                Text("Don't forget to save or you'll risk losing all your progress")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .offset(y: animateKeepChatting ? 0 : 15)
            .opacity(animateKeepChatting ? 1.0 : 0.0)
        }
        .padding(.vertical, 32)
        .onAppear {
            // Staggered animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateArrow = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                animateTitle = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                animateContent = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4)) {
                animateButtons = true
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
                animateDivider = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.55)) {
                animateKeepChatting = true
            }
        }
    }
}

// Preference key to track last message position
struct LastMessagePositionKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let onboardingViewModel = OnboardingViewModel(sessionViewModel: sessionViewModel)

    PreviewModeChatView()
        .environmentObject(sessionViewModel)
        .environmentObject(onboardingViewModel)
        .preferredColorScheme(.dark)
}
