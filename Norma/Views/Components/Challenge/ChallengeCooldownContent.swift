//
//  ChallengeCooldownContent.swift
//  Norma
//
//  Created by Claude on 1/17/26.
//

import SwiftUI

/// Content shown when user has already started a challenge today (cooldown state)
struct ChallengeCooldownContent: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @State private var iconAppeared = false
    @State private var textAppeared = false
    @State private var statsAppeared = false
    @State private var showBirdCollection = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon - simple, no backdrop
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(Color("NormaPastelTeal"))
                .scaleEffect(iconAppeared ? 1 : 0.8)
                .opacity(iconAppeared ? 1 : 0)

            Spacer()
                .frame(height: 32)

            // Title & subtitle
            VStack(spacing: 12) {
                Text("See You Tomorrow")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)

                Text("New challenges unlock daily.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .opacity(textAppeared ? 1 : 0)
            .offset(y: textAppeared ? 0 : 10)

            Spacer()
                .frame(height: 40)

            // Stats as pill badges
            HStack(spacing: 12) {
                StatPill(
                    icon: "flame.fill",
                    value: "\(challengeViewModel.currentStreak)",
                    label: "streak",
                    color: Color("NormaPastelCoral")
                )

                StatPill(
                    icon: "star.fill",
                    value: "\(challengeViewModel.totalPoints)",
                    label: "points",
                    color: Color("NormaPastelTeal")
                )

                StatPill(
                    icon: "bird.fill",
                    value: "\(challengeViewModel.unlockedTierCount)",
                    label: "birds",
                    color: Color("NormaPastelLavender")
                )
            }
            .frame(maxWidth: .infinity)
            .opacity(statsAppeared ? 1 : 0)
            .offset(y: statsAppeared ? 0 : 10)

            Spacer()
                .frame(height: 48)

            // View Collection Button
            Button {
                showBirdCollection = true
            } label: {
                Text("View Collection")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("NormaPastelTeal"))
                    )
            }
            .opacity(statsAppeared ? 1 : 0)
            .offset(y: statsAppeared ? 0 : 10)

            Spacer()
        }
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                iconAppeared = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15)) {
                textAppeared = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                statsAppeared = true
            }
        }
        .sheet(isPresented: $showBirdCollection) {
            BirdCollectionView(totalPoints: challengeViewModel.totalPoints)
        }
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
            Text("\(value) \(label)")
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }
}

// MARK: - Previews

#Preview("Cooldown State") {
    ChallengeCooldownContent()
        .background(Color("NormaBackground"))
        .environmentObject(ChallengeViewModel(
            dataManager: DataManager(),
            sessionViewModel: SessionViewModel(dataManager: DataManager())
        ))
}

#Preview("Stat Pills") {
    HStack(spacing: 12) {
        StatPill(icon: "flame.fill", value: "5", label: "streak", color: Color("NormaPastelCoral"))
        StatPill(icon: "star.fill", value: "42", label: "points", color: Color("NormaPastelTeal"))
        StatPill(icon: "bird.fill", value: "3", label: "birds", color: Color("NormaPastelLavender"))
    }
    .padding(24)
    .background(Color("NormaBackground"))
}
