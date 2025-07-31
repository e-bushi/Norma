//
//  BillDetailView.swift
//  Norma
//
//  Created by Claude on 7/5/25.
//

import SwiftUI
import UserNotifications

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
    @State private var showNotificationAlert = false
    @State private var isReminderOn: Bool
    @State private var isMarkingAsUnpaid = false
    
    init(bill: Bill, expenses: [Expense]) {
        self.bill = bill
        self.expenses = expenses
        self._isReminderOn = State(initialValue: bill.isReminderOn)
    }
    
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
        .alert("Enable Notifications", isPresented: $showNotificationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("To receive bill reminders, please enable notifications for Norma in Settings.")
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
                    
                    // Reminder toggle section
                    ReminderToggleRow(
                        isReminderOn: isReminderOn,
                        onToggle: { isOn in
                            Task {
                                await toggleReminder(isOn)
                            }
                        }
                    )
                    
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
                        } else if showPaymentSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        } else if showPaymentError {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 16))
                        }
                        
                        Text(getPaymentButtonText())
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: getPaymentButtonColors()),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .opacity(isMarkingAsPaid ? 0.8 : 1.0)
                    .scaleEffect(showPaymentSuccess || showPaymentError ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: showPaymentSuccess)
                    .animation(.easeInOut(duration: 0.2), value: showPaymentError)
                }
                .disabled(isMarkingAsPaid)
                .buttonStyle(PlainButtonStyle())
            } else {
                // Show Mark as Unpaid button when bill is paid
                Button(action: {
                    Task {
                        await markBillAsUnpaid()
                    }
                }) {
                    HStack(spacing: 8) {
                        if isMarkingAsUnpaid {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                .scaleEffect(0.8)
                        } else if showPaymentSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                        } else if showPaymentError {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                        } else {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                                .font(.system(size: 16))
                        }
                        
                        Text(getUnpaidButtonText())
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .opacity(isMarkingAsUnpaid ? 0.8 : 1.0)
                    .scaleEffect(showPaymentSuccess || showPaymentError ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: showPaymentSuccess)
                    .animation(.easeInOut(duration: 0.2), value: showPaymentError)
                }
                .disabled(isMarkingAsUnpaid)
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
    
    private func getPaymentButtonText() -> String {
        if isMarkingAsPaid {
            return "Processing..."
        } else if showPaymentSuccess {
            return "Success!"
        } else if showPaymentError {
            return "Failed"
        } else {
            return "Mark as Paid"
        }
    }
    
    private func getPaymentButtonColors() -> [Color] {
        if showPaymentSuccess {
            return [Color.green, Color.green.opacity(0.8)]
        } else if showPaymentError {
            return [Color.red, Color.red.opacity(0.8)]
        } else {
            return [Color.blue, Color.blue.opacity(0.8)]
        }
    }
    
    private func getUnpaidButtonText() -> String {
        if isMarkingAsUnpaid {
            return "Processing..."
        } else if showPaymentSuccess {
            return "Success!"
        } else if showPaymentError {
            return "Failed"
        } else {
            return "Mark as Unpaid"
        }
    }
    
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
        
        if !billViewModel.showError {
            showPaymentSuccess = true
            // Auto-hide success state after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showPaymentSuccess = false
            }
        } else {
            showPaymentError = true
            // Auto-hide error state after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showPaymentError = false
            }
        }
    }
    
    private func markBillAsUnpaid() async {
        isMarkingAsUnpaid = true
        
        // Add a small delay for better UX
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        await billViewModel.markBillAsUnpaid(bill)
        
        isMarkingAsUnpaid = false
        
        if !billViewModel.showError {
            showPaymentSuccess = true
            // Auto-hide success state after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showPaymentSuccess = false
            }
        } else {
            showPaymentError = true
            // Auto-hide error state after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showPaymentError = false
            }
        }
    }
    
    private func toggleReminder(_ isOn: Bool) async {
        let notificationService = NotificationService.shared
        
        // If user is trying to turn ON reminders, check if notifications are enabled
        if isOn {
            // Check current notification permission status synchronously
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            let isEnabled = settings.authorizationStatus == .authorized
            
            if !isEnabled {
                // Show alert to enable notifications
                await MainActor.run {
                    showNotificationAlert = true
                }
                return
            }
        }
        
        // Update the state variable first for immediate UI feedback
        await MainActor.run {
            isReminderOn = isOn
        }
        
        // Proceed with updating the bill
        var updatedBill = bill
        updatedBill.isReminderOn = isOn
        
        await billViewModel.updateBill(updatedBill)
        
        // Schedule or cancel notifications based on toggle
        if isOn {
            await notificationService.scheduleBillReminders(for: updatedBill)
        } else {
            await notificationService.cancelNotifications(for: updatedBill)
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
