//
//  LandingPageView.swift
//  Norma
//
//  Created by Claude on 8/2/25.
//

import SwiftUI

struct LandingPageView: View {
    @Binding var showSignUp: Bool
    @Binding var showSignIn: Bool
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel

    // Animation states
    @State private var coinVisible = false
    @State private var orbitCoinVisibility: [Bool] = Array(repeating: false, count: 8)
    @State private var startHovering = false
    @State private var titleScale: CGFloat = 0.8
    @State private var titleOpacity = 0.0
    @State private var titleOffset: CGFloat = -20
    @State private var subtitleOpacity = 0.0
    @State private var subtitleScale: CGFloat = 0.9
    @State private var talkButtonOpacity = 0.0
    @State private var talkButtonOffset: CGFloat = 30
    @State private var signInOpacity = 0.0
    @State private var signInOffset: CGFloat = 20
    #if DEBUG
    @State private var showDebugSignUp = false
    #endif

    // Orbiting coins (all except royalty)
    private let orbitingCoins: [CoinTier] = [
        .starter, .basic, .silver, .tealSteel, .gold, .skyBeige, .pinkPanther, .opal
    ]

    // Haptic generator
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 4) {
                    // Norma title
                    Text("Norma")
                        .font(.normaTitle(64))
                        .foregroundColor(.primary)
                        .scaleEffect(titleScale)
                        .opacity(titleOpacity)
                        .offset(y: titleOffset)
                        .padding(.top, 32)
                        .padding(.bottom, 0)

                    // Subtitle - plain text
                    Text("Financial clarity for wherever you call home")
                        .font(.normaSubheadline(18))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: 200)
                        .scaleEffect(subtitleScale)
                        .opacity(subtitleOpacity)

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

                                MotionCoin3DView(fileName: "norma-coin-royalty")
                                    .frame(width: 160, height: 160)
                            }
                            .scaleEffect(coinVisible ? 1 : 0.3)
                            .opacity(coinVisible ? 1 : 0)
                        }
                    }
                    .frame(width: 300, height: 300)

                    Spacer()

                    // Bottom buttons
                    VStack(spacing: 16) {
                        #if DEBUG
                        Button(action: {
                            let vm = onboardingViewModel.previewModeViewModel

                            // Simulate onboarding data
                            vm.userName = "Chris"
                            vm.userCurrency = "USD"
                            vm.userIncome = 5000
                            vm.userFreedomFund = 1000

                            // Mock bill (Phase 2 collects at least one)
                            let dueDate = Calendar.current.date(from: DateComponents(
                                year: Calendar.current.component(.year, from: Date()),
                                month: Calendar.current.component(.month, from: Date()),
                                day: 1
                            )) ?? Date()
                            let bill = Bill(
                                id: UUID().uuidString,
                                userId: "preview-mode-user",
                                name: "Rent",
                                dueDate: dueDate,
                                nextDueDate: Calendar.current.date(byAdding: .month, value: 1, to: dueDate),
                                amount: 1200,
                                status: .scheduled,
                                frequency: .monthly
                            )
                            vm.bills.append(bill)

                            showDebugSignUp = true
                        }) {
                            Text("Skip to Sign Up (Debug)")
                                .font(.normaInput(14))
                                .foregroundColor(.secondary)
                        }
                        #endif

                        // Talk to Norma button with glass effect
                        Button(action: {
                            onboardingViewModel.currentStep = .previewMode
                        }) {
                            Text("Talk to Norma now")
                                .font(.normaHeadline(16))
                                .foregroundColor(Color("NormaPastelTeal"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule()
                                        .fill(Color("NormaPastelTeal").opacity(0.4))
                                        .glassEffect(in: Capsule())
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color("NormaPastelTeal").opacity(0.3), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .opacity(talkButtonOpacity)
                        .offset(y: talkButtonOffset)

                        // Sign in link
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .font(.normaInput(14))
                                .foregroundColor(.secondary)

                            Button(action: {
                                showSignIn = true
                                showSignUp = false
                                onboardingViewModel.currentStep = .authentication
                            }) {
                                Text("Sign in here")
                                    .font(.normaHeadline(14))
                                    .foregroundColor(.primary)
                                    .underline()
                            }
                        }
                        .opacity(signInOpacity)
                        .offset(y: signInOffset)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
                }
            }
            .background(Color("NormaBackground"))
        }
        #if DEBUG
        .sheet(isPresented: $showDebugSignUp) {
            SaveProgressModal(
                userName: onboardingViewModel.previewModeViewModel.userName ?? "there",
                onSignUpWithEmail: {
                    showDebugSignUp = false
                    onboardingViewModel.showSignUp = true
                    onboardingViewModel.currentStep = .authentication
                },
                onSignUpWithApple: {
                    Task {
                        _ = await onboardingViewModel.signInWithApple(fromPreviewMode: true)
                    }
                },
                onSignUpWithGoogle: {
                    Task {
                        _ = await onboardingViewModel.signInWithGoogle(fromPreviewMode: true)
                    }
                },
                onContinueChatting: {
                    showDebugSignUp = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled()
        }
        #endif
        .onAppear {
            // Prepare haptic generator
            impactGenerator.prepare()

            // Coin pops in first
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                coinVisible = true
            }

            // Stagger orbiting coins with haptics - use withAnimation for proper sync
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

            // Talk button slides up
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.6)) {
                talkButtonOpacity = 1.0
                talkButtonOffset = 0
            }

            // Sign in slides up last
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.75)) {
                signInOpacity = 1.0
                signInOffset = 0
            }
        }
    }
}

#Preview {
    LandingPageView(showSignUp: .constant(false), showSignIn: .constant(false))
        .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
}
