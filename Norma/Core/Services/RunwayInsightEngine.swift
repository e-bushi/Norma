//
//  RunwayInsightEngine.swift
//  Norma
//
//  Rule-based insight generation for the runway-first app. Replaces the
//  deleted note-prose LLM engine: every insight is computed deterministically
//  from data the app already has — bills, commit tokens, the FreedomFundEntry
//  ledger, and the current runway tier — so it's instant, free, and testable.
//
//  Four rules (see plans/norma-chat.md follow-up #2):
//   - bill collision  → two+ outflows land in the same upcoming week
//   - burn spike      → this week's burn is meaningfully above last week's
//   - low runway      → runway drops under the 30-day line
//   - tier milestone  → runway crosses UP into a new status tier
//
//  Dedup is by `Insight.ruleKey`: a live match is already showing (skip); a
//  dismissed match must never resurface. Keys carry a coarse time bucket so a
//  condition can legitimately re-warn later (next week/month) without spamming.
//

import Foundation
import SwiftData

@MainActor
final class RunwayInsightEngine {
    static let shared = RunwayInsightEngine()
    private init() {}

    private let cooldown: TimeInterval = 6 * 60 * 60 // 6 hours
    private var isRunning = false

    private var lastRunAt: Double {
        get { UserDefaults.standard.double(forKey: "runwayInsight.lastRunAt") }
        set { UserDefaults.standard.set(newValue, forKey: "runwayInsight.lastRunAt") }
    }

    /// Previous runway tier index (0…4), -1 before the first run. Used to fire
    /// a milestone only on an upward crossing.
    private var lastTierIndex: Int {
        get { UserDefaults.standard.object(forKey: "runwayInsight.lastTier") as? Int ?? -1 }
        set { UserDefaults.standard.set(newValue, forKey: "runwayInsight.lastTier") }
    }

    // MARK: - Public API

    /// Entries must already be filtered to the current user. Bills come from
    /// BillViewModel (Supabase-backed, not in SwiftData); tokens + existing
    /// insights are fetched here.
    func analyzeIfNeeded(
        modelContext: ModelContext,
        bills: [Bill],
        entries: [FreedomFundEntry],
        freedomFund: Double,
        monthlyBills: Double,
        monthlyIncome: Double = 0,
        currency: String,
        now: Date = Date()
    ) {
        guard !isRunning else { return }
        guard now.timeIntervalSince1970 - lastRunAt > cooldown else { return }
        isRunning = true
        defer { isRunning = false }

        let tokens = (try? modelContext.fetch(FetchDescriptor<NoteToken>())) ?? []
        let existing = (try? modelContext.fetch(FetchDescriptor<Insight>())) ?? []
        // A key already showing (live) or dismissed must not be re-inserted.
        let blockedKeys = Set(existing.compactMap { $0.ruleKey })

        let burn = ArcCalculationService.dailyBurn(entries: entries, monthlyBills: monthlyBills, monthlyIncome: monthlyIncome)
        let runwayDays = burn > 0 ? Int(floor(freedomFund / burn)) : nil

        var candidates: [Insight] = []
        candidates += billCollision(bills: bills, tokens: tokens, currency: currency, now: now)
        candidates += burnSpike(entries: entries, freedomFund: freedomFund, now: now)
        candidates += lowRunway(runwayDays: runwayDays, now: now)
        candidates += tierMilestone(runwayDays: runwayDays)

        var inserted = false
        for candidate in candidates {
            guard let key = candidate.ruleKey, !blockedKeys.contains(key) else { continue }
            modelContext.insert(candidate)
            inserted = true
        }
        if inserted { try? modelContext.save() }
        lastRunAt = now.timeIntervalSince1970
    }

    // MARK: - Rule: bill collision

    private func billCollision(bills: [Bill], tokens: [NoteToken], currency: String, now: Date) -> [Insight] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        guard let horizon = cal.date(byAdding: .day, value: 45, to: today) else { return [] }

        struct Outflow { let date: Date; let amount: Double; let label: String }
        var outflows: [Outflow] = []

        for bill in bills where !bill.isPaidThisCycle {
            guard let due = nextDue(bill, after: today, cal: cal), due >= today, due <= horizon else { continue }
            outflows.append(Outflow(date: due, amount: bill.amount, label: bill.name.lowercased()))
        }
        for token in tokens where token.kind == .commit {
            let date = cal.startOfDay(for: token.occurredAt)
            guard date >= today, date <= horizon else { continue }
            let label = token.subject?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            outflows.append(Outflow(date: date, amount: token.amount, label: (label?.isEmpty == false ? label! : "a commitment")))
        }

        guard outflows.count >= 2 else { return [] }

        // Group by ISO week, find the nearest week holding 2+ outflows.
        let grouped = Dictionary(grouping: outflows) { weekKey(for: $0.date, cal: cal) }
        let colliding = grouped
            .filter { $0.value.count >= 2 }
            .min { ($0.value.map(\.date).min() ?? horizon) < ($1.value.map(\.date).min() ?? horizon) }

        guard let (week, items) = colliding else { return [] }

