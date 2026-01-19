//
//  ChallengeStatsRow.swift
//  Norma
//
//  Created by Claude on 12/30/25.
//

import SwiftUI

/// A conversational row showing challenge stats with inline colored SF symbols
struct ChallengeStatsRow: View {
    let currentStreak: Int
    let formattedDailyCap: String
    let formattedTodaySpent: String
    let formattedRemaining: String
    let isOverBudget: Bool


    private var boldFont: Font { Font.custom(FontFamily.Rubik.semiBold, size: 22) }

    // Streak color: gray if zero, pastel purple if active
    private var streakColor: Color {
        currentStreak > 0 ? Color("NormaPastelPurple") : Color.gray
    }

    private var streakText: Text {
        Text("You're on a ").font(boldFont)
        + Text(Image(systemName: "flame.fill")).foregroundColor(streakColor)
        + Text(" \(currentStreak) day streak").font(boldFont).foregroundColor(streakColor)
        + Text(" staying under the daily cap.").font(boldFont)
    }

    private var capText: Text {
        Text(" Today's cap is ").font(boldFont)
        + Text(Image(systemName: "target")).foregroundColor(Color("NormaPastelTeal"))
        + Text(" \(formattedDailyCap)").font(boldFont).foregroundColor(Color("NormaPastelTeal"))
        + Text(" — spent ").font(boldFont)
        + Text(" \(formattedTodaySpent)").font(boldFont).foregroundColor(Color("NormaPastelCoral"))
        + Text(" so far.").font(boldFont)
    }

    private var remainingText: Text {
        if isOverBudget {
            return Text(" Over by ").font(boldFont)
            + Text(Image(systemName: "exclamationmark.triangle.fill")).foregroundColor(Color("NormaPastelCoral"))
            + Text(" \(formattedRemaining)").font(boldFont).foregroundColor(Color("NormaPastelCoral"))
        } else {
            return Text(" ").font(boldFont)
            + Text(Image(systemName: "checkmark.circle.fill")).foregroundColor(Color("NormaPastelTeal"))
            + Text(" \(formattedRemaining)").font(boldFont).foregroundColor(Color("NormaPastelTeal"))
            + Text(" left today.").font(boldFont)
        }
    }

    /// Unique identifier for the current stats state (triggers animation on change)
    private var statsIdentifier: String {
        "\(currentStreak)-\(formattedDailyCap)-\(formattedTodaySpent)-\(formattedRemaining)"
    }

    var body: some View {
        (streakText + capText + remainingText)
            .multilineTextAlignment(.center)
            .lineSpacing(7)
            .padding(.horizontal, 12)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: statsIdentifier)
    }
}

/// Compact version for smaller spaces
struct ChallengeStatsRowCompact: View {
    let currentStreak: Int
    let totalPoints: Int
    let pointsToNextTier: Int

    var body: some View {
        HStack(spacing: 16) {
            // Streak
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color("NormaPastelCoral"))
                Text("\(currentStreak)")
                    .font(.normaFinancial(14))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStreak)
            }

            // Points
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color("NormaPastelTeal"))
                Text("\(totalPoints) pts")
                    .font(.normaFinancial(14))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: totalPoints)
            }

            Spacer()

            // Next tier
            if pointsToNextTier > 0 {
                Text("\(pointsToNextTier) to next tier")
                    .font(.normaInput(12))
                    .foregroundColor(.secondary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: pointsToNextTier)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

#Preview {
    VStack(spacing: 24) {
        ChallengeStatsRow(
            currentStreak: 5,
            formattedDailyCap: "$45",
            formattedTodaySpent: "$32",
            formattedRemaining: "$13",
            isOverBudget: false
        )
        .padding(.horizontal, 20)

        ChallengeStatsRow(
            currentStreak: 0,
            formattedDailyCap: "$45",
            formattedTodaySpent: "$52",
            formattedRemaining: "$7",
            isOverBudget: true
        )
        .padding(.horizontal, 20)

        ChallengeStatsRowCompact(
            currentStreak: 5,
            totalPoints: 42,
            pointsToNextTier: 18
        )
    }
    .padding()
}
