//
//  CoinCollectionView.swift
//  Norma
//
//  Created by Claude on 12/29/25.
//

import SwiftUI

/// Horizontal scrollable view showing all coin tiers with locked/unlocked states
struct CoinCollectionView: View {
    let arcCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coin Collection")
                .font(.custom(FontFamily.Rubik.medium, size: 16))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(CoinTier.allTiersInOrder) { tier in
                        CoinTierCard(
                            tier: tier,
                            isUnlocked: CoinTierService.isTierUnlocked(tier, for: arcCount),
                            isCurrentTier: tier == CoinTierService.currentCoinTier(for: arcCount)
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.clear)
                .glassEffect(in: RoundedRectangle(cornerRadius: 16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
        )
    }
}

/// Individual coin tier card showing locked/unlocked state
struct CoinTierCard: View {
    let tier: CoinTier
    let isUnlocked: Bool
    let isCurrentTier: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Coin view with grayscale for locked coins
                StaticCoin3DView(fileName: tier.fileName)
                    .frame(width: 56, height: 56)
                    .saturation(isUnlocked ? 1.0 : 0.0)
                    .opacity(isUnlocked ? 1.0 : 0.5)

                // Lock overlay for locked coins
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(4)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                        .offset(x: 18, y: 18)
                }

                // Current tier indicator ring
                if isCurrentTier {
                    Circle()
                        .stroke(Color("NormaPastelTeal"), lineWidth: 2)
                        .frame(width: 64, height: 64)
                }
            }

            // Tier name
            Text(tier.displayName)
                .font(.custom(FontFamily.Rubik.medium, size: 11))
                .foregroundColor(isUnlocked ? .primary : .secondary)
                .lineLimit(1)

            // Arc requirement
            Text("\(tier.requiredArcs) arc\(tier.requiredArcs == 1 ? "" : "s")")
                .font(.custom(FontFamily.Rubik.regular, size: 10))
                .foregroundColor(isUnlocked ? Color("NormaPastelTeal") : .secondary)
        }
        .frame(width: 72)
    }
}

#Preview {
    VStack(spacing: 20) {
        CoinCollectionView(arcCount: 0)
        CoinCollectionView(arcCount: 3)
        CoinCollectionView(arcCount: 12)
    }
    .padding()
    .background(Color("NormaBackground"))
}
