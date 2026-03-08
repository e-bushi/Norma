//
//  QuickActionsHubView.swift
//  Norma
//
//  Created by Claude on 3/2/26.
//

import SwiftUI

struct QuickActionsHubView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var billViewModel: BillViewModel

    @State private var expandedAction: QuickAction?

    // Badge counts
    @State private var pendingTransactionCount: Int = 0
    @State private var overdueCount: Int = 0
    @State private var reminderCount: Int = 0

    // Callbacks
    var onInsertText: (String) -> Void = { _ in }
    var onShowPendingTransactions: () -> Void = {}

    private enum QuickAction: String, CaseIterable {
        case logExpense
        case setReminder
        case checkBill
        case pendingTransactions
        case currencyConversion
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private var activeBills: [Bill] {
        billViewModel.bills.filter { $0.status == .scheduled || $0.status == .overdue }
            .sorted { $0.dueDate < $1.dueDate }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(Int(amount))"
    }

    var body: some View {
        VStack(spacing: 4) {
            actionRow(action: .logExpense, icon: "plus.circle.fill", iconColor: Color("NormaPastelTeal"), title: "Log an Expense")
            actionRow(action: .setReminder, icon: "bell.fill", iconColor: Color("NormaPastelPurple"), title: "Set a Reminder", badge: reminderCount > 0 ? reminderCount : nil)
            actionRow(action: .checkBill, icon: "doc.text.fill", iconColor: Color("NormaPastelCoral"), title: "Check/Update a Bill", badge: overdueCount > 0 ? overdueCount : nil)
            actionRow(action: .pendingTransactions, icon: "clock.arrow.circlepath", iconColor: Color("NormaPastelPurple").opacity(0.8), title: "Pending Transactions", badge: pendingTransactionCount > 0 ? pendingTransactionCount : nil)
            actionRow(action: .currencyConversion, icon: "coloncurrencysign.arrow.trianglehead.counterclockwise.rotate.90", iconColor: Color("NormaPastelTeal").opacity(0.8), title: "Currency Conversion")
        }
        .task {
            let reminders = await NotificationService.shared.getPendingAIReminders()
            reminderCount = reminders.count
            pendingTransactionCount = dataManager.getPendingTransactionsCount()
            overdueCount = billViewModel.overdueBills.count
        }
    }

    // MARK: - Action Row

    @ViewBuilder
    private func actionRow(
        action: QuickAction,
        icon: String,
        iconColor: Color,
        title: String,
        badge: Int? = nil
    ) -> some View {
        let isExpanded = expandedAction == action
        let isExpandable = action == .checkBill

        VStack(spacing: 0) {
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()

                switch action {
                case .logExpense:
                    onInsertText("I need to log an expense")
                case .setReminder:
                    onInsertText("Remind me to ")
                case .pendingTransactions:
                    onShowPendingTransactions()
                case .currencyConversion:
                    onInsertText("How much is 100 USD in EUR?")
                case .checkBill:
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        expandedAction = isExpanded ? nil : action
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                        .frame(width: 22)

                    Text(title)
                        .font(.custom(FontFamily.Rubik.medium, size: 16))
                        .foregroundColor(.primary)

                    Spacer()

                    if let badge = badge {
                        Text("\(badge)")
                            .font(.custom(FontFamily.Rubik.medium, size: 11))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color("NormaPastelCoral")))
                    }

                    if isExpandable {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    } else {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .padding(.horizontal, 10)

                billListContent
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Bill List Content

    private var billListContent: some View {
        VStack(spacing: 6) {
            if activeBills.isEmpty {
                Text("No active bills")
                    .font(.custom(FontFamily.Rubik.regular, size: 15))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 6)
                    .transition(.opacity)
            } else {
                ForEach(Array(activeBills.prefix(5).enumerated()), id: \.element.id) { index, bill in
                    billRow(bill: bill)
                        .transition(.asymmetric(
                            insertion: .opacity
                                .combined(with: .move(edge: .leading))
                                .animation(.spring(response: 0.35, dampingFraction: 0.75).delay(Double(index) * 0.06)),
                            removal: .opacity.animation(.easeOut(duration: 0.15))
                        ))
                }
            }
        }
    }

    private func billRow(bill: Bill) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(bill.name)
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundColor(.primary)
                Text(formatCurrency(bill.amount))
                    .font(.normaFinancial(13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                Task {
                    await billViewModel.markBillAsPaid(bill)
                    overdueCount = billViewModel.overdueBills.count
                }
            } label: {
                Text("Mark Paid")
                    .font(.custom(FontFamily.Rubik.medium, size: 13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color("NormaPastelTeal"))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)

    QuickActionsHubView()
        .padding()
        .background(Color("NormaBackground"))
        .environmentObject(dataManager)
        .environmentObject(sessionViewModel)
        .environmentObject(BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        .preferredColorScheme(.dark)
}
