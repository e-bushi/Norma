//
//  ForecastSheet.swift
//  Norma
//
//  D6 — Forecast sheet. Dark sheet that slides up over the notes list
//  via the chart icon in the bottom bar. Surfaces breathing room,
//  next bill (with overdue indicator), and weekly-spending pace.
//

import SwiftUI
import SwiftData

struct ForecastSheet: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    @State private var showBills = false
    @State private var whatIfMode = false
    @State private var showDailyRate = false

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private let onAccentText = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255)
    private let accentPurple = Color(red: 0x96/255, green: 0x76/255, blue: 0xD9/255)

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroBlock
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                    weeklySpendingSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                    nextBillSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                    if !commitments.isEmpty {
                        commitmentsSection
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                    }

                    if !intentions.isEmpty {
                        intentionsSection
                            .padding(.horizontal, 24)
                            .padding(.bottom, 48)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        showDailyRate = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(cream.opacity(0.85))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showBills) {
            BillsView()
                .environmentObject(sessionViewModel)
                .environmentObject(billViewModel)
                .environmentObject(expenseViewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showDailyRate) {
            DailyRateSheet()
                .environmentObject(sessionViewModel)
                .environmentObject(billViewModel)
                .environmentObject(profileViewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(heroLabel)
                .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                .tracking(0.66)
                .foregroundStyle(mutedText)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(formatCurrency(displayedBreathingRoom))
                    .font(.system(size: 72, weight: .heavy))
                    .tracking(-3.24)
                    .foregroundStyle(cream)
                Text(".")
                    .font(.system(size: 72, weight: .heavy))
                    .tracking(-3.24)
                    .foregroundStyle(accentPurple)
            }

            modeToggle
                .padding(.top, 4)
        }
    }

    private var heroLabel: String {
        whatIfMode
            ? "IF EVERY INTENTION LANDS"
            : "\(monthShortLabel.uppercased())'S BREATHING ROOM"
    }

    // MARK: - Mode toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modePill("now", active: !whatIfMode) { whatIfMode = false }
            modePill("what if", active: whatIfMode) { whatIfMode = true }
        }
        .padding(4)
        .background(Capsule().fill(cream.opacity(0.04)))
    }

    @ViewBuilder
    private func modePill(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                action()
            }
        } label: {
            Text(label)
                .font(.custom(active ? FontFamily.Rubik.semiBold : FontFamily.Rubik.medium, size: 12))
                .tracking(-0.06)
                .foregroundStyle(active ? onAccentText : mutedText)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    if active { Capsule().fill(accentPurple) }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Next Bill

    @ViewBuilder
    private var nextBillSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("next bill up")
                .font(.custom(FontFamily.Rubik.medium, size: 18))
                .foregroundStyle(mutedText)

            if let bill = nextBill {
                nextBillCard(bill)
            } else {
                noBillsCard
            }

            if !monthlyBills.isEmpty {
                viewAllPill
                    .padding(.top, 8)
            }
        }
    }

    @ViewBuilder
    private func nextBillCard(_ bill: Bill) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accentPurple)
                    .frame(width: 6, height: 6)
                Text(dueLabel(for: bill))
                    .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                    .tracking(0.88)
                    .textCase(.uppercase)
                    .foregroundStyle(accentPurple)
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(formatCurrency(bill.amount))
                    .font(.system(size: 32, weight: .bold))
                    .tracking(-0.64)
                    .foregroundStyle(accentPurple)
                Text(bill.name.lowercased())
                    .font(.custom(FontFamily.Rubik.medium, size: 14))
                    .foregroundStyle(cream)
                Text(shortDate(bill.effectiveDueDate))
                    .font(.custom(FontFamily.Rubik.regular, size: 13).italic())
                    .foregroundStyle(dimText)
            }
            .padding(.top, 2)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(accentPurple.opacity(0.08)))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accentPurple.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        )
    }

    private var noBillsCard: some View {
        Text("nothing due this month")
            .font(.custom(FontFamily.Rubik.medium, size: 13))
            .foregroundStyle(dimText)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18).fill(cream.opacity(0.04)))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(cream.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
    }

    // MARK: - View All Pill

    private var viewAllPill: some View {
        HStack {
            Spacer()
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                showBills = true
            } label: {
                HStack(spacing: 10) {
                    Text("view all \(monthlyBills.count) \(monthlyBills.count == 1 ? "bill" : "bills")")
                        .font(.custom(FontFamily.Rubik.medium, size: 13))
                        .foregroundStyle(cream)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(cream)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .overlay(
                    Capsule().stroke(cream.opacity(0.32), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                )
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: - Weekly Spending

    private var weeklySpendingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("spending pace")
                    .font(.custom(FontFamily.Rubik.medium, size: 18))
                    .foregroundStyle(mutedText)
                Spacer()
                Text("\(formatCurrency(displayedBreathingRoom)) cap")
                    .font(.custom(FontFamily.Rubik.medium, size: 11))
                    .tracking(0.44)
                    .textCase(.uppercase)
                    .foregroundStyle(accentPurple)
            }

            ForecastSparkline(
                weeklyAmounts: weeks.map { $0.amount },
                weeklyLimit: weeklyLimit,
                currentWeekIndex: weeks.firstIndex(where: { $0.isCurrent }),
                accent: accentPurple
            )
            .frame(height: 110)

            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { i, week in
                    weekLabel(week, alignment: weekAlignment(for: i))
                    if i < weeks.count - 1 { Spacer() }
                }
            }

            HStack {
                Spacer()
                freshnessChip
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var freshnessChip: some View {
        if daysBehind == 0 {
            HStack(spacing: 8) {
                Circle()
                    .fill(mutedText)
                    .frame(width: 5, height: 5)
                Text("up to date")
                    .font(.custom(FontFamily.Rubik.regular, size: 12))
                    .foregroundStyle(mutedText)
            }
        } else {
            HStack(spacing: 8) {
                Circle()
                    .fill(accentPurple)
                    .frame(width: 5, height: 5)
                Text("\(daysBehind) \(daysBehind == 1 ? "day" : "days") behind")
                    .font(.custom(FontFamily.Rubik.medium, size: 12))
                    .foregroundStyle(cream)
                Text("·")
                    .font(.custom(FontFamily.Rubik.regular, size: 12))
                    .foregroundStyle(mutedText)
                Text("\(formatCurrency(gapFillEstimate)) estimated")
                    .font(.custom(FontFamily.Rubik.regular, size: 12))
                    .foregroundStyle(mutedText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(accentPurple.opacity(0.03)))
            .overlay(
                Capsule().stroke(accentPurple, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            )
        }
    }

    private func weekAlignment(for index: Int) -> HorizontalAlignment {
        switch index {
        case 0: return .leading
        case weeks.count - 1: return .trailing
        default: return .center
        }
    }

    // MARK: - Commitments

    private var commitmentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("commitments")
                    .font(.custom(FontFamily.Rubik.medium, size: 18))
                    .foregroundStyle(mutedText)
                Spacer()
                Text("\(commitments.count) · \(formatCurrency(totalCommitmentsForMonth))")
                    .font(.custom(FontFamily.Rubik.medium, size: 11))
                    .tracking(0.44)
                    .foregroundStyle(mutedText)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(commitments, id: \.id) { token in
                    commitmentRow(token)
                }
            }
        }
    }

    @ViewBuilder
    private func commitmentRow(_ token: NoteToken) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(formatCurrency(token.amount))
                .font(.system(size: 30, weight: .bold))
                .tracking(-0.75)
                .foregroundStyle(cream)
                .frame(width: 100, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(token.subject ?? "commitment")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundStyle(cream)
                Text("due \(shortDate(token.occurredAt))")
                    .font(.custom(FontFamily.Rubik.regular, size: 12))
                    .foregroundStyle(mutedText)
            }
        }
    }

    // MARK: - Intentions

    private var intentionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("intentions")
                    .font(.custom(FontFamily.Rubik.medium, size: 18))
                    .foregroundStyle(mutedText)
                Spacer()
                Text("\(intentions.count) · \(formatCurrency(totalIntentionsForMonth))")
                    .font(.custom(FontFamily.Rubik.medium, size: 11))
                    .tracking(0.44)
                    .foregroundStyle(mutedText)
            }

            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(intentions, id: \.id) { token in
                    intentionChip(token)
                }
            }
        }
    }

    @ViewBuilder
    private func intentionChip(_ token: NoteToken) -> some View {
        let hardened = whatIfMode
        HStack(spacing: 8) {
            Circle()
                .strokeBorder(accentPurple, lineWidth: hardened ? 0 : 1)
                .background(Circle().fill(hardened ? accentPurple : Color.clear))
                .frame(width: 5, height: 5)
            Text(token.subject ?? "intention")
                .font(.custom(FontFamily.Rubik.medium, size: 13))
                .foregroundStyle(hardened ? cream : cream)
            Text(formatCurrency(token.amount))
                .font(.custom(FontFamily.Rubik.regular, size: 13))
                .foregroundStyle(hardened ? cream : mutedText)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background(Capsule().fill(accentPurple.opacity(hardened ? 0.12 : 0.03)))
        .overlay(
            Capsule().stroke(
                accentPurple,
                style: StrokeStyle(lineWidth: 1, dash: hardened ? [] : [3, 3])
            )
        )
    }

    @ViewBuilder
    private func weekLabel(_ week: WeekBucket, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(week.name)
                .font(.custom(week.isCurrent ? FontFamily.Rubik.semiBold : FontFamily.Rubik.medium, size: 11))
                .tracking(0.44)
                .textCase(.uppercase)
                .foregroundStyle(week.isCurrent ? accentPurple : dimText)

            Group {
                if week.isProjection {
                    Text("~\(formatCurrency(week.amount))")
                        .font(.custom(FontFamily.Rubik.medium, size: 12).italic())
                } else {
                    Text(formatCurrency(week.amount))
                        .font(.custom(week.isCurrent ? FontFamily.Rubik.semiBold : FontFamily.Rubik.medium, size: 12))
                }
            }
            .foregroundStyle(week.isCurrent ? cream : mutedText)
        }
    }

    // MARK: - Computed: month context

    private var displayedMonthDate: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        return cal.date(from: comps) ?? Date()
    }

    private var monthShortLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f.string(from: displayedMonthDate).lowercased()
    }

    // MARK: - Computed: financials

    private var monthlyIncome: Double {
        sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    /// Bills whose effective due date falls in the displayed month.
    private var monthlyBills: [Bill] {
        let cal = Calendar.current
        return billViewModel.bills.filter { bill in
            cal.isDate(bill.effectiveDueDate, equalTo: displayedMonthDate, toGranularity: .month)
        }
    }

    private var totalBillsForMonth: Double {
        monthlyBills.reduce(0) { $0 + $1.amount }
    }

    private var spendingService: SpendingService {
        SpendingService(context: modelContext, currency: currency, bills: billViewModel.bills)
    }

    private var commitments: [NoteToken] {
        spendingService.commitmentTokens(inMonthOf: displayedMonthDate)
    }

    private var intentions: [NoteToken] {
        spendingService.intentionTokens(inMonthOf: displayedMonthDate)
    }

    private var totalCommitmentsForMonth: Double {
        spendingService.totalCommitments(inMonthOf: displayedMonthDate)
    }

    private var totalIntentionsForMonth: Double {
        spendingService.totalIntentions(inMonthOf: displayedMonthDate)
    }

    // MARK: - Freshness + gap-fill

    /// Number of days between the user's last expense entry and today, capped
    /// to days inside the displayed month. Zero = up to date.
    private var daysBehind: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let latest = spendingService.latestExpenseDate(inMonthOf: displayedMonthDate) else {
            // No entries yet this month: treat as fresh, not stale.
            return 0
        }
        let latestDay = cal.startOfDay(for: latest)
        guard latestDay < today else { return 0 }
        let days = cal.dateComponents([.day], from: latestDay, to: today).day ?? 0
        // Cap to days within the displayed month (in case latest is in a prior month edge case).
        return max(0, days)
    }

    /// Effective daily rate used for gap-fill — the user's manual setting if
    /// present, otherwise breathing room ÷ days remaining in month.
    private var effectiveDailyRate: Double {
        if let manual = sessionViewModel.currentUser?.settings.dailyRate, manual > 0 {
            return manual
        }
        let cal = Calendar.current
        let now = Date()
        let totalDays = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let currentDay = cal.component(.day, from: now)
        let daysLeft = max(1, totalDays - currentDay + 1)
        return breathingRoom / Double(daysLeft)
    }

    /// Estimated spend across missed days, used by the freshness signal and
    /// folded into the cumulative spending pace line.
    private var gapFillEstimate: Double {
        Double(daysBehind) * effectiveDailyRate
    }

    private var breathingRoom: Double {
        max(0, monthlyIncome - totalBillsForMonth - totalCommitmentsForMonth)
    }

    private var displayedBreathingRoom: Double {
        whatIfMode ? max(0, breathingRoom - totalIntentionsForMonth) : breathingRoom
    }

    private var weeklyLimit: Double {
        displayedBreathingRoom / 4
    }

    /// Earliest unpaid bill in the displayed month. Falls back to nil if none.
    private var nextBill: Bill? {
        monthlyBills
            .filter { $0.status != .paid }
            .min(by: { $0.effectiveDueDate < $1.effectiveDueDate })
    }

    // MARK: - Weekly buckets

    private struct WeekBucket {
        let name: String
        let amount: Double
        let isCurrent: Bool
        let isProjection: Bool
    }

    /// Four week buckets covering days 1–7, 8–14, 15–21, 22–end of the displayed month.
    /// Past + current weeks reflect actual expenses; future weeks are italic projections
    /// based on the current pace (avg per elapsed day in the month).
    private var weeks: [WeekBucket] {
        let cal = Calendar.current
        let now = Date()
        let monthStart = displayedMonthDate

        // Bucket actual expenses by week-of-month, sourced from NoteTokens.
        var actualByWeek = spendingService.weeklyActuals(inMonthOf: monthStart)

        // Day ranges per week (closed): used for current-week detection
        let daysInMonth = cal.range(of: .day, in: .month, for: monthStart)?.last ?? 30
        let ranges: [ClosedRange<Int>] = [
            1...7,
            8...14,
            15...21,
            22...daysInMonth
        ]

        // Fold gap-fill into the appropriate week buckets so the trajectory line
        // doesn't lie about empty days. Each missing day adds the daily rate to
        // the bucket containing that day.
        if daysBehind > 0,
           let latest = spendingService.latestExpenseDate(inMonthOf: monthStart) {
            let latestDay = cal.component(.day, from: latest)
            let today = cal.component(.day, from: now)
            let firstMissing = latestDay + 1
            if firstMissing <= today {
                for day in firstMissing...today {
                    if let idx = ranges.firstIndex(where: { $0.contains(day) }) {
                        actualByWeek[idx] += effectiveDailyRate
                    }
                }
            }
        }

        // Determine which week index "now" falls into, but only if displaying current month.
        let isDisplayingCurrentMonth = cal.isDate(now, equalTo: monthStart, toGranularity: .month)
        let currentWeekIndex: Int? = {
            guard isDisplayingCurrentMonth else { return nil }
            let day = cal.component(.day, from: now)
            return ranges.firstIndex(where: { $0.contains(day) })
        }()

        // Pace projection: avg per elapsed day so far this month × 7
        let projectionPerWeek: Double = {
            if isDisplayingCurrentMonth {
                let elapsedDays = cal.component(.day, from: now)
                let totalSpent = actualByWeek.reduce(0, +)
                guard elapsedDays > 0, totalSpent > 0 else { return 0 }
                return (totalSpent / Double(elapsedDays)) * 7
            } else {
                // Next month: project from current month's pace
                let elapsedDays = max(1, cal.component(.day, from: now))
                let currentMonthSpent = spendingService.totalSpent(inMonthOf: now)
                guard currentMonthSpent > 0 else { return 0 }
                return (currentMonthSpent / Double(elapsedDays)) * 7
            }
        }()

        return (0..<4).map { idx in
            let isCurrent = currentWeekIndex == idx
            let isPast = currentWeekIndex.map { idx < $0 } ?? false
            let isFuture = !isCurrent && !isPast && isDisplayingCurrentMonth
            let isNextMonth = !isDisplayingCurrentMonth

            let isProjection = isFuture || isNextMonth
            let amount = isProjection ? projectionPerWeek : actualByWeek[idx]
            let baseName = "w\(idx + 1)"
            let name = isCurrent ? "\(baseName) · now" : baseName
            return WeekBucket(name: name, amount: amount, isCurrent: isCurrent, isProjection: isProjection)
        }
    }

    // MARK: - Formatting helpers

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(Int(amount))"
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date).lowercased()
    }

    private func dueLabel(for bill: Bill) -> String {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let due = cal.startOfDay(for: bill.effectiveDueDate)
        let days = cal.dateComponents([.day], from: now, to: due).day ?? 0
        if days < 0 { return "overdue \(-days) \(-days == 1 ? "day" : "days")" }
        if days == 0 { return "due today" }
        return "due in \(days) \(days == 1 ? "day" : "days")"
    }
}

