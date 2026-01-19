//
//  AppLoadingView.swift
//  Norma
//
//  Created by Claude on 1/3/26.
//

import SwiftUI

struct AppLoadingView: View {
    // External state
    let isDataReady: Bool
    let onStart: () -> Void

    // Orbiting coins (all except royalty)
    private let orbitingCoins: [CoinTier] = [
        .starter, .basic, .silver, .tealSteel, .gold, .skyBeige, .pinkPanther, .opal
    ]

    // Animation states - coins
    @State private var coinVisible = false
    @State private var orbitCoinVisibility: [Bool] = Array(repeating: false, count: 8)
    @State private var startHovering = false

    // Animation states - text
    @State private var titleScale: CGFloat = 0.8
    @State private var titleOpacity = 0.0
    @State private var titleOffset: CGFloat = -20
    @State private var subtitleOpacity = 0.0
    @State private var subtitleScale: CGFloat = 0.9

    // Animation states - loading/start button
    @State private var loadingOpacity = 0.0
    @State private var loadingOffset: CGFloat = 30
    @State private var dotCount = 0
    @State private var showStartButton = false
    @State private var startButtonScale: CGFloat = 0.8

    // Haptic generator
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)

    // Timer for animated dots
    @State private var dotTimer: Timer?

    var body: some View {
        ZStack {
            Color("NormaBackground")
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                // Coin orbit system with TimelineView for smooth hover
                TimelineView(.animation(paused: !startHovering)) { timeline in
                    let time = startHovering ? timeline.date.timeIntervalSinceReferenceDate : 0

                    ZStack {
                        // Orbiting smaller coins with hover effect
                        ForEach(Array(orbitingCoins.enumerated()), id: \.element.id) { index, coin in
                            let angleOffset = (360.0 / Double(orbitingCoins.count)) * Double(index)
                            let isVisible = index < orbitCoinVisibility.count && orbitCoinVisibility[index]
                            // Each coin hovers with a phase offset for wave effect
                            let phaseOffset = Double(index) * 0.4
                            let individualHover = sin(time * 1.5 + phaseOffset) * 6

                            ZStack {
                                // Glow effect behind coin
                                Circle()
                                    .fill(coin.glowColor.opacity(0.15))
                                    .frame(width: 50, height: 50)
                                    .blur(radius: 12)

                                StaticCoin3DView(fileName: coin.fileName)
                                    .frame(width: 44, height: 44)
                            }
                            .offset(
                                x: cos(angleOffset * .pi / 180) * 120,
                                y: sin(angleOffset * .pi / 180) * 120 + individualHover
                            )
                            .scaleEffect(isVisible ? 1 : 0)
                            .opacity(isVisible ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
                        }

                        // Center royalty coin with glow
                        ZStack {
                            // Glow effect behind royalty coin
                            Circle()
                                .fill(CoinTier.royalty.glowColor.opacity(0.12))
                                .frame(width: 180, height: 180)
                                .blur(radius: 30)

                            StaticCoin3DView(fileName: CoinTier.royalty.fileName)
                                .frame(width: 160, height: 160)
                        }
                        .scaleEffect(coinVisible ? 1 : 0.3)
                        .opacity(coinVisible ? 1 : 0)
                    }
                }
                .frame(width: 300, height: 300)

                // Norma title
                Text("Norma")
                    .font(.normaTitle(64))
                    .foregroundColor(.primary)
                    .scaleEffect(titleScale)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)

                // Subtitle
                Text("Financial clarity for wherever you call home")
                    .font(.normaSubheadline(18))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .scaleEffect(subtitleScale)
                    .opacity(subtitleOpacity)
                    .padding(.horizontal, 32)

                Spacer()

                // Loading indicator or Start button
                ZStack {
                    // Loading text with animated dots
                    if !showStartButton {
                        HStack(spacing: 0) {
                            Text("loading")
                                .font(.normaInput(14))
                                .foregroundColor(.secondary)
                            Text(String(repeating: ".", count: dotCount))
                                .font(.normaInput(14))
                                .foregroundColor(.secondary)
                                .frame(width: 20, alignment: .leading)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(.clear)
                                .glassEffect(in: Capsule())
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        )
                        .opacity(loadingOpacity)
                        .offset(y: loadingOffset)
                    }

                    // Start button
                    if showStartButton {
                        Button(action: {
                            heavyImpactGenerator.impactOccurred()
                            onStart()
                        }) {
                            Text("Start")
                                .font(.normaHeadline(18))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule()
                                        .fill(Color("NormaPastelTeal").opacity(0.3))
                                        .glassEffect(in: Capsule())
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color("NormaPastelTeal").opacity(0.4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(startButtonScale)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAppearanceAnimations()
        }
        .onChange(of: isDataReady) { _, ready in
            if ready {
                transitionToStartButton()
            }
        }
        .onDisappear {
            dotTimer?.invalidate()
        }
    }

    private func startAppearanceAnimations() {
        // Prepare haptic generators
        impactGenerator.prepare()
        heavyImpactGenerator.prepare()

        // Center coin pops in first
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
            coinVisible = true
        }

        // Stagger orbiting coins with haptics
        let staggerDelay = 0.1
        let startDelay = 0.3
        for index in 0..<orbitingCoins.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + (Double(index) * staggerDelay)) {
                impactGenerator.impactOccurred()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    orbitCoinVisibility[index] = true
                }
            }
        }

        // Start continuous hover animation after all coins appear
        let totalHoverDelay = startDelay + (Double(orbitingCoins.count) * staggerDelay) + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + totalHoverDelay) {
            startHovering = true
        }

        // Title drops in with spring
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.2)) {
            titleScale = 1.0
            titleOpacity = 1.0
            titleOffset = 0
        }

        // Subtitle fades in and scales up
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            subtitleOpacity = 1.0
            subtitleScale = 1.0
        }

        // Loading indicator slides up
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.6)) {
            loadingOpacity = 1.0
            loadingOffset = 0
        }

        // Start animated dots
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            startDotAnimation()
        }

        // Check if data is already ready
        if isDataReady {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                transitionToStartButton()
            }
        }
    }

    private func startDotAnimation() {
        dotTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                dotCount = (dotCount % 3) + 1
            }
        }
    }

    private func transitionToStartButton() {
        // Stop dot animation
        dotTimer?.invalidate()

        // Animate transition
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            loadingOpacity = 0
            showStartButton = true
            startButtonScale = 1.0
        }

        // Haptic feedback for ready state
        heavyImpactGenerator.impactOccurred()
    }
}

#Preview("Loading") {
    AppLoadingView(isDataReady: false, onStart: {})
}

#Preview("Ready") {
    AppLoadingView(isDataReady: true, onStart: {})
}
