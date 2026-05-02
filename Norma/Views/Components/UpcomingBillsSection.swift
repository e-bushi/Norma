//
//  UpcomingBillsSection.swift
//  Norma
//
//  Created by Claude on 12/31/25.
//

import SwiftUI

struct UpcomingBillsSection: View {
    @EnvironmentObject var billViewModel: BillViewModel
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.colorScheme) var colorScheme

    private let maxBillsToShow = 2

    private var urgentBills: [Bill] {
        // Get unpaid bills sorted by due date (soonest first)
        billViewModel.upcomingBills
            .filter { bill in
                let status = bill.calculateStatus(from: expenseViewModel.expenses)
                return status != .paid
            }
            .sorted { $0.effectiveDueDate < $1.effectiveDueDate }
    }

    private var displayedBills: [Bill] {
        Array(urgentBills.prefix(maxBillsToShow))
    }

    private var hasMoreBills: Bool {
        urgentBills.count > maxBillsToShow
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text("BILLS DUE")
                    .font(.normaInput(12))
                    .foregroundColor(.secondary)
                    .tracking(1.5)

                Spacer()

                if hasMoreBills {
                    Text("+\(urgentBills.count - maxBillsToShow) more")
                        .font(.normaInput(12))
                        .foregroundColor(.secondary)
                }
            }

            // Bills list
            VStack(spacing: 8) {
                ForEach(displayedBills) { bill in
                    billRow(bill: bill)
                }
            }
        }
    }

    private func billRow(bill: Bill) -> some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor(for: bill))
                .frame(width: 8, height: 8)

            // Bill info
            VStack(alignment: .leading, spacing: 2) {
                Text(bill.name)
                    .font(.normaInput(14))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(formattedDueDate(bill.effectiveDueDate))
                    .font(.normaInput(12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Amount
            Text(profileViewModel.formatCurrency(bill.amount))
                .font(.normaFinancial(16))
                .foregroundColor(.primary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func statusColor(for bill: Bill) -> Color {
        let status = bill.calculateStatus(from: expenseViewModel.expenses)
        switch status {
        case .overdue:
            return Color("NormaPastelCoral")
        case .scheduled:
            // Check if due within 3 days
            let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: bill.effectiveDueDate).day ?? 0
            if daysUntilDue <= 3 {
                return Color("NormaPastelCoral").opacity(0.7)
            }
            return Color("NormaPastelTeal")
        case .paid:
            return Color("NormaPastelTeal")
        }
    }

    private func formattedDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: date)
        let daysUntil = calendar.dateComponents([.day], from: today, to: dueDay).day ?? 0

        if daysUntil < 0 {
            return "Overdue"
        } else if daysUntil == 0 {
            return "Due today"
        } else if daysUntil == 1 {
            return "Due tomorrow"
        } else if daysUntil <= 7 {
            return "Due in \(daysUntil) days"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "Due \(formatter.string(from: date))"
        }
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let billViewModel = BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let expenseViewModel = ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)

    return UpcomingBillsSection()
        .environmentObject(billViewModel)
        .environmentObject(expenseViewModel)
        .environmentObject(profileViewModel)
        .padding()
        .background(Color("NormaBackground"))
}
