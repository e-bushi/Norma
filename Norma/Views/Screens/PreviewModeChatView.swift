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
    @State private var dynamicSpacerHeight: CGFloat = 180
    @State private var viewportHeight: CGFloat = 0
    @State private var lastMessagePosition: CGFloat = 0
    @GestureState private var isUserScrolling = false
    @State private var newlyAddedMessageIds: Set<String> = []
    @State private var showSaveModal = false
    @State private var showCapsules = false
    @State private var showArcSimulator = false
    @State private var arcSimulatorData: (currentArcs: Int, totalMonthlyBills: Double, freedomFund: Double, currency: String)?

    private let maxSpacerHeight: CGFloat = 600
    private let maxToolChainDepth: Int = 2

    private var toolExecutor: PreviewModeToolExecutor {
        PreviewModeToolExecutor(previewModeViewModel: previewModeViewModel)
    }

    /// All 5 onboarding data points collected — drives Save button visibility
    private var onboardingDataComplete: Bool {
        previewModeViewModel.onboardingDataComplete
    }

    /// Arc count for passing into the system prompt
    private var arcCount: Int {
        guard let freedomFund = previewModeViewModel.userFreedomFund else { return 0 }
        return ArcCalculationService.calculateArcs(
            freedomFund: freedomFund,
            bills: previewModeViewModel.bills
        )
    }

    private var currentSystemPrompt: String {
        NormaSystemPrompts.onboardingChatPrompt(
            userName: previewModeViewModel.userName,
            currency: previewModeViewModel.userCurrency,
            hasBill: !previewModeViewModel.bills.isEmpty,
            hasIncome: previewModeViewModel.userIncome != nil,
            hasFreedomFund: previewModeViewModel.userFreedomFund != nil,
            arcCount: arcCount
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                chatContent
                    .background(Color("NormaBackground").ignoresSafeArea())
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }

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

                            Text("Get Started")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color("NormaPastelTeal").opacity(0.8))
                                )
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if onboardingDataComplete {
                        Button(action: {
                            showSaveModal = true
                        }) {
                            Text("Save")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color("NormaPastelTeal"))
                        }
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: onboardingDataComplete)
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showSaveModal) {
            SaveProgressModal(
                userName: previewModeViewModel.userName ?? "there",
                onSignUpWithEmail: {
                    showSaveModal = false
                    onboardingViewModel.showSignUp = true
                    onboardingViewModel.currentStep = .authentication
                },
                onSignUpWithApple: {
                    handleAppleSignIn()
                },
                onSignUpWithGoogle: {
                    handleGoogleSignIn()
                },
                onContinueChatting: {
                    handleKeepChatting()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showArcSimulator) {
            ArcSimulatorSheetView(
                initialFreedomFund: arcSimulatorData?.freedomFund ?? previewModeViewModel.userFreedomFund ?? 0,
                totalMonthlyBills: arcSimulatorData?.totalMonthlyBills ?? ArcCalculationService.calculateMonthlyBillsTotal(bills: previewModeViewModel.bills),
                currency: arcSimulatorData?.currency ?? previewModeViewModel.userCurrency ?? "USD",
                bills: previewModeViewModel.bills
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            showInitialGreeting()
        }
        .onChange(of: previewModeViewModel.bills.count) { _, count in
            if count > 0 && !showCapsules {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showCapsules = true
                }
            }
        }
        .onChange(of: showSaveModal) { _, showModal in
            if showModal && sessionViewModel.isAuthenticated {
                showSaveModal = false
                Task {
                    await onboardingViewModel.handleAuthenticatedPreviewModeCompletion()
                }
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
                                ChatBubbleView(
                                    message: message,
                                    shouldAnimate: newlyAddedMessageIds.contains(message.id),
                                    onArcSimulatorTap: { arcs, bills, fund, currency in
                                        arcSimulatorData = (arcs, bills, fund, currency)
                                        showArcSimulator = true
                                    }
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
                    adjustSpacerAndScroll(proxy: proxy)
                }
                .onChange(of: messages.count) {
                    adjustSpacerAndScroll(proxy: proxy)
                }
                .onChange(of: isLoading) {
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

        let chatMessage = ChatMessage(role: .user, content: userMessage)
        messages.append(chatMessage)

        inputText = ""
        hideKeyboard()

        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if !Task.isCancelled {
                await MainActor.run {
                    isLoading = true
                }
            }
            await processUserMessage(userMessage)
        }
    }

    private func processUserMessage(_ message: String) async {
        do {
            let conversationHistory = createConversationHistory()
            let tools = getAllTools()

            let response = try await AnthropicService.shared.sendMessageWithTools(
                messages: conversationHistory,
                systemPrompt: currentSystemPrompt,
                tools: tools
            )

            switch response {
            case .text(let text):
                await MainActor.run {
                    isLoading = false
                    let aiMessage = ChatMessage(role: .assistant, content: text)
                    newlyAddedMessageIds.insert(aiMessage.id)
                    messages.append(aiMessage)
                }

            case .toolUse(let id, let name, let input):
                print("🔧 Tool use requested: \(name)")

                let (toolResult, uiComponent) = await executeToolAndGetResult(toolId: id, name: name, input: input)

                await MainActor.run {
                    let activityMessage = createToolActivityMessage(name: name, input: input)
                    let toolUseMessage = ChatMessage(
                        role: .assistant,
                        content: activityMessage,
                        uiComponent: .toolActivity(activityMessage),
                        isVisible: true,
                        anthropicContent: .toolUse(id: id, name: name, input: input)
                    )
                    messages.append(toolUseMessage)

                    let toolResultMessage = ChatMessage(
                        role: .user,
                        content: "",
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

                let finalResponse = try await AnthropicService.shared.sendMessageWithTools(
                    messages: updatedHistory,
                    systemPrompt: currentSystemPrompt,
                    tools: tools
                )

                if case .toolUse(let nextId, let nextName, let nextInput) = finalResponse {
                    await processToolUse(id: nextId, name: nextName, input: nextInput, history: updatedHistory, previousUIComponent: uiComponent, depth: 1)
                } else if case .text(let text) = finalResponse {
                    await MainActor.run {
                        isLoading = false
                        let aiMessage = ChatMessage(role: .assistant, content: text, uiComponent: uiComponent)
                        newlyAddedMessageIds.insert(aiMessage.id)
                        messages.append(aiMessage)
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                        if let component = uiComponent {
                            let aiMessage = ChatMessage(role: .assistant, content: "", uiComponent: component)
                            newlyAddedMessageIds.insert(aiMessage.id)
                            messages.append(aiMessage)
                        }
                    }
                }

            case .toolResult:
                await MainActor.run {
                    isLoading = false
                }
            }

        } catch {
            print("❌ Error in processUserMessage: \(error.localizedDescription)")
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
        case "save_user_freedom_fund":
            return "Saving your freedom fund..."
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
        case "show_arc_simulator":
            return "Preparing arc simulator..."
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

    private func processToolUse(id: String, name: String, input: [String: Any], history: [AnthropicMessage], previousUIComponent: UIComponent?, depth: Int = 0) async {
        if depth >= maxToolChainDepth {
            await MainActor.run {
                isLoading = false
                let errorMessage = ChatMessage(role: .assistant, content: "I encountered an issue processing your request. Please try again.")
                messages.append(errorMessage)
            }
            return
        }

        let (toolResult, uiComponent) = await executeToolAndGetResult(toolId: id, name: name, input: input)

        // Add tool use/result to messages for conversation history
        await MainActor.run {
            let activityMessage = createToolActivityMessage(name: name, input: input)
            let toolUseMessage = ChatMessage(
                role: .assistant,
                content: activityMessage,
                uiComponent: .toolActivity(activityMessage),
                isVisible: true,
                anthropicContent: .toolUse(id: id, name: name, input: input)
            )
            messages.append(toolUseMessage)

            let toolResultMessage = ChatMessage(
                role: .user,
                content: "",
                isVisible: false,
                anthropicContent: .toolResult(toolUseId: id, content: toolResult)
            )
            messages.append(toolResultMessage)
        }

        var updatedHistory = history
        updatedHistory.append(AnthropicMessage(
            role: "assistant",
            content: .toolUse(id: id, name: name, input: input)
        ))
        updatedHistory.append(AnthropicMessage(
            role: "user",
            content: .toolResult(toolUseId: id, content: toolResult)
        ))

        do {
            let response = try await AnthropicService.shared.sendMessageWithTools(
                messages: updatedHistory,
                systemPrompt: currentSystemPrompt,
                tools: getAllTools()
            )

            if case .toolUse(let nextId, let nextName, let nextInput) = response {
                await processToolUse(id: nextId, name: nextName, input: nextInput, history: updatedHistory, previousUIComponent: uiComponent ?? previousUIComponent, depth: depth + 1)
            } else if case .text(let text) = response {
                await MainActor.run {
                    isLoading = false
                    let aiMessage = ChatMessage(role: .assistant, content: text, uiComponent: uiComponent ?? previousUIComponent)
                    newlyAddedMessageIds.insert(aiMessage.id)
                    messages.append(aiMessage)
                }
            } else {
                await MainActor.run {
                    isLoading = false
                    if let component = uiComponent ?? previousUIComponent {
                        let aiMessage = ChatMessage(role: .assistant, content: "", uiComponent: component)
                        newlyAddedMessageIds.insert(aiMessage.id)
                        messages.append(aiMessage)
                    }
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
        if !isUserScrolling {
            scrollToBottom(proxy: proxy)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            proxy.scrollTo("bottomSpacer", anchor: .bottom)
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }

    private func showInitialGreeting() {
        guard messages.isEmpty else { return }

        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)

            await MainActor.run {
                isLoading = true
            }

            do {
                let initialMessage = AnthropicMessage(
                    role: "user",
                    content: .text("Start the conversation")
                )

                let response = try await AnthropicService.shared.sendMessageWithTools(
                    messages: [initialMessage],
                    systemPrompt: currentSystemPrompt,
                    tools: []
                )

                await MainActor.run {
                    isLoading = false

                    if case .text(let text) = response {
                        let greetingMessage = ChatMessage(role: .assistant, content: text)
                        newlyAddedMessageIds.insert(greetingMessage.id)
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

    private func handleKeepChatting() {
        showSaveModal = false
    }

    private func handleAppleSignIn() {
        Task {
            await onboardingViewModel.signInWithAppleFromPreviewMode()
        }
    }

    private func handleGoogleSignIn() {
        Task {
            await onboardingViewModel.signInWithGoogleFromPreviewMode()
        }
    }
}

struct SaveProgressModal: View {
    let userName: String
    let onSignUpWithEmail: () -> Void
    let onSignUpWithApple: () -> Void
    let onSignUpWithGoogle: () -> Void
    let onContinueChatting: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var animateArrow = false
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateButtons = false
    @State private var animateDivider = false
    @State private var animateKeepChatting = false

    private let accentColor = Color("NormaPastelTeal")
    private let secondaryColor = Color("NormaPastelPurple")

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    Color("NormaBackground")

                    LavaOrb(
                        color: accentColor,
                        size: 200,
                        blur: 60,
                        opacity: 0.15,
                        bounds: geometry.size,
                        speed: 5.0
                    )

                    LavaOrb(
                        color: secondaryColor,
                        size: 160,
                        blur: 50,
                        opacity: 0.12,
                        bounds: geometry.size,
                        speed: 6.0
                    )
                }
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 40)

                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 200, height: 200)
                            .blur(radius: 30)

                        Arrow3DView()
                            .frame(width: 160, height: 160)
                    }
                    .scaleEffect(animateArrow ? 1.0 : 0.3)
                    .opacity(animateArrow ? 1.0 : 0.0)

                    Spacer(minLength: 24)

                    WaveTextView(
                        text: "Nice work, \(userName)!",
                        font: .normaHeadline(32),
                        color: .primary,
                        isAnimating: animateTitle,
                        alignment: .center
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 12)

                    Text("You're all set up. Create an account\nto save your progress.")
                        .normaBody()
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                        .opacity(animateSubtitle ? 1.0 : 0.0)

                    Spacer(minLength: 8)

                    Text("Your data is fully encrypted and private")
                        .normaCaption()
                        .foregroundColor(.secondary.opacity(0.7))
                        .opacity(animateSubtitle ? 1.0 : 0.0)

                    Spacer(minLength: 32)

                    VStack(spacing: 12) {
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            onSignUpWithApple()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)

                                Text("Continue with Apple")
                                    .font(.normaHeadline(16))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black)
                            .cornerRadius(12)
                        }

                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            onSignUpWithGoogle()
                        }) {
                            HStack(spacing: 12) {
                                Image("google-logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)

                                Text("Continue with Google")
                                    .font(.normaHeadline(16))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color("NormaSurface"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }

                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            onSignUpWithEmail()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)

                                Text("Continue with Email")
                                    .font(.normaHeadline(16))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(accentColor)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .scaleEffect(animateButtons ? 1.0 : 0.95)
                    .opacity(animateButtons ? 1.0 : 0.0)

                    Spacer(minLength: 20)

                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 1)
                        Text("or")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateDivider ? 1.0 : 0.0)

                    Spacer(minLength: 16)

                    VStack(spacing: 8) {
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            onContinueChatting()
                        }) {
                            Text("Keep Chatting")
                                .font(.normaHeadline(14))
                                .foregroundColor(accentColor)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(accentColor.opacity(0.12))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)

                        Text("Save later or risk losing your progress")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .offset(y: animateKeepChatting ? 0 : 15)
                    .opacity(animateKeepChatting ? 1.0 : 0.0)

                    Spacer(minLength: 32)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.1)) {
            animateArrow = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            animateTitle = true
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            animateSubtitle = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) {
            animateButtons = true
        }

        withAnimation(.easeOut(duration: 0.3).delay(0.6)) {
            animateDivider = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.65)) {
            animateKeepChatting = true
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
