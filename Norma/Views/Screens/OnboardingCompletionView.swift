//
//  OnboardingCompletionView.swift
//  Norma
//
//  Created by Claude on 6/29/25.
//

import SwiftUI

struct OnboardingCompletionView: View {
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @State private var showContent = false
    @State private var showCheckmark = false
    @State private var showTitle = false
    @State private var showItems = [false, false, false]
    @State private var showLoading = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Success animation
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.green.opacity(0.15),
                                        Color.blue.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .scaleEffect(showCheckmark ? 1 : 0.1)
                            .opacity(showCheckmark ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3), value: showCheckmark)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Perfect! We're all set")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .opacity(showTitle ? 1 : 0)
                            .offset(y: showTitle ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.6), value: showTitle)
                        
                        Text("Your financial companion is ready")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(showTitle ? 1 : 0)
                            .offset(y: showTitle ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.8), value: showTitle)
                    }
                }
                
                // Preview of collected data
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Profile Setup")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Name, preferences, and goals")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                            .opacity(showItems[0] ? 1 : 0)
                            .scaleEffect(showItems[0] ? 1 : 0.5)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(1.2), value: showItems[0])
                    }
                    .opacity(showItems[0] ? 1 : 0)
                    .offset(x: showItems[0] ? 0 : -30)
                    
                    HStack(spacing: 16) {
                        Image(systemName: "dollarsign.circle.badge.checkmark")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Financial Overview")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Income and currency settings")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                            .opacity(showItems[1] ? 1 : 0)
                            .scaleEffect(showItems[1] ? 1 : 0.5)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(1.4), value: showItems[1])
                    }
                    .opacity(showItems[1] ? 1 : 0)
                    .offset(x: showItems[1] ? 0 : -30)
                    
                    HStack(spacing: 16) {
                        Image(systemName: "bell.badge.checkmark")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Smart Reminders")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Personalized notification settings")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                            .opacity(showItems[2] ? 1 : 0)
                            .scaleEffect(showItems[2] ? 1 : 0.5)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(1.6), value: showItems[2])
                    }
                    .opacity(showItems[2] ? 1 : 0)
                    .offset(x: showItems[2] ? 0 : -30)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 32)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
                
                // Loading indicator
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .opacity(showLoading ? 1 : 0)
                        
                        Text("Preparing your dashboard...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .opacity(showLoading ? 1 : 0)
                    }
                    .animation(.easeIn(duration: 0.4).delay(1.8), value: showLoading)
                }
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            // Trigger animations in sequence
            withAnimation {
                showContent = true
            }
            
            // Main checkmark
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showCheckmark = true
            }
            
            // Title texts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showTitle = true
            }
            
            // List items
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showItems[0] = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                showItems[1] = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                showItems[2] = true
            }
            
            // Loading indicator
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                showLoading = true
            }
            
            // Complete the onboarding after showing all animations
            Task {
                try? await Task.sleep(nanoseconds: 4_500_000_000) // 4.5 seconds
                await MainActor.run {
                    print("🎯 [DEBUG] OnboardingCompletionView - Setting completion flags")
                    print("🎯 [DEBUG] Before - hasCompletedOnboarding: \(sessionViewModel.hasCompletedOnboarding)")
                    print("🎯 [DEBUG] Before - hasCompletedInitialSetup: \(sessionViewModel.hasCompletedInitialSetup)")
                    
                    // Mark both onboarding and initial setup as complete - data is already saved
                    sessionViewModel.hasCompletedOnboarding = true
                    sessionViewModel.hasCompletedInitialSetup = true
                    sessionViewModel.shouldShowOnboarding = false
                    
                    print("🎯 [DEBUG] After - hasCompletedOnboarding: \(sessionViewModel.hasCompletedOnboarding)")
                    print("🎯 [DEBUG] After - hasCompletedInitialSetup: \(sessionViewModel.hasCompletedInitialSetup)")
                    print("🎯 [DEBUG] After - isAuthenticated: \(sessionViewModel.isAuthenticated)")
                    print("🎯 [DEBUG] After - shouldShowMainApp: \(sessionViewModel.shouldShowMainApp)")
                }
            }
        }
    }
}

#Preview {
    OnboardingCompletionView()
        .environmentObject(SessionViewModel(dataManager: DataManager()))
        .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
}
