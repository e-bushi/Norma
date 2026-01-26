//
//  OnboardingQuestionView.swift
//  Norma
//
//  Created by Claude on 1/25/26.
//

import SwiftUI

// MARK: - Question Types

enum OnboardingQuestion: CaseIterable {
    case feelingsCheck
    case controlVision
    case moneyWorries
    case moneyTiming
    case moneyPersonality
    case yourWhy

    var title: String {
        switch self {
        case .feelingsCheck:
            return "How do you feel when you check your bank account?"
        case .controlVision:
            return "What would change if you felt in control of your money?"
        case .moneyWorries:
            return "What keeps you up at night about money?"
        case .moneyTiming:
            return "When do you usually think about money?"
        case .moneyPersonality:
            return "Pick your money personality"
        case .yourWhy:
            return "What's your why?"
        }
    }

    var options: [QuestionOption] {
        switch self {
        case .feelingsCheck:
            return [
                QuestionOption(id: "anxious", title: "Anxious", subtitle: "It stresses me out", icon: "bolt.heart"),
                QuestionOption(id: "confident", title: "Confident", subtitle: "I know where I stand", icon: "hand.thumbsup"),
                QuestionOption(id: "avoid", title: "I avoid it", subtitle: "Ignorance is bliss?", icon: "eye.slash"),
                QuestionOption(id: "depends", title: "It depends", subtitle: "Some days are better", icon: "arrow.left.arrow.right")
            ]
        case .controlVision:
            return [
                QuestionOption(id: "less_stress", title: "Less stress", subtitle: "Finally breathe easy", icon: "wind"),
                QuestionOption(id: "more_freedom", title: "More freedom", subtitle: "Do what I want", icon: "bird"),
                QuestionOption(id: "better_sleep", title: "Better sleep", subtitle: "No more worrying", icon: "moon.zzz"),
                QuestionOption(id: "save_matters", title: "Save for what matters", subtitle: "Goals become real", icon: "star")
            ]
        case .moneyWorries:
            return [
                QuestionOption(id: "bills", title: "Bills piling up", subtitle: "They never stop", icon: "doc.text"),
                QuestionOption(id: "not_saving", title: "Not saving enough", subtitle: "Where does it go?", icon: "arrow.down.circle"),
                QuestionOption(id: "overspending", title: "Overspending", subtitle: "It adds up fast", icon: "cart"),
                QuestionOption(id: "unexpected", title: "Unexpected expenses", subtitle: "Always something", icon: "exclamationmark.triangle"),
                QuestionOption(id: "nothing", title: "Nothing, I'm good", subtitle: "Just improving", icon: "checkmark.circle")
            ]
        case .moneyTiming:
            return [
                QuestionOption(id: "payday", title: "Payday", subtitle: "The good day", icon: "dollarsign.circle"),
                QuestionOption(id: "bills_hit", title: "When bills hit", subtitle: "Reality check", icon: "envelope"),
                QuestionOption(id: "sunday_dread", title: "Sunday night dread", subtitle: "Week ahead worries", icon: "moon"),
                QuestionOption(id: "end_month", title: "End of month", subtitle: "Checking what's left", icon: "calendar"),
                QuestionOption(id: "constantly", title: "Constantly", subtitle: "It's always there", icon: "clock")
            ]
        case .moneyPersonality:
            return [
                QuestionOption(id: "planner", title: "The Planner", subtitle: "Spreadsheets are life", icon: "tablecells"),
                QuestionOption(id: "spender", title: "The Spontaneous Spender", subtitle: "YOLO, right?", icon: "sparkles"),
                QuestionOption(id: "avoider", title: "The Avoider", subtitle: "What bank account?", icon: "eye.slash"),
                QuestionOption(id: "optimizer", title: "The Optimizer", subtitle: "Always hunting deals", icon: "magnifyingglass")
            ]
        case .yourWhy:
            return [
                QuestionOption(id: "family", title: "Family", subtitle: "For the people I love", icon: "heart"),
                QuestionOption(id: "freedom", title: "Freedom", subtitle: "Live on my terms", icon: "bird"),
                QuestionOption(id: "peace", title: "Peace of mind", subtitle: "Stop worrying", icon: "leaf"),
                QuestionOption(id: "goal", title: "A specific goal", subtitle: "Something I'm saving for", icon: "flag"),
                QuestionOption(id: "better", title: "Just want to do better", subtitle: "Growth mindset", icon: "arrow.up.right")
            ]
        }
    }

    var stepNumber: Int {
        switch self {
        case .feelingsCheck: return 1
        case .controlVision: return 2
        case .moneyWorries: return 3
        case .moneyTiming: return 4
        case .moneyPersonality: return 5
        case .yourWhy: return 6
        }
    }
}

struct QuestionOption: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
}

// MARK: - Main View

struct OnboardingQuestionView: View {
    let question: OnboardingQuestion
    let onContinue: (String) -> Void

    @State private var selectedOption: String? = nil
    @State private var animateTitle = false
    @State private var animateOptions = false
    @State private var animateButton = false

    private let totalSteps = 13

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            OnboardingProgressBar(currentStep: question.stepNumber, totalSteps: totalSteps)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            Spacer()

            // Question title
            Text(question.title)
                .font(.normaHeadline(28))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .scaleEffect(animateTitle ? 1.0 : 0.9)
                .opacity(animateTitle ? 1.0 : 0.0)

            Spacer()
                .frame(height: 40)

            // Options grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(Array(question.options.enumerated()), id: \.element.id) { index, option in
                    OptionCard(
                        option: option,
                        isSelected: selectedOption == option.id,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedOption = option.id
                            }
                        }
                    )
                    .opacity(animateOptions ? 1.0 : 0.0)
                    .offset(y: animateOptions ? 0 : 20)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05),
                        value: animateOptions
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            Button(action: {
                if let selected = selectedOption {
                    onContinue(selected)
                }
            }) {
                Text("Continue")
                    .font(.normaHeadline(16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(selectedOption != nil ? Color("NormaPastelTeal") : Color("NormaSurface"))
                    .cornerRadius(12)
            }
            .disabled(selectedOption == nil)
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
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                animateOptions = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4)) {
                animateButton = true
            }
        }
    }
}

// MARK: - Option Card

struct OptionCard: View {
    let option: QuestionOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: option.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? Color("NormaPastelTeal") : .primary)

                Text(option.title)
                    .font(.normaHeadline(14))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(option.subtitle)
                    .normaCaption()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("NormaSurface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color("NormaPastelTeal") : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingQuestionView(question: .feelingsCheck) { selected in
        print("Selected: \(selected)")
    }
    .preferredColorScheme(.dark)
}
