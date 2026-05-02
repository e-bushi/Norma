//
//  GroupChipView.swift
//  Norma
//
//  Single capsule that summarizes a group of 3+ same-kind tokens.
//  Replaces the fanned CapsuleStack — count + total live in one pill that
//  matches the visual language of the inline ChipView.
//

import SwiftUI

struct GroupChipView: View {
    let kind: NoteToken.Kind
    let tokens: [NoteToken]

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(NormaPalette.lavender)
                .frame(width: 5, height: 5)

            Text(headerLabel)
                .font(.system(size: 10, weight: .medium))
                .tracking(1.6)
                .foregroundStyle(NormaPalette.lavender)

            separator

            Text(formattedTotal)
                .font(.system(size: 12))
                .foregroundStyle(NormaPalette.lavenderText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .glassEffect(in: Capsule())
        .overlay(Capsule().stroke(NormaPalette.lavender.opacity(0.7), lineWidth: 1))
        .fixedSize(horizontal: true, vertical: true)
    }

    private var separator: some View {
        Text("·")
            .font(.system(size: 10))
            .foregroundStyle(NormaPalette.lavender.opacity(0.55))
    }

    private var headerLabel: String {
        let count = tokens.count
        let noun: String
        switch kind {
        case .expense:  noun = count == 1 ? "EXPENSE"  : "EXPENSES"
        case .bill:     noun = count == 1 ? "BILL"     : "BILLS"
        case .income:   noun = "INCOME"
        case .transfer: noun = count == 1 ? "TRANSFER" : "TRANSFERS"
        case .reminder: noun = count == 1 ? "REMINDER" : "REMINDERS"
        }
        return "\(count) \(noun)"
    }

    private var formattedTotal: String {
        guard let primaryCurrency = tokens.first?.currency else { return "" }
        let same = tokens.allSatisfy { $0.currency == primaryCurrency }
        guard same else {
            let usd = tokens.reduce(0.0) { $0 + ($1.usdEquivalent ?? 0) }
            let body = NormaPalette.thousandsSeparated(formatted(usd))
            return "≈ $\(body)"
        }
        let total = tokens.reduce(0.0) { $0 + $1.amount }
        let symbol = NormaPalette.currencySymbol(for: primaryCurrency)
        let body = NormaPalette.thousandsSeparated(formatted(total))
        let signPrefix = kind == .income ? "+" : ""
        switch primaryCurrency.uppercased() {
        case "USD", "CAD", "AUD", "NZD":
            return "\(signPrefix)\(symbol)\(body)"
        default:
            return "\(signPrefix)\(body)\(symbol)"
        }
    }

    private func formatted(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}
