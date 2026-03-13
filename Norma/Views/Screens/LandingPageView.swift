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
    @State private var coinOpacity = 0.0
    @State private var coinScale: CGFloat = 0.8
    @State private var titleOpacity = 0.0
    @State private var titleOffset: CGFloat = -20
    @State private var subtitleOpacity = 0.0
    @State private var subtitleOffset: CGFloat = 10
    @State private var talkButtonOpacity = 0.0
    @State private var talkButtonOffset: CGFloat = 30
    @State private var signInOpacity = 0.0
    @State private var signInOffset: CGFloat = 20
    #if DEBUG
    @State private var showDebugSignUp = false
    #endif

    // Haptic generator
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                // Purple-tinted gradient background (matches onboarding style)
                LinearGradient(
                    colors: [
                        colorScheme == .dark
                            ? Color(red: 0.10, green: 0.06, blue: 0.16)
                            : Color(red: 0.93, green: 0.90, blue: 0.98),
                        colorScheme == .dark
                            ? Color(red: 0.04, green: 0.02, blue: 0.08)
                            : Color(red: 0.96, green: 0.94, blue: 0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Dot pattern background (same as MainChatView)
                DotPatternView()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)

                    // Royalty coin at top — tilt-reactive
                    MotionCoin3DView(fileName: "norma-coin-royalty")
                        .frame(width: 200, height: 200)
                        .opacity(coinOpacity)
                        .scaleEffect(coinScale)

                    Spacer()

                    // Norma title — left-aligned, editorial size
                    Text("Norma")
                        .font(.normaTitle(80))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(titleOpacity)
                        .offset(y: titleOffset)
                        .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 10)

                    // Subtitle
                    Text("Track your spending wherever the world takes you.")
                        .font(.normaSubheadline(19))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(subtitleOpacity)
                        .offset(y: subtitleOffset)
                        .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 28)

                    // Bottom buttons
                    VStack(spacing: 16) {
                        // Talk to Norma
                        Button(action: {
                            impactGenerator.impactOccurred()
                            onboardingViewModel.currentStep = .previewMode
                        }) {
                            Text("Talk to Norma to Sign Up")
                                .font(.normaHeadline(18))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color("NormaPastelPurple").opacity(0.7))
                                        .glassEffect(in: RoundedRectangle(cornerRadius: 14))
                                )
                        }
                        .buttonStyle(LandingButtonStyle())
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
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
                }
            }
            .background(colorScheme == .dark
                    ? Color(red: 0.04, green: 0.02, blue: 0.08)
                    : Color(red: 0.96, green: 0.94, blue: 0.98))
        }
        #if DEBUG
        .sheet(isPresented: $showDebugSignUp) {
            NotificationPermissionView(
                onPermissionGranted: { showDebugSignUp = false },
                onSkip: { showDebugSignUp = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled()
        }
        #endif
        .onAppear {
            impactGenerator.prepare()

            // Coin fades in and scales up
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                coinOpacity = 1.0
                coinScale = 1.0
            }

            // Title drops in with spring
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.3)) {
                titleOpacity = 1.0
                titleOffset = 0
            }

            // Subtitle fades in with slight rise
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                subtitleOpacity = 1.0
                subtitleOffset = 0
            }

            // Talk button slides up
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.7)) {
                talkButtonOpacity = 1.0
                talkButtonOffset = 0
            }

            // Sign in slides up last
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.85)) {
                signInOpacity = 1.0
                signInOffset = 0
            }
        }
    }
}

// MARK: - Button Style

private struct LandingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    LandingPageView(showSignUp: .constant(false), showSignIn: .constant(false))
        .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
}
