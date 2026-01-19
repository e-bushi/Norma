//
//  CapTrendIndicator.swift
//  Norma
//
//  Created by Claude on 1/17/26.
//

import SwiftUI

/// Visual indicator showing how the daily cap has changed due to previous spending behavior
struct CapTrendIndicator: View {
    let capChange: Double  // Positive = cap increased (banked budget), Negative = cap decreased
    let initialCap: Double  // What the cap would be without any banking
    let formatCurrency: (Double) -> String

    private var isPositive: Bool { capChange > 0 }
    private var isNegative: Bool { capChange < 0 }
    private var isNeutral: Bool { abs(capChange) < 0.01 }

    private var trendColor: Color {
        if isPositive {
            return Color("NormaPastelTeal")
        } else if isNegative {
            return Color("NormaPastelCoral")
        } else {
            return Color.gray
        }
    }

    private var arrowIcon: String {
        if isPositive {
            return "arrow.up.circle.fill"
        } else if isNegative {
            return "arrow.down.circle.fill"
        } else {
            return "equal.circle.fill"
        }
    }

    private var trendText: String {
        if isPositive {
            return "Cap up \(formatCurrency(capChange))"
        } else if isNegative {
            return "Cap down \(formatCurrency(abs(capChange)))"
        } else {
            return "On track"
        }
    }

    private var subtitleText: String {
        if isPositive {
            return "from staying under yesterday's cap"
        } else if isNegative {
            return "from going over yesterday's cap"
        } else {
            return "spending matches your pace"
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            // Main trend row
            HStack(spacing: 8) {
                Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(trendColor)

                Text(trendText)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                    .foregroundColor(trendColor)
            }

            // Subtitle
            Text(subtitleText)
                .font(.custom(FontFamily.Rubik.regular, size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.clear)
                .glassEffect(in: Capsule())
        )
        .overlay(
            Capsule()
                .stroke(trendColor.opacity(0.25), lineWidth: 0.5)
        )
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 16) {
        CapTrendIndicator(
            capChange: 22.50,
            initialCap: 200.00,
            formatCurrency: { String(format: "$%.2f", $0) }
        )

        CapTrendIndicator(
            capChange: -15.00,
            initialCap: 200.00,
            formatCurrency: { String(format: "$%.2f", $0) }
        )

        CapTrendIndicator(
            capChange: 0,
            initialCap: 200.00,
            formatCurrency: { String(format: "$%.2f", $0) }
        )
    }
    .padding()
    .background(Color("NormaBackground"))
}
