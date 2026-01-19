//
//  ChatEmptyStateView.swift
//  Norma
//
//  Created by Claude on 5/10/25.
//

import SwiftUI

struct ChatEmptyStateView: View {
    let arcCount: Int

    @State private var visibleWords: Int = 0
    @State private var coinVisible: Bool = false

    private let words = ["How", "can", "I", "help", "with", "your", "finances?"]
    private let coinSize: CGFloat = 120

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 12) {
                // Motion coin based on user's current tier (tilts with device)
                // Wrapped in CrossfadeView for smooth transition when tier changes
                // initialDelay of 0.7s lets the appearance animation complete before crossfade
                CrossfadeView(
                    key: CoinTierService.currentCoinFileName(for: arcCount),
                    duration: 0.45,
                    initialDelay: 0.7
                ) { fileName in
                    MotionCoin3DView(fileName: fileName)
                        .id(fileName)
                        .frame(width: coinSize, height: coinSize)
                }
                .scaleEffect(coinVisible ? 1 : 0.3)
                .opacity(coinVisible ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: coinVisible)

                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        ForEach(Array(words[0...3].enumerated()), id: \.offset) { index, word in
                            Text(word)
                                .font(.normaHeadline())
                                .tracking(-1)
                                .fixedSize()
                                .opacity(index < visibleWords ? 1 : 0)
                                .scaleEffect(index < visibleWords ? 1 : 0.3)
                                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.1), value: visibleWords)
                        }
                    }
                    .fixedSize()

                    HStack(spacing: 8) {
                        ForEach(Array(words[4...6].enumerated()), id: \.offset) { index, word in
                            Text(word)
                                .font(.normaHeadline())
                                .tracking(-1)
                                .fixedSize()
                                .opacity((index + 4) < visibleWords ? 1 : 0)
                                .scaleEffect((index + 4) < visibleWords ? 1 : 0.3)
                                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index + 4) * 0.1), value: visibleWords)
                        }
                    }
                    .fixedSize()
                }
                .padding(.horizontal, 40)
                .onAppear {
                    coinVisible = false
                    visibleWords = 0

                    // Coin pops in first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        coinVisible = true
                    }
                    // Words follow shortly after
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        visibleWords = words.count
                    }
                }
                .onDisappear {
                    coinVisible = false
                    visibleWords = 0
                }
            }
            .frame(width: geometry.size.width)
            .position(x: geometry.size.width / 2, y: (geometry.size.height / 2) - 80)
        }
    }
}

#Preview {
    ChatEmptyStateView(arcCount: 3)
        .background(Color("NormaBackground"))
}
