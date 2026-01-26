//
//  OnboardingProgressBar.swift
//  Norma
//
//  Created by Claude on 1/25/26.
//

import SwiftUI

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    var accentColor: Color = Color("NormaPastelTeal")

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("NormaSurface"))
                    .frame(height: 8)

                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(accentColor)
                    .frame(width: progressWidth(totalWidth: geometry.size.width), height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
            }
        }
        .frame(height: 8)
    }

    private func progressWidth(totalWidth: CGFloat) -> CGFloat {
        guard totalSteps > 0 else { return 0 }
        let progress = CGFloat(currentStep) / CGFloat(totalSteps)
        return totalWidth * progress
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingProgressBar(currentStep: 1, totalSteps: 13)
        OnboardingProgressBar(currentStep: 5, totalSteps: 13)
        OnboardingProgressBar(currentStep: 10, totalSteps: 13)
        OnboardingProgressBar(currentStep: 13, totalSteps: 13)
    }
    .padding()
    .background(Color("NormaBackground"))
}
