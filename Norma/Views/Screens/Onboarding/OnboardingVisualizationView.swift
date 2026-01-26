//
//  OnboardingVisualizationView.swift
//  Norma
//
//  Created by Claude on 1/25/26.
//

import SwiftUI

struct OnboardingVisualizationView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var animateTitle = false
    @State private var animateVision = false
    @State private var animateLines: [Bool] = [false, false, false, false]
    @State private var animateButton = false

    private let stepNumber = 7
    private let totalSteps = 13

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            OnboardingProgressBar(currentStep: stepNumber, totalSteps: totalSteps)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            Spacer()

            // Title
            VStack(spacing: 8) {
                Text("Imagine 3 months from now...")
                    .font(.normaHeadline(28))
                    .multilineTextAlignment(.center)
                    .scaleEffect(animateTitle ? 1.0 : 0.9)
                    .opacity(animateTitle ? 1.0 : 0.0)
            }
            .padding(.horizontal, 32)

            Spacer()
                .frame(height: 48)

            // Vision content
            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(visionLines.enumerated()), id: \.offset) { index, line in
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: line.icon)
                            .font(.system(size: 24))
                            .foregroundColor(Color("NormaPastelTeal"))
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(line.title)
                                .font(.normaHeadline(16))
                                .foregroundColor(.primary)

                            Text(line.description)
                                .normaBody()
                                .foregroundColor(.secondary)
                        }
                    }
                    .opacity(index < animateLines.count && animateLines[index] ? 1.0 : 0.0)
                    .offset(x: index < animateLines.count && animateLines[index] ? 0 : -20)
                }
            }
            .padding(24)
            .background(Color("NormaSurface"))
            .cornerRadius(16)
            .padding(.horizontal, 24)
            .scaleEffect(animateVision ? 1.0 : 0.95)
            .opacity(animateVision ? 1.0 : 0.0)

            Spacer()

            // Continue button
            Button(action: onContinue) {
                Text("I can see it")
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
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                animateTitle = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                animateVision = true
            }
            // Animate each line with staggered delay
            for i in 0..<animateLines.count {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5 + Double(i) * 0.15)) {
                    animateLines[i] = true
                }
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.2)) {
                animateButton = true
            }
        }
    }

    private var visionLines: [VisionLine] {
        // Personalize based on user responses
        var lines: [VisionLine] = []

        // Based on controlVision
        switch onboardingViewModel.controlVision {
        case "less_stress":
            lines.append(VisionLine(
                icon: "wind",
                title: "You wake up calm",
                description: "No more racing thoughts about money"
            ))
        case "more_freedom":
            lines.append(VisionLine(
                icon: "bird",
                title: "You feel free",
                description: "Making choices because you want to, not because you have to"
            ))
        case "better_sleep":
            lines.append(VisionLine(
                icon: "moon.zzz",
                title: "You sleep soundly",
                description: "No more 3am money anxiety"
            ))
        case "save_matters":
            lines.append(VisionLine(
                icon: "star",
                title: "Your goals are closer",
                description: "Every month, real progress toward what matters"
            ))
        default:
            lines.append(VisionLine(
                icon: "sparkles",
                title: "Things feel different",
                description: "Money is no longer a source of stress"
            ))
        }

        // Based on moneyWorry
        switch onboardingViewModel.moneyWorry {
        case "bills":
            lines.append(VisionLine(
                icon: "checkmark.circle",
                title: "Bills are handled",
                description: "You know exactly what's due and when"
            ))
        case "not_saving":
            lines.append(VisionLine(
                icon: "arrow.up.circle",
                title: "Your savings are growing",
                description: "Automatically, without even thinking about it"
            ))
        case "overspending":
            lines.append(VisionLine(
                icon: "chart.line.downtrend.xyaxis",
                title: "Spending is in control",
                description: "You know where every dollar goes"
            ))
        case "unexpected":
            lines.append(VisionLine(
                icon: "shield.checkered",
                title: "You have a safety net",
                description: "Unexpected expenses don't derail you anymore"
            ))
        default:
            lines.append(VisionLine(
                icon: "chart.bar",
                title: "You see the full picture",
                description: "Complete clarity on your finances"
            ))
        }

        // Based on userWhy
        switch onboardingViewModel.userWhy {
        case "family":
            lines.append(VisionLine(
                icon: "heart.fill",
                title: "Your family feels secure",
                description: "You're building something that lasts"
            ))
        case "freedom":
            lines.append(VisionLine(
                icon: "airplane.departure",
                title: "Options are opening up",
                description: "Life on your own terms gets closer"
            ))
        case "peace":
            lines.append(VisionLine(
                icon: "leaf.fill",
                title: "Your mind is at peace",
                description: "Money thoughts don't control your day"
            ))
        case "goal":
            lines.append(VisionLine(
                icon: "flag.fill",
                title: "Your goal is in sight",
                description: "What once felt impossible now feels inevitable"
            ))
        default:
            lines.append(VisionLine(
                icon: "arrow.up.right",
                title: "You're growing",
                description: "Every day, a little better than before"
            ))
        }

        // Always add the closing line
        lines.append(VisionLine(
            icon: "hands.clap",
            title: "And it started today",
            description: "Right here, with this decision"
        ))

        return lines
    }
}

struct VisionLine {
    let icon: String
    let title: String
    let description: String
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let onboardingViewModel = OnboardingViewModel(sessionViewModel: sessionViewModel)

    return OnboardingVisualizationView {
        print("Continue tapped")
    }
    .environmentObject(onboardingViewModel)
    .preferredColorScheme(.dark)
}
