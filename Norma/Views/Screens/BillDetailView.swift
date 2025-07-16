//
//  BillDetailView.swift
//  Norma
//
//  Created by Claude on 7/5/25.
//

import SwiftUI

struct BillDetailView: View {
    let bill: Bill
    let expenses: [Expense]
    
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showEditBillSheet = false
    @State private var isMarkingAsPaid = false
    @State private var showPaymentSuccess = false
    @State private var showPaymentError = false
    @State private var paymentErrorMessage = ""
    
    // Calculate bill status and payment info
    private var calculatedStatus: BillStatus {
        bill.calculateStatus(from: expenses)
    }
    
    private var amountPaidThisPeriod: Double {
        bill.getAmountPaidThisPeriod(from: expenses)
    }
    
    private var isFullyPaid: Bool {
        bill.isFullyPaid(from: expenses)
    }
    
    private var remainingAmount: Double {
        max(0, bill.amount - amountPaidThisPeriod)
    }
    
    private var relatedExpenses: [Expense] {
        expenses.filter { $0.billId == bill.id }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Bill details section
                    billDetailsView
                    
                    // Related payments section
                    if !relatedExpenses.isEmpty {
                        relatedPaymentsView
                    }
                    
                    // Action buttons
                    actionButtonsView
                }
                .padding()
            }
        }
        .sheet(isPresented: $showEditBillSheet) {
            EditBillView(bill: bill)
                .environmentObject(billViewModel)
        }
        .alert("Payment Successful", isPresented: $showPaymentSuccess) {
            Button("OK") { }
        } message: {
            Text("Bill has been marked as paid and will recur next period.")
        }
        .alert("Payment Failed", isPresented: $showPaymentError) {
            Button("OK") { }
        } message: {
            Text(paymentErrorMessage)
        }
    }
    
    
    @ViewBuilder
    private var billDetailsView: some View {
        VStack(spacing: 16) {
            // Header with status badge
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bill.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: statusIcon)
                            .font(.system(size: 12))
                            .foregroundColor(statusColor)
                        
                        Text(calculatedStatus.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(statusColor)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(profileViewModel.formatCurrency(bill.amount))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(bill.frequency.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
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
            
            // Bill details grid
            VStack(spacing: 16) {
                Text("BILL DETAILS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    DetailRow(label: "Due Date", value: formatDueDate())
                    
                    if let merchant = bill.merchant {
                        DetailRow(label: "Merchant", value: merchant)
                    }
                    
                    if let reminderDays = bill.reminderDays {
                        DetailRow(label: "Reminder", value: "\(reminderDays) days before")
                    }
                    
                    if bill.isAutoPayEnabled {
                        DetailRow(label: "Auto Pay", value: "Enabled")
                    }
                    
                    if let notes = bill.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(notes)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .lineLimit(nil)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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
    }
    
    @ViewBuilder
    private var relatedPaymentsView: some View {
        let dateFormatter = ISO8601DateFormatter()
        let sortedExpenses = relatedExpenses.sorted { expense1, expense2 in
            guard let date1 = dateFormatter.date(from: expense1.expenseDate),
                  let date2 = dateFormatter.date(from: expense2.expenseDate) else { return false }
            return date1 > date2
        }
        let recentExpenses = Array(sortedExpenses.prefix(5))
        
        VStack(spacing: 16) {
            Text("RECENT PAYMENTS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 0) {
                ForEach(recentExpenses, id: \.id) { expense in
                    HStack(spacing: 16) {
                        // Payment icon
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                        }
                        
                        // Payment info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatPaymentDate(expense.expenseDate))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                            Text(expense.paymentMethod.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Amount
                        Text(profileViewModel.formatCurrency(expense.amount))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    if expense.id != recentExpenses.last?.id {
                        Divider()
                            .padding(.horizontal, 20)
                    }
                }
            }
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
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            if !isFullyPaid {
                Button(action: {
                    Task {
                        await markBillAsPaid()
                    }
                }) {
                    HStack(spacing: 8) {
                        if isMarkingAsPaid {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 16))
                        }
                        
                        Text(isMarkingAsPaid ? "Processing..." : "Mark as Paid")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue,
                                        Color.blue.opacity(0.8)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .opacity(isMarkingAsPaid ? 0.8 : 1.0)
                }
                .disabled(isMarkingAsPaid)
                .buttonStyle(PlainButtonStyle())
            }
            
            Button(action: {
                showEditBillSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                    
                    Text("Edit Bill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                Task {
                    await billViewModel.deleteBill(bill)
                    dismiss()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                    
                    Text("Remove Bill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Helper Views
    
    private struct DetailRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 2)
        }
    }
    
    // MARK: - Helper Properties
    
    private var statusIcon: String {
        switch calculatedStatus {
        case .paid: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .scheduled: return "calendar.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch calculatedStatus {
        case .paid: return .green
        case .overdue: return .red
        case .scheduled: return .blue
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDueDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: bill.dueDate)
    }
    
    private func formatPaymentDate(_ expenseDate: String) -> String {
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: expenseDate) else {
            return "Unknown"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func markBillAsPaid() async {
        isMarkingAsPaid = true
        
        // Add a small delay for better UX
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        await billViewModel.markBillAsPaid(bill, paymentMethod: .debitCard)
        
        isMarkingAsPaid = false
        
        if billViewModel.errorMessage == nil {
            showPaymentSuccess = true
            // Optionally dismiss after showing success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        } else {
            paymentErrorMessage = billViewModel.errorMessage ?? "Failed to mark bill as paid"
            showPaymentError = true
        }
    }
}

#Preview {
    let sampleBill = Bill(
        id: "1",
        userId: "user1",
        name: "Rent",
        dueDate: Date(),
        amount: 1200.00,
        status: .scheduled,
        frequency: .monthly,
        merchant: "Property Management Co",
        reminderDays: 3,
        notes: "Monthly rent payment"
    )
    
    let sampleExpenses: [Expense] = []
    
    return BillDetailView(bill: sampleBill, expenses: sampleExpenses)
        .environmentObject(BillViewModel(dataManager: DataManager(), sessionViewModel: SessionViewModel(dataManager: DataManager())))
        .environmentObject(ExpenseViewModel(dataManager: DataManager(), sessionViewModel: SessionViewModel(dataManager: DataManager())))
}
