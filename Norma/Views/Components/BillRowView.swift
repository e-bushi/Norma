//
//  BillRowView.swift
//  Norma
//
//  Created by Claude on 7/30/25.
//

import SwiftUI

struct BillRowView: View {
    let bill: Bill
    
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @State private var selectedBill: Bill? = nil
    
    // Use the actual bill status from the database
    private var billStatus: BillStatus {
        bill.status
    }
    
    private var statusIcon: String {
        switch billStatus {
        case .paid: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .scheduled: return "calendar.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch billStatus {
        case .paid: return .green
        case .overdue: return .red
        case .scheduled: return .blue
        }
    }
    
    private var dueDateText: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        if billStatus == .paid {
            // For paid bills, show the next due date if available
            if let nextDueDate = bill.nextDueDate {
                let nextDateString = formatter.string(from: nextDueDate)
                return "Paid ✓ • Next: \(nextDateString)"
            } else {
                // Fallback: calculate next due date for display
                let nextDueDate = calculateNextDueDate(from: bill.dueDate, frequency: bill.frequency)
                let nextDateString = formatter.string(from: nextDueDate)
                return "Paid ✓ • Next: \(nextDateString)"
            }
        } else {
            // For unpaid bills, show days until/since due
            let days = calendar.dateComponents([.day], from: Date(), to: bill.dueDate).day ?? 0
            
            if days == 0 {
                return "Due today"
            } else if days == 1 {
                return "Due tomorrow"
            } else if days < 0 {
                return "\(abs(days)) days overdue"
            } else {
                return "Due in \(days) days"
            }
        }
    }
    
    private func calculateNextDueDate(from date: Date, frequency: BillFrequency) -> Date {
        let calendar = Calendar.current
        
        switch frequency {
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
    
    var body: some View {
        Button(action: {
            selectedBill = bill
        }) {
            HStack(spacing: 12) {
                // Status icon
                Circle()
                    .fill(statusColor.opacity(0.1))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: statusIcon)
                            .font(.system(size: 12))
                            .foregroundColor(statusColor)
                    )

                // Bill info
                VStack(alignment: .leading, spacing: 2) {
                    Text(bill.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)

                    Text(dueDateText)
                        .font(.system(size: 10))
                        .foregroundColor(billStatus == .overdue ? .red : .secondary)
                }

                Spacer()

                // Amount
                Text(profileViewModel.formatCurrency(bill.amount))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(billStatus == .overdue ? .red : .primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(item: $selectedBill) { bill in
            BillDetailView(bill: bill, expenses: expenseViewModel.expenses)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let expenseViewModel = ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    
    // Sample bills with different states
    let paidBill = Bill(
        id: "1",
        userId: "user123",
        name: "Rent",
        dueDate: Date(),
        nextDueDate: Date().addingTimeInterval(86400 * 30), // 30 days later
        amount: 1200.00,
        status: .paid,
        frequency: .monthly
    )
    
    let scheduledBill = Bill(
        id: "2",
        userId: "user123",
        name: "Internet",
        dueDate: Date().addingTimeInterval(86400 * 5), // 5 days from now
        nextDueDate: Date().addingTimeInterval(86400 * 35), // 35 days from now
        amount: 89.99,
        status: .scheduled,
        frequency: .monthly
    )
    
    let overdueBill = Bill(
        id: "3",
        userId: "user123",
        name: "Electric",
        dueDate: Date().addingTimeInterval(-86400 * 3), // 3 days ago
        nextDueDate: Date().addingTimeInterval(86400 * 27), // 27 days from now
        amount: 125.50,
        status: .overdue,
        frequency: .monthly
    )
    
    return VStack(spacing: 20) {
        BillRowView(bill: paidBill)
        BillRowView(bill: scheduledBill)
        BillRowView(bill: overdueBill)
    }
    .padding()
    .background(Color("NormaCard"))
    .environmentObject(expenseViewModel)
    .environmentObject(profileViewModel)
}
