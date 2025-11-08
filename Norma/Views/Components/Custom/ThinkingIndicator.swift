//
//  ThinkingIndicator.swift
//  Norma
//
//  Created by Claude on 1/22/25.
//

import SwiftUI

struct ThinkingIndicator: View {
    @State private var showContent = false
    @State private var typedText = ""
    @State private var showPhase2 = false
    @State private var showDot1 = false
    @State private var showDot2 = false
    @State private var showDot3 = false

    private let thinkingText = "Thinking"

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack(spacing: 2) {
                if !showPhase2 {
                    // Phase 1: Typing "Thinking"
                    Text(typedText)
                        .font(.normaTitle(14))
                        .foregroundColor(Color("NormaText").opacity(0.7))
                } else {
                    // Phase 2: Three dots with staggered pop
                    HStack(spacing: 4) {
                        if showDot1 {
                            Text("•")
                                .font(.normaTitle(14))
                                .foregroundColor(Color("NormaText").opacity(0.7))
                                .transition(.scale.combined(with: .opacity))
                        }
                        if showDot2 {
                            Text("•")
                                .font(.normaTitle(14))
                                .foregroundColor(Color("NormaText").opacity(0.7))
                                .transition(.scale.combined(with: .opacity))
                        }
                        if showDot3 {
                            Text("•")
                                .font(.normaTitle(14))
                                .foregroundColor(Color("NormaText").opacity(0.7))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .stroke(Color("NormaText").opacity(0.15), lineWidth: 1)
                    .background(Capsule().fill(.clear))
            )
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.95)
            .offset(y: showContent ? 0 : 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                // Series of soft pulse haptics
                performPulseHaptics()

                // Soft pop animation
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showContent = true
                }

                // Start typing animation
                startTypingAnimation()
            }

            Spacer(minLength: 0)
                .frame(width: UIScreen.main.bounds.width * 0.02)
        }
    }

    private func startTypingAnimation() {
        typedText = ""
        let characters = Array(thinkingText)

        // Type out "Thinking"
        for (index, character) in characters.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                typedText.append(character)

                // After typing completes, transition to dots
                if index == characters.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        startDotAnimation()
                    }
                }
            }
        }
    }

    private func startDotAnimation() {
        // Transition to phase 2
        withAnimation(.easeInOut(duration: 0.2)) {
            showPhase2 = true
        }

        // Staggered dot appearances
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.2)) {
            showDot1 = true
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.35)) {
            showDot2 = true
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.5)) {
            showDot3 = true
        }

        // Reset and repeat the dot animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.2)) {
                showDot1 = false
                showDot2 = false
                showDot3 = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                startDotAnimation()
            }
        }
    }

    private func performPulseHaptics() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()

        // First pulse - firmer
        impactFeedback.impactOccurred(intensity: 0.7)

        // Second pulse after 0.15s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            impactFeedback.impactOccurred(intensity: 0.6)
        }

        // Third pulse after 0.3s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            impactFeedback.impactOccurred(intensity: 0.5)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ThinkingIndicator()
    }
    .padding()
    .background(Color("NormaBackground"))
}
