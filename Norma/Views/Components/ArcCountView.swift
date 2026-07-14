//
//  ArcCountView.swift
//  Norma
//
//  Created by Claude on 12/18/25.
//

import SwiftUI
import SwiftData

struct ArcCountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @Query(sort: \FreedomFundEntry.createdAt, order: .reverse)
    private var allEntries: [FreedomFundEntry]
    @Query(
        filter: #Predicate<Insight> { $0.dismissedAt == nil },
        sort: \Insight.createdAt,
        order: .reverse
    )
    private var insights: [Insight]

    let arcCount: Int
    let freedomFund: Double
    let totalMonthlyBills: Double
    let currency: String

    @State private var showFreedomFundEdit = false
    @State private var showInfoPopover = false

    @Environment(\.modelContext) private var modelContext
    /// Balance re-anchor via popover: tapping the amount capsule opens a small
    /// popover with the amount field; saving writes the balance + a ledger row.
    @State private var showBalancePopover = false
    @State private var showStatusPopover = false
    @State private var showInsights = false
    @State private var popoverInsightId: UUID?
    @State private var balanceText = ""
    @FocusState private var balanceFocused: Bool

    @State private var heroWordCount = 0
    @State private var pillVisible = false
    @State private var rangeVisible = false
    @State private var activityVisible = false
    /// Which hero message the runway view shows.
    ///   - runway:  arcCount >= 1 (covered for N months)
    ///   - addBill: funded, but no bills tracked yet — runway can't be computed,
    ///              so "refill" would be the wrong nudge. Ask for a bill instead.
    ///   - refill:  any other arcCount == 0 (empty/low fund).
    private enum RunwayState { case runway, addBill, refill }

    private var runwayState: RunwayState {
        if freedomFund <= 0 { return .refill }
        if runwayDays == nil { return .addBill }
        return .runway
    }

    /// Observed daily burn from the ledger (falls back to bills ÷ 30).
    private var dailyBurn: Double {
        let userId = sessionViewModel.currentUser?.userId
        let entries = allEntries.filter { $0.userId == userId }
        return ArcCalculationService.dailyBurn(entries: entries, monthlyBills: totalMonthlyBills)
    }

    /// Runway in days: balance ÷ burn. Nil when there's no balance or no burn
    /// source (no bills and no observed history) — the "add a bill" state.
    private var runwayDays: Int? {
        guard dailyBurn > 0, freedomFund > 0 else { return nil }
        return Int(floor(freedomFund / dailyBurn))
    }

    /// Compact runway value + unit for the hero (e.g. "7" / "weeks").
    private var compactRunway: (value: String, unit: String) {
        ArcCalculationService.compactRunway(days: runwayDays ?? 0)
    }

    private var heroWordTotal: Int {
        switch runwayState {
        case .runway:  return 5
        case .addBill: return 8
        case .refill:  return 4
        }
    }

    private let bg = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private var accentPurple: Color { NormaPalette.lavender }
    private var glassBorder: Color { cream.opacity(0.22) }
    private var glassFill: Color { Color.white.opacity(0.04) }
    private var heroFont: Font { .system(size: 64, weight: .bold) }

    private struct ActivityItem: Identifiable {
        let id: UUID
        let date: String
        let label: String
        let amount: String
        let isIncome: Bool
        var faded: Bool = false
    }

    /// A merged timeline row — either a fund-balance change or an AI insight,
    /// carried together in one date-sorted feed.
    private struct TimelineRow: Identifiable {
        let id: UUID
        let date: Date
        let kind: Kind
        enum Kind {
            case fund(ActivityItem)
            case insight(headline: String, detail: String, dateLabel: String)
        }
    }

    /// True once the user has connected a bank account as their fund source.
    private var hasLinkedAccount: Bool {
        sessionViewModel.currentUser?.settings.arcAccountId != nil
    }

    /// "First time" state: the user has never engaged with the freedom fund.
    /// No manual balance, no linked account, and no ledger history. This is
    /// distinct from "time to refill" (arcCount == 0), which means they've
    /// funded it before and since drawn it down.
    private var isFirstTime: Bool {
        let hasHistory = allEntries.contains { $0.userId == sessionViewModel.currentUser?.userId }
        return freedomFund <= 0 && !hasLinkedAccount && !hasHistory
    }

    /// The merged activity feed: fund-balance changes + AI insights, sorted
    /// together newest-first. Insights long-press into the full InsightsView.
    private var timelineRows: [TimelineRow] {
        guard let userId = sessionViewModel.currentUser?.userId else { return [] }
        let fundRows = allEntries
            .filter { $0.userId == userId }
            .map { entry in
                TimelineRow(
                    id: UUID(uuidString: entry.id) ?? UUID(),
                    date: entry.createdAt,
                    kind: .fund(ActivityItem(
                        id: UUID(uuidString: entry.id) ?? UUID(),
                        date: Self.dateLabel(for: entry.createdAt),
                        label: Self.activityLabel(for: entry),
                        amount: formatSignedCurrency(entry.delta),
                        isIncome: entry.delta > 0
                    ))
                )
            }
        let insightRows = insights.map { insight in
            TimelineRow(
                id: insight.id,
                date: insight.createdAt,
                kind: .insight(
                    headline: insight.headline,
                    detail: insight.detail,
                    dateLabel: Self.dateLabel(for: insight.createdAt)
                )
            )
        }
        return (fundRows + insightRows).sorted { $0.date > $1.date }
    }

    private static func dateLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "today" }
        if calendar.isDateInYesterday(date) { return "yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date).lowercased()
    }

    private static func activityLabel(for entry: FreedomFundEntry) -> String {
        switch entry.source {
        case .manualEdit:
            return entry.delta >= 0 ? "added to fund" : "withdrew from fund"
        case .linkedAccountSync:
            return "balance synced"
        }
    }

    private func formatSignedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        let absString = formatter.string(from: NSNumber(value: abs(value))) ?? "$\(Int(abs(value)))"
        let prefix = value >= 0 ? "+" : "−"
        return "\(prefix)\(absString)"
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    private var upcomingMonths: [(name: String, shortName: String, isCovered: Bool, year: Int)] {
        let calendar = Calendar.current
        let now = Date()
        return (1...24).map { offset in
            guard let futureDate = calendar.date(byAdding: .month, value: offset, to: now) else {
                return (name: "", shortName: "", isCovered: false, year: 0)
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            let fullName = formatter.string(from: futureDate)
            formatter.dateFormat = "MMM"
            let shortName = formatter.string(from: futureDate).lowercased()
            let year = calendar.component(.year, from: futureDate)
            return (name: fullName, shortName: shortName, isCovered: offset <= arcCount, year: year)
        }
    }

    var body: some View {
        // No NavigationStack here — HomeView owns the stack and the chrome
        // (settings + notes). This view is pure content now.
        Group {
            if isFirstTime {
                firstTimeContent
            } else {
                fundedContent
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showFreedomFundEdit) {
            FreedomFundEditSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showInsights) {
            InsightsView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .onAppear {
            if !isFirstTime { runEntranceAnimation() }
        }
    }

    // MARK: - First-time content (never engaged with the fund)

    @ViewBuilder
    private var firstTimeContent: some View {
        FreedomFundFirstTimeView {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            showFreedomFundEdit = true
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Funded / Refill content (arcCount >= 0, has history)

    @ViewBuilder
    private var fundedContent: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Status + amount capsules. The status capsule uses the theme
                // color; the amount capsule opens the balance-edit popover.
                HStack(spacing: 8) {
                    Button {
                        beginBalanceEdit()
                    } label: {
                        Text("balance: \(formatCurrency(freedomFund))")
                            .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                            .foregroundColor(cream)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(glassFill))
                            .overlay(Capsule().stroke(glassBorder, lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .popover(isPresented: $showBalancePopover, arrowEdge: .top) {
                        balanceEditPopover
                            .presentationCompactAdaptation(.popover)
                    }

                    if runwayState == .runway {
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            showStatusPopover = true
                        } label: {
                            Text(statusLine)
                                .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                                .foregroundColor(accentPurple)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(accentPurple.opacity(0.14)))
                                .overlay(Capsule().stroke(accentPurple.opacity(0.5), lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .popover(isPresented: $showStatusPopover, arrowEdge: .top) {
                            statusInfoPopover
                                .presentationCompactAdaptation(.popover)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .opacity(pillVisible ? 1 : 0)
                .offset(y: pillVisible ? 0 : 8)

                // Runway hero — the wave-text headline, restored.
                VStack(alignment: .leading, spacing: 0) {
                    switch runwayState {
                    case .runway:
                        HStack(spacing: 14) {
                            waveWord(compactRunway.value, index: 0)
                            waveWord(compactRunway.unit, index: 1)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 14) {
                            waveWord("of", index: 2)
                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                waveWord("runway", index: 3)
                                waveWord(".", index: 4, color: accentPurple)
                            }
                        }
                    case .addBill:
                        HStack(spacing: 14) {
                            waveWord("add", index: 0)
                            waveWord("a", index: 1)
                            waveWord("bill", index: 2)
                        }
                        HStack(spacing: 14) {
                            waveWord("to", index: 3)
                            waveWord("see", index: 4)
                            waveWord("your", index: 5)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            waveWord("runway", index: 6)
                            waveWord(".", index: 7, color: accentPurple)
                        }
                    case .refill:
                        HStack(spacing: 14) {
                            waveWord("time", index: 0)
                            waveWord("to", index: 1)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            waveWord("refill", index: 2)
                            waveWord(".", index: 3, color: accentPurple)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                if arcCount > 0 {
                    let firstCovered = upcomingMonths.first(where: { $0.isCovered })
                    let lastCovered = upcomingMonths.last(where: { $0.isCovered })
                    HStack(spacing: 12) {
                        if let first = firstCovered {
                            rangePill(first.shortName, year: first.year)
                        }
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(mutedText)
                        if let last = lastCovered {
                            rangePill(last.shortName, year: last.year)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                    .opacity(rangeVisible ? 1 : 0)
                    .offset(y: rangeVisible ? 0 : 8)
                }

                Text("recent activity")
                    .font(.custom(FontFamily.Rubik.medium, size: 13))
                    .foregroundColor(mutedText)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .opacity(activityVisible ? 1 : 0)

                ZStack(alignment: .top) {
                    if timelineRows.isEmpty {
                        Text("no activity yet.")
                            .font(.custom(FontFamily.Rubik.regular, size: 14).italic())
                            .foregroundColor(dimText)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 32)
                            .padding(.bottom, 40)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 10) {
                                ForEach(timelineRows) { row in
                                    timelineRowView(row)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 120)
                        }
                        LinearGradient(
                            colors: [bg, bg.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 28)
                        .allowsHitTesting(false)
                    }
                }
                .opacity(activityVisible ? 1 : 0)
                .offset(y: activityVisible ? 0 : 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(bg.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
    }

    /// Status word shown above the balance hero.
    private var statusLine: String {
        switch runwayState {
        case .runway:
            return ArcCalculationService.getStateName(days: runwayDays ?? 0).lowercased()
        case .addBill:
            return "add a bill to see your runway"
        case .refill:
            return "time to refill"
        }
    }

    private var currencySymbol: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currency
        return f.currencySymbol ?? "$"
    }

    /// The popover balance editor — reuses AnimatedAmountField in a compact
    /// form. Save writes through commitBalance and dismisses.
    @ViewBuilder
    private var balanceEditPopover: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("total spendable balance")
                .font(.custom(FontFamily.Rubik.medium, size: 15))
                .foregroundColor(mutedText)

            HStack(alignment: .center, spacing: 5) {
                Text(currencySymbol)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(cream.opacity(0.55))
                AnimatedAmountField(
                    text: $balanceText,
                    focused: $balanceFocused,
                    font: .system(size: 48, weight: .bold),
                    textColor: cream,
                    placeholderColor: cream.opacity(0.3),
                    caretColor: accentPurple,
                    caretHeight: 42,
                    tracking: -1
                )
            }

            Button {
                commitBalance()
                showBalancePopover = false
            } label: {
                Text("save")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                    .foregroundColor(cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(glassFill))
                    .overlay(Capsule().stroke(accentPurple.opacity(0.55), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(width: 340)
        .background(bg)
    }

    /// Legend of the runway status tiers, highlighting the user's current one.
    @ViewBuilder
    private var statusInfoPopover: some View {
        let current = ArcCalculationService.getStateName(days: runwayDays ?? 0)
        let tiers: [(name: String, desc: String)] = [
            ("Urgency", "less than two weeks. every decision matters."),
            ("Cautionary", "a couple weeks to a month. breathing room, not comfort."),
            ("Steady", "one to four months. solid ground."),
            ("Calm", "four to nine months. real distance from zero."),
            ("Abundant", "nine months or more. serious cushion.")
        ]
        VStack(alignment: .leading, spacing: 16) {
            Text("what your status means")
                .font(.custom(FontFamily.Rubik.semiBold, size: 17))
                .foregroundColor(cream)
            ForEach(tiers, id: \.name) { tier in
                let isCurrent = tier.name == current
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(isCurrent ? accentPurple : cream.opacity(0.25))
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(tier.name.lowercased())
                            .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                            .foregroundColor(isCurrent ? accentPurple : cream)
                        Text(tier.desc)
                            .font(.custom(FontFamily.Rubik.regular, size: 14))
                            .foregroundColor(mutedText)
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 340)
        .background(bg)
    }

    private func beginBalanceEdit() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        if freedomFund > 0 {
            let isWhole = freedomFund.truncatingRemainder(dividingBy: 1) == 0
            balanceText = String(format: isWhole ? "%.0f" : "%.2f", freedomFund)
        } else {
            balanceText = ""
        }
        showBalancePopover = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            balanceFocused = true
        }
    }

    /// The re-anchor. Writes the new balance to settings + a manual-edit ledger
    /// entry, mirroring FreedomFundEditSheet's save path. No-ops if unchanged or
    /// unparseable.
    private func commitBalance() {
        balanceFocused = false
        guard var updatedProfile = sessionViewModel.currentUser else { return }
        let cleaned = balanceText.filter { $0.isNumber || $0 == "." }
        guard let newFund = Double(cleaned) else { return }
        var updatedSettings = updatedProfile.settings
        guard updatedSettings.freedomFund != newFund else { return }
        updatedSettings.freedomFund = newFund
        updatedProfile.freedomFund = newFund
        FreedomFundLedger.recordIfChanged(
            in: modelContext,
            userId: updatedProfile.userId,
            newBalance: newFund,
            source: .manualEdit
        )
        updatedProfile.settings = updatedSettings
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        Task { await sessionViewModel.updateUserProfile(updatedProfile) }
    }

    @ViewBuilder
    private func waveWord(_ text: String, index: Int, color: Color? = nil) -> some View {
        let visible = index < heroWordCount
        Text(text)
            .font(heroFont)
            .foregroundColor(color ?? cream)
            .tracking(-2.56)
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 18)
            .blur(radius: visible ? 0 : 5)
    }

    private func runEntranceAnimation() {
        guard heroWordCount == 0 else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                pillVisible = true
            }
        }

        let heroStart = 0.3
        for i in 0..<heroWordTotal {
            DispatchQueue.main.asyncAfter(deadline: .now() + heroStart + Double(i) * 0.06) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    heroWordCount = i + 1
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                rangeVisible = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            withAnimation(.easeOut(duration: 0.5)) {
                activityVisible = true
            }
        }
    }

    @ViewBuilder
    private func rangePill(_ name: String, year: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(name)
                .font(.custom(FontFamily.Rubik.semiBold, size: 14))
                .foregroundColor(cream)
            Text(String(year))
                .font(.custom(FontFamily.Rubik.medium, size: 12))
                .foregroundColor(cream.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Capsule().fill(glassFill))
        .overlay(Capsule().stroke(glassBorder, lineWidth: 1))
    }

    @ViewBuilder
    private func timelineRowView(_ row: TimelineRow) -> some View {
        switch row.kind {
        case .fund(let item):
            HStack(spacing: 0) {
                if !item.isIncome { Spacer(minLength: 0) }
                activityRow(item)
                if item.isIncome { Spacer(minLength: 0) }
            }
        case .insight(let headline, let detail, let dateLabel):
            HStack(spacing: 0) {
                insightRow(headline: headline, dateLabel: dateLabel)
                    .onLongPressGesture {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        popoverInsightId = row.id
                    }
                    .popover(
                        isPresented: Binding(
                            get: { popoverInsightId == row.id },
                            set: { if !$0 { popoverInsightId = nil } }
                        ),
                        arrowEdge: .top
                    ) {
                        insightDetailPopover(headline: headline, detail: detail)
                            .presentationCompactAdaptation(.popover)
                    }
                Spacer(minLength: 0)
            }
        }
    }

    /// Long-press popover for an insight — shows the full write-up plus a
    /// button through to the complete InsightsView.
    @ViewBuilder
    private func insightDetailPopover(headline: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("norma")
                .font(.custom(FontFamily.Rubik.semiBold, size: 13))
                .foregroundColor(accentPurple)
            Text(headline)
                .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                .foregroundColor(cream)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(.custom(FontFamily.Rubik.regular, size: 15))
                .foregroundColor(mutedText)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                popoverInsightId = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showInsights = true
                }
            } label: {
                Text("see all insights")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                    .foregroundColor(accentPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(accentPurple.opacity(0.12)))
                    .overlay(Capsule().stroke(accentPurple.opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(width: 340)
        .background(bg)
    }

    /// AI-insight row — Norma's commentary as a capsule matching the fund rows.
    /// Content-width, max two lines (ellipsis past that). The norma·date pill
    /// hovers over the bottom-trailing edge so it reads as a signature.
    @ViewBuilder
    private func insightRow(headline: String, dateLabel: String) -> some View {
        Text(headline)
            .font(.custom(FontFamily.Rubik.medium, size: 16))
            .foregroundColor(cream)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
            .truncationMode(.tail)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: 300, alignment: .leading)
            .glassEffect(in: Capsule())
            .overlay(Capsule().stroke(glassBorder, lineWidth: 1))
            .overlay(alignment: .bottomLeading) {
                HStack(spacing: 5) {
                    Text("norma")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 12))
                        .foregroundColor(accentPurple)
                    Text("·")
                        .font(.custom(FontFamily.Rubik.regular, size: 12))
                        .foregroundColor(dimText)
                    Text(dateLabel)
                        .font(.custom(FontFamily.Rubik.regular, size: 12).italic())
                        .foregroundColor(dimText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(bg))
                .overlay(Capsule().stroke(glassBorder, lineWidth: 1))
                .offset(x: 14, y: 12)
            }
            .padding(.bottom, 12)
    }

    @ViewBuilder
    private func activityRow(_ item: ActivityItem) -> some View {
        HStack(spacing: 10) {
            Text(item.date)
                .font(.custom(FontFamily.Rubik.regular, size: 15).italic())
                .foregroundColor(dimText)

            if item.isIncome {
                Circle()
                    .fill(cream.opacity(0.3))
                    .frame(width: 3, height: 3)
            } else {
                Rectangle()
                    .fill(cream.opacity(0.3))
                    .frame(width: 8, height: 1)
            }

            Text(item.label)
                .font(.custom(FontFamily.Rubik.medium, size: 16))
                .foregroundColor(mutedText)

            Text(item.amount)
                .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                .foregroundColor(item.isIncome ? accentPurple : mutedText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(
            Group {
                if !item.isIncome {
                    Capsule().fill(Color.white.opacity(0.02))
                }
            }
        )
        .overlay(
            Capsule()
                .stroke(
                    item.isIncome ? accentPurple.opacity(0.32) : glassBorder,
                    style: item.isIncome
                        ? StrokeStyle(lineWidth: 1, dash: [4, 3])
                        : StrokeStyle(lineWidth: 1)
                )
        )
    }
}

// MARK: - Freedom Fund First-Time Interstitial
/// Shown the first time a user opens the runway detail before they've ever
/// funded the fund (no balance, no linked account, no ledger history).
///
/// Two stages:
///   1. `.intro` — a typographic wave-text sequence (same rhythm as the
///      onboarding interstitial) that explains what a freedom fund is and how
///      norma reads it. Auto-advances; tap anywhere to skip forward.
///   2. `.setup` — a stripped-down action screen: just the "keep it current"
///      methods and the CTA that hands off to `FreedomFundEditSheet`.
struct FreedomFundFirstTimeView: View {
    let onSetUp: () -> Void

    private enum Stage { case intro, setup }
    @State private var stage: Stage = .intro

    // Intro phase machine
    @State private var introPhaseIndex = 0
    @State private var introDidFinish = false

    // Setup-stage entrance
    @State private var heroAnimating = false
    @State private var methodsVisible = false

    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private var accentPurple: Color { NormaPalette.lavender }
    private var glassBorder: Color { cream.opacity(0.22) }
    private var glassFill: Color { Color.white.opacity(0.04) }

    private let wordHaptic = UIImpactFeedbackGenerator(style: .soft)
    private let advanceHaptic = UIImpactFeedbackGenerator(style: .light)

    /// What it is / why it matters, delivered one line at a time.
    private let introPhases = [
        "this is your freedom fund.",
        "money you set aside to cover your bills.",
        "norma reads it as runway — how many months you're covered."
    ]
    /// How long each line lingers after its wave-in completes before advancing.
    private let introHold: Double = 1.7

    var body: some View {
        ZStack {
            if stage == .intro {
                introContent
                    .transition(.opacity)
            } else {
                setupContent
                    .transition(.opacity)
            }
        }
    }

    // MARK: Stage 1 — wave-text intro

    private var introContent: some View {
        ZStack(alignment: .leading) {
            // Tap anywhere to skip forward.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { advanceIntro() }

            WaveTextView(
                text: introPhases[introPhaseIndex],
                font: .system(size: 56, weight: .bold),
                color: cream,
                isAnimating: true,
                alignment: .leading,
                tracking: -1.5,
                wordSpacing: 12,
                lineSpacing: 0,
                onWordAppear: { _ in
                    wordHaptic.impactOccurred(intensity: 0.5)
                    wordHaptic.prepare()
                }
            )
            .id(introPhaseIndex)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onAppear {
            wordHaptic.prepare()
            advanceHaptic.prepare()
            scheduleIntroAdvance()
        }
    }

    private func scheduleIntroAdvance() {
        // Wave-in finishes ~ (0.5 + (n - 1) * 0.06)s, plus a hold, then advance.
        let wordCount = introPhases[introPhaseIndex].split(separator: " ").count
        let inDuration = 0.5 + Double(max(0, wordCount - 1)) * 0.06
        let totalShow = inDuration + introHold
        let snapshot = introPhaseIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + totalShow) {
            guard !introDidFinish, introPhaseIndex == snapshot, stage == .intro else { return }
            advanceIntro()
        }
    }

    private func advanceIntro() {
        guard !introDidFinish else { return }
        if introPhaseIndex < introPhases.count - 1 {
            withAnimation(.easeInOut(duration: 0.35)) { introPhaseIndex += 1 }
            scheduleIntroAdvance()
        } else {
            finishIntro()
        }
    }

    private func finishIntro() {
        guard !introDidFinish else { return }
        introDidFinish = true
        advanceHaptic.impactOccurred()
        withAnimation(.easeInOut(duration: 0.4)) { stage = .setup }
        runSetupEntrance()
    }

    // MARK: Stage 2 — setup actions

    private var setupContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    WaveTextView(
                        text: "how to keep it current",
                        font: .system(size: 56, weight: .bold),
                        color: cream,
                        isAnimating: heroAnimating,
                        alignment: .leading,
                        accentSuffix: ".",
                        accentColor: accentPurple,
                        tracking: -1.5,
                        wordSpacing: 12,
                        lineSpacing: 0,
                        onWordAppear: { _ in
                            wordHaptic.impactOccurred(intensity: 0.5)
                            wordHaptic.prepare()
                        }
                    )
                    .padding(.top, 24)

                    VStack(spacing: 12) {
                        methodCard(
                            icon: "pencil",
                            title: "enter it manually",
                            detail: "type how much you have. update it whenever it changes."
                        )
                        methodCard(
                            icon: "building.columns.fill",
                            title: "connect an account",
                            detail: "link a bank and your balance syncs on its own — no manual updates."
                        )
                    }
                    .padding(.top, 28)
                    .opacity(methodsVisible ? 1 : 0)
                    .offset(y: methodsVisible ? 0 : 10)

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                onSetUp()
            } label: {
                Text("set up my fund")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                    .foregroundColor(cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(glassFill))
                    .overlay(Capsule().stroke(accentPurple.opacity(0.55), lineWidth: 1))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .opacity(methodsVisible ? 1 : 0)
        }
    }

    private func runSetupEntrance() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            heroAnimating = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                methodsVisible = true
            }
        }
    }

    @ViewBuilder
    private func methodCard(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(accentPurple)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                    .foregroundColor(cream)
                Text(detail)
                    .font(.custom(FontFamily.Rubik.regular, size: 13))
                    .foregroundColor(mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(glassFill))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(glassBorder, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        )
    }
}

// MARK: - Freedom Fund Edit Sheet
struct FreedomFundEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @ObservedObject private var plaidService = PlaidService.shared

    @State private var freedomFundText: String = ""
    @State private var isSaving = false
    @State private var useLinkedAccount: Bool = false
    @State private var selectedAccountId: String?
    @FocusState private var isTextFieldFocused: Bool

    private let bg = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private var accentPurple: Color { NormaPalette.lavender }
    private var glassBorder: Color { cream.opacity(0.22) }
    private var glassFill: Color { Color.white.opacity(0.04) }
    private var heroFont: Font { .system(size: 64, weight: .bold) }

    private var currentFreedomFund: Double {
        sessionViewModel.currentUser?.settings.freedomFund ?? 0
    }

    private var currentArcAccountId: String? {
        sessionViewModel.currentUser?.settings.arcAccountId
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private var currencySymbol: String {
        CurrencyData.getSymbol(for: currency)
    }

    private var hasPlaidAccounts: Bool {
        FeatureFlags.plaidEnabled && !plaidService.connectedAccounts.isEmpty
    }

    private var selectedAccountBalance: Double? {
        guard let accountId = selectedAccountId else { return nil }
        return plaidService.connectedAccounts.first { $0.accountId == accountId }?.balances.current
    }

    @State private var showFundInfo = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                if hasPlaidAccounts {
                    HStack(spacing: 10) {
                        sourcePill("manual", active: !useLinkedAccount) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                useLinkedAccount = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isTextFieldFocused = true
                            }
                        }
                        sourcePill("linked account", active: useLinkedAccount) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                useLinkedAccount = true
                                isTextFieldFocused = false
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 4) {
                        Text(currencySymbol)
                            .font(heroFont)
                            .tracking(-2.56)
                            .foregroundColor(cream.opacity(0.55))

                        if useLinkedAccount, let balance = selectedAccountBalance {
                            Text(formatNumberWithoutCurrency(balance))
                                .font(heroFont)
                                .tracking(-2.56)
                                .foregroundColor(cream)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        } else {
                            AnimatedAmountField(
                                text: $freedomFundText,
                                focused: $isTextFieldFocused,
                                font: heroFont,
                                textColor: cream,
                                placeholderColor: cream.opacity(0.3),
                                caretColor: accentPurple,
                                caretHeight: 46,
                                tracking: -2.56
                            )
                        }
                    }

                    Text(useLinkedAccount ? "from linked account" : "how much is in your freedom fund?")
                        .font(.custom(FontFamily.Rubik.medium, size: 13))
                        .foregroundColor(mutedText)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                if useLinkedAccount {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(plaidService.connectedAccounts) { account in
                                accountCard(account)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }

                Spacer(minLength: 0)
            }
            .background(bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button {
                    saveChanges()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(cream)
                                .scaleEffect(0.85)
                        } else {
                            Text("save")
                                .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                                .foregroundColor(cream)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(glassFill))
                    .overlay(Capsule().stroke(accentPurple.opacity(0.55), lineWidth: 1))
                }
                .disabled(isSaving || (useLinkedAccount && selectedAccountId == nil))
                .opacity(isSaving || (useLinkedAccount && selectedAccountId == nil) ? 0.4 : 1)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showFundInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundColor(mutedText)
                    }
                    .popover(isPresented: $showFundInfo, arrowEdge: .top) {
                        FreedomFundInfoPopover()
                            .presentationCompactAdaptation(.popover)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("done")
                            .font(.custom(FontFamily.Rubik.medium, size: 14))
                            .foregroundColor(cream)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if let arcAccountId = currentArcAccountId,
               plaidService.connectedAccounts.contains(where: { $0.accountId == arcAccountId }) {
                useLinkedAccount = true
                selectedAccountId = arcAccountId
            } else {
                useLinkedAccount = false
                if currentFreedomFund > 0 {
                    // Seed the raw (un-grouped) value — AnimatedAmountField owns
                    // comma formatting for display; the stored string stays plain.
                    let isWhole = currentFreedomFund == currentFreedomFund.rounded()
                    freedomFundText = String(format: isWhole ? "%.0f" : "%.2f", currentFreedomFund)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFieldFocused = true
                }
            }
        }
    }

    @ViewBuilder
    private func sourcePill(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        } label: {
            Text(label)
                .font(.custom(FontFamily.Rubik.medium, size: 13))
                .foregroundColor(active ? cream : mutedText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(active ? Capsule().fill(glassFill) : Capsule().fill(.clear))
                .overlay(
                    Capsule().stroke(
                        active ? glassBorder : mutedText.opacity(0.4),
                        style: active ? StrokeStyle(lineWidth: 1) : StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func accountCard(_ account: PlaidService.PlaidAccount) -> some View {
        let selected = selectedAccountId == account.accountId
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedAccountId = account.accountId
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(selected ? accentPurple : dimText)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(account.name)
                            .font(.custom(FontFamily.Rubik.medium, size: 15))
                            .foregroundColor(cream)

                        if let mask = account.mask {
                            Text("••\(mask)")
                                .font(.custom(FontFamily.Rubik.regular, size: 12))
                                .foregroundColor(mutedText)
                        }
                    }

                    if let current = account.balances.current {
                        Text(formatCurrencyFull(current))
                            .font(.custom(FontFamily.Rubik.regular, size: 13))
                            .foregroundColor(mutedText)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 14).fill(glassFill))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        selected ? accentPurple.opacity(0.55) : glassBorder,
                        style: selected ? StrokeStyle(lineWidth: 1) : StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatCurrencyFull(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    private func formatNumberWithoutCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private func parseNumber(_ text: String) -> Double {
        let cleanedText = text.replacingOccurrences(of: ",", with: "")
        return Double(cleanedText) ?? 0
    }

    private func saveChanges() {
        guard let currentUser = sessionViewModel.currentUser else { return }

        isSaving = true

        var updatedSettings = currentUser.settings
        var updatedProfile = currentUser

        if useLinkedAccount {
            // Wire the account. Plaid is the source of truth for the value —
            // we don't snapshot the balance into settings, and we don't write
            // a ledger entry here. RootView's Plaid sync already records
            // .linkedAccountSync entries whenever the live balance moves.
            guard let accountId = selectedAccountId else {
                isSaving = false
                return
            }
            updatedSettings.arcAccountId = accountId
        } else {
            // Manual is the source of truth for this branch — settings.freedomFund
            // holds the user-typed value, and we record a manual-edit ledger
            // entry when it actually changes.
            let newFreedomFund = parseNumber(freedomFundText)
            updatedSettings.arcAccountId = nil
            updatedSettings.freedomFund = newFreedomFund
            updatedProfile.freedomFund = newFreedomFund

            FreedomFundLedger.recordIfChanged(
                in: modelContext,
                userId: currentUser.userId,
                newBalance: newFreedomFund,
                source: .manualEdit
            )
        }

        updatedProfile.settings = updatedSettings

        Task {
            await sessionViewModel.updateUserProfile(updatedProfile)

            await MainActor.run {
                isSaving = false

                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

                dismiss()
            }
        }
    }
}

// MARK: - Income Edit Sheet
struct IncomeEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionViewModel: SessionViewModel

    @State private var incomeText: String = ""
    @State private var isSaving = false
    @FocusState private var isTextFieldFocused: Bool

    private var currentIncome: Double {
        sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private var currencySymbol: String {
        CurrencyData.getSymbol(for: currency)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color("NormaPastelTeal"))

                    Text("Update Monthly Income")
                        .font(.custom(FontFamily.Rubik.medium, size: 18))
                        .foregroundColor(.primary)

                    Text("Enter your monthly income after taxes")
                        .font(.normaInput(14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                // Amount input
                HStack(spacing: 8) {
                    Text(currencySymbol)
                        .font(.custom(FontFamily.Rubik.medium, size: 24))
                        .foregroundColor(.primary)

                    TextField("0", text: $incomeText)
                        .font(.custom(FontFamily.Rubik.regular, size: 24))
                        .keyboardType(.decimalPad)
                        .focused($isTextFieldFocused)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isTextFieldFocused ? Color("NormaPastelTeal") : Color.clear,
                            lineWidth: 2
                        )
                )
                .padding(.horizontal, 24)

                Spacer()

                // Save button
                Button {
                    saveChanges()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                                .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("NormaPastelTeal"))
                    )
                    .foregroundColor(.white)
                }
                .disabled(isSaving)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color("NormaBackground"))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Monthly Income")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            // Pre-populate with current value
            if currentIncome > 0 {
                incomeText = formatNumberWithoutCurrency(currentIncome)
            }

            // Auto-focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
    }

    private func formatNumberWithoutCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private func parseNumber(_ text: String) -> Double {
        let cleanedText = text.replacingOccurrences(of: ",", with: "")
        return Double(cleanedText) ?? 0
    }

    private func saveChanges() {
        guard let currentUser = sessionViewModel.currentUser else { return }

        isSaving = true

        let newIncome = parseNumber(incomeText)

        // Create updated settings
        var updatedSettings = currentUser.settings
        updatedSettings.monthlyIncome = newIncome

        // Create updated profile - encryption handled by Edge Function via updateUserProfile
        var updatedProfile = currentUser
        updatedProfile.settings = updatedSettings

        Task {
            await sessionViewModel.updateUserProfile(updatedProfile)

            await MainActor.run {
                isSaving = false

                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

                dismiss()
            }
        }
    }
}

// MARK: - Arc Info Popover
struct ArcInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color("NormaPastelTeal"))

                Text("your runway")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("runway is how many months your freedom fund can cover your bills.")
                    .font(.normaInput(14))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("if your monthly bills are $1,500 and you have $4,500 saved, you have 3 months of runway.")
                    .font(.normaInput(14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            HStack(spacing: 10) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 20))
                    .foregroundColor(NormaPalette.lavender)

                Text("connect an account")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundColor(.primary)
            }

            Text("link a bank account and your balance becomes your freedom fund automatically — no manual updates.")
                .font(.normaInput(14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 300)
        .background(Color("NormaBackground"))
    }
}

// MARK: - Freedom Fund Info Popover
struct FreedomFundInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color("NormaPastelTeal"))

                Text("Freedom Fund")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Your Freedom Fund is the total amount you have saved to cover bills.")
                    .font(.normaInput(14))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Arcs are calculated by dividing this amount by your total monthly bills. The more you save, the more months you're covered.")
                    .font(.normaInput(14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            HStack(spacing: 10) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 20))
                    .foregroundColor(NormaPalette.lavender)

                Text("Linked Account")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundColor(.primary)
            }

            Text("Connect a bank account to automatically sync your balance as your Freedom Fund. No more manual updates.")
                .font(.normaInput(14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 300)
        .background(Color("NormaBackground"))
    }
}


#Preview {
    ArcCountView(
        arcCount: 3,
        freedomFund: 4500,
        totalMonthlyBills: 1500,
        currency: "USD"
    )
    .environmentObject(SessionViewModel(dataManager: DataManager()))
}
