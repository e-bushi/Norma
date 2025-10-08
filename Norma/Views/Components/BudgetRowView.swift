//
//  BudgetRowView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct BudgetRowView: View {
    @EnvironmentObject private var sessionViewModel: SessionViewModel

    let budget: Budget
    let spent: Double
    let category: Category?

    private var currencySymbol: String {
        let currencyCode = sessionViewModel.currentUser?.settings.currency ?? "USD"
        return CurrencyData.getCurrency(for: currencyCode).symbol
    }

    private var remaining: Double {
        budget.amount - spent
    }

    private var percentageUsed: Double {
        budget.amount > 0 ? (spent / budget.amount) * 100 : 0
    }

    private var statusColor: Color {
        if percentageUsed >= 100 {
            return .red
        } else if percentageUsed >= 80 {
            return .orange
        } else if percentageUsed >= 50 {
            return .yellow
        } else {
            return .green
        }
    }

    private var statusIcon: String {
        if percentageUsed >= 100 {
            return "exclamationmark.triangle.fill"
        } else if percentageUsed >= 80 {
            return "exclamationmark.circle.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }

    var body: some View {
        HStack {
            // Icon and Budget Name Section
            HStack(spacing: 12) {
                Image(systemName: category?.icon ?? "target")
                    .font(.system(size: 16))
                    .foregroundColor(category?.color ?? .blue)
                    .frame(width: 40, height: 40)
                    .background((category?.color ?? .blue).opacity(0.2))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        // Progress indicator
                        HStack(spacing: 4) {
                            Image(systemName: statusIcon)
                                .font(.caption)
                                .foregroundColor(statusColor)

                            Text("\(Int(percentageUsed))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        if let endDate = budget.endDate {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("Ends \(endDate, format: .dateTime.month().day())")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }

            Spacer()

            // Amount Section
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(currencySymbol)\(spent, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("of \(currencySymbol)\(budget.amount, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
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
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
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
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)

    let sampleBudget = Budget(
        userId: "preview-user",
        name: "Groceries",
        amount: 500,
        categoryId: "grocery-cat",
        startDate: Date(),
        endDate: nil,
        isActive: true,
        alertThreshold: 0.8,
        notes: nil
    )

    let sampleCategory = Category(
        name: "Groceries",
        type: .expense,
        icon: "cart.fill",
        colorHex: "#4CAF50"
    )

    return VStack(spacing: 16) {
        // Good progress
        BudgetRowView(budget: sampleBudget, spent: 150, category: sampleCategory)

        // Medium progress
        BudgetRowView(budget: sampleBudget, spent: 300, category: sampleCategory)

        // Near limit
        BudgetRowView(budget: sampleBudget, spent: 425, category: sampleCategory)

        // Over budget
        BudgetRowView(budget: sampleBudget, spent: 550, category: sampleCategory)
    }
    .padding()
    .environmentObject(sessionViewModel)
}
