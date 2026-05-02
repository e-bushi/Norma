//
//  CalendarSheet.swift
//  Norma
//
//  D7 — Calendar sheet. Dark sheet that slides up over the notes list
//  via the calendar icon in the bottom bar. Surfaces the month grid,
//  reminder dots, and tap-to-inspect reminder cards for the selected day.
//

import SwiftUI
import SwiftData
import UserNotifications

struct CalendarSheet: View {
    enum Tab { case thisMonth, nextMonth }

    @State private var selectedTab: Tab = .thisMonth
    @State private var selectedDay: Int = 1
    @State private var allReminders: [Reminder] = []
    @Environment(\.modelContext) private var modelContext

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private let onAccentText = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255)
    private let accentPurple = Color(red: 0x96/255, green: 0x76/255, blue: 0xD9/255)

    private var heroFont: Font { .system(size: 56, weight: .heavy) }

    private struct Reminder: Identifiable {
        let id: String
        let title: String
        let date: Date
        let kindLabel: String  // "bill" or "reminder"
        let amount: String?    // present for bills, nil for plain reminders
    }

    var body: some View {
        VStack(spacing: 0) {
            dragHandle

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroBlock
                        .padding(.horizontal, 24)

                    filterCapsules
                        .padding(.horizontal, 24)
                        .padding(.top, 18)

                    calendarGrid
                        .padding(.horizontal, 24)
                        .padding(.top, 22)

                    selectedDayLabel
                        .padding(.horizontal, 24)
                        .padding(.top, 22)

                    reminderCards
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 32)
                }
            }
        }
        .background(bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task { await loadReminders() }
    }

    // MARK: - Drag handle

    private var dragHandle: some View {
        Capsule()
            .fill(cream.opacity(0.2))
            .frame(width: 36, height: 4)
            .padding(.top, 6)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthLabel)
                .font(.custom(FontFamily.Rubik.medium, size: 13))
                .foregroundStyle(mutedText)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(reminderCountForCurrentTab) \(reminderCountForCurrentTab == 1 ? "reminder" : "reminders")")
                    .font(heroFont)
                    .tracking(-2.24)
                    .foregroundStyle(cream)
                Text(".")
                    .font(heroFont)
                    .tracking(-2.24)
                    .foregroundStyle(accentPurple)
            }

            Text(nextReminderText)
                .font(.custom(FontFamily.Rubik.regular, size: 15).italic())
                .foregroundStyle(mutedText)
                .padding(.top, 2)
        }
    }

    // MARK: - Filter Capsules

    private var filterCapsules: some View {
        HStack(spacing: 8) {
            tabPill("this month", active: selectedTab == .thisMonth) {
                selectedTab = .thisMonth
                selectedDay = activeReminders.keys.sorted().first ?? 1
            }
            tabPill("next month", active: selectedTab == .nextMonth) {
                selectedTab = .nextMonth
                selectedDay = 1
            }
        }
    }

    @ViewBuilder
    private func tabPill(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                action()
            }
        } label: {
            Text(label)
                .font(.custom(active ? FontFamily.Rubik.semiBold : FontFamily.Rubik.medium, size: 12))
                .foregroundStyle(active ? onAccentText : cream)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    if active { Capsule().fill(accentPurple) }
                }
                .overlay(
                    Capsule().stroke(
                        active ? accentPurple : cream.opacity(0.32),
                        style: active ? StrokeStyle(lineWidth: 1) : StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Calendar grid

    private var calendarGrid: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Weekday header
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { letter in
                    Text(letter)
                        .font(.custom(FontFamily.Rubik.semiBold, size: 10))
                        .tracking(1.0)
                        .textCase(.uppercase)
                        .foregroundStyle(dimText)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 6)

            // Day cells, in rows of 7
            let grid = monthGridDays
            ForEach(0..<(grid.count / 7), id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        dayCell(day: grid[row * 7 + col])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(day: Int?) -> some View {
        let hasReminder = day.map { activeReminders[$0] != nil } ?? false
        let isSelected = day == selectedDay && day != nil
        VStack(spacing: 4) {
            if let day {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        selectedDay = day
                    }
                } label: {
                    ZStack {
                        if isSelected {
                            Circle().fill(accentPurple).frame(width: 32, height: 32)
                        }
                        Text("\(day)")
                            .font(.custom(isSelected ? FontFamily.Rubik.semiBold : FontFamily.Rubik.medium, size: 14))
                            .foregroundStyle(isSelected ? onAccentText : cream)
                    }
                    .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 32, height: 32)
            }

            // Reminder dot — always allocated (4×4) so rows align
            Circle()
                .fill(hasReminder ? accentPurple : Color.clear)
                .frame(width: 4, height: 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
    }

    // MARK: - Selected day label

    private var selectedDayLabel: some View {
        Text(selectedDayText)
            .font(.custom(FontFamily.Rubik.medium, size: 11))
            .tracking(0.66)
            .textCase(.uppercase)
            .foregroundStyle(mutedText)
    }

    // MARK: - Reminder cards

    private var reminderCards: some View {
        VStack(spacing: 8) {
            let items = activeReminders[selectedDay] ?? []
            if items.isEmpty {
                Text("nothing scheduled")
                    .font(.custom(FontFamily.Rubik.medium, size: 13))
                    .foregroundStyle(dimText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 14)
            } else {
                ForEach(items) { item in
                    reminderCard(item)
                }
            }
        }
    }

    @ViewBuilder
    private func reminderCard(_ item: Reminder) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title.lowercased())
                    .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                    .tracking(-0.16)
                    .foregroundStyle(cream)
                Text("\(timeLabel(for: item.date)) · \(item.kindLabel)")
                    .font(.custom(FontFamily.Rubik.medium, size: 12))
                    .foregroundStyle(accentPurple)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let amount = item.amount {
                Text(amount)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                    .tracking(-0.18)
                    .foregroundStyle(cream)
            }

            Button {
                cancel(item)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(mutedText)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle().stroke(
                            mutedText.opacity(0.6),
                            style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                        )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18).fill(accentPurple.opacity(0.06)))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accentPurple.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        )
    }

    private func cancel(_ item: Reminder) {
        NotificationService.shared.cancelAIReminder(identifier: item.id)
        // If this reminder originated from a note token, clear its
        // confirmedAt so the chip on the note flips back to dashed and
        // the next LLM re-extraction's preservation logic doesn't zombie
        // a fresh OS notification back into existence.
        if let tokenId = NoteRepository.parseReminderTokenId(from: item.id) {
            NoteRepository(context: modelContext).unconfirmReminder(tokenId: tokenId)
        }
        allReminders.removeAll { $0.id == item.id }
    }

    private func timeLabel(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date).lowercased()
    }

    // MARK: - Data loading

    private func loadReminders() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let cal = Calendar.current
        let now = Date()
        var loaded: [Reminder] = []
        for req in requests {
            guard let trigger = req.trigger as? UNCalendarNotificationTrigger,
                  let next = trigger.nextTriggerDate(),
                  next >= cal.startOfDay(for: now)
            else { continue }

            let isBill = req.content.categoryIdentifier == "BILL_REMINDER"
            let amountString: String? = {
                if let amt = req.content.userInfo["amount"] as? Double {
                    let f = NumberFormatter()
                    f.numberStyle = .currency
                    return f.string(from: NSNumber(value: amt))
                }
                return nil
            }()

            // Bills carry the friendlier name in userInfo; default to the
            // notification title for AI-extracted reminders.
            let title: String = {
                if isBill, let billName = req.content.userInfo["billName"] as? String, !billName.isEmpty {
                    return billName
                }
                return req.content.title
            }()

            loaded.append(Reminder(
                id: req.identifier,
                title: title,
                date: next,
                kindLabel: isBill ? "bill" : "reminder",
                amount: amountString
            ))
        }
        allReminders = loaded
    }

    // MARK: - Date helpers

    private var displayedMonthDate: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        let firstOfThisMonth = cal.date(from: comps) ?? Date()
        if selectedTab == .nextMonth {
            return cal.date(byAdding: .month, value: 1, to: firstOfThisMonth) ?? firstOfThisMonth
        }
        return firstOfThisMonth
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: displayedMonthDate).lowercased()
    }

    private var monthGridDays: [Int?] {
        let cal = Calendar.current
        let firstWeekday = cal.component(.weekday, from: displayedMonthDate) // 1 = Sun … 7 = Sat
        let daysInMonth = cal.range(of: .day, in: .month, for: displayedMonthDate)?.count ?? 30
        let leading = firstWeekday - 1
        var grid: [Int?] = Array(repeating: nil, count: leading)
        for d in 1...daysInMonth { grid.append(d) }
        while grid.count % 7 != 0 { grid.append(nil) }
        return grid
    }

    /// Reminders bucketed by day-of-month for the currently displayed month.
    private var activeReminders: [Int: [Reminder]] {
        let cal = Calendar.current
        let target = cal.dateComponents([.year, .month], from: displayedMonthDate)
        var dict: [Int: [Reminder]] = [:]
        for r in allReminders {
            let comps = cal.dateComponents([.year, .month, .day], from: r.date)
            if comps.year == target.year, comps.month == target.month, let d = comps.day {
                dict[d, default: []].append(r)
            }
        }
        // Sort each day's reminders chronologically.
        for (k, v) in dict { dict[k] = v.sorted { $0.date < $1.date } }
        return dict
    }

    private var reminderCountForCurrentTab: Int {
        activeReminders.values.reduce(0) { $0 + $1.count }
    }

    private var nextReminderText: String {
        guard let nextDay = activeReminders.keys.sorted().first else {
            return "no reminders this month."
        }
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: displayedMonthDate)
        comps.day = nextDay
        guard let date = cal.date(from: comps) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "EEE"
        let weekday = f.string(from: date).lowercased()
        return "next: \(weekday), the \(nextDay)\(ordinalSuffix(nextDay))."
    }

    private var selectedDayText: String {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: displayedMonthDate)
        comps.day = selectedDay
        guard let date = cal.date(from: comps) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date).lowercased()
    }

    private func ordinalSuffix(_ day: Int) -> String {
        let mod100 = day % 100
        if mod100 >= 11 && mod100 <= 13 { return "th" }
        switch day % 10 {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
}

#Preview {
    Color.black
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            CalendarSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
}
