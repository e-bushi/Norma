//
//  MiniBillCardView.swift
//  Norma
//
//  Created by Claude on 12/4/25.
//

import SwiftUI

struct MiniBillCardView: View {
    let bills: [Bill]
    let currency: String

    private let maxItemsToShow = 5

    private var displayedBills: [Bill] {
        Array(bills.prefix(maxItemsToShow))
    }

    private var remainingCount: Int {
        max(0, bills.count - maxItemsToShow)
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(displayedBills) { bill in
                MiniBillRow(bill: bill, currency: currency)
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

struct MiniBillRow: View {
    let bill: Bill
    let currency: String

    private var statusIcon: String {
        switch bill.status {
        case .paid: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .scheduled: return "calendar.circle.fill"
        }
    }

    private var statusColor: Color {
        switch bill.status {
        case .paid: return Color("NormaPastelTeal")
        case .overdue: return .red
        case .scheduled: return Color("NormaPastelPurple")
        }
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: bill.amount)) ?? "$\(Int(bill.amount))"
    }

    private var dueDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: bill.dueDate)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: statusIcon)
                .font(.system(size: 18))
                .foregroundColor(statusColor)

            // Bill info
            VStack(alignment: .leading, spacing: 2) {
                Text(bill.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                Text("Due \(dueDateText)")
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
    VStack(spacing: 20) {
        MiniBillCardView(
            bills: [
                Bill(id: "1", userId: "user", name: "Netflix", dueDate: Date(), amount: 15.99, status: .scheduled, frequency: .monthly),
                Bill(id: "2", userId: "user", name: "Rent", dueDate: Date().addingTimeInterval(86400 * 5), amount: 1200, status: .scheduled, frequency: .monthly),
                Bill(id: "3", userId: "user", name: "Electric", dueDate: Date().addingTimeInterval(-86400), amount: 85.50, status: .overdue, frequency: .monthly)
            ],
            currency: "USD"
        )
    }
    .padding()
    .background(Color("NormaBackground"))
}
