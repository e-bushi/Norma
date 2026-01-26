//
//  FeatureShowcaseView.swift
//  Norma
//
//  Created by Claude on 1/25/26.
//

import SwiftUI

// MARK: - Feature Types

enum OnboardingFeature: CaseIterable {
    case screenshot
    case moneyTasks
    case purchasingPower
    case challenges
    case freedomFund

    var title: String {
        switch self {
        case .screenshot:
            return "See a bill? Screenshot it."
        case .moneyTasks:
            return "Create reminders by chatting"
        case .purchasingPower:
            return "Know what you can really spend"
        case .challenges:
            return "Make saving fun"
        case .freedomFund:
            return "Watch your safety net grow"
        }
    }

    var subtitle: String {
        switch self {
        case .screenshot:
            return "Norma reads it and adds it for you"
        case .moneyTasks:
            return "Just tell Norma what you need"
        case .purchasingPower:
            return "See your true spending power after bills"
        case .challenges:
            return "Take on challenges, earn rewards, collect companions"
        case .freedomFund:
            return "Your emergency fund, visualized"
        }
    }

    var stepNumber: Int {
        switch self {
        case .screenshot: return 9
        case .moneyTasks: return 10
        case .purchasingPower: return 11
        case .challenges: return 12
        case .freedomFund: return 13
        }
    }

    var accentColor: Color {
        switch self {
        case .screenshot: return Color("NormaPastelPurple")
        case .moneyTasks: return Color("NormaPastelTeal")
        case .purchasingPower: return Color("NormaPastelCoral")
        case .challenges: return Color("NormaPastelYellow")
        case .freedomFund: return Color("NormaPastelTeal")
        }
    }
}

// MARK: - Main View

struct FeatureShowcaseView: View {
    let feature: OnboardingFeature
    let onContinue: () -> Void

    @State private var animateVisual = false
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateMockup = false
    @State private var animateButton = false

    private let totalSteps = 13

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            OnboardingProgressBar(currentStep: feature.stepNumber, totalSteps: totalSteps)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            Spacer()

            // Visual representation
            featureVisual
                .frame(height: 220)
                .scaleEffect(animateVisual ? 1.0 : 0.8)
                .opacity(animateVisual ? 1.0 : 0.0)

            Spacer()
                .frame(height: 32)

            // Title
            Text(feature.title)
                .font(.normaHeadline(28))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .scaleEffect(animateTitle ? 1.0 : 0.9)
                .opacity(animateTitle ? 1.0 : 0.0)

            Spacer()
                .frame(height: 12)

            // Subtitle
            Text(feature.subtitle)
                .normaBody()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
                .opacity(animateSubtitle ? 1.0 : 0.0)
                .offset(y: animateSubtitle ? 0 : 10)

            Spacer()
                .frame(height: 32)

            // Feature mockup/preview
            featureMockup
                .padding(.horizontal, 24)
                .opacity(animateMockup ? 1.0 : 0.0)
                .offset(y: animateMockup ? 0 : 20)

            Spacer()

            // Continue button
            Button(action: onContinue) {
                Text(feature == .freedomFund ? "Let's go!" : "Continue")
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
                animateVisual = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                animateTitle = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4)) {
                animateSubtitle = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5)) {
                animateMockup = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.6)) {
                animateButton = true
            }
        }
    }

    @ViewBuilder
    private var featureVisual: some View {
        switch feature {
        case .screenshot:
            ScreenshotFeatureVisual()
        case .moneyTasks:
            MoneyTasksFeatureVisual()
        case .purchasingPower:
            PurchasingPowerFeatureVisual()
        case .challenges:
            ChallengesFeatureVisual()
        case .freedomFund:
            FreedomFundFeatureVisual()
        }
    }

    @ViewBuilder
    private var featureMockup: some View {
        switch feature {
        case .screenshot:
            ScreenshotMockup()
        case .moneyTasks:
            MoneyTasksMockup()
        case .purchasingPower:
            PurchasingPowerMockup()
        case .challenges:
            ChallengesMockup()
        case .freedomFund:
            FreedomFundMockup()
        }
    }
}

// MARK: - Feature Visuals

struct ScreenshotFeatureVisual: View {
    @State private var showArrow = false

    var body: some View {
        HStack(spacing: 24) {
            // Phone with screenshot
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("NormaSurface"))
                    .frame(width: 80, height: 160)

                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 32))
                        .foregroundColor(Color("NormaPastelPurple"))

                    Text("Bill")
                        .normaCaption()
                        .foregroundColor(.secondary)
                }
            }

            // Arrow
            Image(systemName: "arrow.right")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color("NormaPastelTeal"))
                .opacity(showArrow ? 1.0 : 0.0)
                .offset(x: showArrow ? 0 : -10)

            // Norma icon
            ZStack {
                Circle()
                    .fill(Color("NormaPastelTeal"))
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5)) {
                showArrow = true
            }
        }
    }
}

