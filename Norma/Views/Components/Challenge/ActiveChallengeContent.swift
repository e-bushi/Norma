//
//  ActiveChallengeContent.swift
//  Norma
//
//  Created by Claude on 1/17/26.
//

import SwiftUI

/// Main content view for an active challenge
struct ActiveChallengeContent: View {
    let challenge: Challenge
    @Binding var heroAppeared: Bool
    @Binding var statsAppeared: Bool
    @Binding var calendarAppeared: Bool
    @Binding var transactionsAppeared: Bool
    @Binding var showBirdCollection: Bool
    var onDayLongPressed: ((Date) -> Void)? = nil

    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var selectedDay: ChallengeDay?
    @State private var waveAnimating = false

    private var percentUsed: Int {
        guard challenge.amountTotal > 0 else { return 0 }
        let used = challenge.amountTotal - challenge.amountRemaining
        return min(100, max(0, Int((used / challenge.amountTotal) * 100)))
    }

    private var percentColor: Color {
        if percentUsed >= 90 {
            return Color("NormaPastelCoral")
        } else if percentUsed >= 70 {
            return Color("NormaPastelYellow")
        } else {
            return Color("NormaPastelTeal")
        }
    }

    private var waveWords: [(word: String, color: Color)] {
        var words: [(String, Color)] = []
        words.append(("You've", .primary))
        words.append(("used", .primary))
        words.append(("\(percentUsed)%", percentColor))
        words.append(("of", .primary))
        words.append(("your", .primary))
        words.append(("total", .primary))
        words.append(("cap.", .primary))
        return words
    }

    private var challengeDays: [ChallengeDay] {
        challengeViewModel.getChallengeDays()
    }

    private func shortDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Info capsules
            HStack(spacing: 10) {
                Text("\(challenge.durationDays) day challenge")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.08))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                    )

                Text("\(profileViewModel.formatCurrency(challenge.amountRemaining)) left")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.08))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                    )
            }
            .padding(.top, 16)
            .scaleEffect(heroAppeared ? 1 : 0.95)
            .opacity(heroAppeared ? 1 : 0)
            .offset(y: heroAppeared ? 0 : 20)

            // Main statement
            ColoredWaveTextView(
                words: waveWords,
                font: .normaHeadline(64),
                isAnimating: waveAnimating,
                alignment: .leading
            )
            .scaleEffect(statsAppeared ? 1 : 0.97)
            .opacity(statsAppeared ? 1 : 0)
            .offset(y: statsAppeared ? 0 : 15)

            // Day capsules - wrapping flow layout
            FlowLayout(spacing: 8) {
                ForEach(challengeDays) { day in
                    ChallengeDayCapsule(
                        day: day,
                        isSelected: selectedDay != nil && Calendar.current.isDate(selectedDay!.date, inSameDayAs: day.date),
                        formattedDate: shortDate(for: day.date),
                        formattedSpending: profileViewModel.formatCurrency(day.spending)
                    )
                    .pressableStyle(
                        onTap: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDay = day
                            }
                        },
                        onLongPress: {
                            let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
                            mediumImpact.impactOccurred()
                            onDayLongPressed?(day.date)
                        }
                    )
                }
            }
            .scaleEffect(calendarAppeared ? 1 : 0.97)
            .opacity(calendarAppeared ? 1 : 0)
            .offset(y: calendarAppeared ? 0 : 15)

            // Transactions for selected day
            if let day = selectedDay {
                ChallengeExpenseList(
                    selectedDay: day,
                    expenses: challengeViewModel.getExpenses(for: day.date)
                )
                .scaleEffect(transactionsAppeared ? 1 : 0.97)
                .opacity(transactionsAppeared ? 1 : 0)
                .offset(y: transactionsAppeared ? 0 : 15)
            }

            Spacer(minLength: 40)
        }
        .onAppear {
            // Select today by default
            let days = challengeViewModel.getChallengeDays()
            selectedDay = days.first { $0.isToday } ?? days.first
        }
        .onChange(of: statsAppeared) { _, appeared in
            // Trigger wave animation when the headline section appears
            if appeared {
                waveAnimating = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    waveAnimating = true
                }
            }
        }
    }
}

