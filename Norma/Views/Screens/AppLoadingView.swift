//
//  AppLoadingView.swift
//  Norma
//
//  Created by Claude on 1/3/26.
//

import SwiftUI

struct AppLoadingView: View {
    let isDataReady: Bool
    let onStart: () -> Void

    // Animation states
    @State private var coinBlur: CGFloat = 20
    @State private var coinOpacity: Double = 0
    @State private var coinScale: CGFloat = 0.8
    @State private var glowOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.5
    @State private var gradientOpacity: Double = 0
    @State private var titleText: String = ""
    @State private var subtitleAnimating: Bool = false
    @State private var subtitleOpacity: Double = 1
    @State private var hasAutoTransitioned = false
    @State private var loadingVisible = false
    @State private var dotCount = 0
    @State private var dotTimer: Timer?

    @Environment(\.colorScheme) private var colorScheme

    private let fullTitle = "Norma"
    private let coinTier = CoinTier.royalty

    var body: some View {
        ZStack {
            // Start with NormaBackground so there's no jarring flash
            Color("NormaBackground")
                .ignoresSafeArea()

            // Gradient fades in over the base background
            CoinGradientBackground(coinColor: coinTier.glowColor, colorScheme: colorScheme)
                .ignoresSafeArea()
                .opacity(gradientOpacity)

            VStack(spacing: 20) {
                Spacer()

                // Coin with bloom glow
                ZStack {
                    // Outer glow bloom
                    Circle()
                        .fill(coinTier.glowColor.opacity(0.15))
                        .frame(width: 280, height: 280)
                        .blur(radius: 50)
                        .scaleEffect(glowScale)
                        .opacity(glowOpacity)

                    // Inner glow
                    Circle()
                        .fill(coinTier.glowColor.opacity(0.25))
                        .frame(width: 160, height: 160)
                        .blur(radius: 25)
                        .scaleEffect(glowScale)
                        .opacity(glowOpacity)

                    // The coin
                    StaticCoin3DView(fileName: coinTier.fileName)
                        .frame(width: 160, height: 160)
                        .blur(radius: coinBlur)
                        .opacity(coinOpacity)
                        .scaleEffect(coinScale)
                }

                // Title — types in letter by letter
                Text(titleText)
                    .font(.normaTitle(64))
                    .foregroundColor(.primary)
                    .frame(height: 70)

                // Subtitle with wave animation
                WaveTextView(
                    text: "Financial clarity for wherever you call home",
                    font: .normaSubheadline(18),
                    color: .secondary,
                    isAnimating: subtitleAnimating,
                    alignment: .center
                )
                .frame(maxWidth: 200)
                .opacity(subtitleOpacity)

                Spacer()

                // Loading capsule
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
                .opacity(loadingVisible ? 1 : 0)
                .offset(y: loadingVisible ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: loadingVisible)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startCinematicReveal()
        }
        .onChange(of: isDataReady) { _, ready in
            if ready && !hasAutoTransitioned {
                autoTransition()
            }
        }
        .onDisappear {
            dotTimer?.invalidate()
        }
    }

    private func startCinematicReveal() {
        // Phase 1: Coin emerges from blur (0.0s – 1.2s)
        withAnimation(.easeOut(duration: 1.2)) {
            coinOpacity = 1
            coinBlur = 0
            coinScale = 1
        }

        // Phase 2: Glow blooms outward (0.4s – 1.6s)
        withAnimation(.easeOut(duration: 1.2).delay(0.4)) {
            glowOpacity = 1
            glowScale = 1
        }

        // Phase 3: Gradient background fades in (0.8s – 2.0s)
        withAnimation(.easeIn(duration: 1.2).delay(0.8)) {
            gradientOpacity = 1
        }

        // Phase 4: Title types in letter by letter (1.5s+)
        let typeDelay = 1.5
        for (index, char) in fullTitle.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + typeDelay + (Double(index) * 0.12)) {
                titleText.append(char)
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
        }

        // Phase 5: Subtitle wave animation (after title finishes)
        let subtitleDelay = typeDelay + (Double(fullTitle.count) * 0.12) + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + subtitleDelay) {
            subtitleAnimating = true
        }

        // Phase 6: Loading capsule slides up after subtitle
        let loadingDelay = subtitleDelay + 1.2
        DispatchQueue.main.asyncAfter(deadline: .now() + loadingDelay) {
            loadingVisible = true
            startDotAnimation()
        }

        // Check if data is ready after full animation
        let animationEnd = loadingDelay + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + animationEnd) {
            if isDataReady && !hasAutoTransitioned {
                autoTransition()
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

    private func autoTransition() {
        hasAutoTransitioned = true
        dotTimer?.invalidate()

        // Hold for 4 seconds, then stagger each element disappearing

        // Loading capsule fades out first
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeOut(duration: 0.4)) {
                loadingVisible = false
            }
        }

        // Subtitle fades out
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                subtitleOpacity = 0
            }
        }

        // Title shrinks and fades
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.4) {
            withAnimation(.easeOut(duration: 0.5)) {
                titleText = ""
            }
        }

        // Coin blurs out and scales down
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.6) {
            withAnimation(.easeOut(duration: 0.6)) {
                coinBlur = 15
                coinOpacity = 0
                coinScale = 0.7
                glowOpacity = 0
                glowScale = 0.5
            }
        }

        // Gradient fades out last
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.9) {
            withAnimation(.easeOut(duration: 0.5)) {
                gradientOpacity = 0
            }
        }

        // Transition to app after everything is gone
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            onStart()
        }
    }
}

#Preview("Loading") {
    AppLoadingView(isDataReady: false, onStart: {})
}

#Preview("Ready") {
    AppLoadingView(isDataReady: true, onStart: {})
}
