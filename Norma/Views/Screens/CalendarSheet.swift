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

    /// Called when the user taps "add for this day" — the host opens the chat
    /// seeded with the date so they can finish the thought.
    var onAddForDate: ((Date) -> Void)? = nil

    @State private var selectedTab: Tab = .thisMonth
    @State private var selectedDay: Int = Calendar.current.component(.day, from: Date())
    @State private var allReminders: [Reminder] = []
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var billViewModel: BillViewModel
    @Query private var allTokens: [NoteToken]
    @Query private var profiles: [UserProfile]

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private let onAccentText = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255)
    private let warning = Color(red: 0.93, green: 0.58, blue: 0.35)
    private var accentPurple: Color { NormaPalette.lavender }

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

                    projectedBalanceCard
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                    reminderCards
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                    if onAddForDate != nil {
                        addForDayButton
                            .padding(.horizontal, 24)
                            .padding(.top, 14)
                    }

                    Spacer(minLength: 32)
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
                selectedDay = Calendar.current.component(.day, from: Date())
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
        let isToday = day.map { isCellToday($0) } ?? false
        let isDanger = day.map { $0 == dangerDay } ?? false
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
                        } else if isDanger {
                            Circle()
                                .stroke(warning, lineWidth: 1.5)
                                .frame(width: 32, height: 32)
                        } else if isToday {
                            Circle()
                                .stroke(accentPurple.opacity(0.85), lineWidth: 1)
                                .frame(width: 32, height: 32)
                        }
                        Text("\(day)")
                            .font(.custom(
                                (isSelected || isToday || isDanger) ? FontFamily.Rubik.semiBold : FontFamily.Rubik.medium,
                                size: 14
                            ))
                            .foregroundStyle(
                                isSelected ? onAccentText : (isDanger ? warning : (isToday ? accentPurple : cream))
                            )
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

    /// True only when `day` falls on the actual current calendar date AND we
    /// are looking at this month's grid. Prevents the "1" cell on the
    /// next-month tab from getting a today ring.
    private func isCellToday(_ day: Int) -> Bool {
        guard selectedTab == .thisMonth else { return false }
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: Date())
        let target = cal.dateComponents([.year, .month], from: displayedMonthDate)
        return comps.day == day && comps.year == target.year && comps.month == target.month
    }

    // MARK: - Selected day label

    private var selectedDayLabel: some View {
        Text(selectedDayText)
            .font(.custom(FontFamily.Rubik.medium, size: 11))
            .tracking(0.66)
            .textCase(.uppercase)
            .foregroundStyle(mutedText)
    }

    // MARK: - Projected balance + add

    @ViewBuilder
    private var projectedBalanceCard: some View {
        if let date = selectedDate, date >= Calendar.current.startOfDay(for: Date()) {
            let balance = projectedBalance(on: date)
            let isDangerDay = selectedDay == dangerDay
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isSelectedToday ? "BALANCE TODAY" : "BALANCE BY THIS DAY")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 10))
                        .tracking(0.6)
                        .foregroundStyle(mutedText)
                    Text("≈ \(formatCurrency(balance))")
                        .font(.custom(FontFamily.Rubik.bold, size: 26))
                        .foregroundStyle(isDangerDay ? warning : cream)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.5), value: balance)
                }
                Spacer(minLength: 8)
                if isDangerDay {
                    Text("your low point\nbefore payday")
                        .font(.custom(FontFamily.Rubik.medium, size: 11))
                        .foregroundStyle(warning.opacity(0.95))
                        .multilineTextAlignment(.trailing)
                } else if payday == nil || monthlyIncome == 0 {
                    Text("before any\nnew income")
                        .font(.custom(FontFamily.Rubik.regular, size: 11))
                        .foregroundStyle(mutedText)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(cream.opacity(0.04)))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke((isDangerDay ? warning : cream).opacity(isDangerDay ? 0.4 : 0.08), lineWidth: 1)
            )
        }
    }

    private var addForDayButton: some View {
        Button {
            guard let date = selectedDate else { return }
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onAddForDate?(date)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("add for \(shortDayLabel)")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 14))
            }
            .foregroundStyle(accentPurple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Capsule().fill(accentPurple.opacity(0.12)))
            .overlay(Capsule().stroke(accentPurple.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var isSelectedToday: Bool {
        guard let d = selectedDate else { return false }
        return Calendar.current.isDateInToday(d)
    }

    private var shortDayLabel: String {
        guard let d = selectedDate else { return "this day" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: d).lowercased()
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

            // Bills carry the friendlier name in userInfo; AI reminders
            // carry the action subject in userInfo too. Fall back to the
            // notification title only for legacy entries that predate the
            // userInfo["subject"] convention.
            let title: String = {
                if isBill, let billName = req.content.userInfo["billName"] as? String, !billName.isEmpty {
                    return billName
                }
                if let subject = req.content.userInfo["subject"] as? String, !subject.isEmpty {
                    return subject
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

    // MARK: - Balance projection

    private var freedomFund: Double { sessionViewModel.currentUser?.settings.freedomFund ?? 0 }
    private var monthlyIncome: Double { sessionViewModel.currentUser?.settings.monthlyIncome ?? 0 }
    private var payday: Int? { profiles.first?.payday }
    private var currencyCode: String { sessionViewModel.currentUser?.settings.currency ?? "USD" }

    private var daysInDisplayedMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: displayedMonthDate)?.count ?? 30
    }

    private func date(forDay day: Int) -> Date? {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: displayedMonthDate)
        comps.day = day
        return cal.date(from: comps)
    }

    private var selectedDate: Date? { date(forDay: selectedDay) }

    /// Projected balance at end of `target`: the current balance minus every
    /// bill + commitment that clears between now and then, plus income on any
    /// payday that lands in the window. Income is included here (unlike the
    /// runway engine) so the calendar shows a realistic dip-and-refill rather
    /// than a straight slide to zero. Past days project the current balance.
    private func projectedBalance(on target: Date) -> Double {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let end = cal.startOfDay(for: target)
        guard end >= today else { return freedomFund }

        var balance = freedomFund

        for bill in billViewModel.bills {
            var occurrences = billOccurrences(bill, afterExclusive: today, through: end, cal: cal)
            if bill.isPaidThisCycle, !occurrences.isEmpty { occurrences.removeFirst() }
            balance -= Double(occurrences.count) * bill.amount
        }

        for token in allTokens where token.kind == .commit {
            let d = cal.startOfDay(for: token.occurredAt)
            if d > today, d <= end { balance -= token.amount }
        }

        if let payday, monthlyIncome > 0 {
            balance += Double(paydayCount(after: today, through: end, payday: payday, cal: cal)) * monthlyIncome
        }

        return balance
    }

    /// The day of the displayed month where the projected balance bottoms out
    /// — the pre-payday low. Only meaningful when income is known (otherwise
    /// the balance only ever falls and the "low" is just month-end), so we
    /// return nil without a payday + income to model the refill against.
    private var dangerDay: Int? {
        guard let _ = payday, monthlyIncome > 0 else { return nil }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var minDay: Int?
        var minBalance = Double.greatestFiniteMagnitude
        for day in 1...daysInDisplayedMonth {
            guard let d = date(forDay: day) else { continue }
            if selectedTab == .thisMonth, cal.startOfDay(for: d) < today { continue }
            let balance = projectedBalance(on: d)
            if balance < minBalance {
                minBalance = balance
                minDay = day
            }
        }
        // Only flag it if it's an actual dip below where we stand today.
        guard minBalance < freedomFund else { return nil }
        return minDay
    }

    private func billOccurrences(_ bill: Bill, afterExclusive start: Date, through end: Date, cal: Calendar) -> [Date] {
        var result: [Date] = []
        guard var due = firstDue(bill, onOrAfter: cal.date(byAdding: .day, value: 1, to: start) ?? start, cal: cal) else {
            return result
        }
        let step: DateComponents?
        switch bill.frequency {
        case .oneTime: step = nil
        case .monthly: step = DateComponents(month: 1)
        case .quarterly: step = DateComponents(month: 3)
        case .yearly: step = DateComponents(year: 1)
        }
        var guardCount = 0
        while due <= end, guardCount < 24 {
            result.append(due)
            guard let step, let next = cal.date(byAdding: step, to: due) else { break }
            due = next
            guardCount += 1
        }
        return result
    }

    private func firstDue(_ bill: Bill, onOrAfter start: Date, cal: Calendar) -> Date? {
        let startDay = cal.startOfDay(for: start)
        if let next = bill.nextDueDate, cal.startOfDay(for: next) >= startDay {
            return cal.startOfDay(for: next)
        }
        let step: DateComponents?
        switch bill.frequency {
        case .oneTime:
            let due = cal.startOfDay(for: bill.dueDate)
            return due >= startDay ? due : nil
        case .monthly: step = DateComponents(month: 1)
        case .quarterly: step = DateComponents(month: 3)
        case .yearly: step = DateComponents(year: 1)
        }
        var due = cal.startOfDay(for: bill.dueDate)
        var guardCount = 0
        while due < startDay, guardCount < 500 {
            guard let step, let next = cal.date(byAdding: step, to: due) else { return nil }
            due = next
            guardCount += 1
        }
        return due
    }

    private func paydayCount(after start: Date, through end: Date, payday: Int, cal: Calendar) -> Int {
        var count = 0
        var d = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: start)) ?? start
        let last = cal.startOfDay(for: end)
        var guardCount = 0
        while d <= last, guardCount < 800 {
            if cal.component(.day, from: d) == payday { count += 1 }
            guard let next = cal.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
            guardCount += 1
        }
        return count
    }

    private func formatCurrency(_ amount: Double) -> String {
        let symbol = NormaPalette.currencySymbol(for: currencyCode)
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        let number = f.string(from: NSNumber(value: amount.rounded())) ?? "\(Int(amount))"
        return "\(symbol)\(number)"
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
