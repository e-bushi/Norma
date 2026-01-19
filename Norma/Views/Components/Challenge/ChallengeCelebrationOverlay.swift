//
//  ChallengeCelebrationOverlay.swift
//  Norma
//
//  Created by Claude on 12/30/25.
//

import SwiftUI

/// Enhanced celebration overlay shown when a challenge is completed
struct ChallengeCelebrationOverlay: View {
    let pointsEarned: Int
    let currentStreak: Int
    let newTierUnlocked: ChallengeTier?
    @Binding var isPresented: Bool

    @State private var contentScale: CGFloat = 0.5
    @State private var contentOpacity: Double = 0
    @State private var showStats = false
    @State private var showTierUnlock = false
    @State private var confettiCounter = 0

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissCelebration()
                }

            // Content
            VStack(spacing: 24) {
                // Success icon with glow
                ZStack {
                    Circle()
                        .fill(Color("NormaPastelTeal").opacity(0.2))
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color("NormaPastelTeal"))
                }

                // Title
                Text("Challenge Complete!")
                    .font(.normaHeadline(28))
                    .foregroundColor(.white)

                // Stats capsules
                if showStats {
                    HStack(spacing: 16) {
                        // Streak
                        MiniStatPill(
                            icon: "flame.fill",
                            value: "\(currentStreak)",
                            label: "Streak",
                            color: Color("NormaPastelCoral")
                        )

                        // Points earned
                        MiniStatPill(
                            icon: "star.fill",
                            value: "+\(pointsEarned)",
                            label: "Points",
                            color: Color("NormaPastelTeal")
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // New tier unlocked
                if let tier = newTierUnlocked, showTierUnlock {
                    VStack(spacing: 12) {
                        Text("NEW TIER UNLOCKED!")
                            .font(.custom(FontFamily.Rubik.semiBold, size: 14))
                            .tracking(1.5)
                            .foregroundColor(tier.glowColor)

                        HStack(spacing: 12) {
                            // Bird icon/3D view
                            ZStack {
                                Circle()
                                    .fill(tier.glowColor.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .blur(radius: 15)

                                Image(systemName: "bird.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(tier.glowColor)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(tier.displayName)
                                    .font(.custom(FontFamily.Rubik.semiBold, size: 20))
                                    .foregroundColor(.white)

                                Text("Tier \(tier.rawValue + 1)")
                                    .font(.custom(FontFamily.Rubik.regular, size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(tier.glowColor.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(tier.glowColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Continue button
                Button {
                    dismissCelebration()
                } label: {
                    Text("Continue")
                        .font(.custom(FontFamily.Rubik.medium, size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color("NormaPastelTeal"))
                        )
                }
                .padding(.horizontal, 40)
                .padding(.top, 16)
            }
            .scaleEffect(contentScale)
            .opacity(contentOpacity)
        }
        .onAppear {
            animateIn()
        }
    }

    private func animateIn() {
        // Main content
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            contentScale = 1.0
            contentOpacity = 1.0
        }

        // Stats after a delay
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.4)) {
            showStats = true
        }

        // Tier unlock after stats
        if newTierUnlocked != nil {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.8)) {
                showTierUnlock = true
            }
        }

        // Confetti
        confettiCounter += 1
    }

    private func dismissCelebration() {
        withAnimation(.easeOut(duration: 0.2)) {
            contentOpacity = 0
            contentScale = 0.9
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

#Preview {
    ZStack {
        Color("NormaBackground")
            .ignoresSafeArea()

        ChallengeCelebrationOverlay(
            pointsEarned: 3,
            currentStreak: 5,
            newTierUnlocked: .blaze,
            isPresented: .constant(true)
        )
    }
}
