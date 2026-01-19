//
//  RewardCelebrationView.swift
//  Norma
//
//  Created by Claude on 12/31/25.
//

import SwiftUI

/// Universal reward celebration view - presented as a sheet
/// Observes RewardQueueManager for reward queue state
struct RewardCelebrationView: View {
    @StateObject private var queueManager = RewardQueueManager.shared
    @Environment(\.colorScheme) private var colorScheme

    // Animation states
    @State private var contentScale: CGFloat = 0.5
    @State private var contentOpacity: Double = 0
    @State private var showBadge = false
    @State private var showCongratulatoryText = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showButton = false

    // MARK: - Adaptive Colors

    private var backgroundGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.08, green: 0.08, blue: 0.12),
                Color(red: 0.05, green: 0.05, blue: 0.08)
            ]
        } else {
            return [
                Color(red: 0.98, green: 0.98, blue: 1.0),
                Color(red: 0.94, green: 0.94, blue: 0.96)
            ]
        }
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.12)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.3, green: 0.3, blue: 0.35)
    }

    private var tertiaryTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.6) : Color(red: 0.45, green: 0.45, blue: 0.5)
    }

    private var mutedTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.4) : Color(red: 0.6, green: 0.6, blue: 0.65)
    }

    var body: some View {
        ZStack {
            // Adaptive gradient background for sheet
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if let reward = queueManager.currentReward {
                // Main content
                VStack(spacing: 0) {
                    Spacer()

                    // 1. Symbol (Icon/3D Model with glow)
                    RewardBadgeView(
                        iconType: reward.iconType,
                        accentColor: reward.accentColor,
                        showBadge: showBadge
                    )

                    Spacer()
                        .frame(height: 32)

                    // 2. Congratulatory text
                    Text(congratulatoryText(for: reward))
                        .font(.custom(FontFamily.Rubik.regular, size: 16))
                        .foregroundColor(secondaryTextColor)
                        .opacity(showCongratulatoryText ? 1 : 0)
                        .offset(y: showCongratulatoryText ? 0 : 12)

                    Spacer()
                        .frame(height: 12)

                    // 3. Reward title
                    Text(reward.title)
                        .font(.normaHeadline(28))
                        .foregroundColor(primaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 12)

                    // 4. Description
                    if !reward.subtitle.isEmpty {
                        Spacer()
                            .frame(height: 12)

                        Text(reward.subtitle)
                            .font(.custom(FontFamily.Rubik.regular, size: 15))
                            .foregroundColor(tertiaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .opacity(showSubtitle ? 1 : 0)
                            .offset(y: showSubtitle ? 0 : 12)
                    }

                    // Queue indicator (if more rewards pending)
                    if queueManager.pendingRewardCount > 0 {
                        Spacer()
                            .frame(height: 20)

                        Text("\(queueManager.pendingRewardCount) more reward\(queueManager.pendingRewardCount == 1 ? "" : "s")")
                            .font(.custom(FontFamily.Rubik.regular, size: 12))
                            .foregroundColor(mutedTextColor)
                    }

                    Spacer()

                    // 5. Continue/Next button at bottom
                    Button {
                        queueManager.dismissCurrent()
                    } label: {
                        HStack {
                            Text(queueManager.buttonText)
                                .font(.custom(FontFamily.Rubik.medium, size: 16))

                            if queueManager.hasMoreRewards {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(reward.accentColor)
                        )
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                    .opacity(showButton ? 1 : 0)
                    .offset(y: showButton ? 0 : 20)
                }
                .scaleEffect(queueManager.isAnimatingOut ? 0.9 : contentScale)
                .opacity(queueManager.isAnimatingOut ? 0 : contentOpacity)
            }
        }
        .onAppear {
            animateIn()
        }
        .onChange(of: queueManager.currentReward?.id) { oldValue, newValue in
            // Reset and re-animate when reward changes
            if oldValue != newValue && newValue != nil {
                resetAnimation()
                animateIn()
            }
        }
    }

    // MARK: - Congratulatory Text

    private func congratulatoryText(for reward: Reward) -> String {
        switch reward.type {
        case .arcEarned:
            return "Nice work!"
        case .challengeStreakExtended:
            return "You're on fire!"
        case .firstChallengeCompleted:
            return "Amazing!"
        case .challengeBeaten:
            return "Well done!"
        case .birdUnlocked:
            return "Congratulations!"
        case .firstChallengeStarted:
            return "Let's go!"
        case .firstPendingTransactionConfirmed:
            return "Great start!"
        case .firstBillAddedViaChat:
            return "Nice one!"
        case .streak5Days:
            return "Keep it up!"
        case .streak10Days:
            return "Incredible!"
        case .streak25Days:
            return "Legendary!"
        case .streak50Days:
            return "Unstoppable!"
        case .streak100Days:
            return "You're a master!"
        }
    }

    // MARK: - Animations

    private func animateIn() {
        // Main content scale and fade
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            contentScale = 1.0
            contentOpacity = 1.0
        }

        // Badge after slight delay
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2)) {
            showBadge = true
        }

        // Congratulatory text
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.35)) {
            showCongratulatoryText = true
        }

        // Title
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.45)) {
            showTitle = true
        }

        // Subtitle
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.55)) {
            showSubtitle = true
        }

        // Button slides up from bottom
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.7)) {
            showButton = true
        }
    }

    private func resetAnimation() {
        contentScale = 0.5
        contentOpacity = 0
        showBadge = false
        showCongratulatoryText = false
        showTitle = false
        showSubtitle = false
        showButton = false
    }
}

private struct PreviewWrapper: View {
    @State private var isReady = false

    var body: some View {
        Group {
            if isReady {
                RewardCelebrationView()
            } else {
                Color.clear
            }
        }
        .task { @MainActor in
            RewardQueueManager.shared.enqueue(.challengeBeaten(pointsEarned: 13, difficulty:    "Hard"))
            isReady = true
        }
    }
}

#Preview("Dark Mode") {
    PreviewWrapper()
        .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    PreviewWrapper()
        .preferredColorScheme(.light)
}