        let sorted = items.sorted { $0.date < $1.date }
        let total = sorted.reduce(0) { $0 + $1.amount }
        let symbol = NormaPalette.currencySymbol(for: currency)
        let amountStr = "\(symbol)\(formatAmount(total))"

        let headline: String
        if sorted.count == 2 {
            headline = "\(sorted[0].label) + \(sorted[1].label) hit the same week"
        } else {
            headline = "\(sorted.count) outflows hit the same week"
        }
        let whenStr = Self.monthDay.string(from: sorted.first!.date)
        let detail = "that's \(amountStr) around \(whenStr). worth setting the balance aside early."

        return [Insight(type: .nudge, headline: headline, detail: detail, ruleKey: "collision-\(week)")]
    }

    // MARK: - Rule: burn spike

    private func burnSpike(entries: [FreedomFundEntry], freedomFund: Double, now: Date) -> [Insight] {
        let cal = Calendar.current
        guard let weekAgo = cal.date(byAdding: .day, value: -7, to: now),
              let twoWeeksAgo = cal.date(byAdding: .day, value: -14, to: now) else { return [] }

        let recentBurn = entries
            .filter { $0.createdAt > weekAgo && $0.createdAt <= now && $0.delta < 0 }
            .reduce(0.0) { $0 - $1.delta }
        let priorBurn = entries
            .filter { $0.createdAt > twoWeeksAgo && $0.createdAt <= weekAgo && $0.delta < 0 }
            .reduce(0.0) { $0 - $1.delta }

        guard priorBurn > 0, recentBurn > priorBurn * 1.25 else { return [] }

        let pct = Int(((recentBurn / priorBurn) - 1) * 100)
        let recentDaily = recentBurn / 7
        let priorDaily = priorBurn / 7
        var detail = "burn is up \(pct)% versus last week."
        if recentDaily > 0, priorDaily > 0, freedomFund > 0 {
            let fewer = Int((freedomFund / priorDaily) - (freedomFund / recentDaily))
            if fewer > 0 { detail += " that's \(fewer) fewer days of runway." }
        }

        return [Insight(
            type: .anomaly,
            headline: "your burn jumped this week",
            detail: detail,
            ruleKey: "burnspike-\(weekKey(for: now, cal: cal))"
        )]
    }

    // MARK: - Rule: low runway

    private func lowRunway(runwayDays: Int?, now: Date) -> [Insight] {
        guard let days = runwayDays, days > 0, days < 30 else { return [] }
        let phrase = ArcCalculationService.convertDaysToHumanScale(days: days)
        // Monthly bucket so a persistent low-runway state can re-warn next month
        // rather than being permanently silenced by one dismissal.
        return [Insight(
            type: .nudge,
            headline: "you're down to \(phrase) of runway",
            detail: "every move counts now — re-anchor your balance so this stays accurate.",
            ruleKey: "lowrunway-\(Self.monthBucket.string(from: now))"
        )]
    }

    // MARK: - Rule: tier milestone

    private func tierMilestone(runwayDays: Int?) -> [Insight] {
        guard let days = runwayDays else { return [] }
        let tier = tierIndex(days: days)
        let previous = lastTierIndex
        lastTierIndex = tier // always record, even when we don't emit

        guard previous >= 0, tier > previous else { return [] }

        let name = ArcCalculationService.getStateName(days: days).lowercased()
        let compact = ArcCalculationService.compactRunway(days: days)
        return [Insight(
            type: .milestone,
            headline: "you crossed into \(name)",
            detail: "\(compact.value) \(compact.unit) of runway now. nice work.",
            ruleKey: "tier-\(name)"
        )]
    }

    // MARK: - Helpers

    /// Next occurrence of a bill at or after `today`. One-time bills only count
    /// if still upcoming; recurring bills step forward from their due date.
    private func nextDue(_ bill: Bill, after today: Date, cal: Calendar) -> Date? {
        if let next = bill.nextDueDate, cal.startOfDay(for: next) >= today {
            return cal.startOfDay(for: next)
        }
        let step: DateComponents
        switch bill.frequency {
        case .oneTime:
            let due = cal.startOfDay(for: bill.dueDate)
            return due >= today ? due : nil
        case .monthly: step = DateComponents(month: 1)
        case .quarterly: step = DateComponents(month: 3)
        case .yearly: step = DateComponents(year: 1)
        }
        var date = cal.startOfDay(for: bill.dueDate)
        var guardCount = 0
        while date < today, guardCount < 500 {
            guard let advanced = cal.date(byAdding: step, to: date) else { return nil }
            date = advanced
            guardCount += 1
        }
        return date
    }

    private func weekKey(for date: Date, cal: Calendar) -> String {
        let week = cal.component(.weekOfYear, from: date)
        let year = cal.component(.yearForWeekOfYear, from: date)
        return String(format: "%04d-W%02d", year, week)
    }

    private func tierIndex(days: Int) -> Int {
        switch days {
        case ..<14: return 0    // Urgency
        case 14..<45: return 1  // Cautionary
        case 45..<120: return 2 // Steady
        case 120..<270: return 3 // Calm
        default: return 4       // Abundant
        }
    }

    private func formatAmount(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return f.string(from: NSNumber(value: value)) ?? String(Int(value))
    }

    private static let monthDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let monthBucket: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f
    }()
}