struct MoneyTasksFeatureVisual: View {
    var body: some View {
        ZStack {
            // Chat bubble
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("NormaSurface"))
                .frame(width: 200, height: 100)

            VStack(spacing: 4) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 32))
                    .foregroundColor(Color("NormaPastelTeal"))

                Text("Reminder set!")
                    .font(.normaHeadline(14))
                    .foregroundColor(.primary)
            }
        }
    }
}

struct PurchasingPowerFeatureVisual: View {
    @State private var fillAmount: CGFloat = 0

    var body: some View {
        VStack(spacing: 16) {
            // Gauge visual
            ZStack {
                Circle()
                    .stroke(Color("NormaSurface"), lineWidth: 12)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: fillAmount)
                    .stroke(Color("NormaPastelCoral"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("$2,450")
                        .font(.normaHeadline(24))
                        .foregroundColor(.primary)

                    Text("Available")
                        .normaCaption()
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                fillAmount = 0.65
            }
        }
    }
}

struct ChallengesFeatureVisual: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color("NormaPastelYellow").opacity(0.2))
                .frame(width: 180, height: 180)

            // Use the existing StaticBird3DView with default fileName
            StaticBird3DView()
                .frame(width: 140, height: 140)
        }
    }
}

struct FreedomFundFeatureVisual: View {
    @State private var fillProgress: CGFloat = 0

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color("NormaPastelTeal").opacity(0.1))
                .frame(width: 180, height: 180)

            // Use the Arc3DView without parameters
            Arc3DView()
                .frame(width: 160, height: 160)
        }
    }
}

// MARK: - Feature Mockups

struct ScreenshotMockup: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 20))
                .foregroundColor(Color("NormaPastelPurple"))

            Text("Share any screenshot with Norma")
                .normaCaption()
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color("NormaSurface"))
        .cornerRadius(12)
    }
}

struct MoneyTasksMockup: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // User message
            HStack {
                Spacer()
                Text("Remind me to pay rent on the 1st")
                    .normaCaption()
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color("NormaPastelTeal"))
                    .cornerRadius(16)
            }

            // Norma response
            HStack {
                Text("Done! I'll remind you on the 1st of each month.")
                    .normaCaption()
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color("NormaSurface"))
                    .cornerRadius(16)
                Spacer()
            }
        }
    }
}

struct PurchasingPowerMockup: View {
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Income")
                    .normaCaption()
                    .foregroundColor(.secondary)
                Text("$5,000")
                    .font(.normaHeadline(14))
                    .foregroundColor(.primary)
            }

            Image(systemName: "minus")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Bills")
                    .normaCaption()
                    .foregroundColor(.secondary)
                Text("$2,550")
                    .font(.normaHeadline(14))
                    .foregroundColor(Color("NormaPastelCoral"))
            }

            Image(systemName: "equal")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Spending Power")
                    .normaCaption()
                    .foregroundColor(.secondary)
                Text("$2,450")
                    .font(.normaHeadline(14))
                    .foregroundColor(Color("NormaPastelTeal"))
            }
        }
        .padding()
        .background(Color("NormaSurface"))
        .cornerRadius(12)
    }
}

struct ChallengesMockup: View {
    var body: some View {
        HStack(spacing: 12) {
            // Challenge card
            VStack(spacing: 8) {
                Image(systemName: "flame")
                    .font(.system(size: 20))
                    .foregroundColor(Color("NormaPastelYellow"))

                Text("No-Spend Day")
                    .normaCaption()
                    .foregroundColor(.primary)

                Text("+50 pts")
                    .normaCaption()
                    .foregroundColor(Color("NormaPastelTeal"))
            }
            .padding()
            .background(Color("NormaSurface"))
            .cornerRadius(12)

            VStack(spacing: 8) {
                Image(systemName: "cart.badge.minus")
                    .font(.system(size: 20))
                    .foregroundColor(Color("NormaPastelPurple"))

                Text("Skip Takeout")
                    .normaCaption()
                    .foregroundColor(.primary)

                Text("+75 pts")
                    .normaCaption()
                    .foregroundColor(Color("NormaPastelTeal"))
            }
            .padding()
            .background(Color("NormaSurface"))
            .cornerRadius(12)
        }
    }
}

struct FreedomFundMockup: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Emergency Fund")
                    .font(.normaHeadline(14))
                    .foregroundColor(.primary)
                Spacer()
                Text("$1,500 / $5,000")
                    .normaCaption()
                    .foregroundColor(.secondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("NormaSurface"))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("NormaPastelTeal"))
                        .frame(width: geometry.size.width * 0.3, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color("NormaSurface").opacity(0.5))
        .cornerRadius(12)
    }
}

#Preview {
    FeatureShowcaseView(feature: .screenshot) {
        print("Continue tapped")
    }
    .preferredColorScheme(.dark)
}
