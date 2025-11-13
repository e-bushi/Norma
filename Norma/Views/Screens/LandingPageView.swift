//
//  LandingPageView.swift
//  Norma
//
//  Created by Claude on 8/2/25.
//

import SwiftUI
import UIKit

struct LandingPageView: View {
    @Binding var showSignUp: Bool
    @Binding var showSignIn: Bool
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    
    // Animation states
    @State private var logoScale = 0.8
    @State private var logoOpacity = 0.0
    @State private var titleScale: CGFloat = 0.5
    @State private var titleOpacity = 0.0
    @State private var descriptionOpacity = 0.0
    @State private var buttonsOpacity = 0.0
    @State private var floatingOffset: CGFloat = 0
    @State private var contentShouldBlur = false
    @State private var contentScale: CGFloat = 0.8
    @State private var typedSubtitle = ""
    @State private var typedDescription = ""

    // Text animation states
    @State private var textAppearAnimation = false
    @State private var currentPage = 0

    private let fullSubtitle = "Your Personal Finance Assistant"
    
    // Content for each page
    private let pageContent = [
        (title: "Smart Budgeting", description: "Track your spending and stay within budget with intelligent insights and alerts."),
        (title: "Expense Calendar", description: "Visualize your spending patterns with our interactive calendar view."),
        (title: "Transaction History", description: "Keep track of all your expenses with detailed transaction records."),
        (title: "AI Assistant", description: "Get personalized financial advice and insights powered by artificial intelligence.")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with Norma title and slogan
                VStack(spacing: 8) {
                    Text("Norma")
                        .font(.normaTitle(48))
                        .foregroundColor(.primary)
                        .scaleEffect(titleScale)
                        .opacity(titleOpacity)

                    Text(typedSubtitle)
                        .font(.normaSubheadline(18))
                        .foregroundColor(.secondary)
                        .opacity(descriptionOpacity)
                }
                .padding(.top, 40)
                .padding(.bottom, 24)

                VStack(spacing: 32) {
                    // Mock views section - Swipeable horizontal layout
                    TabView(selection: $currentPage) {
                        // Mini Budget Disclosure View
                        MiniBudgetDisclosureView(appeared: currentPage == 0 && titleOpacity > 0)
                            .padding(.horizontal, 24)
                            .tag(0)

                        // Mini Expense Calendar View
                        MiniExpenseCalendarView(appeared: currentPage == 1 && titleOpacity > 0)
                            .padding(.horizontal, 24)
                            .tag(1)

                        // Mini Expense Disclosure View
                        MiniExpenseDisclosureView(appeared: currentPage == 2 && titleOpacity > 0)
                            .padding(.horizontal, 24)
                            .tag(2)

                        // Mini Chat View
                        MiniChatView(appeared: currentPage == 3 && titleOpacity > 0)
                            .padding(.horizontal, 24)
                            .tag(3)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .opacity(titleOpacity)
                    .onChange(of: currentPage) {
                        triggerTextAnimation()
                    }

                    // Animated title and description
                    VStack(spacing: 12) {
                        Text(pageContent[currentPage].title)
                            .font(.normaTitle(24))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .offset(x: textAppearAnimation ? 0 : -20)
                            .scaleEffect(textAppearAnimation ? 1 : 0.95)
                            .opacity(textAppearAnimation ? 1 : 0)
                            .rotation3DEffect(
                                .degrees(textAppearAnimation ? 0 : -5),
                                axis: (x: 0.0, y: 1.0, z: 0.0)
                            )
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0.3)
                                .delay(0.1),
                                value: textAppearAnimation
                            )

                        Text(typedDescription)
                            .font(.normaInput(16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .frame(minHeight: 50)
                            .opacity(textAppearAnimation ? 1 : 0)
                    }
                    .padding(.horizontal, 32)

                    // Custom page indicator dots
                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color("NormaPastelTeal") : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }

                    Spacer()
                }
                .padding(.top, 4)
                .fluidBlur(isActive: contentShouldBlur)
                .scaleEffect(contentScale)
            
            // Bottom buttons
            VStack(spacing: 16) {
                // Talk to Norma button
                Button(action: {
                    onboardingViewModel.currentStep = .previewMode
                }) {
                    Text("Talk to Norma now")
                        .font(.normaHeadline(16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color("NormaPastelTeal"),
                                            Color("NormaPastelTeal").opacity(0.8)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())

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
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
            .opacity(buttonsOpacity)
            }
            .background(Color("NormaBackground"))
        }
        .onAppear {
            // Trigger blur/pop animation for content
            contentShouldBlur = true

            // Start haptic feedback sequence
            startHapticSequence()

            // Start with scale animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                contentScale = 1.0
            }

            // Animate title with soft pop
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                titleScale = 1.0
                titleOpacity = 1.0
            }

            // Start typing subtitle after title appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.3)) {
                    descriptionOpacity = 1.0
                }
                startTypingAnimation()
            }

            // Trigger animations
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                titleOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
                buttonsOpacity = 1.0
            }

            // Floating animation
            withAnimation(.easeInOut(duration: 3.0).delay(1.0).repeatForever(autoreverses: true)) {
                floatingOffset = -15
            }

            // Initial text animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    textAppearAnimation = true
                }

                // Start description typing after title appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    startDescriptionTyping()
                }
            }
        }
    }
    
    // Helper method to trigger text animation on page change
    private func triggerTextAnimation() {
        // Reset animation state
        typedDescription = ""
        withAnimation(.easeOut(duration: 0.1)) {
            textAppearAnimation = false
        }

        // Small delay to ensure the state reset is processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                textAppearAnimation = true
            }

            // Start description typing after title appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                startDescriptionTyping()
            }
        }
    }

    // Typing animation for subtitle
    private func startTypingAnimation() {
        typedSubtitle = ""
        let characters = Array(fullSubtitle)

        for (index, character) in characters.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                typedSubtitle.append(character)
            }
        }
    }

    // Typing animation for description
    private func startDescriptionTyping() {
        typedDescription = ""
        let description = pageContent[currentPage].description
        let characters = Array(description)

        for (index, character) in characters.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.03) {
                typedDescription.append(character)
            }
        }
    }

    // Haptic feedback animation that syncs with blur/pop animation
    private func startHapticSequence() {
        // Total duration should match animation (~1.2 seconds)
        let totalDuration: Double = 1.2

        // Phase 1: Fast soft impacts (0.0 - 0.4s) - Light vibration feel
        let phase1Duration: Double = 0.4
        let phase1Interval: Double = 0.05 // 20 impacts per second
        let phase1Count = Int(phase1Duration / phase1Interval)

        let softGenerator = UIImpactFeedbackGenerator(style: .soft)
        softGenerator.prepare()

        for i in 0..<phase1Count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * phase1Interval) {
                softGenerator.impactOccurred(intensity: 0.5)
            }
        }

        // Phase 2: Transition period (0.4 - 0.7s) - Slowing down, mixing soft and medium
        let phase2Start: Double = 0.4
        let phase2Duration: Double = 0.3
        let phase2Intervals: [Double] = [0.08, 0.10, 0.12] // Gradually slower

        let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
        mediumGenerator.prepare()

        var currentTime = phase2Start
        for interval in phase2Intervals {
            DispatchQueue.main.asyncAfter(deadline: .now() + currentTime) {
                mediumGenerator.impactOccurred(intensity: 0.7)
            }
            currentTime += interval
        }

        // Phase 3: Slow rigid impacts (0.7 - 1.2s) - Pronounced, spaced out
        let phase3Start: Double = 0.7
        let phase3Intervals: [Double] = [0.15, 0.18, 0.20] // Much slower

        let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
        rigidGenerator.prepare()

        currentTime = phase3Start
        for interval in phase3Intervals {
            DispatchQueue.main.asyncAfter(deadline: .now() + currentTime) {
                rigidGenerator.impactOccurred(intensity: 1.0)
            }
            currentTime += interval
        }
    }
}

#Preview {
    LandingPageView(showSignUp: .constant(false), showSignIn: .constant(false))
        .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
}
