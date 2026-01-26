//
//  OnboardingEncouragementView.swift
//  Norma
//
//  Created by Claude on 1/25/26.
//

import SwiftUI

struct OnboardingEncouragementView: View {
    let onContinue: () -> Void

    @State private var animateIcon = false
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateButton = false
    @State private var pulseAnimation = false

    private let stepNumber = 8
    private let totalSteps = 13

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            OnboardingProgressBar(currentStep: stepNumber, totalSteps: totalSteps)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            Spacer()

            // Celebratory icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color("NormaPastelTeal").opacity(0.3),
                                Color("NormaPastelTeal").opacity(0.0)
                            ]),
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0.5 : 0.8)

                // Main icon circle
                Circle()
                    .fill(Color("NormaPastelTeal"))
                    .frame(width: 120, height: 120)
                    .shadow(color: Color("NormaPastelTeal").opacity(0.5), radius: 20, x: 0, y: 10)

                Image(systemName: "star.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white)
            }
            .scaleEffect(animateIcon ? 1.0 : 0.3)
            .opacity(animateIcon ? 1.0 : 0.0)

            Spacer()
                .frame(height: 48)

            // Title
            Text("You're already ahead")
                .font(.normaHeadline(32))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .scaleEffect(animateTitle ? 1.0 : 0.9)
                .opacity(animateTitle ? 1.0 : 0.0)

            Spacer()
                .frame(height: 16)

            // Subtitle
            Text("Most people never take this step.\nYou just did.")
                .normaBody()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
                .opacity(animateSubtitle ? 1.0 : 0.0)
                .offset(y: animateSubtitle ? 0 : 10)

            Spacer()

            // Transition text
            Text("Now let me show you what I can do")
                .normaCaption()
                .foregroundColor(.secondary)
                .padding(.bottom, 16)
                .opacity(animateButton ? 1.0 : 0.0)

            // Continue button
            Button(action: onContinue) {
                Text("Show me")
                    .font(.normaHeadline(16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("NormaPastelTeal"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .scaleEffect(animateButton ? 1.0 : 0.9)
            .opacity(animateButton ? 1.0 : 0.0)
        }
        .background(Color("NormaBackground").ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateIcon = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                animateTitle = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5)) {
                animateSubtitle = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.7)) {
                animateButton = true
            }
            // Start pulse animation
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.5)) {
                pulseAnimation = true
            }
        }
    }
}

#Preview {
    OnboardingEncouragementView {
        print("Continue tapped")
    }
    .preferredColorScheme(.dark)
}
