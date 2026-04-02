//
//  MiniChatView.swift
//  Norma
//
//  Created by Claude on 3/3/26.
//

import SwiftUI
import AVFoundation

enum MiniChatContext {
    case bill
    case expense
}

struct MiniChatView: View {
    let selectedDate: Date
    let context: MiniChatContext
    let accentColor: Color?

    init(selectedDate: Date, context: MiniChatContext = .bill, accentColor: Color? = nil) {
        self.selectedDate = selectedDate
        self.context = context
        self.accentColor = accentColor
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var billViewModel: BillViewModel
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @EnvironmentObject var dataManager: DataManager

    @State private var currentAIMessage: ChatMessage? = nil
    @State private var isThinking = false
    @State private var shouldAnimateMessage = false
    @State private var inputText: String = ""
    @State private var conversationHistory: [AnthropicMessage] = []
    @State private var isRecording = false
    @State private var audioEngine = AVAudioEngine()
    @State private var taskCreated = false
    @State private var selectedDetent: PresentationDetent = .medium
    @FocusState private var isInputFocused: Bool

    @ObservedObject private var deepgramService = DeepgramService.shared

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: selectedDate)
    }

    private var isExpanded: Bool {
        selectedDetent == .large
    }

    private var isSendActive: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private var systemPrompt: String {
        switch context {
        case .bill:
            return NormaSystemPrompts.billCreationMiniChatPrompt(selectedDate: selectedDate, currency: currency)
        case .expense:
            return NormaSystemPrompts.expenseCreationMiniChatPrompt(selectedDate: selectedDate, currency: currency)
        }
    }

    private var tools: [AnthropicTool] {
        switch context {
        case .bill:
            return [ChatToolsProvider.getBillCreationTool()]
        case .expense:
            return [ChatToolsProvider.getExpenseCreationTool()]
        }
    }

    private var toolExecutor: ChatToolExecutor {
        ChatToolExecutor(
            billViewModel: billViewModel,
            expenseViewModel: expenseViewModel,
            challengeViewModel: challengeViewModel,
            dataManager: dataManager
        )
    }

    /// Parse message content into colored word tuples for wave animation.
    /// Text wrapped in ** ** gets the teal accent color.
    private var coloredWords: [(word: String, color: Color)] {
        guard let content = currentAIMessage?.content else { return [] }
        var result: [(word: String, color: Color)] = []
        let parts = content.components(separatedBy: "**")
        for (index, part) in parts.enumerated() {
            let inBold = index % 2 == 1
            let words = part.split(separator: " ", omittingEmptySubsequences: false)
            for word in words where !word.isEmpty {
                result.append((
                    word: String(word),
                    color: inBold ? Color("NormaPastelTeal") : .primary
                ))
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Scrollable AI message area
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if isThinking {
                            MiniChatThinkingView()
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                        } else if currentAIMessage != nil && !coloredWords.isEmpty {
                            ColoredWaveTextView(
                                words: coloredWords,
                                font: .normaHeadline(48),
                                isAnimating: shouldAnimateMessage,
                                alignment: .leading
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .contentShape(Rectangle())
                .onTapGesture {
                    isInputFocused = true
                }
                .background(
                    DotPatternView(
                        dotSize: isExpanded ? 3 : 2,
                        spacing: isExpanded ? 18 : 12,
                        dotOpacity: isExpanded ? 0.25 : 0.15
                    )
                    .animation(.easeInOut(duration: 0.4), value: isExpanded)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
                )

                Spacer(minLength: 0)

                // Input bar
                HStack(alignment: .center, spacing: 12) {
                    ZStack(alignment: .leading) {
                        if inputText.isEmpty && !isRecording {
                            Text("Tell Norma the name and cost")
                                .font(.normaInput())
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        if isRecording && inputText.isEmpty {
                            Text("Listening...")
                                .font(.normaInput())
                                .foregroundColor(.secondary.opacity(0.5))
                                .italic()
                        }
                        TextField("", text: $inputText, axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.normaInput())
                            .lineLimit(1...3)
                            .focused($isInputFocused)
                            .submitLabel(.send)
                            .onSubmit {
                                if isSendActive {
                                    sendMessage()
                                }
                            }
                    }

                    // Voice / Stop / Send button
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        if isRecording {
                            stopVoiceInput()
                        } else if isSendActive {
                            sendMessage()
                        } else {
                            startVoiceInput()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(buttonFillColor)
                                .shadow(color: isRecording ? Color("NormaPastelPurple").opacity(0.5) : .clear, radius: 8)
                                .frame(width: 44, height: 44)

                            // Waveform icon — idle
                            Image(systemName: "waveform")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                                .opacity(!isSendActive && !isRecording ? 1 : 0)
                                .scaleEffect(!isSendActive && !isRecording ? 1 : 0.5)

                            // Stop icon — recording
                            Image(systemName: "stop.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(isRecording ? 1 : 0)
                                .scaleEffect(isRecording ? 1 : 0.5)

                            // Send arrow — has text, not recording
                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .opacity(isSendActive && !isRecording ? 1 : 0)
                                .scaleEffect(isSendActive && !isRecording ? 1 : 0.5)
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: isSendActive)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: isRecording)
                    }
                    .buttonStyle(SendButtonStyle())
                    .disabled(isThinking)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.clear)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 28))
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(isRecording ? Color("NormaPastelPurple").opacity(0.5) : Color.gray.opacity(0.22), lineWidth: isRecording ? 1.5 : 1)
                )
                .animation(.easeInOut(duration: 0.25), value: isRecording)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .background {
                CoinGradientBackground(
                    coinColor: accentColor ?? Color("NormaPastelPurple"),
                    colorScheme: colorScheme
                )
                .ignoresSafeArea()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // TODO: show info
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            let greetingText: String
            switch context {
            case .bill:
                greetingText = "What bill do you want to add on **\(formattedDate)**?"
            case .expense:
                greetingText = "What expense do you want to add on **\(formattedDate)**?"
            }
            let greeting = ChatMessage(
                role: .assistant,
                content: greetingText
            )
            currentAIMessage = greeting

            // Seed conversation history with the initial greeting
            conversationHistory.append(AnthropicMessage(
                role: "assistant",
                content: .text(greeting.content)
            ))

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                shouldAnimateMessage = true
            }
        }
        .onDisappear {
            if isRecording { stopVoiceInput() }
        }
        .presentationDetents([.medium, .large], selection: $selectedDetent)
        .presentationDragIndicator(.visible)
    }

    private var buttonFillColor: Color {
        if isRecording {
            return Color("NormaPastelPurple")
        } else if isSendActive {
            return .black
        } else {
            return Color.gray.opacity(0.15)
        }
    }

    // MARK: - Voice Input

    private func startVoiceInput() {
        AVAudioApplication.requestRecordPermission { granted in
            guard granted else { return }
            DispatchQueue.main.async {
                self.isRecording = true
                self.inputText = ""

                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

                    try self.deepgramService.startLiveTranscription(
                        audioEngine: self.audioEngine,
                        onPartialResult: { partialText in
                            self.inputText = partialText
                        },
                        onFinalResult: { finalText in
                            self.inputText = finalText
                        },
                        onError: { error in
                            print("MiniChat transcription error: \(error)")
                            self.stopVoiceInput()
                        }
                    )
                } catch {
                    print("MiniChat: Failed to start voice input: \(error)")
                    self.isRecording = false
                }
            }
        }
    }

    private func stopVoiceInput() {
        deepgramService.stopTranscription()
        isRecording = false

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("MiniChat: Failed to deactivate audio session: \(error)")
        }
    }

    // MARK: - Send & API

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        inputText = ""

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Add user message to conversation history
        conversationHistory.append(AnthropicMessage(
            role: "user",
            content: .text(trimmed)
        ))

        // Show thinking
        shouldAnimateMessage = false
        withAnimation(.easeOut(duration: 0.2)) {
            currentAIMessage = nil
            isThinking = true
        }

        Task {
            await processAPICall()
        }
    }

    private func processAPICall(depth: Int = 0) async {
        guard depth < 3 else {
            showAIMessage("Something went wrong. Please try again.")
            return
        }

        do {
            let response = try await AnthropicService.shared.sendMessageWithTools(
                messages: conversationHistory,
                systemPrompt: systemPrompt,
                tools: tools
            )

            switch response {
            case .text(let text):
                // Append assistant response to history
                conversationHistory.append(AnthropicMessage(
                    role: "assistant",
                    content: .text(text)
                ))
                showAIMessage(text)

            case .toolUse(let id, let name, let input):
                // Append the tool_use to history as assistant message
                conversationHistory.append(AnthropicMessage(
                    role: "assistant",
                    content: .toolUse(id: id, name: name, input: input)
                ))

                // Execute the tool
                let (toolResult, _) = await toolExecutor.executeToolAndGetResult(
                    toolId: id, name: name, input: input
                )

                let expectedTool = context == .bill ? "create_bill" : "create_expense"
                if name == expectedTool && toolResult.hasPrefix("Successfully") {
                    taskCreated = true
                }

                // Append tool result to history
                conversationHistory.append(AnthropicMessage(
                    role: "user",
                    content: .toolResult(toolUseId: id, content: toolResult)
                ))

                // Call API again to get the assistant's follow-up text
                await processAPICall(depth: depth + 1)

            case .toolResult:
                showAIMessage("Something went wrong. Please try again.")
            }
        } catch {
            print("MiniChat API error: \(error)")
            let itemType = context == .bill ? "bill" : "expense"
            showAIMessage("Couldn't connect right now. Try typing the \(itemType) name and amount.")
        }
    }

    private func showAIMessage(_ text: String) {
        shouldAnimateMessage = false
        withAnimation(.easeOut(duration: 0.2)) {
            isThinking = false
            currentAIMessage = ChatMessage(role: .assistant, content: text)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            shouldAnimateMessage = true
        }
    }
}

// MARK: - Thinking View with Spinning Coin

private struct MiniChatThinkingView: View {
    var body: some View {
        HStack(spacing: 10) {
            HeroCoin3DView(fileName: "norma-coin-royalty")
                .frame(width: 32, height: 32)

            ThinkingIndicator()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)

    MiniChatView(selectedDate: Date())
        .environmentObject(dataManager)
        .environmentObject(BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        .environmentObject(sessionViewModel)
        .environmentObject(ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        .environmentObject(ChallengeViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
}
