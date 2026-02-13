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
    
    func systemPrompt(currency: String, monthlyIncome: Double, freedomFund: Double, bills: [Bill], challenge: Challenge?) -> String {
        // All contexts now use the same comprehensive prompt
        return NormaSystemPrompts.generalChatPrompt(
            currency: currency,
            monthlyIncome: monthlyIncome,
            freedomFund: freedomFund,
            bills: bills,
            challenge: challenge
        )
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
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
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
        // Check subscription status first - allow access during trial or with active subscription
        if !subscriptionManager.hasActiveSubscription {
            PaywallView()
        } else {
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
                        ThinkingIndicator()
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
            } else if context == .expenses {
                quickActionButtonsForExpenses
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
    
    @ViewBuilder
    private var quickActionButtonsForExpenses: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "cup.and.saucer.fill",
                    title: "Food & Dining",
                    color: .orange,
                    action: { inputText = "I spent money on food" }
                )
                
                QuickActionButton(
                    icon: "fuelpump.fill",
                    title: "Gas",
                    color: .blue,
                    action: { inputText = "I bought gas" }
                )
                
                QuickActionButton(
                    icon: "cart.fill",
                    title: "Groceries",
                    color: .green,
                    action: { inputText = "I went grocery shopping" }
                )
                
                QuickActionButton(
                    icon: "creditcard.fill",
                    title: "Shopping",
                    color: .purple,
                    action: { inputText = "I bought something" }
                )
                
                QuickActionButton(
                    icon: "car.fill",
                    title: "Transportation",
                    color: .indigo,
                    action: { inputText = "I paid for transportation" }
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
            role: .assistant,
            content: context.welcomeMessage
        )
        messages = [welcomeMessage]
    }

    private func sendMessage() {
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }

        // Add user message
        let chatMessage = ChatMessage(role: .user, content: userMessage)
        messages.append(chatMessage)

        // Clear input
        inputText = ""

        // Process message with AI
        Task {
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
            // Create conversation history for Claude
            let conversationHistory = createConversationHistory()
            
            // Get tools for this context
            let tools = getToolsForContext()
            
            // Get user's currency and financial data (default to USD and 0 if not set)
            let currency = sessionViewModel.currentUser?.settings.currency ?? "USD"
            let monthlyIncome = sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
            let freedomFund = sessionViewModel.currentUser?.settings.freedomFund ?? 0

            // Get response from Norma AI with comprehensive prompt including all user data
            let response = try await AnthropicService.shared.sendMessageWithTools(
                messages: conversationHistory,
                systemPrompt: context.systemPrompt(
                    currency: currency,
                    monthlyIncome: monthlyIncome,
                    freedomFund: freedomFund,
                    bills: billViewModel.bills,
                    challenge: nil // No challenge support in this view yet
                ),
                tools: tools
            )
            
            // Handle the response content
            switch response {
            case .text(let text):
                await MainActor.run {
                    isLoading = false
                    let aiMessage = ChatMessage(role: .assistant, content: text)
                    messages.append(aiMessage)
                }
                
            case .toolUse(let id, let name, let input):
                // Claude wants to use a tool - execute it and continue conversation
                print("🔧 Tool use requested: \(name)")
                print("📝 Tool input: \(input)")
                
                // Execute the tool and get result
                let toolResult = await executeToolAndGetResult(toolId: id, name: name, input: input)
                print("✅ Tool result: \(toolResult)")
                
                // Continue conversation with tool result
                var updatedHistory = conversationHistory
                updatedHistory.append(AnthropicMessage(
                    role: "assistant",
                    content: .toolUse(id: id, name: name, input: input)
                ))
                updatedHistory.append(AnthropicMessage(
                    role: "user",
                    content: .toolResult(toolUseId: id, content: toolResult)
                ))
                
                // Get Claude's final response after tool execution
                let finalResponse = try await AnthropicService.shared.sendMessageWithTools(
                    messages: updatedHistory,
                    systemPrompt: context.systemPrompt(
                        currency: currency,
                        monthlyIncome: monthlyIncome,
                        freedomFund: freedomFund,
                        bills: billViewModel.bills,
                        challenge: nil
                    ),
                    tools: tools
                )
                
                await MainActor.run {
                    isLoading = false

                    // Handle final response
                    if case .text(let text) = finalResponse {
                        let aiMessage = ChatMessage(role: .assistant, content: text)
                        messages.append(aiMessage)
                    }
                }
                
            case .toolResult:
                // Tool results are not expected as direct responses
                await MainActor.run {
                    isLoading = false
                }
                break
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
    
    private func getToolsForContext() -> [AnthropicTool] {
        switch context {
        case .bills:
            return [getBillCreationTool()]
        case .expenses:
            return [getExpenseCreationTool()]
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
    
    private func getExpenseCreationTool() -> AnthropicTool {
        return AnthropicTool(
            name: "create_expense",
            description: "Create a new expense record for the user",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "name": AnthropicToolProperty(
                        type: "string",
                        description: "Name/description of the expense (e.g. 'Lunch at Subway', 'Gas for car')"
                    ),
                    "amount": AnthropicToolProperty(
                        type: "number",
                        description: "Amount spent on this expense as a decimal number (e.g., 25.50, 100.00)"
                    ),
                    "expense_date": AnthropicToolProperty(
                        type: "string",
                        description: "Date of the expense in ISO8601 format with timezone (e.g. 2025-07-07T12:00:00-07:00). Default to today if not specified"
                    ),
                    "payment_method": AnthropicToolProperty(
                        type: "string",
                        description: "Payment method used: 'Cash', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Digital Wallet', 'Check', or 'Other'"
                    ),
                    "merchant": AnthropicToolProperty(
                        type: "string",
                        description: "Name of the merchant/store (optional)"
                    ),
                    "location": AnthropicToolProperty(
                        type: "string",
                        description: "Location where the expense occurred (optional)"
                    ),
                    "tags": AnthropicToolProperty(
                        type: "array",
                        description: "Array of tags to categorize the expense (optional)"
                    ),
                    "notes": AnthropicToolProperty(
                        type: "string",
                        description: "Additional notes about the expense (optional)"
                    )
                ],
                required: ["name", "amount", "expense_date", "payment_method"]
            )
        )
    }
    
    private func executeToolAndGetResult(toolId: String, name: String, input: [String: Any]) async -> String {
        switch name {
        case "create_bill":
            return await executeBillCreation(input: input)
        case "create_expense":
            return await executeExpenseCreation(input: input)
        default:
            return "Error: Unknown tool '\(name)'"
        }
    }
    
    private func executeBillCreation(input: [String: Any]) async -> String {
        print("🔍 [DEBUG] executeBillCreation called with input: \(input)")
        
        guard let userId = sessionViewModel.currentUser?.userId else {
            print("❌ [DEBUG] No user ID found in sessionViewModel.currentUser")
            return "Error: No user found"
        }
        
        print("✅ [DEBUG] User ID found: \(userId)")
        
        guard let name = input["name"] as? String,
              let dueDateString = input["due_date"] as? String,
              let frequencyString = input["frequency"] as? String,
              let statusString = input["status"] as? String else {
            print("❌ [DEBUG] Missing required information in input")
            return "Error: Missing required information (name, amount, due_date, frequency, or status)"
        }
        
        // Handle amount as either Int or Double
        let amount: Double
        if let doubleAmount = input["amount"] as? Double {
            amount = doubleAmount
        } else if let intAmount = input["amount"] as? Int {
            amount = Double(intAmount)
        } else {
            print("❌ [DEBUG] Invalid amount type")
            return "Error: Invalid amount format"
        }
        
        print("✅ [DEBUG] All required parameters found - name: \(name), amount: \(amount), due_date: \(dueDateString), frequency: \(frequencyString), status: \(statusString)")
        
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
        
        print("🔄 [DEBUG] About to call billViewModel.addBill with status: \(status)...")
        
        // Create the bill through billViewModel with the specified status
        let createdBill = await billViewModel.addBill(
            name: name,
            amount: amount,
            dueDate: dueDate,
            frequency: frequency,
            status: status
        )
        
        print("✅ [DEBUG] billViewModel.addBill completed successfully")
        
        // If status is "Paid", create an expense record
        if status == .paid, let bill = createdBill, let billId = bill.id {
            print("🔄 [DEBUG] Bill status is Paid, creating expense record with billId: \(billId)...")
            
            // Convert bill frequency to expense frequency
            let expenseFrequency: ExpenseFrequency = {
                switch frequency {
                case .monthly: return .monthly
                case .quarterly: return .quarterly  
                case .yearly: return .annually
                }
            }()
            
            // Format today's date as ISO8601 string for expense_date in local timezone
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.timeZone = TimeZone.current
            let todayString = dateFormatter.string(from: Date())
            
            await expenseViewModel.addExpense(
                name: name,
                amount: amount,
                expenseDate: todayString,
                billId: billId,
                paymentMethod: .debitCard,
                isRecurring: true, // Bill payments are recurring
                recurringFrequency: expenseFrequency,
                merchant: name,
                location: nil,
                tags: ["Bill Payment"],
                createdAt: nil, // Let Supabase fill this in
                updatedAt: nil,
                notes: "Bill payment",
                attachmentUrls: []
            )
            
            print("✅ [DEBUG] Expense created for paid bill")
        } else if status == .paid {
            print("⚠️ [DEBUG] Could not create expense: Bill creation failed or bill ID is missing")
        }
        
        return "Successfully created bill '\(name)' for $\(String(format: "%.2f", amount)) due on \(formatDateForDisplay(dueDate))"
    }
    
    private func executeExpenseCreation(input: [String: Any]) async -> String {
        print("🔍 [DEBUG] executeExpenseCreation called with input: \(input)")
        
        guard let userId = sessionViewModel.currentUser?.userId else {
            print("❌ [DEBUG] No user ID found in sessionViewModel.currentUser")
            return "Error: No user found"
        }
        
        print("✅ [DEBUG] User ID found: \(userId)")
        
        guard let name = input["name"] as? String,
              let expenseDateString = input["expense_date"] as? String,
              let paymentMethodString = input["payment_method"] as? String else {
            print("❌ [DEBUG] Missing required information in input")
            return "Error: Missing required information (name, amount, expense_date, or payment_method)"
        }
        
        // Handle amount as either Int or Double
        let amount: Double
        if let doubleAmount = input["amount"] as? Double {
            amount = doubleAmount
        } else if let intAmount = input["amount"] as? Int {
            amount = Double(intAmount)
        } else {
            print("❌ [DEBUG] Invalid amount type")
            return "Error: Invalid amount format"
        }
        
        print("✅ [DEBUG] All required parameters found - name: \(name), amount: \(amount), expense_date: \(expenseDateString), payment_method: \(paymentMethodString)")
        
        // Parse payment method
        let paymentMethod: PaymentMethod
        switch paymentMethodString {
        case "Cash":
            paymentMethod = .cash
        case "Credit Card":
            paymentMethod = .creditCard
        case "Debit Card":
            paymentMethod = .debitCard
        case "Bank Transfer":
            paymentMethod = .bankTransfer
        case "Digital Wallet":
            paymentMethod = .digitalWallet
        case "Check":
            paymentMethod = .check
        case "Other":
            paymentMethod = .other
        default:
            // Fallback for case-insensitive matching
            switch paymentMethodString.lowercased() {
            case "cash":
                paymentMethod = .cash
            case "credit card":
                paymentMethod = .creditCard
            case "debit card":
                paymentMethod = .debitCard
            case "bank transfer":
                paymentMethod = .bankTransfer
            case "digital wallet":
                paymentMethod = .digitalWallet
            case "check":
                paymentMethod = .check
            default:
                paymentMethod = .debitCard // default fallback
            }
        }
        
        // Parse optional parameters
        let merchant = input["merchant"] as? String
        let location = input["location"] as? String
        let notes = input["notes"] as? String
        let tags = input["tags"] as? [String] ?? []
        
        print("🔄 [DEBUG] About to call expenseViewModel.addExpense...")
        
        // Create the expense through expenseViewModel
        let success = await expenseViewModel.addExpense(
            name: name,
            amount: amount,
            expenseDate: expenseDateString,
            billId: nil,
            paymentMethod: paymentMethod,
            isRecurring: false,
            recurringFrequency: nil,
            merchant: merchant,
            location: location,
            tags: tags,
            createdAt: nil,
            updatedAt: nil,
            notes: notes,
            attachmentUrls: []
        )
        
        print("✅ [DEBUG] expenseViewModel.addExpense completed successfully")
        
        if success {
            return "Successfully recorded expense '\(name)' for $\(String(format: "%.2f", amount)) paid with \(paymentMethod.rawValue)"
        } else {
            return "Error: Failed to create expense"
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
