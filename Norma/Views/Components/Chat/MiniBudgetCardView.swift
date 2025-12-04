//
//  MiniBudgetCardView.swift
//  Norma
//
//  Created by Claude on 12/4/25.
//

import SwiftUI

struct MiniBudgetCardView: View {
    let budgets: [Budget]
    let currency: String

    private let maxItemsToShow = 5

    private var displayedBudgets: [Budget] {
        Array(budgets.prefix(maxItemsToShow))
    }

    private var remainingCount: Int {
        max(0, budgets.count - maxItemsToShow)
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(displayedBudgets) { budget in
                MiniBudgetRow(budget: budget, currency: currency)
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

struct MiniBudgetRow: View {
    let budget: Budget
    let currency: String

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: budget.amount)) ?? "$\(Int(budget.amount))"
    }

    private var formattedSpent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: budget.currentSpent)) ?? "$\(Int(budget.currentSpent))"
    }

    private var spentPercentage: Double {
        guard budget.amount > 0 else { return 0 }
        return min(budget.currentSpent / budget.amount, 1.0)
    }

    private var statusColor: Color {
        if spentPercentage >= 1.0 {
            return .red
        } else if spentPercentage >= budget.alertThreshold {
            return .orange
        } else {
            return Color("NormaPastelPurple")
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Budget icon
            Circle()
                .fill(statusColor.opacity(0.15))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 14))
                        .foregroundColor(statusColor)
                )

            // Budget info
            VStack(alignment: .leading, spacing: 2) {
                Text(budget.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                Text("\(formattedSpent) of \(formattedAmount)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Progress indicator
            Text("\(Int(spentPercentage * 100))%")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(statusColor)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MiniBudgetCardView(
            budgets: [
                Budget(userId: "user", name: "Groceries", amount: 500, startDate: Date(), currentSpent: 320),
                Budget(userId: "user", name: "Entertainment", amount: 200, startDate: Date(), currentSpent: 180),
                Budget(userId: "user", name: "Transport", amount: 150, startDate: Date(), currentSpent: 75)
            ],
            currency: "USD"
        )
    }
    .padding()
    .background(Color("NormaBackground"))
}
