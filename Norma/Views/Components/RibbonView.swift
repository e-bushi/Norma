//
//  RibbonView.swift
//  Norma
//
//  Created by Claude on 4/25/26.
//
//  Compact summary ribbon used when a note carries multiple kind groups.
//  One row per kind: solid border for expense, dashed for bill.

import SwiftUI

struct RibbonView: View {
    let kind: NoteToken.Kind
    let tokens: [NoteToken]
    var onTap: (() -> Void)? = nil

    private let ribbonHeight: CGFloat = 50
    private let ridgeOffset: CGFloat = 7

    var body: some View {
        ZStack(alignment: .top) {
            ridge
                .padding(.horizontal, 24)
                .offset(y: 0)
            ridge
                .padding(.horizontal, 12)
                .offset(y: ridgeOffset)
            ribbonRow
                .offset(y: ridgeOffset * 2)
        }
        .frame(height: ribbonHeight + ridgeOffset * 2)
    }

    private var ridge: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 6, bottomLeadingRadius: 0,
            bottomTrailingRadius: 0, topTrailingRadius: 6
        )
        .stroke(
            NormaPalette.lavender.opacity(0.45),
            style: StrokeStyle(lineWidth: 1, dash: dashPattern)
        )
        .frame(height: 4)
    }

    private var ribbonRow: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(NormaPalette.lavender)
                    .frame(width: 6, height: 6)

                Text(kindLabel)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.6)
                    .foregroundStyle(NormaPalette.lavender)

                Text("·")
                    .font(.system(size: 11))
                    .foregroundStyle(NormaPalette.lavender.opacity(0.55))

                Text(countLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(NormaPalette.lavenderText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(formattedTotal)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(NormaPalette.lavenderText)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NormaPalette.lavender.opacity(0.7))
                    .padding(.leading, 2)
            }
            .padding(.horizontal, 18)
            .frame(height: ribbonHeight)
            .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        NormaPalette.lavender.opacity(0.7),
                        style: StrokeStyle(lineWidth: 1, dash: dashPattern)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var dashPattern: [CGFloat] { kind == .bill ? [4, 3] : [] }

    private var kindLabel: String {
        switch kind {
        case .expense: return "EXPENSES"
        case .bill: return "BILLS"
        case .income: return "INCOME"
        case .transfer: return "TRANSFERS"
        case .reminder: return "REMINDERS"
        }
    }

    private var countLabel: String {
        let count = tokens.count
        switch kind {
        case .bill:
            let monthly = tokens.filter { $0.recurrence == .monthly }.count
            if monthly == count { return "\(count) monthly" }
            return "\(count) recurring"
        default:
            return "\(count) entries"
        }
    }

    private var formattedTotal: String {
        guard let primary = tokens.first?.currency else { return "" }
        let same = tokens.allSatisfy { $0.currency == primary }
        guard same else {
            let usd = tokens.reduce(0.0) { $0 + ($1.usdEquivalent ?? 0) }
            return "$\(NormaPalette.thousandsSeparated(String(format: "%.2f", usd)))"
        }
        let total = tokens.reduce(0.0) { $0 + $1.amount }
        let symbol = NormaPalette.currencySymbol(for: primary)
        let body = NormaPalette.thousandsSeparated(String(format: "%.0f", total))
        switch primary.uppercased() {
        case "USD", "CAD", "AUD", "NZD":
            return "\(symbol)\(body)"
        default:
            return "\(body)\(symbol)"
        }
    }
}
