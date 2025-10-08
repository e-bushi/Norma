//
//  CreateBudgetView.swift
//  Norma
//
//  Created by Claude on 7/20/25.
//

import SwiftUI

struct CreateBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var budgetViewModel: BudgetViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    let preselectedCategory: Category?
    
    // Form fields
    @State private var budgetName = ""
    @State private var selectedCategory: Category?
    @State private var budgetAmount = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
    @State private var notes = ""

    // Alert threshold is set to 80% by default and not user-configurable
    private let alertThreshold: Double = 0.8
    
    init(preselectedCategory: Category? = nil) {
        self.preselectedCategory = preselectedCategory
    }
    
    // UI state
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isAmountFieldFocused: Bool
    @State private var showCategoryPicker = false
    
    // Computed properties
    private var expenseCategories: [Category] {
        dataManager.getCategories(ofType: .expense).filter { $0.isActive }
    }
    
    private var formattedAmount: Double? {
        Double(budgetAmount.replacingOccurrences(of: ",", with: ""))
    }
    
    private var isFormValid: Bool {
        !budgetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        formattedAmount != nil &&
        formattedAmount! > 0
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

                    // Budget amount card
                    budgetAmountCard

                    // Budget details section
                    budgetDetailsSection

                    // Date range section
                    dateRangeSection

                    // Save button
                    saveButtonView
                }
                .padding()
            }
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let category = preselectedCategory {
                    selectedCategory = category
                    if budgetName.isEmpty {
                        budgetName = "New Budget"
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
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "target")
                            .font(.system(size: 26))
                            .foregroundColor(.blue)
                    )
            }

            // Budget name
            VStack(spacing: 4) {
                TextField("Budget Name", text: $budgetName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                if let category = selectedCategory {
                    Text(category.name)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var budgetAmountCard: some View {
        VStack(spacing: 8) {
            Text("Budget Amount (\(currencySymbol))")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            TextField("0.00", text: $budgetAmount)
                .font(.system(size: 32, weight: .bold))
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
                        .font(.system(size: 16, weight: .semibold))
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
    private var budgetDetailsSection: some View {
        VStack(spacing: 16) {
            Text("BUDGET DETAILS")
                .font(.system(size: 11, weight: .semibold))
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
                                if budgetName.isEmpty {
                                    budgetName = "\(category.name) Budget"
                                }
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

                Divider()

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
                .frame(maxWidth: .infinity, alignment: .leading)
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
    private var dateRangeSection: some View {
        VStack(spacing: 16) {
            Text("DATE RANGE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                DetailRow(label: "Start Date", value: "") {
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                }
                
                DetailRow(label: "End Date", value: "") {
                    DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
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
            saveBudget()
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
                
                Text("Create Budget")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFormValid ? Color.blue : Color.gray)
            )
        }
        .disabled(!isFormValid || isLoading)
    }
    
    // MARK: - Actions
    
    private func saveBudget() {
        guard let userId = sessionViewModel.currentUser?.userId,
              let amount = formattedAmount else {
            showError(message: "Invalid budget information")
            return
        }
        
        let trimmedName = budgetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showError(message: "Budget name is required")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let newBudget = Budget(
                    userId: userId,
                    name: trimmedName,
                    amount: amount,
                    categoryId: selectedCategory?.id,
                    startDate: startDate,
                    endDate: endDate,
                    isActive: true,
                    currentSpent: 0,
                    alertThreshold: alertThreshold,
                    notes: notes.isEmpty ? nil : notes
                )
                
                try await dataManager.addBudget(newBudget)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError(message: "Failed to create budget: \(error.localizedDescription)")
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

struct DetailRow<Content: View>: View {
    let label: String
    let value: String
    var content: (() -> Content)?
    
    init(label: String, value: String, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.value = value
        self.content = content
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            if let content = content {
                content()
            } else {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }
        }
    }
}

extension DetailRow where Content == EmptyView {
    init(label: String, value: String) {
        self.label = label
        self.value = value
        self.content = nil
    }
}

// MARK: - Preview

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let budgetViewModel = BudgetViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    
    return CreateBudgetView()
        .environmentObject(dataManager)
        .environmentObject(sessionViewModel)
        .environmentObject(budgetViewModel)
        .environmentObject(profileViewModel)
}
