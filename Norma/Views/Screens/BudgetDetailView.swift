//
//  BudgetDetailView.swift
//  Norma
//
//  Created by Claude on 7/26/25.
//

import SwiftUI

struct BudgetDetailView: View {
    let budget: Budget
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var budgetViewModel: BudgetViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    @State private var showEditBudgetSheet = false
    @State private var showDeleteConfirmation = false
    
    private var linkedExpenses: [Expense] {
        expenseViewModel.expenses.filter { $0.budgetId == budget.id }
            .sorted { expense1, expense2 in
                let formatter = ISO8601DateFormatter()
                guard let date1 = formatter.date(from: expense1.expenseDate),
                      let date2 = formatter.date(from: expense2.expenseDate) else {
                    return false
                }
                return date1 > date2
            }
    }
    
    private var totalSpent: Double {
        // Use the currentSpent from the budget model (maintained in database)
        budget.currentSpent
    }
    
    private var remainingAmount: Double {
        budget.amount - totalSpent
    }
    
    private var percentageUsed: Double {
        guard budget.amount > 0 else { return 0 }
        return min(totalSpent / budget.amount, 1.5)
    }
    
    private var isOverBudget: Bool {
        totalSpent > budget.amount
    }
    
    private var statusColor: Color {
        if percentageUsed < 0.5 {
            return Color("NormaPastelTeal")
        } else if percentageUsed < 0.8 {
            return Color("NormaPastelBeige")
        } else if percentageUsed < 1.0 {
            return Color("NormaPastelCoral")
        } else {
            return .red
        }
    }
    
