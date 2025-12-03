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
    @State private var titleScale: CGFloat = 0.5
    @State private var titleOpacity = 0.0
    @State private var descriptionOpacity = 0.0
    @State private var buttonsOpacity = 0.0
    @State private var contentShouldBlur = true
    @State private var contentScale: CGFloat = 0.8
    @State private var typedSubtitle = ""
    @State private var typedDescription = ""

    // Text animation states
    @State private var textAppearAnimation = false
    @State private var currentPage = 0
    @State private var peekOffset: CGFloat = 0

    private let fullSubtitle = "Know what you can really afford"
    
    // Content for each page
    private let pageContent = [
        (title: "See Where It Goes", description: "Your spending by category. No guesswork."),
        (title: "Never Miss a Bill", description: "Every due date, right where you need it."),
        (title: "Quick Expense Logging", description: "Track purchases in seconds. Ask Norma to log it."),
        (title: "Ask Before You Buy", description: "Should I buy this? Just ask. I'll tell you if it's smart.")
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
                .padding(.top, 32)
                .padding(.bottom, 20)

                VStack(spacing: 20) {
                    // Mock views section - Swipeable horizontal layout
                    TabView(selection: $currentPage) {
                        // Mini Budget Disclosure View
                        MiniBudgetDisclosureView(appeared: currentPage == 0 && titleOpacity > 0)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .tag(0)

                        // Mini Expense Calendar View
                        MiniExpenseCalendarView(appeared: currentPage == 1 && titleOpacity > 0)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .tag(1)

                        // Mini Expense Disclosure View
                        MiniExpenseDisclosureView(appeared: currentPage == 2 && titleOpacity > 0)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .tag(2)

                        // Mini Chat View
                        MiniChatView(appeared: currentPage == 3 && titleOpacity > 0)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .tag(3)
                    }
                    .offset(x: peekOffset)
                    .frame(height: 320)
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
            // Single clean entrance for content
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                contentScale = 1.0
            }

            // Title with soft pop
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

            // Buttons fade in
            withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
                buttonsOpacity = 1.0
            }

            // Initial text animation for page content
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    textAppearAnimation = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    startDescriptionTyping()
                }
            }

            // Swipe hint animation - peek to show next card
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    peekOffset = -75
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.3)) {
                        peekOffset = 0
                    }
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
}

#Preview {
    LandingPageView(showSignUp: .constant(false), showSignIn: .constant(false))
        .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
}
