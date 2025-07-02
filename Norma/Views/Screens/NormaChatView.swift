//
//  NormaChatView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

enum NormaChatContext {
    case bills
    case expenses
    case profile
    
    var title: String {
        switch self {
        case .bills:
            return "Bills"
        case .expenses:
            return "Expenses"
        case .profile:
            return "Chat with Norma - Profile"
        }
    }
    
    var welcomeMessage: String {
        switch self {
        case .bills:
            return "Hi! I'm here to help you add and manage your bills. I can help you create recurring bills like rent, utilities, subscriptions, and more. What bill would you like to add?"
        case .expenses:
            return "Hi! I'm ready to help you track your expenses. Tell me about something you've spent money on recently, and I'll help you record it."
        case .profile:
            return "Hi! I can help you update your financial profile, set goals, and personalize your experience. What would you like to work on?"
        }
    }
    
    var systemPrompt: String {
        switch self {
        case .bills:
            return NormaSystemPrompts.billCreationPrompt()
        case .expenses:
            return NormaSystemPrompts.generalAssistantPrompt() // TODO: Create expense-specific prompt
        case .profile:
            return NormaSystemPrompts.generalAssistantPrompt() // TODO: Create profile-specific prompt
        }
    }
}

struct NormaChatView: View {
    // Chat context
    let context: NormaChatContext
    
    // Environment objects
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    
    // Chat state
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Chat scroll
    
    // Dismiss
    @Environment(\.dismiss) private var dismiss
    
