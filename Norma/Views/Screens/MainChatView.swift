//
//  MainChatView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct MainChatView: View {
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var scrollViewProxy: ScrollViewProxy?
    
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                chatContent

                inputArea
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Chat")
                        .font(.system(size: 17, weight: .semibold))
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
            .onAppear {
                setupInitialMessage()
                checkSubscriptionStatus()
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
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    
    @ViewBuilder
    private var chatContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
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
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: messages.count)
            }
            .onTapGesture {
                hideKeyboard()
            }
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
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                TextField("Ask me anything about your finances...", text: $inputText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .onSubmit {
                        if !inputText.isEmpty {
                            sendMessage()
                        }
                    }
                
                Button(action: sendMessage) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        inputText.isEmpty ? Color.gray : Color.blue,
                                        inputText.isEmpty ? Color.gray.opacity(0.8) : Color.blue.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "arrow.up")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                .scaleEffect(inputText.isEmpty ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: inputText.isEmpty)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
    
    @ViewBuilder
    private var quickActionButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                QuickChatButton(
                    icon: "plus.circle.fill",
                    title: "Add Bill",
                    gradient: [.blue, .blue.opacity(0.7)],
                    action: { inputText = "I need to add a new bill" }
                )
                
                QuickChatButton(
                    icon: "creditcard.fill",
                    title: "Log Expense",
                    gradient: [.purple, .purple.opacity(0.7)],
                    action: { inputText = "I just spent money on something" }
                )
                
                QuickChatButton(
                    icon: "chart.pie.fill",
                    title: "View Summary",
                    gradient: [.green, .green.opacity(0.7)],
                    action: { inputText = "Show me my spending summary" }
                )
                
                QuickChatButton(
                    icon: "calendar.badge.exclamationmark",
                    title: "What's Due",
                    gradient: [.orange, .orange.opacity(0.7)],
                    action: { inputText = "What bills are due soon?" }
                )
                
                QuickChatButton(
                    icon: "target",
                    title: "Set Goal",
                    gradient: [.indigo, .indigo.opacity(0.7)],
                    action: { inputText = "Help me set a savings goal" }
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func setupInitialMessage() {
        let greetings = [
            "Hey! I'm Norma, your financial companion. How can I help you today?",
            "Hi there! Ready to take control of your finances? What would you like to do?",
            "Welcome back! I'm here to help with your bills and expenses. What's on your mind?",
            "Hello! Let's make managing money simple. What can I help you with?"
        ]

        let randomGreeting = greetings.randomElement() ?? greetings[0]
        messages = [ChatMessage(role: .assistant, content: randomGreeting)]
    }

    private func checkSubscriptionStatus() {
        if !subscriptionManager.hasActiveSubscription {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let proMessage = ChatMessage(
                    role: .assistant,
                    content: "💎 Upgrade to Pro to unlock unlimited chat conversations and premium features!"
                )
                messages.append(proMessage)
            }
        }
    }

    private func sendMessage() {
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }

        guard subscriptionManager.hasActiveSubscription else {
            showPaywall = true
            return
        }

        let chatMessage = ChatMessage(role: .user, content: userMessage)
        messages.append(chatMessage)

        inputText = ""
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
            
            let response = try await AnthropicService.shared.sendMessageWithTools(
                messages: conversationHistory,
                systemPrompt: NormaSystemPrompts.generalChatPrompt(currency: currency),
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
                
                let toolResult = await executeToolAndGetResult(toolId: id, name: name, input: input)
                
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
                    systemPrompt: NormaSystemPrompts.generalChatPrompt(currency: currency),
                    tools: tools
                )
                
                await MainActor.run {
                    isLoading = false

                    if case .text(let text) = finalResponse {
                        let aiMessage = ChatMessage(role: .assistant, content: text)
                        messages.append(aiMessage)
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
        return [
            getBillCreationTool(),
            getExpenseCreationTool(),
            getBillQueryTool(),
            getExpenseSummaryTool()
        ]
    }
    
    private func getBillCreationTool() -> AnthropicTool {
        AnthropicTool(
            name: "create_bill",
            description: "Create a new recurring bill for the user",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "name": AnthropicToolProperty(
                        type: "string",
                        description: "Name of the bill"
                    ),
                    "amount": AnthropicToolProperty(
                        type: "number",
                        description: "Amount of the bill"
                    ),
                    "due_date": AnthropicToolProperty(
                        type: "string",
                        description: "Due date in YYYY-MM-DD format"
                    ),
                    "frequency": AnthropicToolProperty(
                        type: "string",
                        description: "Frequency: 'Monthly', 'Quarterly', or 'Yearly'"
                    ),
                    "status": AnthropicToolProperty(
                        type: "string",
                        description: "Status: 'Paid', 'Overdue', or 'Scheduled'"
                    )
                ],
                required: ["name", "amount", "due_date", "frequency", "status"]
            )
        )
    }
    
    private func getExpenseCreationTool() -> AnthropicTool {
        AnthropicTool(
            name: "create_expense",
            description: "Create a new expense record",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "name": AnthropicToolProperty(
                        type: "string",
                        description: "Name/description of the expense"
                    ),
                    "amount": AnthropicToolProperty(
                        type: "number",
                        description: "Amount spent"
                    ),
                    "expense_date": AnthropicToolProperty(
                        type: "string",
                        description: "Date in ISO8601 format"
                    ),
                    "payment_method": AnthropicToolProperty(
                        type: "string",
                        description: "Payment method: 'Cash', 'Credit Card', 'Debit Card', etc."
                    ),
                    "merchant": AnthropicToolProperty(
                        type: "string",
                        description: "Merchant name (optional)"
                    ),
                    "tags": AnthropicToolProperty(
                        type: "array",
                        description: "Tags for categorization (optional)"
                    )
                ],
                required: ["name", "amount", "expense_date", "payment_method"]
            )
        )
    }
    
    private func getBillQueryTool() -> AnthropicTool {
        AnthropicTool(
            name: "query_bills",
            description: "Query user's bills and due dates",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "status": AnthropicToolProperty(
                        type: "string",
                        description: "Filter by status: 'all', 'overdue', 'scheduled', 'paid'"
                    )
                ],
                required: ["status"]
            )
        )
    }
    
    private func getExpenseSummaryTool() -> AnthropicTool {
        AnthropicTool(
            name: "expense_summary",
            description: "Get expense summary for a time period",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "period": AnthropicToolProperty(
                        type: "string",
                        description: "Time period: 'week', 'month', 'year'"
                    )
                ],
                required: ["period"]
            )
        )
    }
    
    private func executeToolAndGetResult(toolId: String, name: String, input: [String: Any]) async -> String {
        switch name {
        case "create_bill":
            return await executeBillCreation(input: input)
        case "create_expense":
            return await executeExpenseCreation(input: input)
        case "query_bills":
            return await executeQueryBills(input: input)
        case "expense_summary":
            return await executeExpenseSummary(input: input)
        default:
            return "Error: Unknown tool '\(name)'"
        }
    }
    
    private func executeBillCreation(input: [String: Any]) async -> String {
        guard let name = input["name"] as? String,
              let dueDateString = input["due_date"] as? String,
              let frequencyString = input["frequency"] as? String,
              let statusString = input["status"] as? String else {
            return "Error: Missing required information"
        }
        
        let amount: Double
        if let doubleAmount = input["amount"] as? Double {
            amount = doubleAmount
        } else if let intAmount = input["amount"] as? Int {
            amount = Double(intAmount)
        } else {
            return "Error: Invalid amount format"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let dueDate = dateFormatter.date(from: dueDateString) else {
            return "Error: Invalid date format"
        }
        
        let frequency: BillFrequency = frequencyString.lowercased() == "monthly" ? .monthly :
                                       frequencyString.lowercased() == "quarterly" ? .quarterly : .yearly
        
        let status: BillStatus = statusString == "Paid" ? .paid :
                                 statusString == "Overdue" ? .overdue : .scheduled
        
        await billViewModel.addBill(
            name: name,
            amount: amount,
            dueDate: dueDate,
            frequency: frequency,
            status: status
        )
        
        return "Successfully created bill '\(name)' for $\(String(format: "%.2f", amount))"
    }
    
    private func executeExpenseCreation(input: [String: Any]) async -> String {
        guard let name = input["name"] as? String,
              let expenseDateString = input["expense_date"] as? String,
              let paymentMethodString = input["payment_method"] as? String else {
            return "Error: Missing required information"
        }
        
        let amount: Double
        if let doubleAmount = input["amount"] as? Double {
            amount = doubleAmount
        } else if let intAmount = input["amount"] as? Int {
            amount = Double(intAmount)
        } else {
            return "Error: Invalid amount format"
        }
        
        let paymentMethod: PaymentMethod = {
            switch paymentMethodString.lowercased() {
            case "cash": return .cash
            case "credit card": return .creditCard
            case "debit card": return .debitCard
            default: return .debitCard
            }
        }()
        
        let merchant = input["merchant"] as? String
        let tags = input["tags"] as? [String] ?? []
        
        let success = await expenseViewModel.addExpense(
            name: name,
            amount: amount,
            expenseDate: expenseDateString,
            billId: nil,
            paymentMethod: paymentMethod,
            isRecurring: false,
            recurringFrequency: nil,
            merchant: merchant,
            location: nil,
            tags: tags,
            createdAt: nil,
            updatedAt: nil,
            notes: nil,
            attachmentUrls: []
        )
        
        return success ? "Successfully recorded expense '\(name)' for $\(String(format: "%.2f", amount))" :
                        "Error: Failed to create expense"
    }
    
    private func executeQueryBills(input: [String: Any]) async -> String {
        let statusFilter = input["status"] as? String ?? "all"
        
        let bills = billViewModel.bills
        let filteredBills: [Bill]
        
        switch statusFilter.lowercased() {
        case "overdue":
            filteredBills = bills.filter { $0.status == .overdue }
        case "scheduled":
            filteredBills = bills.filter { $0.status == .scheduled }
        case "paid":
            filteredBills = bills.filter { $0.status == .paid }
        default:
            filteredBills = bills
        }
        
        if filteredBills.isEmpty {
            return "You don't have any \(statusFilter == "all" ? "" : statusFilter) bills."
        }
        
        var result = "Here are your \(statusFilter == "all" ? "" : statusFilter) bills:\n"
        for bill in filteredBills.prefix(5) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            result += "• \(bill.name): $\(String(format: "%.2f", bill.amount)) due \(formatter.string(from: bill.dueDate))\n"
        }
        
        if filteredBills.count > 5 {
            result += "...and \(filteredBills.count - 5) more"
        }
        
        return result
    }
    
    private func executeExpenseSummary(input: [String: Any]) async -> String {
        let period = input["period"] as? String ?? "month"
        
        let expenses = expenseViewModel.expenses
        let now = Date()
        let calendar = Calendar.current
        let dateFormatter = ISO8601DateFormatter()
        
        let filteredExpenses: [Expense]
        switch period.lowercased() {
        case "week":
            let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            filteredExpenses = expenses.filter { expense in
                guard let createdAtString = expense.createdAt,
                      let createdAtDate = dateFormatter.date(from: createdAtString) else {
                    return false
                }
                return createdAtDate >= weekAgo
            }
        case "year":
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            filteredExpenses = expenses.filter { expense in
                guard let createdAtString = expense.createdAt,
                      let createdAtDate = dateFormatter.date(from: createdAtString) else {
                    return false
                }
                return createdAtDate >= yearAgo
            }
        default:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            filteredExpenses = expenses.filter { expense in
                guard let createdAtString = expense.createdAt,
                      let createdAtDate = dateFormatter.date(from: createdAtString) else {
                    return false
                }
                return createdAtDate >= monthAgo
            }
        }
        
        let total = filteredExpenses.reduce(0) { $0 + $1.amount }
        let count = filteredExpenses.count
        
        return "In the past \(period), you've recorded \(count) expense\(count == 1 ? "" : "s") totaling $\(String(format: "%.2f", total))"
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

struct QuickChatButton: View {
    let icon: String
    let title: String
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradient),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
    }
}

extension NormaSystemPrompts {
    static func generalChatPrompt(currency: String) -> String {
        """
        You are Norma, a friendly and helpful financial AI assistant integrated into a personal finance app.
        You help users manage their bills, track expenses, and achieve their financial goals.
        
        The user's currency is \(currency).
        
        Guidelines:
        - Be conversational, friendly, and encouraging
        - Keep responses concise and helpful
        - Use emojis occasionally to make conversations more engaging
        - When discussing money, always use the user's currency (\(currency))
        - Provide actionable advice and insights
        - If you need more information to help, ask clarifying questions
        - Be supportive and non-judgmental about spending habits
        
        You have access to tools to:
        - Create bills and expenses
        - Query existing bills and their status
        - Provide spending summaries
        
        Always aim to make financial management feel simple and achievable.
        """
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    
    return MainChatView()
        .environmentObject(dataManager)
        .environmentObject(sessionViewModel)
        .environmentObject(BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        .environmentObject(ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        .preferredColorScheme(.dark)
}
