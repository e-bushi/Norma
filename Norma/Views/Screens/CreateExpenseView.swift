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
    @State private var merchant = ""
    @State private var notes = ""
    @State private var isRecurring = false
    @State private var recurringFrequency: ExpenseFrequency = .monthly

    // UI state
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isAmountFieldFocused: Bool
    
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

    private var currencySymbol: String {
        let currencyCode = sessionViewModel.currentUser?.settings.currency ?? "USD"
        return CurrencyData.getCurrency(for: currencyCode).symbol
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with centered icon and name
                    headerView

                    // Expense amount card
                    expenseAmountCard

                    // Expense details section
                    expenseDetailsSection

                    // Date section
                    dateSection

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
    private var headerView: some View {
        VStack(spacing: 12) {
            // Category icon (if available)
            if let category = selectedCategory {
                Circle()
                    .fill(category.color.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: category.icon)
                            .font(.system(size: 26))
                            .foregroundColor(category.color)
                    )
            } else {
                Circle()
                    .fill(Color("NormaPastelCoral").opacity(0.15))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 26))
                            .foregroundColor(Color("NormaPastelCoral"))
                    )
            }

            // Expense name
            VStack(spacing: 4) {
                TextField("Expense Name", text: $expenseName)
                    .font(.normaTitle())
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                if let category = selectedCategory {
                    Text(category.name)
                        .font(.normaHeadline(14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var expenseAmountCard: some View {
        VStack(spacing: 8) {
            Text("Expense Amount (\(currencySymbol))")
                .font(.normaHeadline(12))
                .foregroundColor(.secondary)

            TextField("0.00", text: $expenseAmount)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .focused($isAmountFieldFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isAmountFieldFocused = false
                        }
                        .font(.normaHeadline(16))
                    }
                }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
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
    
    @ViewBuilder
    private var expenseDetailsSection: some View {
        VStack(spacing: 16) {
            Text("EXPENSE DETAILS")
                .font(.normaHeadline(11))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
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
                                        .font(.normaHeadline(14))
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
                        .font(.normaHeadline(14))
                    }
                }

                Divider()

                // Merchant input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Merchant")
                        .font(.normaHeadline(14))
                        .foregroundColor(.secondary)

                    TextField("Store or business name (optional)", text: $merchant)
                        .font(.normaHeadline(14))
                        .foregroundColor(.primary)
                }

                Divider()

                // Notes input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.normaHeadline(14))
                        .foregroundColor(.secondary)

                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .font(.normaHeadline(14))
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
    private var dateSection: some View {
        VStack(spacing: 16) {
            Text("DATE")
                .font(.normaHeadline(11))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                DetailRow(label: "Expense Date", value: "") {
                    DatePicker("", selection: $expenseDate, displayedComponents: [.date])
                        .labelsHidden()
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
                    .font(.normaHeadline(16))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: isFormValid ? [
                                Color("NormaPastelCoral"),
                                Color("NormaPastelCoral").opacity(0.8)
                            ] : [
                                Color.gray,
                                Color.gray.opacity(0.8)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
        }
        .disabled(!isFormValid || isLoading)
        .buttonStyle(PlainButtonStyle())
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
                paymentMethod: .debitCard, // Default payment method
                isRecurring: false,
                recurringFrequency: nil,
                merchant: merchant.isEmpty ? nil : merchant,
                location: nil, // No longer capturing location
                tags: [], // No longer capturing tags
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

// MARK: - Detail Row

private struct DetailRow<Content: View>: View {
    let label: String
    let value: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Spacer()

            content()
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