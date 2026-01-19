//
//  BirdCollectionView.swift
//  Norma
//
//  Created by Claude on 12/30/25.
//

import SwiftUI

/// Grid view showing all challenge tier birds with locked/unlocked states
struct BirdCollectionView: View {
    let totalPoints: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with current stats
                    VStack(spacing: 8) {
                        Text("\(totalPoints)")
                            .font(.normaHeadline(48))
                            .foregroundColor(.primary)

                        Text("Total Points")
                            .font(.custom(FontFamily.Rubik.medium, size: 14))
                            .foregroundColor(.secondary)

                        // Progress to next tier
                        let current = ChallengeTierService.currentTier(for: totalPoints)
                        let pointsToNext = ChallengeTierService.pointsToNextTier(for: totalPoints)

                        if pointsToNext > 0 {
                            Text("\(pointsToNext) points to \(current.nextTier?.displayName ?? "max")")
                                .font(.custom(FontFamily.Rubik.regular, size: 13))
                                .foregroundColor(Color("NormaPastelTeal"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color("NormaPastelTeal").opacity(0.12))
                                )
                        }
                    }
                    .padding(.top, 16)

                    // Unlocked count
                    let unlockedCount = ChallengeTierService.unlockedTierCount(for: totalPoints)
                    Text("\(unlockedCount) of \(ChallengeTier.allCases.count) Unlocked")
                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                        .foregroundColor(.secondary)

                    // Bird grid (2 columns x 5 rows)
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible())
                    ], spacing: 24) {
                        ForEach(ChallengeTier.allTiersInOrder, id: \.self) { tier in
                            BirdTierCard(
                                tier: tier,
                                isUnlocked: ChallengeTierService.isTierUnlocked(tier, for: totalPoints),
                                isCurrent: ChallengeTierService.currentTier(for: totalPoints) == tier
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
            .background(Color("NormaBackground"))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Bird Collection")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

/// Individual bird tier card
struct BirdTierCard: View {
    let tier: ChallengeTier
    let isUnlocked: Bool
    let isCurrent: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if isUnlocked {
                    // Glow effect behind bird
                    Circle()
                        .fill(tier.glowColor.opacity(0.15))
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)

                    // 3D Bird
                    StaticBird3DView(fileName: tier.fileName)
                        .id(tier.fileName)
                        .frame(width: 80, height: 80)

                    // Current tier indicator
                    if isCurrent {
                        Circle()
                            .stroke(tier.glowColor, lineWidth: 3)
                            .frame(width: 90, height: 90)
                    }
                } else {
                    // Locked state - grayed out bird with lock
                    ZStack {
                        StaticBird3DView(fileName: tier.fileName)
                            .id("\(tier.fileName)-locked")
                            .frame(width: 80, height: 80)
                            .saturation(0)
                            .opacity(0.3)

                        Circle()
                            .fill(Color.black.opacity(0.25))
                            .frame(width: 80, height: 80)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(height: 100)

            // Tier name
            Text(tier.displayName)
                .font(.custom(FontFamily.Rubik.medium, size: 14))
                .foregroundColor(isUnlocked ? .primary : .secondary)

            // Points required
            Text("\(tier.requiredPoints) pts")
                .font(.custom(FontFamily.Rubik.regular, size: 12))
                .foregroundColor(isUnlocked ? tier.glowColor : .secondary)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isCurrent ? tier.glowColor.opacity(0.08) : Color.gray.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isCurrent ? tier.glowColor.opacity(0.3) : Color.gray.opacity(0.1),
                    lineWidth: isCurrent ? 1.5 : 0.5
                )
        )
    }
}

/// Compact teaser for the main view with "View Collection" button
struct BirdCollectionTeaser: View {
    let totalPoints: Int
    let pointsToNextTier: Int
    @Binding var showCollection: Bool

    private var unlockedCount: Int {
        ChallengeTierService.unlockedTierCount(for: totalPoints)
    }

    private var currentTier: ChallengeTier {
        ChallengeTierService.currentTier(for: totalPoints)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Progress header
            HStack {
                if pointsToNextTier > 0, let nextTier = currentTier.nextTier {
                    Text("\(pointsToNextTier) pts to \(nextTier.displayName)")
                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                        .foregroundColor(.primary)
                } else {
                    Text("Max tier reached!")
                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                        .foregroundColor(Color("NormaPastelTeal"))
                }

                Spacer()

                Text("\(unlockedCount)/\(ChallengeTier.allCases.count)")
                    .font(.custom(FontFamily.Rubik.regular, size: 13))
                    .foregroundColor(.secondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 6)

                    // Progress
                    let progress = ChallengeTierService.progressToNextTier(for: totalPoints)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(currentTier.glowColor)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)

            // Mini bird icons row
            HStack(spacing: 4) {
                ForEach(ChallengeTier.allTiersInOrder, id: \.self) { tier in
                    Circle()
                        .fill(
                            ChallengeTierService.isTierUnlocked(tier, for: totalPoints)
                                ? tier.glowColor
                                : Color.gray.opacity(0.2)
                        )
                        .frame(width: 8, height: 8)
                }
                Spacer()
            }

            // View collection button
            Button {
                showCollection = true
            } label: {
                HStack {
                    Text("View Collection")
                        .font(.custom(FontFamily.Rubik.medium, size: 13))
                        .foregroundColor(Color("NormaPastelTeal"))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color("NormaPastelTeal"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("NormaPastelTeal").opacity(0.08))
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    BirdCollectionView(totalPoints: 42)
}
