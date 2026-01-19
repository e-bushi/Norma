//
//  RewardBadgeView.swift
//  Norma
//
//  Created by Claude on 12/31/25.
//

import SwiftUI

/// Displays the icon/3D model for a reward with glow effect
struct RewardBadgeView: View {
    let iconType: RewardIconType
    let accentColor: Color
    let showBadge: Bool

    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(accentColor.opacity(0.25))
                .frame(width: 160, height: 160)
                .blur(radius: 35)

            // Icon content
            Group {
                switch iconType {
                case .sfSymbol(let name):
                    Image(systemName: name)
                        .font(.system(size: 80))
                        .foregroundColor(accentColor)

                case .tierBird(let tier):
                    StaticBird3DView(fileName: tier.fileName)
                        .frame(width: 120, height: 120)

                case .coin(let tier):
                    StaticCoin3DView(fileName: tier.fileName)
                        .frame(width: 100, height: 100)
                }
            }
            .scaleEffect(showBadge ? 1.0 : 0.5)
            .opacity(showBadge ? 1.0 : 0.0)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        // SF Symbol reward
        RewardBadgeView(
            iconType: .sfSymbol(name: "flame.fill"),
            accentColor: Color("NormaPastelCoral"),
            showBadge: true
        )

        // Bird reward
        RewardBadgeView(
            iconType: .tierBird(tier: .blaze),
            accentColor: ChallengeTier.blaze.glowColor,
            showBadge: true
        )

        // Coin reward
        RewardBadgeView(
            iconType: .coin(tier: .gold),
            accentColor: CoinTier.gold.glowColor,
            showBadge: true
        )
    }
    .padding()
    .background(Color("NormaBackground"))
}
