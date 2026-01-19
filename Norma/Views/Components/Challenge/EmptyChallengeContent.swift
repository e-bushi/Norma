//
//  EmptyChallengeContent.swift
//  Norma
//
//  Created by Claude on 1/17/26.
//

import SwiftUI

/// Content shown when there's no active challenge
struct EmptyChallengeContent: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel

    @State private var birdAppeared = false
    @State private var textAppeared = false
    @State private var selectorAppeared = false

    var body: some View {
        if challengeViewModel.canCreateChallenge {
            StartJourneyContent(
                birdAppeared: $birdAppeared,
                textAppeared: $textAppeared,
                selectorAppeared: $selectorAppeared
            )
            .onAppear {
                animateEntrance()
            }
        } else {
            ChallengeCooldownContent()
        }
    }

    private func animateEntrance() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            birdAppeared = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            textAppeared = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35)) {
            selectorAppeared = true
        }
    }
}

// MARK: - Start Journey Content

struct StartJourneyContent: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel

    @Binding var birdAppeared: Bool
    @Binding var textAppeared: Bool
    @Binding var selectorAppeared: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 40)

            // Hero: Large 3D Bird
            StaticBird3DView(fileName: ChallengeTier.starter.fileName)
                .id(ChallengeTier.starter.fileName)
                .frame(width: 180, height: 180)
                .scaleEffect(birdAppeared ? 1 : 0.8)
                .opacity(birdAppeared ? 1 : 0)

            Spacer()
                .frame(height: 32)

            // Text content
            VStack(spacing: 12) {
                Text("Challenge Yourself")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(.primary)

                Text("Stay within budget. Earn rewards.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .opacity(textAppeared ? 1 : 0)
            .offset(y: textAppeared ? 0 : 10)

            Spacer()
                .frame(height: 48)

            // Difficulty Selector
            ChallengeDifficultySelector(
                selectedDifficulty: $challengeViewModel.selectedDifficulty,
                streakMultiplier: challengeViewModel.streakMultiplier
            ) {
                Task {
                    await challengeViewModel.startNewChallenge()
                }
            }
            .opacity(selectorAppeared ? 1 : 0)
            .offset(y: selectorAppeared ? 0 : 15)

            Spacer(minLength: 60)
        }
    }
}

// MARK: - Previews

#Preview("Start Journey") {
    ScrollView(showsIndicators: false) {
        StartJourneyContent(
            birdAppeared: .constant(true),
            textAppeared: .constant(true),
            selectorAppeared: .constant(true)
        )
        .padding(.horizontal, 20)
    }
    .background(Color("NormaBackground"))
    .environmentObject(ChallengeViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}

#Preview("Empty Challenge Content") {
    EmptyChallengeContent()
        .padding(.horizontal, 20)
        .background(Color("NormaBackground"))
        .environmentObject(ChallengeViewModel(
            dataManager: DataManager(),
            sessionViewModel: SessionViewModel(dataManager: DataManager())
        ))
        .environmentObject(ProfileViewModel(
            dataManager: DataManager(),
            sessionViewModel: SessionViewModel(dataManager: DataManager())
        ))
}
