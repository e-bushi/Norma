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
    enum Tab { case thisMonth, nextMonth }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel

    @State private var selectedTab: Tab = .thisMonth
    @State private var showBills = false

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private let onAccentText = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255)
    private let accentPurple = Color(red: 0x96/255, green: 0x76/255, blue: 0xD9/255)

    private var heroFont: Font { .system(size: 56, weight: .heavy) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroBlock
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                    filterCapsules
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                    nextBillSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                    viewAllPill
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                    weeklySpendingSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        // TODO: present forecast info / explainer
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18, weight: .medium))
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
    }

    // MARK: - Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(monthLabel)
                .font(.custom(FontFamily.Rubik.medium, size: 18))
                .foregroundStyle(mutedText)
                .padding(.bottom, 6)

            Text(formatCurrency(breathingRoom))
                .font(heroFont)
                .tracking(-2.24)
                .foregroundStyle(cream)

            Text("in breathing")
                .font(heroFont)
                .tracking(-2.24)
                .foregroundStyle(cream)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("room")
                    .font(heroFont)
                    .tracking(-2.24)
                    .foregroundStyle(cream)
                Text(".")
                    .font(.system(size: 56, weight: .bold))
                    .tracking(-2.24)
                    .foregroundStyle(accentPurple)
            }
        }
    }

    // MARK: - Filter Capsules

    private var filterCapsules: some View {
        HStack(spacing: 8) {
            tabPill("this month", active: selectedTab == .thisMonth) { selectedTab = .thisMonth }
            tabPill("next month", active: selectedTab == .nextMonth) { selectedTab = .nextMonth }
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
                .font(.custom(active ? FontFamily.Rubik.semiBold : FontFamily.Rubik.medium, size: 13))
                .foregroundStyle(active ? onAccentText : cream)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
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

    // MARK: - Next Bill

    @ViewBuilder
    private var nextBillSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("next bill up")
                .font(.custom(FontFamily.Rubik.medium, size: 18))
                .foregroundStyle(mutedText)

            if let bill = nextBill {
                nextBillCard(bill)
            } else {
                noBillsCard
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
        Text("nothing due \(selectedTab == .thisMonth ? "this month" : "next month")")
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
                Text("weekly spending")
                    .font(.custom(FontFamily.Rubik.medium, size: 18))
                    .foregroundStyle(mutedText)
                Spacer()
                Text("\(formatCurrency(weeklyLimit)) limit")
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
        }
    }

    private func weekAlignment(for index: Int) -> HorizontalAlignment {
        switch index {
        case 0: return .leading
        case weeks.count - 1: return .trailing
        default: return .center
        }
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
        SpendingService(context: modelContext, currency: currency)
    }

    /// Spending for the displayed month, sourced from NoteTokens. Next-month
    /// view shows $0 (nothing spent yet) — projection logic lives in `weeks`.
    private var spentSoFarForMonth: Double {
        selectedTab == .thisMonth ? spendingService.totalSpent(inMonthOf: displayedMonthDate) : 0
    }

    private var breathingRoom: Double {
        max(0, monthlyIncome - totalBillsForMonth - spentSoFarForMonth)
    }

    private var weeklyLimit: Double {
        monthlyIncome / 4
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
        let actualByWeek = spendingService.weeklyActuals(inMonthOf: monthStart)

        // Day ranges per week (closed): used for current-week detection
        let daysInMonth = cal.range(of: .day, in: .month, for: monthStart)?.last ?? 30
        let ranges: [ClosedRange<Int>] = [
            1...7,
            8...14,
            15...21,
            22...daysInMonth
        ]

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
