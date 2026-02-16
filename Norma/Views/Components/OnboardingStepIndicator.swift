//
//  OnboardingStepIndicator.swift
//  Norma
//
//  Created by Claude on 1/25/26.
//

import SwiftUI

struct OnboardingStepIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    @State private var displayedStep: Int = 0

    var body: some View {
        HStack(spacing: 0) {
            Spacer()

            Text("\(displayedStep)")
                .font(.normaHeadline(24))
                .foregroundColor(.primary)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.3), value: displayedStep)

            Text(" / \(totalSteps)")
                .font(.custom(FontFamily.Rubik.regular, size: 13))
                .foregroundColor(.secondary.opacity(0.5))
                .baselineOffset(2)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                displayedStep = currentStep
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingStepIndicator(currentStep: 1, totalSteps: 9)
        OnboardingStepIndicator(currentStep: 5, totalSteps: 9)
        OnboardingStepIndicator(currentStep: 9, totalSteps: 9)
    }
    .padding()
    .background(Color("NormaBackground"))
    .preferredColorScheme(.dark)
}
