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
    @State private var visibleCapsuleCount: Int = 0

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

                // Timezone capsules or add button
                if timezoneManager.selectedTimezones.isEmpty {
                    Button {
                        showTimezoneSelection = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .medium))
                            Text("World Clocks")
                                .font(.normaFinancial(14))
                        }
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)
                    .opacity(timezonesVisible ? 1 : 0)
                    .scaleEffect(timezonesVisible ? 1 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: timezonesVisible)
                } else {
                    // Vertical list of timezone capsules with staggered entrance
                    VStack(spacing: 8) {
                        ForEach(Array(timezoneManager.selectedTimezones.prefix(3).enumerated()), id: \.element.id) { index, timezone in
                            TimezoneCapsuleView(timezone: timezone, color: capsuleColors[index]) {
                                showTimezoneSelection = true
                            }
                            .opacity(visibleCapsuleCount > index ? 1 : 0)
                            .offset(y: visibleCapsuleCount > index ? 0 : 10)
                            .animation(
                                .spring(response: 0.45, dampingFraction: 0.75)
                                    .delay(Double(index) * 0.1),
                                value: visibleCapsuleCount
                            )
                        }
                    }
                    .padding(.top, 16)
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
                    visibleCapsuleCount = timezoneManager.selectedTimezones.prefix(3).count
                }
            }
            .onDisappear {
                coinVisible = false
                textAnimating = false
                timezonesVisible = false
                visibleCapsuleCount = 0
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
