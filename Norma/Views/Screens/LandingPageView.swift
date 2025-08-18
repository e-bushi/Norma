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
    @State private var logoScale = 0.8
    @State private var logoOpacity = 0.0
    @State private var titleOpacity = 0.0
    @State private var descriptionOpacity = 0.0
    @State private var buttonsOpacity = 0.0
    @State private var floatingOffset: CGFloat = 0
    
    // Text animation states
    @State private var textAppearAnimation = false
    @State private var currentPage = 0
    
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
                VStack(spacing: 32) {
                    // Mock views section - Swipeable horizontal layout
                    TabView(selection: $currentPage) {
                        // Mini Budget Disclosure View
                        MiniBudgetDisclosureView()
                            .padding(.horizontal, 24)
                            .tag(0)
                        
                        // Mini Expense Calendar View
                        MiniExpenseCalendarView()
                            .padding(.horizontal, 24)
                            .tag(1)
                        
                        // Mini Expense Disclosure View
                        MiniExpenseDisclosureView()
                            .padding(.horizontal, 24)
                            .tag(2)
                        
                        // Mini Chat View
                        MiniChatView()
                            .padding(.horizontal, 24)
                            .tag(3)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    // Fixed height for consistent layout
                    .opacity(titleOpacity)
                    .onChange(of: currentPage) {
                        triggerTextAnimation()
                    }
                    
                    // Animated title and description
                    VStack(spacing: 12) {
                        Text(pageContent[currentPage].title)
                            .font(.system(size: 24, weight: .bold))
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
                        
                        Text(pageContent[currentPage].description)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .offset(x: textAppearAnimation ? 0 : -20)
                            .scaleEffect(textAppearAnimation ? 1 : 0.95)
                            .opacity(textAppearAnimation ? 1 : 0)
                            .rotation3DEffect(
                                .degrees(textAppearAnimation ? 0 : -5),
                                axis: (x: 0.0, y: 1.0, z: 0.0)
                            )
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0.3)
                                .delay(0.3),
                                value: textAppearAnimation
                            )
                    }
                    .padding(.horizontal, 32)
                    
                    // Custom page indicator dots
                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.purple : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 20)
            
            // Bottom buttons
            VStack(spacing: 16) {
                // Sign Up button
                Button(action: {
                    showSignUp = true
                    onboardingViewModel.currentStep = .authentication
                }) {
                    Text("Sign up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.3), lineWidth: 1.5)
                                )
                        )
                }
                
                // Sign In button
                Button(action: {
                    showSignIn = true
                    showSignUp = false
                    onboardingViewModel.currentStep = .authentication
                }) {
                    Text("Sign in")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
            .opacity(buttonsOpacity)
            }
            .background(Color(UIColor.systemBackground))
        }
        .onAppear {
            // Trigger animations
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                titleOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                descriptionOpacity = 1.0
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
            }
        }
    }
    
    // Helper method to trigger text animation on page change
    private func triggerTextAnimation() {
        // Reset animation state
        withAnimation(.easeOut(duration: 0.1)) {
            textAppearAnimation = false
        }
        
        // Small delay to ensure the state reset is processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                textAppearAnimation = true
            }
        }
    }
}

#Preview {
    LandingPageView(showSignUp: .constant(false), showSignIn: .constant(false))
        .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
}
