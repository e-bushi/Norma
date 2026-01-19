//
//  MiniChallengeCardView.swift
//  Norma
//
//  Created by Claude on 12/22/25.
//

import SwiftUI

struct MiniChallengeCardView: View {
    let challenge: Challenge
    let currency: String

    private var formattedRemaining: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: challenge.amountRemaining)) ?? "$\(Int(challenge.amountRemaining))"
    }

    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: challenge.amountTotal)) ?? "$\(Int(challenge.amountTotal))"
    }

    private var statusColor: Color {
        switch challenge.status {
        case .completed:
            return Color("NormaPastelTeal")
        case .failed:
            return .red
        case .active:
            if challenge.isOverBudget {
                return .red
            } else if challenge.percentageRemaining < 20 {
                return .orange
            } else {
                return Color("NormaPastelPurple")
            }
        }
    }

    private var statusText: String {
        switch challenge.status {
        case .completed:
            return "Completed"
        case .failed:
            return "Over budget"
        case .active:
            return "Active"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with status badge
            HStack {
                Text(statusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.15))
                    )

                Spacer()

                // Days remaining
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text(challenge.formattedDaysRemaining)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.secondary)
            }

            // Main amount display
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedRemaining)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(statusColor)

                Text("left of \(formattedTotal)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 8)

                    // Progress (remaining percentage)
                    let progress = max(0, min(1, challenge.percentageRemaining / 100))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            // Date range
            HStack {
                Text(formatDate(challenge.startDate))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                Text(formatDate(challenge.endDate))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(statusColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Active challenge
        MiniChallengeCardView(
            challenge: Challenge(
                userId: "user",
                amountTotal: 500,
                amountRemaining: 247,
                currency: "USD",
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                status: .active
            ),
            currency: "USD"
        )

        // Nearly depleted challenge
        MiniChallengeCardView(
            challenge: Challenge(
                userId: "user",
                amountTotal: 500,
                amountRemaining: 45,
                currency: "USD",
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                status: .active
            ),
            currency: "USD"
        )
    }
    .padding()
    .background(Color("NormaBackground"))
}
