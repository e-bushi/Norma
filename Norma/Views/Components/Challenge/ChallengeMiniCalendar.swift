//
//  ChallengeMiniCalendar.swift
//  Norma
//
//  Created by Claude on 1/17/26.
//

import SwiftUI

// MARK: - Combined Calendar + Stats View

/// Combined view showing day stats above the calendar
struct ChallengeDayCalendarView: View {
    let challenge: Challenge
    let challengeDays: [ChallengeDay]
    @Binding var selectedDay: ChallengeDay?
    @EnvironmentObject var profileViewModel: ProfileViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Stats header for selected day
            if let day = selectedDay {
                DayStatsHeader(selectedDay: day)
            }

            // Calendar grid
            ChallengeMiniCalendar(
                challenge: challenge,
                challengeDays: challengeDays,
                selectedDay: $selectedDay
            )
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.clear)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 16))

                // Radar rings from bottom-right
                Canvas { context, size in
                    let origin = CGPoint(x: size.width, y: size.height)
                    let ringCount = 8
                    let maxRadius: CGFloat = 250
                    let ringSpacing = maxRadius / CGFloat(ringCount)

                    for i in 1...ringCount {
                        let radius = CGFloat(i) * ringSpacing
                        let opacity = 0.12 * (1.0 - CGFloat(i) / CGFloat(ringCount))
                        let rect = CGRect(
                            x: origin.x - radius,
                            y: origin.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )
                        context.stroke(
                            Path(ellipseIn: rect),
                            with: .color(Color("NormaPastelTeal").opacity(opacity)),
                            lineWidth: 0.8
                        )
                    }
                }
                .allowsHitTesting(false)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        )
    }
}

// MARK: - Day Stats Header

