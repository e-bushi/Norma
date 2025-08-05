//
//  OnboardingView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI
import UIKit

struct OnboardingView: View {
    @State private var showTransition = false
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    
    var body: some View {
        ZStack {
            if !showTransition {
                NormaOnboardingStoryView(
                    onComplete: {
                        startTransition()
                    },
                    onSkip: {
                        startTransition()
                    }
                )
                .transition(.opacity)
            } else {
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
    }
    
    private func startTransition() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Show transition screen
        withAnimation(.easeIn(duration: 0.3)) {
            showTransition = true
        }
        
        // Navigate to notifications after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onboardingViewModel.currentStep = .notifications
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
        .preferredColorScheme(.light)
}