    init(context: NormaChatContext) {
        self.context = context
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with context-specific branding
                headerView
                    .padding(.bottom, 8)
                
                Divider()
                    
                
                // Chat content
                chatContent
                
                Divider()
                
                // Input area
                inputArea
            }
            .navigationTitle(context.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                }
            }
            .onAppear {
                setupInitialMessage()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 12) {
            // Norma avatar and context-specific intro
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    contextColor,
                                    contextColor.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: contextIcon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(UIColor.systemBackground))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Norma AI Assistant")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(contextDescription)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)
        }
        .background(Color(UIColor.systemBackground))
    }
    
    @ViewBuilder
    private var chatContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                    
                    if isLoading {
                        TypingIndicatorView()
                            .id("typing")
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) {
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: isLoading) {
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    @ViewBuilder
    private var inputArea: some View {
        VStack(spacing: 12) {
            // Context-specific quick action buttons
            if context == .bills {
                quickActionButtonsForBills
            }
            
            // Text input
            HStack(spacing: 12) {
                TextField(contextPlaceholder, text: $inputText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(UIColor.systemGray6))
                    )
                    .lineLimit(1...4)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : contextColor)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
    
    @ViewBuilder
    private var quickActionButtonsForBills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "house.fill",
                    title: "Rent/Mortgage",
                    color: .blue,
                    action: { inputText = "Help me add my rent payment" }
                )
                
                QuickActionButton(
                    icon: "bolt.fill",
                    title: "Utilities",
                    color: .orange,
                    action: { inputText = "I want to add a utility bill" }
                )
                
                QuickActionButton(
                    icon: "tv.fill",
                    title: "Subscriptions",
                    color: .purple,
                    action: { inputText = "Help me add a subscription" }
                )
                
                QuickActionButton(
                    icon: "car.fill",
                    title: "Insurance",
                    color: .green,
                    action: { inputText = "I need to add an insurance bill" }
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Computed Properties
    
    private var contextColor: Color {
        switch context {
        case .bills:
            return .blue
        case .expenses:
            return .purple
        case .profile:
            return .green
        }
    }
    
    private var contextIcon: String {
        switch context {
        case .bills:
            return "doc.text"
        case .expenses:
            return "creditcard"
        case .profile:
            return "person"
        }
    }
    
    private var contextDescription: String {
        switch context {
        case .bills:
            return "I'll help you create and manage recurring bills"
        case .expenses:
            return "I'll help you track and categorize expenses"
        case .profile:
            return "I'll help you update your financial profile"
        }
    }
    
    private var contextPlaceholder: String {
        switch context {
        case .bills:
            return "Tell me about a bill you'd like to add..."
        case .expenses:
            return "What did you spend money on?"
        case .profile:
            return "What would you like to update?"
        }
    }
    
    // MARK: - Functions
    
    private func setupInitialMessage() {
        let welcomeMessage = ChatMessage(
            text: context.welcomeMessage,
            isUser: false
        )
        messages = [welcomeMessage]
    }
    
    private func sendMessage() {
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }
        
        // Add user message
        let chatMessage = ChatMessage(text: userMessage, isUser: true)
        messages.append(chatMessage)
        
        // Clear input and show loading
        inputText = ""
        isLoading = true
        
        // Process message with AI
        Task {
            await processUserMessage(userMessage)
        }
    }
    
    private func processUserMessage(_ message: String) async {
        do {
            // Create conversation history for Claude
            let conversationHistory = createConversationHistory()
            
            // Get tools for this context
            let tools = getToolsForContext()
            
            // Get response from Norma AI with context-specific tools and prompt
            let response = try await AnthropicService.shared.sendMessageWithTools(
                messages: conversationHistory,
                systemPrompt: context.systemPrompt,
                tools: tools
            )
            
            await MainActor.run {
                isLoading = false
                
                // Handle the response content
                switch response {
                case .text(let text):
                    let aiMessage = ChatMessage(text: text, isUser: false)
                    messages.append(aiMessage)
                    
                case .toolUse(let id, let name, let input):
                    // Handle tool use based on context
                    handleToolUse(toolId: id, name: name, input: input)
                    
                case .toolResult:
                    // Tool results are not expected as direct responses
                    break
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
                role: chatMessage.isUser ? "user" : "assistant",
                content: .text(chatMessage.text)
            )
        }
    }
    
    private func getToolsForContext() -> [AnthropicTool] {
        switch context {
        case .bills:
            return [getBillCreationTool()]
        case .expenses:
            return [] // TODO: Add expense tools
        case .profile:
            return [] // TODO: Add profile tools
        }
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
                        description: "Monthly amount of the bill"
                    ),
                    "due_date": AnthropicToolProperty(
                        type: "string",
                        description: "Due date in YYYY-MM-DD format"
                    ),
                    "frequency": AnthropicToolProperty(
                        type: "string",
                        description: "How often the bill occurs"
                    )
                ],
                required: ["name", "amount", "due_date", "frequency"]
            )
        )
    }
    
    private func handleToolUse(toolId: String, name: String, input: [String: Any]) {
        Task {
            switch name {
            case "create_bill":
                await handleCreateBill(toolId: toolId, input: input)
            default:
                await MainActor.run {
                    let errorMessage = ChatMessage(text: "Sorry, I couldn't process that request right now.", isUser: false)
                    messages.append(errorMessage)
                }
            }
        }
    }
    
    private func handleCreateBill(toolId: String, input: [String: Any]) async {
        guard let _ = sessionViewModel.currentUser?.userId,
              let name = input["name"] as? String,
              let amount = input["amount"] as? Double,
              let dueDateString = input["due_date"] as? String,
              let frequencyString = input["frequency"] as? String else {
            
            await MainActor.run {
                let errorMessage = ChatMessage(text: "I'm missing some information to create the bill. Could you provide the name, amount, due date, and frequency?", isUser: false)
                messages.append(errorMessage)
            }
            return
        }
        
        // Parse date
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let dueDate = formatter.date(from: dueDateString) else {
            await MainActor.run {
                let errorMessage = ChatMessage(text: "I couldn't understand the due date format. Could you provide it as YYYY-MM-DD?", isUser: false)
                messages.append(errorMessage)
            }
            return
        }
        
        // Parse frequency
        let frequency: BillFrequency
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
        
        do {
            await billViewModel.addBill(
                name: name,
                amount: amount,
                dueDate: dueDate,
                frequency: frequency
            )
            
            await MainActor.run {
                let successMessage = ChatMessage(
                    text: "Perfect! I've created your '\(name)' bill for $\(Int(amount)) due on \(formatDateForDisplay(dueDate)). It's set to recur \(frequencyString). You can view it in your Bills tab! 🎉\n\nWould you like to add another bill?",
                    isUser: false
                )
                messages.append(successMessage)
            }
        } catch {
            await MainActor.run {
                let errorMessage = ChatMessage(text: "Sorry, I couldn't create the bill right now. Please try again later.", isUser: false)
                messages.append(errorMessage)
            }
        }
    }
    
    private func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            if isLoading {
                proxy.scrollTo("typing", anchor: UnitPoint.bottom)
            } else if let lastMessage = messages.last {
                proxy.scrollTo(lastMessage.id, anchor: UnitPoint.bottom)
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    
    return NormaChatView(context: .bills)
        .environmentObject(dataManager)
        .environmentObject(sessionViewModel)
        .environmentObject(BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        .environmentObject(ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
}
