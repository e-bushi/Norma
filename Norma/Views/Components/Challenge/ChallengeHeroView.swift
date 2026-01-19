//
//  ChallengeHeroView.swift
//  Norma
//
//  Created by Claude on 12/30/25.
//

import SwiftUI

/// Hero section for the Challenges view showing amount remaining
struct ChallengeHeroView: View {
    let challenge: Challenge
    let stats: ChallengeStats?
    let totalPoints: Int
    let tierFileName: String
    var onPointsTapped: (() -> Void)? = nil
    @EnvironmentObject var profileViewModel: ProfileViewModel

    private var formattedAmount: String {
        profileViewModel.formatCurrency(challenge.amountRemaining)
    }

    private var daysRemainingText: String {
        let days = challenge.daysRemaining
        if days == 1 {
            return "1 day remaining"
        } else {
            return "\(days) days remaining"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Amount remaining display with subtle glow
            HStack(spacing: 8) {
                Text(formattedAmount)
                    .font(.normaHeadline(72))
                    .foregroundColor(.primary)
                    .shadow(color: Color("NormaPastelTeal").opacity(0.25), radius: 20, y: 4)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: formattedAmount)

                Text("left")
                    .font(.normaHeadline(32))
                    .foregroundColor(.secondary)
            }

            // Days remaining, difficulty, and points badges
            HStack(spacing: 10) {
                // Days remaining capsule
                Text(daysRemainingText)
                    .font(.normaFinancial(14))
                    .foregroundColor(Color("NormaPastelTeal"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color("NormaPastelTeal").opacity(0.15))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color("NormaPastelTeal").opacity(0.3), lineWidth: 0.5)
                    )

                // Difficulty badge
                HStack(spacing: 6) {
                    Image(systemName: challenge.difficulty.icon)
                        .font(.system(size: 12))
                    Text(challenge.difficulty.displayName.uppercased())
                        .font(.custom(FontFamily.Rubik.medium, size: 11))
                        .tracking(1)
                }
                .foregroundColor(challenge.difficulty.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(challenge.difficulty.color.opacity(0.12))
                )

                // Points capsule (tappable to view bird collection)
                Button {
                    onPointsTapped?()
                } label: {
                    HStack(spacing: 4) {
                        NavBarBird3DView(fileName: tierFileName)
                            .id(tierFileName)
                            .frame(width: 18, height: 18)

                        Text("\(totalPoints) pts")
                            .font(.normaFinancial(12))
                            .foregroundColor(.primary)
                            .contentTransition(.numericText(countsDown: false))
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: totalPoints)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.08))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

#Preview {
    ChallengeHeroView(
        challenge: Challenge(
            userId: "test",
            amountTotal: 500,
            amountRemaining: 247,
            currency: "USD",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            status: .active,
            difficulty: .medium
        ),
        stats: ChallengeStats(userId: "test", totalPoints: 42),
        totalPoints: 42,
        tierFileName: ChallengeTier.starter.fileName
    )
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}