/// Compact stats header showing spent, cap, and status for selected day
struct DayStatsHeader: View {
    let selectedDay: ChallengeDay
    @EnvironmentObject var profileViewModel: ProfileViewModel

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDay.date)
    }

    private var statusColor: Color {
        guard selectedDay.dailyCap != nil else { return .secondary }
        return selectedDay.isOverBudget ? Color("NormaPastelCoral") : Color("NormaPastelGreen")
    }

    private var statusIcon: String {
        guard selectedDay.dailyCap != nil else { return "circle.dashed" }
        return selectedDay.isOverBudget ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
    }

    private var statusText: String {
        guard let cap = selectedDay.dailyCap else { return "No cap set" }
        let difference = abs(cap - selectedDay.spending)
        let formattedDiff = profileViewModel.formatCurrency(difference)
        if selectedDay.isOverBudget {
            return "\(formattedDiff) over"
        } else {
            return "\(formattedDiff) under"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Date header row
            HStack {
                Text(dateText.uppercased())
                    .font(.normaInput(11))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                Spacer()
                if selectedDay.isToday {
                    Text("TODAY")
                        .font(.normaInput(10))
                        .foregroundColor(Color("NormaPastelCoral"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color("NormaPastelCoral").opacity(0.15))
                        )
                }
            }

            // Summary stats row
            HStack(spacing: 0) {
                // Total Spent
                VStack(alignment: .leading, spacing: 4) {
                    Text("SPENT")
                        .font(.normaInput(10))
                        .foregroundColor(.secondary)
                        .tracking(0.8)
                    Text(profileViewModel.formatCurrency(selectedDay.spending))
                        .font(.normaFinancial(18))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                }

                Spacer()

                // Daily Cap
                if let cap = selectedDay.dailyCap {
                    VStack(alignment: .center, spacing: 4) {
                        Text("CAP")
                            .font(.normaInput(10))
                            .foregroundColor(.secondary)
                            .tracking(0.8)
                        Text(profileViewModel.formatCurrency(cap))
                            .font(.normaFinancial(18))
                            .foregroundColor(.secondary)
                            .contentTransition(.numericText())
                    }

                    Spacer()

                    // Status
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("STATUS")
                            .font(.normaInput(10))
                            .foregroundColor(.secondary)
                            .tracking(0.8)
                        HStack(spacing: 4) {
                            Image(systemName: statusIcon)
                                .font(.system(size: 12))
                            Text(statusText)
                                .font(.normaInput(14))
                                .contentTransition(.numericText())
                        }
                        .foregroundColor(statusColor)
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedDay.spending)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedDay.dailyCap)
        }
        .padding(16)
        .background(
            Rectangle()
                .fill(selectedDay.isToday ? statusColor.opacity(0.05) : Color.clear)
        )
        .overlay(
            Rectangle()
                .fill(selectedDay.isToday ? statusColor.opacity(0.2) : Color.gray.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

// MARK: - Mini Calendar

/// Mini calendar view showing 2 weeks centered around the challenge
struct ChallengeMiniCalendar: View {
    let challenge: Challenge
    let challengeDays: [ChallengeDay]
    @Binding var selectedDay: ChallengeDay?
    @EnvironmentObject var profileViewModel: ProfileViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    // Haptic feedback
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    /// Generate 2 weeks of calendar days centered around the challenge
    private var calendarDays: [MiniCalendarDay] {
        let calendar = Calendar.current

        // Start from the beginning of the week containing the challenge start
        let challengeStart = challenge.startDate
        let weekday = calendar.component(.weekday, from: challengeStart)
        let daysToSubtract = weekday - 1 // Sunday = 1
        let calendarStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: challengeStart) ?? challengeStart

        var days: [MiniCalendarDay] = []

        // Generate 14 days (2 weeks)
        for i in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: i, to: calendarStart) else { continue }

            let isPartOfChallenge = date >= calendar.startOfDay(for: challenge.startDate) &&
                                    date <= calendar.startOfDay(for: challenge.endDate)
            let isToday = calendar.isDateInToday(date)
            let isPast = date < calendar.startOfDay(for: Date())

            // Find matching challenge day if it exists
            let matchingChallengeDay = challengeDays.first { challengeDay in
                calendar.isDate(challengeDay.date, inSameDayAs: date)
            }

            days.append(MiniCalendarDay(
                date: date,
                dayNumber: calendar.component(.day, from: date),
                isPartOfChallenge: isPartOfChallenge,
                isToday: isToday,
                isPast: isPast,
                spending: matchingChallengeDay?.spending ?? 0,
                challengeDay: matchingChallengeDay
            ))
        }

        return days
    }

    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack(spacing: 4) {
                ForEach(weekdayLabels.indices, id: \.self) { index in
                    Text(weekdayLabels[index])
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(calendarDays) { day in
                    MiniCalendarCell(
                        day: day,
                        isSelected: selectedDay?.date != nil && Calendar.current.isDate(selectedDay!.date, inSameDayAs: day.date)
                    )
                    .onTapGesture {
                        // Only allow tapping challenge days (including future days)
                        guard day.isPartOfChallenge else { return }

                        impactGenerator.impactOccurred()

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            // Use existing challengeDay if available, otherwise create one for future days
                            if let challengeDay = day.challengeDay {
                                selectedDay = challengeDay
                            } else {
                                // Create a ChallengeDay for future days to trigger the animation
                                selectedDay = ChallengeDay(
                                    date: day.date,
                                    isToday: day.isToday,
                                    isPast: day.isPast,
                                    spending: 0,
                                    dailyCap: nil
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Mini Calendar Day Model

struct MiniCalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let dayNumber: Int
    let isPartOfChallenge: Bool
    let isToday: Bool
    let isPast: Bool
    let spending: Double
    let challengeDay: ChallengeDay?
}

// MARK: - Mini Calendar Cell

struct MiniCalendarCell: View {
    let day: MiniCalendarDay
    let isSelected: Bool
    @EnvironmentObject var profileViewModel: ProfileViewModel

    private var hasSpending: Bool {
        day.spending > 0 && day.isPartOfChallenge
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(day.dayNumber)")
                .font(.system(size: 14, weight: day.isPartOfChallenge ? .semibold : .regular))
                .foregroundColor(textColor)

            // Spending dot indicator for challenge days with spending
            if hasSpending {
                Circle()
                    .fill(Color("NormaPastelCoral"))
                    .frame(width: 4, height: 4)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: isSelected ? 1.5 : 0.5)
        )
        .opacity(cellOpacity)
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if day.isToday && day.isPartOfChallenge {
            return Color("NormaPastelTeal")
        } else if day.isPartOfChallenge {
            return .primary
        } else {
            return .secondary.opacity(0.4)
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color("NormaPastelTeal")
        } else if day.isToday && day.isPartOfChallenge {
            return Color("NormaPastelTeal").opacity(0.1)
        } else if day.isPartOfChallenge {
            return Color.gray.opacity(0.05)
        } else {
            return Color.clear
        }
    }

    private var borderColor: Color {
        if isSelected {
            return Color("NormaPastelTeal")
        } else if day.isToday && day.isPartOfChallenge {
            return Color("NormaPastelTeal").opacity(0.3)
        } else if day.isPartOfChallenge {
            return Color.gray.opacity(0.15)
        } else {
            return Color.clear
        }
    }

    private var cellOpacity: Double {
        if day.isPartOfChallenge {
            return 1.0
        } else {
            return 0.5
        }
    }
}

// MARK: - Previews

#Preview("Mini Calendar") {
    ChallengeMiniCalendar(
        challenge: Challenge(
            id: "preview",
            userId: "user",
            amountTotal: 500,
            amountRemaining: 320,
            currency: "USD",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date(),
            status: .active,
            difficulty: .medium,
            durationDays: 5
        ),
        challengeDays: [
            ChallengeDay(date: Date(), isToday: true, isPast: false, spending: 45.50, dailyCap: 100.00)
        ],
        selectedDay: .constant(nil)
    )
    .padding(20)
    .background(Color("NormaBackground"))
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}

#Preview("Mini Calendar - Mid Challenge") {
    ChallengeMiniCalendar(
        challenge: Challenge(
            id: "preview",
            userId: "user",
            amountTotal: 500,
            amountRemaining: 200,
            currency: "USD",
            startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
            status: .active,
            difficulty: .hard,
            durationDays: 5
        ),
        challengeDays: [
            ChallengeDay(
                date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                isToday: false,
                isPast: true,
                spending: 80.00,
                dailyCap: 100.00
            ),
            ChallengeDay(
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                isToday: false,
                isPast: true,
                spending: 120.00,
                dailyCap: 100.00
            ),
            ChallengeDay(date: Date(), isToday: true, isPast: false, spending: 45.50, dailyCap: 100.00)
        ],
        selectedDay: .constant(ChallengeDay(date: Date(), isToday: true, isPast: false, spending: 45.50, dailyCap: 100.00))
    )
    .padding(20)
    .background(Color("NormaBackground"))
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}

#Preview("Combined Calendar + Stats") {
    ChallengeDayCalendarView(
        challenge: Challenge(
            id: "preview",
            userId: "user",
            amountTotal: 500,
            amountRemaining: 200,
            currency: "USD",
            startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
            status: .active,
            difficulty: .hard,
            durationDays: 5
        ),
        challengeDays: [
            ChallengeDay(
                date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                isToday: false,
                isPast: true,
                spending: 80.00,
                dailyCap: 100.00
            ),
            ChallengeDay(
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                isToday: false,
                isPast: true,
                spending: 120.00,
                dailyCap: 100.00
            ),
            ChallengeDay(date: Date(), isToday: true, isPast: false, spending: 45.50, dailyCap: 100.00)
        ],
        selectedDay: .constant(ChallengeDay(date: Date(), isToday: true, isPast: false, spending: 45.50, dailyCap: 100.00))
    )
    .padding(20)
    .background(Color("NormaBackground"))
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}

#Preview("Combined Calendar - Over Budget") {
    ChallengeDayCalendarView(
        challenge: Challenge(
            id: "preview",
            userId: "user",
            amountTotal: 500,
            amountRemaining: 200,
            currency: "USD",
            startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
            status: .active,
            difficulty: .hard,
            durationDays: 5
        ),
        challengeDays: [
            ChallengeDay(date: Date(), isToday: true, isPast: false, spending: 125.50, dailyCap: 100.00)
        ],
        selectedDay: .constant(ChallengeDay(date: Date(), isToday: true, isPast: false, spending: 125.50, dailyCap: 100.00))
    )
    .padding(20)
    .background(Color("NormaBackground"))
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}
