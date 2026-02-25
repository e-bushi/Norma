//
//  ChatEmptyStateView.swift
//  Norma
//
//  Created by Claude on 5/10/25.
//

import SwiftUI

struct ChatEmptyStateView: View {
    let arcCount: Int

    @State private var textAnimating: Bool = false
    @State private var coinVisible: Bool = false
    @State private var timezonesVisible: Bool = false
    @State private var showTimezoneSelection: Bool = false

    @ObservedObject private var timezoneManager = TimezoneManager.shared

    private let greetingText = "How can I help with your finances?"
    private let coinSize: CGFloat = 120
    private let capsuleColors: [Color] = [
        Color("NormaPastelTeal"),
        Color("NormaPastelPurple"),
        Color("NormaPastelCoral")
    ]

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

                WaveTextView(
                    text: greetingText,
                    font: .normaHeadline(),
                    color: .primary,
                    isAnimating: textAnimating,
                    alignment: .center
                )
                .padding(.horizontal, 40)

                // Timezone button
                if timezoneManager.selectedTimezones.isEmpty {
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showTimezoneSelection = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                            Text("Add World Clocks")
                                .font(.normaFinancial(14))
                                .lineLimit(1)
                                .fixedSize()
                        }
                        .foregroundColor(Color("NormaPastelTeal"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color("NormaPastelTeal").opacity(0.15))
                                .glassEffect(in: Capsule())
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color("NormaPastelTeal").opacity(0.3), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(CapsulePressStyle())
                    .padding(.top, 16)
                    .opacity(timezonesVisible ? 1 : 0)
                    .scaleEffect(timezonesVisible ? 1 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: timezonesVisible)
                } else {
                    VStack(spacing: 12) {
                        // First row: up to 2 timezones
                        HStack(spacing: 10) {
                            ForEach(Array(timezoneManager.selectedTimezones.prefix(2).enumerated()), id: \.element.id) { index, timezone in
                                TimezoneCapsuleView(timezone: timezone, color: capsuleColors[index]) {
                                    showTimezoneSelection = true
                                }
                            }
                        }

                        // Second row: 3rd timezone if exists
                        if timezoneManager.selectedTimezones.count > 2 {
                            TimezoneCapsuleView(timezone: timezoneManager.selectedTimezones[2], color: capsuleColors[2]) {
                                showTimezoneSelection = true
                            }
                        }
                    }
                    .padding(.top, 16)
                    .opacity(timezonesVisible ? 1 : 0)
                    .scaleEffect(timezonesVisible ? 1 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: timezonesVisible)
                }
            }
            .frame(width: geometry.size.width)
            .position(x: geometry.size.width / 2, y: (geometry.size.height / 2) - 60)
            .onAppear {
                coinVisible = false
                textAnimating = false
                timezonesVisible = false

                // Coin pops in first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    coinVisible = true
                }
                // Words follow shortly after
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    textAnimating = true
                }
                // Timezones appear last
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    timezonesVisible = true
                }
            }
            .onDisappear {
                coinVisible = false
                textAnimating = false
                timezonesVisible = false
            }
        }
        .sheet(isPresented: $showTimezoneSelection) {
            TimezoneSelectionView()
        }
    }

}

#Preview {
    ZStack {
        Color("NormaBackground")
            .ignoresSafeArea()

        ChatEmptyStateView(arcCount: 3)
    }
}
