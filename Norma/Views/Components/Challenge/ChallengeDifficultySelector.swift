//
//  ChallengeDifficultySelector.swift
//  Norma
//
//  Created by Claude on 12/30/25.
//

import SwiftUI

/// Difficulty selector for starting a new challenge
struct ChallengeDifficultySelector: View {
    @Binding var selectedDifficulty: ChallengeDifficulty
    let streakMultiplier: Double
    let onStartChallenge: () -> Void

    private var pointsWithBonus: Int {
        Int(Double(selectedDifficulty.pointReward) * streakMultiplier)
    }

    var body: some View {
        VStack(spacing: 32) {
            // Difficulty cards
            HStack(spacing: 16) {
                ForEach(ChallengeDifficulty.allCases, id: \.self) { difficulty in
                    DifficultyCard(
                        difficulty: difficulty,
                        isSelected: selectedDifficulty == difficulty
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selectedDifficulty = difficulty
                        }
                    }
                }
            }

            // Start button with points
            VStack(spacing: 16) {
                Button {
                    onStartChallenge()
                } label: {
                    Text("Start Challenge")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selectedDifficulty.color)
                        )
                }

                // Points and streak info as pill badges
                HStack(spacing: 12) {
                    // Points pill
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 13))
                        Text("\(pointsWithBonus) points")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(selectedDifficulty.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selectedDifficulty.color.opacity(0.12))
                    )

                    // Streak pill (only if multiplier > 1)
                    if streakMultiplier > 1 {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 13))
                            Text("\(streakMultiplier, specifier: "%.1f")x streak")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(Color("NormaPastelCoral"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color("NormaPastelCoral").opacity(0.12))
                        )
                    }
                }
            }
        }
    }
}

/// Individual difficulty card - minimal design
struct DifficultyCard: View {
    let difficulty: ChallengeDifficulty
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Large icon
            Image(systemName: difficulty.icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(isSelected ? difficulty.color : Color.secondary.opacity(0.6))

            // Name
            Text(difficulty.displayName)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? difficulty.color.opacity(0.12) : Color.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? difficulty.color.opacity(0.4) : Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    VStack {
        Spacer()

        ChallengeDifficultySelector(
            selectedDifficulty: .constant(.medium),
            streakMultiplier: 1.5
        ) {
            print("Start challenge")
        }
        .padding(.horizontal, 20)

        Spacer()
    }
    .background(Color("NormaBackground"))
}
