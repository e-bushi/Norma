//
//  ChallengeSkeletons.swift
//  Norma
//
//  Created by Claude on 1/18/26.
//

import SwiftUI

// MARK: - Hero Skeleton

/// Skeleton loading state for the challenge hero view
struct ChallengeHeroSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            // Amount display skeleton
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(shimmerOpacity))
                    .frame(width: 180, height: 72)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.08))
                    .frame(width: 40, height: 32)
            }

            // Badges skeleton
            HStack(spacing: 10) {
                // Days remaining capsule
                Capsule()
                    .fill(Color.gray.opacity(shimmerOpacity))
                    .frame(width: 120, height: 34)

                // Difficulty badge
                Capsule()
                    .fill(Color.gray.opacity(shimmerOpacity * 0.8))
                    .frame(width: 80, height: 34)

                // Points capsule
                Capsule()
                    .fill(Color.gray.opacity(shimmerOpacity * 0.6))
                    .frame(width: 70, height: 30)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }

    private var shimmerOpacity: Double {
        isAnimating ? 0.15 : 0.08
    }
}

// MARK: - Stats Row Skeleton

/// Skeleton loading state for the challenge stats row
struct ChallengeStatsRowSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 10) {
            // First line
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(shimmerOpacity))
                    .frame(width: 100, height: 22)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(shimmerOpacity * 0.9))
                    .frame(width: 80, height: 22)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(shimmerOpacity * 0.8))
                    .frame(width: 140, height: 22)
            }

            // Second line
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(shimmerOpacity * 0.7))
                    .frame(width: 120, height: 22)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(shimmerOpacity * 0.6))
                    .frame(width: 60, height: 22)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(shimmerOpacity * 0.5))
                    .frame(width: 90, height: 22)
            }

            // Third line
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(shimmerOpacity * 0.6))
                    .frame(width: 70, height: 22)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(shimmerOpacity * 0.5))
                    .frame(width: 100, height: 22)
            }
        }
        .padding(.horizontal, 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }

    private var shimmerOpacity: Double {
        isAnimating ? 0.15 : 0.08
    }
}

// MARK: - Full Content Skeleton

/// Complete skeleton for the entire ActiveChallengeContent view
struct ActiveChallengeContentSkeleton: View {
    @State private var heroAppeared = false
    @State private var statsAppeared = false

    var body: some View {
        VStack(spacing: 24) {
            // Hero skeleton
            ChallengeHeroSkeleton()
                .scaleEffect(heroAppeared ? 1 : 0.95)
                .opacity(heroAppeared ? 1 : 0)
                .offset(y: heroAppeared ? 0 : 20)

            // Stats row skeleton
            ChallengeStatsRowSkeleton()
                .scaleEffect(statsAppeared ? 1 : 0.97)
                .opacity(statsAppeared ? 1 : 0)
                .offset(y: statsAppeared ? 0 : 15)


            Spacer(minLength: 40)
        }
        .onAppear {
            animateEntrance()
        }
    }

    private func animateEntrance() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            heroAppeared = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
            statsAppeared = true
        }

    }
}

// MARK: - Previews

#Preview("Hero Skeleton") {
    ChallengeHeroSkeleton()
        .padding(20)
        .background(Color("NormaBackground"))
}

#Preview("Stats Row Skeleton") {
    ChallengeStatsRowSkeleton()
        .padding(20)
        .background(Color("NormaBackground"))
}

#Preview("Full Content Skeleton") {
    ScrollView(showsIndicators: false) {
        ActiveChallengeContentSkeleton()
            .padding(.horizontal, 20)
            .padding(.top, 20)
    }
    .background(Color("NormaBackground"))
}