// MARK: - Flow Layout

/// Minimal wrapping HStack — places each subview on the current line if it fits,
/// otherwise wraps to a new line. Used for the intention chip flow.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                y += lineHeight + lineSpacing
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            totalWidth = max(totalWidth, x - spacing)
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: totalWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.minX + maxWidth {
                y += lineHeight + lineSpacing
                x = bounds.minX
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Sparkline (Canvas-rendered, dynamic)

private struct ForecastSparkline: View {
    let weeklyAmounts: [Double]
    let weeklyLimit: Double
    let currentWeekIndex: Int?
    let accent: Color

    var body: some View {
        Canvas { context, size in
            let weeks = weeklyAmounts.count
            guard weeks > 0 else { return }

            // Cumulative spend trajectory across the month
            var cumulative: [Double] = []
            var running = 0.0
            for amount in weeklyAmounts {
                running += amount
                cumulative.append(running)
            }

            // Y scale: y=0 at top, y=size.height at bottom.
            // The dashed limit line sits at the monthly cap (4 × weeklyLimit).
            // Anything above the cap clips visually at the top padding.
            let monthlyCap = max(weeklyLimit * 4, 1)
            let topPad: CGFloat = 20    // matches D6 limit-line offset (y=20 in 110-unit canvas)
            let bottom = size.height
            let plotHeight = bottom - topPad

            func y(for value: Double) -> CGFloat {
                let clamped = min(max(value / monthlyCap, 0), 1)
                return bottom - (plotHeight * clamped)
            }

            // X positions: 5 anchors (start of month + end of each week)
            let xStep = size.width / CGFloat(weeks)
            var points: [CGPoint] = [CGPoint(x: 0, y: bottom)]
            for (i, total) in cumulative.enumerated() {
                points.append(CGPoint(x: CGFloat(i + 1) * xStep, y: y(for: total)))
            }

            // Filled area below the line
            var fillPath = Path()
            fillPath.move(to: CGPoint(x: 0, y: bottom))
            for p in points { fillPath.addLine(to: p) }
            fillPath.addLine(to: CGPoint(x: size.width, y: bottom))
            fillPath.closeSubpath()
            context.fill(fillPath, with: .color(accent.opacity(0.14)))

            // Limit line at the monthly cap
            let limitY = topPad
            var limitPath = Path()
            limitPath.move(to: CGPoint(x: 0, y: limitY))
            limitPath.addLine(to: CGPoint(x: size.width, y: limitY))
            context.stroke(
                limitPath,
                with: .color(accent.opacity(0.45)),
                style: StrokeStyle(lineWidth: 1, dash: [4, 4])
            )

            // Trend line
            var linePath = Path()
            linePath.move(to: points[0])
            for p in points.dropFirst() { linePath.addLine(to: p) }
            context.stroke(
                linePath,
                with: .color(accent),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )

            // Current-week dot — sits at the end-of-current-week point (index + 1 in `points`)
            if let cwi = currentWeekIndex, cwi >= 0, cwi < weeks {
                let dot = points[cwi + 1]
                let outer = CGRect(x: dot.x - 9, y: dot.y - 9, width: 18, height: 18)
                context.fill(Path(ellipseIn: outer), with: .color(accent.opacity(0.25)))
                let inner = CGRect(x: dot.x - 4.5, y: dot.y - 4.5, width: 9, height: 9)
                context.fill(Path(ellipseIn: inner), with: .color(accent))
            }
        }
    }
}

#Preview {
    Color.black
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ForecastSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
}
