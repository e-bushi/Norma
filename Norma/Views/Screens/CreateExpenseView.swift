//
//  CreateExpenseView.swift
//  Norma
//
//  Created by Claude on 9/18/25.
//

import SwiftUI

struct CreateExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var dataManager: DataManager
    
    // Form fields
    @State private var expenseName = ""
    @State private var expenseAmount = ""
    @State private var expenseDate = Date()
    @State private var selectedCategory: Category?
    @State private var paymentMethod: PaymentMethod = .debitCard
    @State private var merchant = ""
    @State private var location = ""
    @State private var notes = ""
    @State private var isRecurring = false
    @State private var recurringFrequency: ExpenseFrequency = .monthly
    @State private var selectedTags: Set<String> = []
    
    // UI state
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isAmountFieldFocused: Bool
    @State private var showTagInput = false
    @State private var newTag = ""
    
    // Computed properties
    private var formattedAmount: Double? {
        Double(expenseAmount.replacingOccurrences(of: ",", with: ""))
    }
    
    private var isFormValid: Bool {
        !expenseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        formattedAmount != nil &&
        formattedAmount! > 0
    }
    
    private var expenseCategories: [Category] {
        dataManager.getCategories(ofType: .expense).filter { $0.isActive }
    }
    
    private var paymentMethodIcon: String {
        switch paymentMethod {
        case .cash:
            return "dollarsign.circle"
        case .creditCard:
            return "creditcard"
        case .debitCard:
            return "creditcard.fill"
        case .bankTransfer:
            return "building.columns"
        case .digitalWallet:
            return "iphone"
        case .check:
            return "doc.text"
        case .other:
            return "questionmark.circle"
        }
    }
    
    private var commonTags: [String] {
        ["Groceries", "Dining Out", "Entertainment", "Transportation", "Shopping", "Healthcare", "Utilities", "Personal"]
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Main expense card
                    mainExpenseCard
                    
                    // Expense details section
                    expenseDetailsSection
                    
                    // Payment details section
                    paymentDetailsSection
                    
                    // Tags section
                    tagsSection
                    
                    // Recurring settings section
                    if isRecurring {
                        recurringSettingsSection
                    }
                    
                    // Notes section
                    if !notes.isEmpty {
                        notesSection
                    }
                    
                    // Save button
                    saveButtonView
                }
                .padding()
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - View Sections
    
    @ViewBuilder
    private var mainExpenseCard: some View {
        VStack(spacing: 16) {
            // Header with name input
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Expense Name", text: $expenseName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        if let category = selectedCategory {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                                .foregroundColor(category.color)
                            
                            Text(category.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        if !merchant.isEmpty {
                            Text("•")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text(merchant)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("$")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        TextField("0.00", text: $expenseAmount)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .focused($isAmountFieldFocused)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        isAmountFieldFocused = false
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                }
                            }
                    }
                    
                    Text(formatDate(expenseDate))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(UIColor.systemBackground),
                                Color.gray.opacity(0.02)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.2),
                                        Color.gray.opacity(0.05)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
    
    @ViewBuilder
    private var expenseDetailsSection: some View {
        VStack(spacing: 16) {
            Text("EXPENSE DETAILS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Date selection
                DetailRow(label: "Date", value: "") {
                    DatePicker("", selection: $expenseDate, displayedComponents: [.date])
                        .labelsHidden()
                }
                
                // Category selection
                DetailRow(label: "Category", value: "") {
                    Menu {
                        Button("None") {
                            selectedCategory = nil
                        }
                        
                        ForEach(expenseCategories) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Label(category.name, systemImage: category.icon)
                            }
                        }
                    } label: {
                        HStack {
                            if let category = selectedCategory {
                                HStack(spacing: 6) {
                                    Image(systemName: category.icon)
                                        .foregroundColor(category.color)
                                        .font(.system(size: 14))
                                    Text(category.name)
                                        .foregroundColor(.primary)
                                }
                            } else {
                                Text("Select Category")
                                    .foregroundColor(.secondary)
                            }
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .font(.system(size: 14))
                    }
                }
                
                // Merchant input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Merchant")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Store or business name (optional)", text: $merchant)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                }
                
                // Location input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Where did you spend? (optional)", text: $location)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                }
                
                // Notes input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .lineLimit(3...6)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private var paymentDetailsSection: some View {
        VStack(spacing: 16) {
            Text("PAYMENT METHOD")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Payment method selection
                DetailRow(label: "Payment Type", value: "") {
                    Menu {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Button {
                                paymentMethod = method
                            } label: {
                                Label(method.rawValue, systemImage: getPaymentMethodIcon(method))
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: paymentMethodIcon)
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            
                            Text(paymentMethod.rawValue)
                                .foregroundColor(.primary)
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .font(.system(size: 14))
                    }
                }
                
                // Recurring toggle
                Toggle(isOn: $isRecurring) {
                    HStack(spacing: 12) {
                        Image(systemName: "repeat")
                            .font(.system(size: 16))
                            .foregroundColor(.purple)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recurring Expense")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("This expense repeats regularly")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .purple))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private var tagsSection: some View {
        VStack(spacing: 16) {
            Text("TAGS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Common tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(commonTags, id: \.self) { tag in
                            TagChip(
                                text: tag,
                                isSelected: selectedTags.contains(tag),
                                action: {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Selected custom tags
                if !selectedTags.subtracting(commonTags).isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(selectedTags.subtracting(commonTags)), id: \.self) { tag in
                                TagChip(
                                    text: tag,
                                    isSelected: true,
                                    showRemove: true,
                                    action: {
                                        selectedTags.remove(tag)
                                    }
                                )
                            }
                        }
                    }
                }
                
                // Add custom tag
                if showTagInput {
                    HStack {
                        TextField("Enter tag", text: $newTag)
                            .font(.system(size: 14))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Add") {
                            if !newTag.isEmpty {
                                selectedTags.insert(newTag)
                                newTag = ""
                                showTagInput = false
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        
                        Button("Cancel") {
                            newTag = ""
                            showTagInput = false
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    }
                } else {
                    Button(action: { showTagInput = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                            Text("Add custom tag")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private var recurringSettingsSection: some View {
        VStack(spacing: 16) {
            Text("RECURRING SETTINGS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                DetailRow(label: "Frequency", value: "") {
                    Menu {
                        ForEach(ExpenseFrequency.allCases, id: \.self) { freq in
                            Button {
                                recurringFrequency = freq
                            } label: {
                                Text(freq.rawValue)
                            }
                        }
                    } label: {
                        HStack {
                            Text(recurringFrequency.rawValue)
                                .foregroundColor(.primary)
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private var notesSection: some View {
        VStack(spacing: 16) {
            Text("NOTES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(notes)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(nil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private var saveButtonView: some View {
        Button(action: {
            saveExpense()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                }
                
                Text("Create Expense")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFormValid ? Color.purple : Color.gray)
            )
        }
        .disabled(!isFormValid || isLoading)
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func getPaymentMethodIcon(_ method: PaymentMethod) -> String {
        switch method {
        case .cash:
            return "dollarsign.circle"
        case .creditCard:
            return "creditcard"
        case .debitCard:
            return "creditcard.fill"
        case .bankTransfer:
            return "building.columns"
        case .digitalWallet:
            return "iphone"
        case .check:
            return "doc.text"
        case .other:
            return "questionmark.circle"
        }
    }
    
    // MARK: - Actions
    
    private func saveExpense() {
        guard let amount = formattedAmount else {
            showError(message: "Invalid expense amount")
            return
        }
        
        let trimmedName = expenseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showError(message: "Expense name is required")
            return
        }
        
        isLoading = true
        
        // Format date as ISO8601 string
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        let expenseDateString = dateFormatter.string(from: expenseDate)
        
        Task {
            let success = await expenseViewModel.addExpense(
                name: trimmedName,
                amount: amount,
                expenseDate: expenseDateString,
                billId: nil,
                paymentMethod: paymentMethod,
                isRecurring: isRecurring,
                recurringFrequency: isRecurring ? recurringFrequency : nil,
                merchant: merchant.isEmpty ? nil : merchant,
                location: location.isEmpty ? nil : location,
                tags: Array(selectedTags),
                createdAt: nil,
                updatedAt: nil,
                notes: notes.isEmpty ? nil : notes,
                attachmentUrls: []
            )
            
            await MainActor.run {
                isLoading = false
                if success {
                    dismiss()
                } else {
                    showError(message: "Failed to create expense")
                }
            }
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Supporting Views

struct TagChip: View {
    let text: String
    let isSelected: Bool
    var showRemove: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(text)
                    .font(.system(size: 12, weight: .medium))
                
                if showRemove {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.purple.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 1)
            )
            .foregroundColor(isSelected ? Color.purple : Color.primary)
        }
    }
}

// MARK: - Preview

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let expenseViewModel = ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    
    return CreateExpenseView()
        .environmentObject(expenseViewModel)
        .environmentObject(sessionViewModel)
        .environmentObject(profileViewModel)
        .environmentObject(dataManager)
}