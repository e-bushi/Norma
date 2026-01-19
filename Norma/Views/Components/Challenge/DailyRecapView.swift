//
//  DailyRecapView.swift
//  Norma
//
//  Created by Claude on 1/17/26.
//

import SwiftUI

/// Data model for daily recap information
struct DailyRecapData {
    let date: Date
    let dailyCap: Double
    let amountSpent: Double
    let wasUnderCap: Bool
    let pointsEarned: Int
    let previousStreak: Int
    let currentStreak: Int
    let streakBroken: Bool

    var amountDifference: Double {
        dailyCap - amountSpent
    }

    var percentOfCap: Double {
        guard dailyCap > 0 else { return 0 }
        return (amountSpent / dailyCap) * 100
    }
}

/// Sheet view showing yesterday's challenge performance
struct DailyRecapView: View {
    let recapData: DailyRecapData
    let formatCurrency: (Double) -> String
    let onDismiss: () -> Void

    @State private var iconAppeared = false
    @State private var headlineAppeared = false
    @State private var sentenceAppeared = false
    @State private var buttonAppeared = false

    private var isSuccess: Bool {
        recapData.wasUnderCap
    }

    private var accentColor: Color {
        isSuccess ? Color("NormaPastelTeal") : Color.orange
    }

    private var iconName: String {
        isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
    }

    private var headline: String {
        isSuccess ? "Nailed it" : "Fresh start ahead"
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let day = formatter.string(from: recapData.date)
        return "\(day)'s Recap"
    }

    private var recapSentence: String {
        let spent = formatCurrency(recapData.amountSpent)
        let cap = formatCurrency(recapData.dailyCap)
        let diff = formatCurrency(abs(recapData.amountDifference))

        if isSuccess {
            if recapData.pointsEarned > 0 {
                return "You spent \(spent) of your \(cap) cap and earned \(recapData.pointsEarned) points."
            } else {
                return "You spent \(spent) of your \(cap) cap."
            }
        } else {
            return "You went \(diff) over your \(cap) cap."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            // Centered content area
            Spacer()

            VStack(spacing: 0) {
                // Icon - pops in with bounce
                Image(systemName: iconName)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(accentColor)
                    .opacity(iconAppeared ? 1 : 0)
                    .scaleEffect(iconAppeared ? 1 : 0.3)

                Spacer()
                    .frame(height: 24)

                // Headline - pops in with bounce
                Text(headline)
                    .font(.normaTitle(28))
                    .foregroundColor(.primary)
                    .opacity(headlineAppeared ? 1 : 0)
                    .scaleEffect(headlineAppeared ? 1 : 0.7)

                Spacer()
                    .frame(height: 8)

                // Day name - fades with headline
                Text(dayName)
                    .font(.normaSubheadline(15))
                    .foregroundColor(.secondary)
                    .opacity(headlineAppeared ? 1 : 0)

                Spacer()
                    .frame(height: 20)

                // Recap sentence - wave animation
                WaveTextView(
                    text: recapSentence,
                    font: .normaFinancial(20),
                    color: .primary,
                    isAnimating: sentenceAppeared
                )
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

                // Streak indicator (if active and not broken)
                if recapData.currentStreak > 1 && !recapData.streakBroken {
                    Spacer()
                        .frame(height: 24)

                    streakIndicator
                        .opacity(sentenceAppeared ? 1 : 0)
                }
            }

            Spacer()

            // Continue button - pops in with bounce
            Button {
                onDismiss()
            } label: {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accentColor)
                    )
            }
            .opacity(buttonAppeared ? 1 : 0)
            .scaleEffect(buttonAppeared ? 1 : 0.9)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("NormaBackground"))
        .onAppear {
            animateEntrance()
        }
    }

    @ViewBuilder
    private var streakIndicator: some View {
        if recapData.currentStreak > 1 {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                Text("\(recapData.currentStreak) day streak")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(Color("NormaPastelCoral"))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color("NormaPastelCoral").opacity(0.12))
            )
        }
    }

    private func animateEntrance() {
        // Icon pops in with bouncy spring
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
            iconAppeared = true
        }
        // Headline pops in with bounce
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65).delay(0.15)) {
            headlineAppeared = true
        }
        // Trigger wave text animation (WaveTextView handles its own animation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            sentenceAppeared = true
        }
        // Button pops in after wave animation completes (~1.2s + 0.4s delay)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(1.3)) {
            buttonAppeared = true
        }
    }
}

// MARK: - Previews

#Preview("Under Budget") {
    DailyRecapView(
        recapData: DailyRecapData(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            dailyCap: 100,
            amountSpent: 72.50,
            wasUnderCap: true,
            pointsEarned: 10,
            previousStreak: 4,
            currentStreak: 5,
            streakBroken: false
        ),
        formatCurrency: { String(format: "$%.2f", $0) },
        onDismiss: {}
    )
}

#Preview("Over Budget") {
    DailyRecapView(
        recapData: DailyRecapData(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            dailyCap: 100,
            amountSpent: 127.30,
            wasUnderCap: false,
            pointsEarned: 0,
            previousStreak: 3,
            currentStreak: 0,
            streakBroken: false
        ),
        formatCurrency: { String(format: "$%.2f", $0) },
        onDismiss: {}
    )
}
