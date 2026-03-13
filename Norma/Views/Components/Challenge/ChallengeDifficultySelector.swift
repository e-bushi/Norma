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

    @State private var displayedPoints: Int = 0
    @State private var displayedStreak: Double = 0
    @State private var hasAppeared = false

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
                        // Animate points change
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            displayedPoints = Int(Double(difficulty.pointReward) * streakMultiplier)
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
                        .font(.custom(FontFamily.Rubik.semiBold, size: 17))
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
                    // Points pill with glass effect
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 13))
                        Text("\(displayedPoints) points")
                            .font(.custom(FontFamily.Rubik.medium, size: 14))
                            .contentTransition(.numericText())
                    }
                    .foregroundColor(selectedDifficulty.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selectedDifficulty.color.opacity(0.12))
                            .glassEffect(in: Capsule())
                    )

                    // Streak pill with glass effect (only if multiplier > 1)
                    if streakMultiplier > 1 {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 13))
                            Text("\(displayedStreak, specifier: "%.1f")x streak")
                                .font(.custom(FontFamily.Rubik.medium, size: 14))
                                .contentTransition(.numericText())
                        }
                        .foregroundColor(Color("NormaPastelCoral"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color("NormaPastelCoral").opacity(0.12))
                                .glassEffect(in: Capsule())
                        )
                    }
                }
            }
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true

            // Animate points from 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    displayedPoints = pointsWithBonus
                }
            }

            // Animate streak from 0 (if applicable)
            if streakMultiplier > 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        displayedStreak = streakMultiplier
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
                .font(.custom(FontFamily.Rubik.medium, size: 15))
                .foregroundColor(isSelected ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? difficulty.color.opacity(0.12) : Color.clear)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 16))

                if isSelected {
                    Canvas { context, size in
                        let spacing: CGFloat = 10
                        let totalLines = Int((size.width + size.height) / spacing) + 1

                        for i in 0..<totalLines {
                            let offset = CGFloat(i) * spacing
                            var path = Path()
                            path.move(to: CGPoint(x: offset, y: 0))
                            path.addLine(to: CGPoint(x: offset - size.height, y: size.height))
                            context.stroke(
                                path,
                                with: .color(difficulty.color.opacity(0.12)),
                                lineWidth: 0.8
                            )
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
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
