//
//  MiniExpenseCardView.swift
//  Norma
//
//  Created by Claude on 12/4/25.
//

import SwiftUI

struct MiniExpenseCardView: View {
    let expenses: [Expense]
    let currency: String

    private let maxItemsToShow = 5

    private var displayedExpenses: [Expense] {
        Array(expenses.prefix(maxItemsToShow))
    }

    private var remainingCount: Int {
        max(0, expenses.count - maxItemsToShow)
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(displayedExpenses) { expense in
                MiniExpenseRow(expense: expense, currency: currency)
            }

            // Show "more" indicator if there are additional items
            if remainingCount > 0 {
                HStack {
                    Spacer()
                    Text("+\(remainingCount) more")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
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

struct MiniExpenseRow: View {
    let expense: Expense
    let currency: String

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: expense.amount)) ?? "$\(Int(expense.amount))"
    }

    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let dateFormatter = ISO8601DateFormatter()
        guard let expenseDate = dateFormatter.date(from: expense.expenseDate) else {
            return "Unknown"
        }
        return formatter.localizedString(for: expenseDate, relativeTo: Date())
    }

    private var paymentIcon: String {
        switch expense.paymentMethod {
        case .cash: return "banknote"
        case .creditCard: return "creditcard.fill"
        case .debitCard: return "creditcard"
        case .bankTransfer: return "building.columns"
        case .digitalWallet: return "iphone"
        case .check: return "doc.text"
        case .other: return "dollarsign.circle"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Payment method icon
            Circle()
                .fill(Color("NormaPastelCoral").opacity(0.15))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: paymentIcon)
                        .font(.system(size: 14))
                        .foregroundColor(Color("NormaPastelCoral"))
                )

            // Expense info
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                Text(timeAgoText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Amount
            Text(formattedAmount)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    let dateFormatter = ISO8601DateFormatter()

    return VStack(spacing: 20) {
        MiniExpenseCardView(
            expenses: [
                Expense(userId: "user", name: "Groceries", amount: 85.50, expenseDate: dateFormatter.string(from: Date()), paymentMethod: .creditCard),
                Expense(userId: "user", name: "Gas", amount: 45.00, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400)), paymentMethod: .debitCard),
                Expense(userId: "user", name: "Coffee", amount: 5.75, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 2)), paymentMethod: .digitalWallet)
            ],
            currency: "USD"
        )
    }
    .padding()
    .background(Color("NormaBackground"))
}
