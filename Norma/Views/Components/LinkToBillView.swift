//
//  LinkToBillView.swift
//  Norma
//
//  Created by Claude on 7/24/25.
//

import SwiftUI

struct LinkToBillView: View {
    let expense: Expense
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var billViewModel: BillViewModel
    
    @State private var selectedBill: Bill?
    @State private var isLoading = false
    
    private var availableBills: [Bill] {
        billViewModel.bills.filter { $0.status != .paid }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if availableBills.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Bills Available")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Create a bill first to link this expense")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select a bill to link this expense to:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(availableBills) { bill in
                                    BillSelectionRow(
                                        bill: bill,
                                        isSelected: selectedBill?.id == bill.id
                                    ) {
                                        selectedBill = bill
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Link to Bill")
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
                            await linkToBill()
                        }
                    }
                    .disabled(selectedBill == nil || isLoading)
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private func linkToBill() async {
        guard let bill = selectedBill else { return }
        
        isLoading = true
        
        let updatedExpense = Expense(
            id: expense.id,
            userId: expense.userId,
            name: expense.name,
            amount: expense.amount,
            expenseDate: expense.expenseDate,
            budgetId: expense.budgetId,
            billId: bill.id,
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

struct BillSelectionRow: View {
    let bill: Bill
    let isSelected: Bool
    let onTap: () -> Void
    
    private var statusColor: Color {
        switch bill.status {
        case .overdue:
            return .red
        case .paid:
            return .green
        default:
            return .blue
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bill.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text("$\(bill.amount, specifier: "%.2f")")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("Due \(bill.dueDate, format: .dateTime.month().day())")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(bill.status.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(statusColor)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
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
    let billViewModel = BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    
    let sampleExpense = Expense(
        id: "1",
        userId: "preview-user-123",
        name: "Groceries",
        amount: 142.75,
        expenseDate: "2025-07-24",
        paymentMethod: .creditCard,
        tags: ["food", "groceries"]
    )
    
    return LinkToBillView(expense: sampleExpense)
        .environmentObject(expenseViewModel)
        .environmentObject(billViewModel)
}
