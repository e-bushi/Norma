//
//  ChatEmptyStateView.swift
//  Norma
//
//  Created by Claude on 5/10/25.
//

import SwiftUI

struct ChatEmptyStateView: View {
    let arcCount: Int
    var onCoinTapped: () -> Void = {}

    @State private var textAnimating: Bool = false
    @State private var coinVisible: Bool = false
    @State private var showHint: Bool = false
    @State private var coinPressed: Bool = false
    @State private var subGreetingVisible: Bool = false

    // Timezone state — commented out for later
    // @State private var showTimezoneSelection: Bool = false
    // @ObservedObject private var timezoneManager = TimezoneManager.shared

    @EnvironmentObject private var sessionViewModel: SessionViewModel

    private var userName: String {
        sessionViewModel.currentUser?.name.components(separatedBy: " ").first ?? ""
    }

    private var subGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "How can I help you this morning?"
        case 12..<17: return "How can I help you this afternoon?"
        case 17..<22: return "How can I help you this evening?"
        default: return "How can I help you tonight?"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 12) {
                // "Tap the coin" hint capsule
                Text("Tap the coin")
                    .font(.custom(FontFamily.Rubik.medium, size: 16))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.clear)
                            .glassEffect(in: Capsule())
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
                    )
                    .scaleEffect(showHint ? 1 : 0.5)
                    .opacity(showHint ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65), value: showHint)

                // Motion coin based on user's current tier (tilts with device)
                CrossfadeView(
                    key: CoinTierService.currentCoinFileName(for: arcCount),
                    duration: 0.45,
                    initialDelay: 0.7
                ) { fileName in
                    MotionCoin3DView(fileName: fileName, hapticsEnabled: false)
                        .id(fileName)
                        .frame(width: scaledCoinSize(for: geometry), height: scaledCoinSize(for: geometry))
                        .allowsHitTesting(false)
                }
                .overlay(
                    Color.clear
                        .contentShape(Circle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !coinPressed {
                                        coinPressed = true
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                    }
                                }
                                .onEnded { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        coinPressed = false
                                        onCoinTapped()
                                    }
                                }
                        )
                )
                .scaleEffect(coinPressed ? 0.9 : (coinVisible ? 1 : 0.3))
                .opacity(coinVisible ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: coinPressed)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: coinVisible)

                // Sub-greeting
                WaveTextView(
                    text: subGreeting,
                    font: .custom(FontFamily.Rubik.medium, size: scaledSubGreetingSize(for: geometry)),
                    color: .white.opacity(0.85),
                    isAnimating: subGreetingVisible,
                    alignment: .center
                )
                .lineSpacing(4)
                .frame(maxWidth: scaledSubGreetingWidth(for: geometry))
                .padding(.horizontal, 24)

            }
            .frame(width: geometry.size.width)
            .position(x: geometry.size.width / 2, y: (geometry.size.height / 2) - 60)
            .onAppear {
                coinVisible = false
                textAnimating = false
                showHint = false
                subGreetingVisible = false

                // Coin pops in first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    coinVisible = true
                }
                // Words follow shortly after
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    textAnimating = true
                }
                // Sub-greeting fades in after text
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    subGreetingVisible = true
                }
                // Hint pops in after everything else has animated in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showHint = true
                }
                // Hint fades out
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showHint = false
                    }
                }
            }
            .onDisappear {
                coinVisible = false
                textAnimating = false
                showHint = false
                subGreetingVisible = false
            }
        }
    }

    private func scaledCoinSize(for geometry: GeometryProxy) -> CGFloat {
        let scale = max(geometry.size.height / 874, 0.5)
        return 120 * scale
    }

    private func scaledSubGreetingSize(for geometry: GeometryProxy) -> CGFloat {
        let scale = max(geometry.size.height / 874, 0.5)
        return 36 * scale
    }

    private func scaledSubGreetingWidth(for geometry: GeometryProxy) -> CGFloat {
        let scale = max(geometry.size.height / 874, 0.5)
        return 400 * scale
    }
}

#Preview {
    ZStack {
        Color("NormaBackground")
            .ignoresSafeArea()

        ChatEmptyStateView(arcCount: 3)
    }
}