// MARK: - Challenge Day Capsule

/// A capsule showing the date and amount spent for a challenge day.
/// Future days that haven't occurred yet use a dashed border.
private struct ChallengeDayCapsule: View {
    let day: ChallengeDay
    let isSelected: Bool
    let formattedDate: String
    let formattedSpending: String

    private var isFuture: Bool {
        !day.isPast && !day.isToday
    }

    private var isExperienced: Bool {
        day.isPast || day.isToday
    }

    private var strokeColor: Color {
        if isSelected {
            return Color("NormaPastelTeal").opacity(0.5)
        } else if isFuture {
            return Color.gray.opacity(0.2)
        } else if day.isToday {
            return Color("NormaPastelTeal").opacity(0.3)
        } else {
            return Color.gray.opacity(0.15)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(formattedDate)
                .font(.custom(FontFamily.Rubik.medium, size: 15))
                .foregroundColor(isSelected || day.isToday ? .primary : .secondary)

            if isFuture {
                Text("—")
                    .font(.custom(FontFamily.Rubik.regular, size: 16))
                    .foregroundColor(.secondary.opacity(0.5))
            } else {
                Text(formattedSpending)
                    .font(.normaFinancial(16))
                    .foregroundColor(day.isOverBudget ? Color("NormaPastelCoral") : .primary)
                    .contentTransition(.numericText(countsDown: false))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background {
            if isExperienced {
                Capsule()
                    .fill(.clear)
                    .glassEffect(in: Capsule())
            } else {
                Capsule()
                    .fill(Color.gray.opacity(0.05))
            }
        }
        .overlay(
            Capsule()
                .stroke(
                    strokeColor,
                    style: isFuture ? StrokeStyle(lineWidth: 1, dash: [5, 4]) : StrokeStyle(lineWidth: isSelected ? 1.5 : 0.5)
                )
        )
    }
}

// MARK: - Previews

// MARK: - Pressable Style Modifier

private struct PressableModifier: ViewModifier {
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.93 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .onLongPressGesture(minimumDuration: 0.5) {
                onLongPress()
            } onPressingChanged: { pressing in
                isPressed = pressing
                if !pressing {
                    // Short press = tap
                }
            }
            .simultaneousGesture(
                TapGesture().onEnded {
                    onTap()
                }
            )
    }
}

private extension View {
    func pressableStyle(onTap: @escaping () -> Void, onLongPress: @escaping () -> Void) -> some View {
        modifier(PressableModifier(onTap: onTap, onLongPress: onLongPress))
    }
}

// MARK: - Previews

#Preview("Active Challenge - Day 1") {
    ScrollView(showsIndicators: false) {
        ActiveChallengeContent(
            challenge: Challenge(
                id: "preview-1",
                userId: "user",
                amountTotal: 500,
                amountRemaining: 500,
                currency: "USD",
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date(),
                status: .active,
                difficulty: .medium,
                durationDays: 5
            ),
            heroAppeared: .constant(true),
            statsAppeared: .constant(true),
            calendarAppeared: .constant(true),
            transactionsAppeared: .constant(true),
            showBirdCollection: .constant(false)
        )
        .padding(.horizontal, 20)
    }
    .background(Color("NormaBackground"))
    .environmentObject(ChallengeViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}

#Preview("Active Challenge - Mid Challenge") {
    ScrollView(showsIndicators: false) {
        ActiveChallengeContent(
            challenge: Challenge(
                id: "preview-2",
                userId: "user",
                amountTotal: 500,
                amountRemaining: 320,
                currency: "USD",
                startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
                status: .active,
                difficulty: .hard,
                durationDays: 5
            ),
            heroAppeared: .constant(true),
            statsAppeared: .constant(true),
            calendarAppeared: .constant(true),
            transactionsAppeared: .constant(true),
            showBirdCollection: .constant(false)
        )
        .padding(.horizontal, 20)
    }
    .background(Color("NormaBackground"))
    .environmentObject(ChallengeViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}
