//
//  QuickActionsHubView.swift
//  Norma
//
//  Created by Claude on 3/2/26.
//

import SwiftUI

struct QuickActionsHubView: View {
    // Callbacks
    var onShowBills: () -> Void = {}
    var onShowActivity: () -> Void = {}
    var onShowExpenses: () -> Void = {}
    var onShowPendingTransactions: () -> Void = {}

    // Badge counts
    var pendingTransactionsCount: Int = 0

    var body: some View {
        VStack(spacing: 4) {
            actionRow(icon: "doc.text.fill", title: "Bills") {
                onShowBills()
            }
            actionRow(icon: "chart.line.uptrend.xyaxis", title: "Activity") {
                onShowActivity()
            }
            actionRow(icon: "creditcard.fill", title: "Expenses") {
                onShowExpenses()
            }
            actionRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Pending Transactions",
                badge: pendingTransactionsCount > 0 ? pendingTransactionsCount : nil
            ) {
                onShowPendingTransactions()
            }
        }
    }

    @ViewBuilder
    private func actionRow(
        icon: String,
        title: String,
        badge: Int? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary.opacity(0.7))
                    .frame(width: 22)

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                if let badge = badge {
                    Text("\(badge)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color("NormaPastelCoral")))
                }

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickActionsHubView()
        .padding()
        .background(Color("NormaBackground"))
        .preferredColorScheme(.dark)
}
