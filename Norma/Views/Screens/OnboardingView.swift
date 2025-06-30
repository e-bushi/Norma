//
//  OnboardingView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI
import UIKit

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showTransition = false
    @State private var fadeOut = false
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with subtle background
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        imageName: "chart.line.uptrend.xyaxis",
                        title: "Welcome\(onboardingViewModel.collectedData.name.isEmpty ? "" : ", \(onboardingViewModel.collectedData.name.split(separator: " ").first ?? "")")!",
                        description: "Keep all your bills, expenses, and income organized in one place with smart tracking and insights.",
                        pageIndex: 0
                    )
                    .tag(0)
                    
                    OnboardingPageView(
                        imageName: "bell.badge",
                        title: "Never Miss a Payment",
                        description: "Get timely reminders for upcoming bills and stay on top of your financial obligations effortlessly.",
                        pageIndex: 1
                    )
                    .tag(1)
                    
                    OnboardingPageView(
                        imageName: "chart.pie",
                        title: "Smart Budgeting",
                        description: "Set budgets, track spending patterns, and achieve your financial goals with detailed analytics.",
                        pageIndex: 2
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(UIColor.systemBackground),
                        Color.gray.opacity(0.02)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Bottom controls with BillHomeView styling
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(UIColor.systemBackground),
                                Color.gray.opacity(0.02)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.2),
                                        Color.gray.opacity(0.05)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
                
                VStack(spacing: 24) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(currentPage == index ? Color.primary : Color.gray.opacity(0.2))
                                .frame(width: currentPage == index ? 28 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Primary button
                    Button(action: {
                        if currentPage < 2 {
                            withAnimation(.spring(response: 0.3)) {
                                currentPage += 1
                            }
                        } else {
                            startTransition()
                        }
                    }) {
                        HStack {
                            Text(currentPage < 2 ? "Continue" : "Get started")
                                .font(.system(size: 16, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(Color(UIColor.systemBackground))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.primary)
                                .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Skip button
                    if currentPage < 2 {
                        Button(action: {
                            startTransition()
                        }) {
                            Text("Skip")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 8)
                    }
                }
                .padding(.vertical, 20)
            }
            .frame(height: 180)
            .padding(.horizontal)
            .padding(.horizontal)
        }
        .background(Color(UIColor.systemBackground))
        .opacity(fadeOut ? 0 : 1)
        .overlay(
            Group {
                if showTransition {
                    ZStack {
                        Color(UIColor.systemBackground)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 24) {
                            // Welcome message
                            VStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 48))
                                    .foregroundColor(.primary)
                                    .symbolEffect(.bounce, value: showTransition)
                                
                                Text("Setting up your personal finance assistant...")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                                    .padding(.top, 8)
                            }
                            .padding(40)
                        }
                    }
                    .transition(.opacity)
                }
            }
        )
    }
    
    private func startTransition() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Fade out current content
        withAnimation(.easeOut(duration: 0.3)) {
            fadeOut = true
        }
        
        // Show transition screen after fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeIn(duration: 0.3)) {
                showTransition = true
            }
            
            // Navigate to chat after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onboardingViewModel.currentStep = .normaChat
            }
        }
    }
}

struct OnboardingPageView: View {
    let imageName: String
    let title: String
    let description: String
    let pageIndex: Int
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon container with enhanced styling
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(UIColor.systemBackground),
                                Color.gray.opacity(0.02)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.2),
                                        Color.gray.opacity(0.05)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                
                Image(systemName: imageName)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 60)
            
            Spacer()
            
            // Content container
            VStack(spacing: 20) {
                // Title with enhanced typography
                VStack(spacing: 8) {
                    Text("STEP \(pageIndex + 1)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                    
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                }
                
                // Description with better styling
                Text(description)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
        .preferredColorScheme(.light)
}