    private var linkedCategory: Category? {
        guard let categoryId = budget.categoryId else { return nil }
        // Categories are managed by DataManager as they're relatively static
        // and shared across all ViewModels
        return dataManager.categories.first { $0.id == categoryId }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                    // Header with budget name (centered)
                    headerView

                    // Date metadata
                    dateMetadataView

                    // Combined budget details (progress + end date)
                    budgetDetailsRow

                    // Recent expenses section
                    expensesSection

                    // Action buttons
                    actionButtonsView
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .alert("Delete Budget", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteBudget()
                }
            }
        } message: {
            Text("Are you sure you want to delete this budget? This will unlink all associated expenses but won't delete them.")
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 12) {
            // Category icon (if available)
            if let category = linkedCategory {
                Circle()
                    .fill(category.color.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: category.icon)
                            .font(.system(size: 26))
                            .foregroundColor(category.color)
                    )
            }

            // Budget name
            VStack(spacing: 4) {
                Text(budget.name)
                    .font(.normaTitle(24))
                    .foregroundColor(.primary)

                if let category = linkedCategory {
                    Text(category.name)
                        .font(.normaHeadline(14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var dateMetadataView: some View {
        HStack(spacing: 12) {
            // Start date
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 32, height: 32)

                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Start")
                        .font(.normaHeadline(11))
                        .foregroundColor(.secondary)

                    Text(budget.startDate, format: .dateTime.month().day().year())
                        .font(.normaHeadline(13))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Arrow separator
            Image(systemName: "arrow.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.horizontal, 4)

            // End date
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 32, height: 32)

                    Image(systemName: "flag.checkered")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("End")
                        .font(.normaHeadline(11))
                        .foregroundColor(.secondary)

                    if let endDate = budget.endDate {
                        Text(endDate, format: .dateTime.month().day().year())
                            .font(.normaHeadline(13))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    } else {
                        Text("No end date")
                            .font(.normaHeadline(13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.03),
                            Color.gray.opacity(0.01)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.15),
                            Color.gray.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    @ViewBuilder
    private var budgetDetailsRow: some View {
        HStack {
            // Icon and progress info
            HStack(spacing: 12) {
                // Circular progress indicator
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: min(percentageUsed, 1.0))
                        .stroke(
                            statusColor,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 50, height: 50)

                    Image(systemName: statusIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(statusColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Progress percentage
                    HStack(spacing: 4) {
                        Image(systemName: statusIcon)
                            .font(.caption)
                            .foregroundColor(statusColor)

                        Text("\(Int(percentageUsed * 100))%")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    // End date
                    if let endDate = budget.endDate {
                        HStack(spacing: 4) {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("Ends \(endDate, format: .dateTime.month().day())")
                                .font(.normaHeadline(14))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }

            Spacer()

            // Amount section
            VStack(alignment: .trailing, spacing: 4) {
                Text(profileViewModel.formatCurrency(totalSpent))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text("of \(profileViewModel.formatCurrency(budget.amount))")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
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
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
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
    }

    private var statusIcon: String {
        if percentageUsed >= 1.0 {
            return "exclamationmark.triangle.fill"
        } else if percentageUsed >= 0.8 {
            return "exclamationmark.circle.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }
    
    @ViewBuilder
    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Linked Expenses")
                    .font(.normaHeadline(16))
                    .foregroundColor(.primary)

                Spacer()

                if !linkedExpenses.isEmpty {
                    Text("\(linkedExpenses.count)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
            }

            if linkedExpenses.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)

                    Text("No expenses linked yet")
                        .font(.normaHeadline(16))
                        .foregroundColor(.primary)

                    Text("Use the chat to add expenses to this budget")
                        .font(.normaHeadline(14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(linkedExpenses.prefix(10)) { expense in
                        BudgetExpenseRow(expense: expense, category: linkedCategory)
                    }

                    if linkedExpenses.count > 10 {
                        Button(action: {
                            // Navigate to full expenses list
                        }) {
                            Text("View all \(linkedExpenses.count) expenses")
                                .font(.normaHeadline(14))
                                .foregroundColor(.blue)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    private var actionButtonsView: some View {
        // Delete button
        Button(action: {
            showDeleteConfirmation = true
        }) {
            HStack {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                Text("Delete Budget")
                    .font(.normaHeadline(16))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
            )
            .foregroundColor(.red)
        }
        .padding(.top, 8)
    }
    
    private func deleteBudget() async {
        // TODO: Implement budget deletion
        await budgetViewModel.deleteBudget(budget)
        dismiss()
    }
}

struct BudgetExpenseRow: View {
    let expense: Expense
    let category: Category?
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    private var expenseDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: expense.expenseDate) ?? Date()
    }

    var body: some View {
        HStack {
            // Category icon (if available)
            if let category = category {
                Circle()
                    .fill(category.color.opacity(0.1))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: category.icon)
                            .font(.system(size: 12))
                            .foregroundColor(category.color)
                    )
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.name)
                    .font(.normaHeadline(12))
                    .foregroundColor(.primary)

                Text(expenseDate, format: .dateTime.month().day())
                    .font(.normaHeadline(10))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(profileViewModel.formatCurrency(expense.amount))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
}

// Placeholder views for missing components
struct EditBudgetView: View {
    let budget: Budget
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Edit Budget")
                    .font(.title)
                Text("Edit functionality coming soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

struct AddExpenseView: View {
    let preselectedBudget: Budget?
    @Environment(\.dismiss) private var dismiss
    
    init(preselectedBudget: Budget? = nil) {
        self.preselectedBudget = preselectedBudget
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Expense")
                    .font(.title)
                if let budget = preselectedBudget {
                    Text("Budget: \(budget.name)")
                        .foregroundColor(.secondary)
                }
                Text("Add expense functionality coming soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let budgetViewModel = BudgetViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let expenseViewModel = ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    
    let sampleBudget = Budget(
        userId: "preview-user-123",
        name: "Groceries Budget",
        amount: 500.0,
        categoryId: "1",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
        isActive: true,
        currentSpent: 275.50,
        alertThreshold: 0.8,
        notes: "Monthly grocery budget for healthy eating"
    )
    
    return BudgetDetailView(budget: sampleBudget)
        .environmentObject(dataManager)
        .environmentObject(budgetViewModel)
        .environmentObject(expenseViewModel)
        .environmentObject(profileViewModel)
}
