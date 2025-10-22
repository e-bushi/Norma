//
//  ChatEmptyStateView.swift
//  Norma
//
//  Created by Claude on 5/10/25.
//

import SwiftUI

struct ChatEmptyStateView: View {
    @State private var visibleWords: Int = 0

    private let words = ["How", "can", "I", "help", "with", "your", "finances?"]

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Spacer()
            Spacer()

            Image("norma")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .brightness(0.3 )

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
                // Reset to 0 first to ensure animation plays
                visibleWords = 0
                // Trigger animation after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    visibleWords = words.count
                }
            }
            .onDisappear {
                // Reset when view disappears
                visibleWords = 0
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ChatEmptyStateView()
        .background(Color("NormaBackground"))
}
