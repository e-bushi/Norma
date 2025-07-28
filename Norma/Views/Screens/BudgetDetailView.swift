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
    @State private var showAddExpenseSheet = false
    
    private var linkedExpenses: [Expense] {
        dataManager.expenses.filter { $0.budgetId == budget.id }
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
        linkedExpenses.reduce(0) { $0 + $1.amount }
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
            return .green
        } else if percentageUsed < 0.8 {
            return .yellow
        } else if percentageUsed < 1.0 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var linkedCategory: Category? {
        guard let categoryId = budget.categoryId else { return nil }
        return dataManager.categories.first { $0.id == categoryId }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                    // Budget overview section
                    budgetOverviewView
                    
                    // Budget details section
                    budgetDetailsView
                    
                    // Progress section
                    progressView
                    
                    // Category info if available
                    if linkedCategory != nil {
                        categoryView
                    }
                    
                    // Notes if available
                    if let notes = budget.notes, !notes.isEmpty {
                        notesView(notes: notes)
                    }
                    
                    // Recent expenses section
                    expensesSection
                    
                    // Action buttons
                    actionButtonsView
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showEditBudgetSheet) {
            EditBudgetView(budget: budget)
                .environmentObject(dataManager)
                .environmentObject(budgetViewModel)
                .environmentObject(profileViewModel)
        }
        .sheet(isPresented: $showAddExpenseSheet) {
            AddExpenseView(preselectedBudget: budget)
                .environmentObject(dataManager)
                .environmentObject(expenseViewModel)
                .environmentObject(profileViewModel)
        }
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
    private var budgetOverviewView: some View {
        VStack(spacing: 16) {
            // Header with amount and name
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if let category = linkedCategory {
                        Text(category.name)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(profileViewModel.formatCurrency(budget.amount))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.system(size: 12))
                        Text("Budget")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            // Status and progress info
            HStack {
                Label {
                    Text(budget.startDate, format: .dateTime.month().day().year())
                        .font(.system(size: 14))
                } icon: {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14))
                    Text("\(Int(percentageUsed * 100))% used")
                        .font(.system(size: 14))
                }
                .foregroundColor(statusColor)
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var budgetDetailsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Budget Details")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 0) {
                // Budget amount
                HStack {
                    Text("Budget Amount")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(profileViewModel.formatCurrency(budget.amount))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 12)
                
                Divider()
                
                // Alert threshold
                HStack {
                    Text("Alert Threshold")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(budget.alertThreshold * 100))%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 12)
                
                Divider()
                
                // End date
                HStack {
                    Text("End Date")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    if let endDate = budget.endDate {
                        Text(endDate, format: .dateTime.month().day().year())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    } else {
                        Text("Not set")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 12)
            }
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    @ViewBuilder
    private var progressView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Progress")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Amount summary
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spent")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text(profileViewModel.formatCurrency(totalSpent))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isOverBudget ? .red : .primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(isOverBudget ? "Over by" : "Remaining")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text(profileViewModel.formatCurrency(abs(remainingAmount)))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isOverBudget ? .red : .green)
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 16)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(statusColor)
                            .frame(
                                width: min(geometry.size.width * percentageUsed, geometry.size.width),
                                height: 16
                            )
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: percentageUsed)
                    }
                }
                .frame(height: 16)
                
                // Alert threshold warning
                if percentageUsed >= budget.alertThreshold {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                        Text("Alert threshold reached")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(statusColor.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(statusColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private var categoryView: some View {
        if let category = linkedCategory {
            VStack(alignment: .leading, spacing: 12) {
                Text("Linked Category")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack {
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: category.icon)
                            .font(.system(size: 18))
                            .foregroundColor(category.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text(category.type.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "link")
                        .font(.system(size: 14))
                        .foregroundColor(category.color)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(category.color.opacity(0.1))
                )
            }
        }
    }
    
    private func notesView(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(notes)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
    }
    
    @ViewBuilder
    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Linked Expenses")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !linkedExpenses.isEmpty {
                    Text("\(linkedExpenses.count)")
                        .font(.system(size: 12, weight: .medium))
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
                    Image(systemName: "doc.text")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No expenses linked yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Expenses linked to this budget will appear here")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(linkedExpenses.prefix(5)) { expense in
                        BudgetExpenseRow(expense: expense)
                    }
                    
                    if linkedExpenses.count > 5 {
                        Button(action: {
                            // Navigate to full expenses list
                        }) {
                            Text("View all \(linkedExpenses.count) expenses")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                                .padding(.vertical, 12)
                        }
                    }
                }
            }
        }
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // Primary action
            HStack(spacing: 12) {
                Button(action: {
                    showAddExpenseSheet = true
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Add Expense")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .foregroundColor(.blue)
                }
            }
            
            // Delete button
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                    Text("Delete Budget")
                        .font(.system(size: 16, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                )
                .foregroundColor(.red)
            }
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
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    private var expenseDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: expense.expenseDate) ?? Date()
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(expenseDate, format: .dateTime.month().day())
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(profileViewModel.formatCurrency(expense.amount))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
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