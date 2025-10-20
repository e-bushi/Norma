//
//  MainChatView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct MainChatView: View {
    @Binding var isMenuOpen: Bool

    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var budgetViewModel: BudgetViewModel
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var scrollViewProxy: ScrollViewProxy?

    @State private var showPaywall = false

    private var toolExecutor: ChatToolExecutor {
        ChatToolExecutor(
            billViewModel: billViewModel,
            expenseViewModel: expenseViewModel,
            budgetViewModel: budgetViewModel
        )
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

                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isMenuOpen.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Norma")
                        .normaHeadline()
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showPaywall = true
                    } label: {
                        Image(systemName: subscriptionManager.hasActiveSubscription ? "checkmark.shield.fill" : "lock.shield")
                            .font(.system(size: 18))
                            .foregroundColor(subscriptionManager.hasActiveSubscription ? .green : .orange)
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    
    @ViewBuilder
    private var chatContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if messages.isEmpty && !isLoading {
                    ChatEmptyStateView()
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }

                        if isLoading {
                            TypingIndicatorView()
                                .id("typing")
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding()
                    .padding(.bottom, 180)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: messages.count)
                }
            }
            .background(Color("NormaBackground"))
            .onChange(of: messages.count) {
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: isLoading) {
                scrollToBottom(proxy: proxy)
            }
            .onAppear {
                self.scrollViewProxy = proxy
            }
        }
    }
    
    @ViewBuilder
    private var inputArea: some View {
        ChatInputView(
            text: $inputText,
            isLoading: isLoading,
            onSend: sendMessage,
            billsTotal: billViewModel.bills.reduce(0) { $0 + $1.amount },
            budgetCount: budgetViewModel.budgets.count,
            monthlySpend: expenseViewModel.totalExpenses
        )
    }
    

    private func sendMessage() {
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }

        let chatMessage = ChatMessage(role: .user, content: userMessage)
        messages.append(chatMessage)

        inputText = ""
        hideKeyboard()
        isLoading = true

        Task {
            await processUserMessage(userMessage)
        }
    }
    
    private func processUserMessage(_ message: String) async {
        do {
            let conversationHistory = createConversationHistory()
            let tools = getAllTools()
            let currency = sessionViewModel.currentUser?.settings.currency ?? "USD"
            
            let systemPrompt = NormaSystemPrompts.generalChatPrompt(
                currency: currency,
                bills: billViewModel.bills,
                expenses: expenseViewModel.expenses,
                budgets: budgetViewModel.budgets
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
                    messages.append(aiMessage)
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
                    bills: billViewModel.bills,
                    expenses: expenseViewModel.expenses,
                    budgets: budgetViewModel.budgets
                )

                print("🤖 Requesting final AI response...")

                let finalResponse = try await AnthropicService.shared.sendMessageWithTools(
                    messages: updatedHistory,
                    systemPrompt: finalSystemPrompt,
                    tools: tools
                )

                print("✅ Final response received: \(finalResponse)")

                await MainActor.run {
                    isLoading = false

                    if case .text(let text) = finalResponse {
                        print("💬 Creating AI message with text: \(text)")
                        print("🎨 Attaching UI component: \(String(describing: uiComponent))")
                        let aiMessage = ChatMessage(role: .assistant, content: text, uiComponent: uiComponent)
                        messages.append(aiMessage)
                        print("✅ Message appended to chat")
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

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            if isLoading {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let lastMessage = messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)

    MainChatView(isMenuOpen: .constant(false))
        .environmentObject(dataManager)
        .environmentObject(sessionViewModel)
        .environmentObject(BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        .environmentObject(ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        .environmentObject(BudgetViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        .preferredColorScheme(.dark)
}
