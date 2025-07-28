//
//  LinkToBudgetView.swift
//  Norma
//
//  Created by Claude on 7/24/25.
//

import SwiftUI

struct LinkToBudgetView: View {
    let expense: Expense
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var budgetViewModel: BudgetViewModel
    
    @State private var selectedBudget: Budget?
    @State private var isLoading = false
    
    private var availableBudgets: [Budget] {
        dataManager.budgets.filter { $0.isActive }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if availableBudgets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "target")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Budgets Available")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Create a budget first to link this expense")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select a budget to link this expense to:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(availableBudgets) { budget in
                                    BudgetSelectionRow(
                                        budget: budget,
                                        isSelected: selectedBudget?.id == budget.id
                                    ) {
                                        selectedBudget = budget
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Link to Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Link") {
                        Task {
                            await linkToBudget()
                        }
                    }
                    .disabled(selectedBudget == nil || isLoading)
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private func linkToBudget() async {
        guard let budget = selectedBudget else { return }
        
        isLoading = true
        
        let updatedExpense = Expense(
            id: expense.id,
            userId: expense.userId,
            name: expense.name,
            amount: expense.amount,
            expenseDate: expense.expenseDate,
            budgetId: budget.id,
            billId: expense.billId,
            paymentMethod: expense.paymentMethod,
            isRecurring: expense.isRecurring,
            recurringFrequency: expense.recurringFrequency,
            merchant: expense.merchant,
            location: expense.location,
            tags: expense.tags,
            createdAt: expense.createdAt,
            updatedAt: expense.updatedAt,
            notes: expense.notes,
            attachmentUrls: expense.attachmentUrls
        )
        
        await expenseViewModel.updateExpense(updatedExpense)
        
        isLoading = false
        dismiss()
    }
}

struct BudgetSelectionRow: View {
    let budget: Budget
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Budget: $\(budget.amount, specifier: "%.2f")")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let expenseViewModel = ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let budgetViewModel = BudgetViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    
    let sampleExpense = Expense(
        id: "1",
        userId: "preview-user-123",
        name: "Groceries",
        amount: 142.75,
        expenseDate: "2025-07-24",
        paymentMethod: .creditCard,
        tags: ["food", "groceries"]
    )
    
    return LinkToBudgetView(expense: sampleExpense)
        .environmentObject(expenseViewModel)
        .environmentObject(dataManager)
        .environmentObject(budgetViewModel)
}