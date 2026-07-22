//
//  NormaKnowsEditSheet.swift
//  Norma
//
//  Editable sheet opened from SettingsView's "what norma knows" section.
//  Designed to look like a NoteCanvasView page — canvas background with
//  the vertical fade gradient, 56pt heavy hero title with the lavender
//  accent period, and a single editable body composed of checklist rows.
//
//  Every row is one editable line of text with a checkbox bullet (Apple
//  Notes style). Structured onboarding fields (currency, income,
//  frequency, payday, runway) are pre-populated as full sentences so the
//  user can rewrite them in place; on save, the prefixes are parsed back
//  out to preserve the structured data the rest of the app reads.
//  Anything the user adds that doesn't match a known prefix is stored as
//  a freeform AI-learned fact.
//

import SwiftUI
import SwiftData

struct NormaKnowsEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    /// Income and currency are canonical on the server profile (the forecast,
    /// arc, and chat all read/write settings.monthlyIncome) — this sheet
    /// hydrates from there and writes back through on save so the two stores
    /// can't drift. Inherited from SettingsView's environment.
    @EnvironmentObject private var sessionViewModel: SessionViewModel

    let profile: UserProfile?

    /// Each row in the body. `id` is stable across edits; `text` is the full
    /// editable line. Whether a row maps to a structured field is decided on
    /// save by matching against `Self.prefixes`.
    private struct Row: Identifiable, Equatable {
        let id: UUID
        var text: String
    }

    @State private var rows: [Row] = []
    @State private var showInfoPopover = false

    private static let bodyFont: Font = .custom(FontFamily.Nunito.regular, size: 18)

    /// Ordered prefixes for the five structured fields. Parsing on save walks
    /// every row, tries each prefix in turn, and writes to the matching
    /// `UserProfile` field. The order also drives initial hydration so the
    /// rows always render in the same sequence on first open.
    private static let prefixes: [(label: String, kind: FieldKind)] = [
        ("you think in ",                kind: .currency),
        ("you bring in about ",          kind: .income),
        ("you get paid ",                kind: .frequency),
        ("usually on day ",              kind: .payday),
        ("you won't let runway dip below ", kind: .runway),
    ]

    private enum FieldKind { case currency, income, frequency, payday, runway }

    var body: some View {
        NavigationStack {
            ZStack {
                NormaPalette.canvas.ignoresSafeArea()

                // Vertical fade — same recipe NoteCanvasView uses to keep the
                // top of the page airy and hand the lower portion back to
                // the canvas so the prose doesn't compete with itself.
                LinearGradient(
                    stops: [
                        .init(color: NormaPalette.canvas.opacity(0),    location: 0.00),
                        .init(color: NormaPalette.canvas.opacity(0),    location: 0.18),
                        .init(color: NormaPalette.canvas.opacity(0.55), location: 0.40),
                        .init(color: NormaPalette.canvas.opacity(0.85), location: 0.62),
                        .init(color: NormaPalette.canvas,               location: 0.88),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        heroTitle

                        completenessChips

                        VStack(alignment: .leading, spacing: 2) {
                            if rows.isEmpty {
                                emptyState
                            }
                            ForEach($rows) { $row in
                                rowView(row: $row)
                            }
                            addRowButton
                        }

                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    infoButton
                }
                .sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .topBarTrailing) {
                    saveButton
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: hydrate)
    }

    // MARK: - Hero

    private var heroTitle: some View {
        (
            Text("what norma knows").foregroundStyle(.white)
            + Text(".").foregroundStyle(NormaPalette.lavender)
        )
        .font(.system(size: 56, weight: .heavy))
        .lineLimit(1...3)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Completeness chips
    //
    // A glanceable summary of which structured fields norma has captured.
    // Filled fields render as solid capsules with the value baked in; empty
    // fields render as dashed capsules with just the label, signalling
    // "still missing — tap the field below to add it".

    private var completenessChips: some View {
        WrappingFlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
            completenessChip(label: "currency", value: filledCurrency)
            completenessChip(label: "income",   value: filledIncome)
            completenessChip(label: "pay frequency", value: filledFrequency)
            completenessChip(label: "payday",   value: filledPayday)
            completenessChip(label: "runway floor", value: filledRunway)
        }
    }

    /// `value` non-nil → solid (filled) capsule with "label · value".
    /// `value` nil     → dashed (empty) capsule with just the label.
    @ViewBuilder
    private func completenessChip(label: String, value: String?) -> some View {
        let isFilled = value != nil
        HStack(spacing: 8) {
            Text(label)
                .font(.custom(FontFamily.Rubik.medium, size: 14))
                .foregroundStyle(isFilled ? Color.white.opacity(0.6) : Color.white.opacity(0.38))
            if let value {
                Text("·")
                    .font(.custom(FontFamily.Rubik.medium, size: 14))
                    .foregroundStyle(.white.opacity(0.3))
                Text(value)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            if isFilled {
                Capsule().fill(Color.white.opacity(0.04))
            }
        }
        .overlay {
            Capsule().stroke(
                isFilled ? Color.white.opacity(0.32) : Color.white.opacity(0.22),
                style: isFilled
                    ? StrokeStyle(lineWidth: 1)
                    : StrokeStyle(lineWidth: 1, dash: [4, 3])
            )
        }
        .fixedSize()
    }

    // MARK: - Filled value helpers (drive the chips)

    private var filledCurrency: String? {
        // Only treat as "filled" when the user has actually been seeded a
        // profile — a brand-new account defaults to USD but we'd rather show
        // the dashed chip there than imply norma already knows.
        guard profile != nil else { return nil }
        return (profile?.currency).flatMap { $0.isEmpty ? nil : $0 }
    }

    private var filledIncome: String? {
        guard let amount = profile?.incomeAmount, amount > 0 else { return nil }
        return String(format: "%g", amount)
    }

    private var filledFrequency: String? {
        guard let freq = profile?.incomeFrequency, !freq.isEmpty else { return nil }
        return freq
    }

    private var filledPayday: String? {
        profile?.payday.map { "day \($0)" }
    }

    private var filledRunway: String? {
        guard let floor = profile?.runwayFloor else { return nil }
        let unit = floor == 1.0 ? "mo" : "mos"
        return "\(String(format: "%g", floor)) \(unit)"
    }

    // MARK: - Rows

    @ViewBuilder
    private func rowView(row: Binding<Row>) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                withAnimation(.easeInOut(duration: 0.2)) {
                    rows.removeAll { $0.id == row.wrappedValue.id }
                }
            } label: {
                Image(systemName: row.wrappedValue.text.trimmingCharacters(in: .whitespaces).isEmpty ? "circle" : "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(row.wrappedValue.text.trimmingCharacters(in: .whitespaces).isEmpty
                                     ? Color.white.opacity(0.25)
                                     : NormaPalette.lavender)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)

            TextField("…", text: row.text, axis: .vertical)
                .font(Self.bodyFont)
                .foregroundStyle(.white.opacity(0.92))
                .tint(NormaPalette.lavender)
                .textFieldStyle(.plain)
                .lineLimit(1...)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    private var emptyState: some View {
        Text("norma hasn't learned anything about you yet. tell her in chat, or jot it down below.")
            .font(Self.bodyFont.italic())
            .foregroundStyle(.white.opacity(0.45))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 12)
    }

    private var addRowButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) {
                rows.append(Row(id: UUID(), text: ""))
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .frame(width: 22, height: 22)
                Text("add something norma should know")
                    .font(Self.bodyFont.italic())
                    .foregroundStyle(.white.opacity(0.35))
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar

    private var infoButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            showInfoPopover = true
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 18))
                .foregroundStyle(NormaPalette.ink.opacity(0.6))
        }
        .popover(isPresented: $showInfoPopover, arrowEdge: .top) {
            NormaKnowsInfoPopover()
                .presentationCompactAdaptation(.popover)
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                Text("save")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(NormaPalette.ink.opacity(0.92))
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .glassEffect(in: Capsule())
            .overlay(
                Capsule().stroke(NormaPalette.ink.opacity(0.25), lineWidth: 1)
            )
            .fixedSize()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Hydration

    private func hydrate() {
        guard rows.isEmpty else { return }

        // Only seed rows for fields that actually have a value. Half-written
        // sentences ("you think in ___", "you bring in about ___") read as
        // broken prose; an empty document is clearer than that.
        var seeded: [Row] = []
        for (prefix, kind) in Self.prefixes {
            if let formatted = formattedValue(for: kind) {
                seeded.append(Row(id: UUID(), text: prefix + formatted))
            }
        }
        if let extras = profile?.facts, !extras.isEmpty {
            seeded.append(contentsOf: extras.map { Row(id: $0.id, text: $0.fact) })
        }
        rows = seeded
    }

    /// Returns the rendered value for a structured field, or `nil` when the
    /// field has no real data — used by hydrate to decide whether to seed a
    /// row at all.
    private func formattedValue(for kind: FieldKind) -> String? {
        switch kind {
        case .currency:
            // Currency always has a value (defaults to USD), but only seed a
            // row when the user has been through onboarding (i.e. the profile
            // exists). For brand-new accounts we want a clean canvas.
            guard profile != nil || sessionViewModel.currentUser != nil else { return nil }
            return sessionViewModel.currentUser?.settings.currency ?? profile?.currency ?? "USD"
        case .income:
            let serverAmount = sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
            let amount = serverAmount > 0 ? serverAmount : (profile?.incomeAmount ?? 0)
            guard amount > 0 else { return nil }
            return String(format: "%g", amount)
        case .frequency:
            guard let freq = profile?.incomeFrequency, !freq.isEmpty else { return nil }
            return freq
        case .payday:
            guard let day = profile?.payday else { return nil }
            return String(day)
        case .runway:
            guard let floor = profile?.runwayFloor else { return nil }
            return "\(String(format: "%g", floor)) months"
        }
    }

    // MARK: - Save

    private func save() {
        let target: UserProfile
        if let existing = profile {
            target = existing
        } else {
            let fresh = UserProfile(currency: "USD")
            modelContext.insert(fresh)
            target = fresh
        }

        // Reset structured fields so cleared rows actually clear the value.
        var currency: String? = nil
        var income: Double? = nil
        var frequency: String? = nil
        var payday: Int? = nil
        var runway: Double? = nil
        var freeform: [FinancialFact] = []

        for row in rows {
            let trimmed = row.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            if let kind = Self.detectFieldKind(in: trimmed) {
                Self.apply(
                    row: trimmed,
                    kind: kind,
                    currency: &currency,
                    income: &income,
                    frequency: &frequency,
                    payday: &payday,
                    runway: &runway
                )
            } else {
                freeform.append(FinancialFact(id: row.id, fact: trimmed, source: "what norma knows"))
            }
        }

        target.currency = currency ?? "USD"
        target.incomeAmount = income
        target.incomeFrequency = frequency
        target.payday = payday
        target.runwayFloor = runway
        target.facts = freeform
        target.updatedAt = Date()

        try? modelContext.save()

        // Write income + currency through to the server profile. Without
        // this, the forecast/arc keep reading the old settings values and
        // the two stores drift the first time income changes on either side.
        if var serverProfile = sessionViewModel.currentUser {
            let newIncome = income ?? 0
            let newCurrency = currency ?? "USD"
            if serverProfile.settings.monthlyIncome != newIncome
                || serverProfile.settings.currency != newCurrency {
                serverProfile.settings.monthlyIncome = newIncome
                serverProfile.settings.currency = newCurrency
                Task { await sessionViewModel.updateUserProfile(serverProfile) }
            }
        }

        dismiss()
    }

    // MARK: - Flexible row parsing
    //
    // We don't rely on the seeded prefixes any more — the mini chat (or the
    // user) is free to rewrite a row in their own voice and we still classify
    // it by looking for content signals: keyword stems, numbers, currency
    // codes, and known frequency words.

    private static let frequencyVocab: [String] = [
        "biweekly", "bi-weekly", "fortnightly", "every two weeks", "every other week",
        "weekly", "every week",
        "monthly", "every month",
        "semi-monthly", "semimonthly", "twice a month",
        "quarterly", "every quarter",
        "annually", "yearly", "every year"
    ]

    private static let runwayKeywords: [String] = ["runway", "buffer", "cushion", "safety net"]
    private static let incomeKeywords: [String] = ["earn", "make", "bring in", "income", "salary", "take home", "pull in"]
    private static let paydayKeywords: [String] = ["payday", "paid on", "get paid on", "on day", "of the month", "of each month"]
    private static let currencyKeywords: [String] = ["think in", "use", "live in", "spend in", "currency", "prefer"]

    /// Inspect a row and decide which structured field (if any) it represents.
    /// Ordering matters — the more specific signals (runway, payday) are
    /// tested before the broader ones (income, currency, frequency).
    private static func detectFieldKind(in text: String) -> FieldKind? {
        let lower = text.lowercased()

        // Runway: must mention runway/buffer + a number + month
        if runwayKeywords.contains(where: { lower.contains($0) }),
           hasNumber(lower), lower.contains("month") {
            return .runway
        }

        // Payday: number-of-the-month phrasing
        if paydayKeywords.contains(where: { lower.contains($0) }),
           extractOrdinalDay(from: lower) != nil {
            return .payday
        }

        // Income: explicit income verb + numeric amount
        if incomeKeywords.contains(where: { lower.contains($0) }), hasNumber(lower) {
            return .income
        }

        // Frequency: matches one of the cadence vocab words
        if frequencyVocab.contains(where: { lower.contains($0) }) {
            return .frequency
        }

        // Currency: a currency-talk keyword + a 3-letter code or symbol
        if currencyKeywords.contains(where: { lower.contains($0) }),
           extractCurrencyCode(from: text) != nil {
            return .currency
        }

        return nil
    }

    private static func apply(
        row: String,
        kind: FieldKind,
        currency: inout String?,
        income: inout Double?,
        frequency: inout String?,
        payday: inout Int?,
        runway: inout Double?
    ) {
        let lower = row.lowercased()
        switch kind {
        case .currency:
            currency = extractCurrencyCode(from: row)
        case .income:
            income = extractFirstNumber(from: lower)
        case .frequency:
            frequency = frequencyVocab.first(where: { lower.contains($0) })
        case .payday:
            payday = extractOrdinalDay(from: lower)
        case .runway:
            runway = extractFirstNumber(from: lower)
        }
    }

    // MARK: - Tiny extractors

    private static func hasNumber(_ text: String) -> Bool {
        text.contains(where: { $0.isNumber })
    }

    /// First numeric run (handles "$5,000", "5000", "5.5", "3 months").
    private static func extractFirstNumber(from text: String) -> Double? {
        var digits = ""
        var sawDigit = false
        for ch in text {
            if ch.isNumber {
                digits.append(ch); sawDigit = true
            } else if (ch == "." || ch == ",") && sawDigit {
                if ch == "." { digits.append(".") }  // drop commas
            } else if sawDigit {
                break
            }
        }
        return Double(digits)
    }

    /// Pulls a day-of-month integer from phrasing like "day 15", "15th",
    /// "the 1st of the month". Bounded to 1...31.
    private static func extractOrdinalDay(from text: String) -> Int? {
        guard let d = extractFirstNumber(from: text) else { return nil }
        let n = Int(d)
        return (1...31).contains(n) ? n : nil
    }

    /// Pull the first plausible currency token: either an ISO 3-letter code
    /// or a recognized symbol. Backed by `CurrencyData`, which already
    /// catalogs every currency the app supports (codes + symbols + names).
    private static let symbolToCode: [String: String] = {
        // Build a symbol→code map from CurrencyData. When multiple currencies
        // share a symbol (e.g. several use "$"), USD/EUR/etc. win because
        // they're inserted last in CurrencyData and overwrite — but for
        // ambiguous cases the user can always disambiguate with a 3-letter
        // code.
        var map: [String: String] = [:]
        // Preferred codes for ambiguous symbols.
        let preferences: [String: String] = [
            "$": "USD", "¥": "JPY", "₨": "INR", "kr": "SEK"
        ]
        for currency in CurrencyData.currencies.values {
            if map[currency.symbol] == nil {
                map[currency.symbol] = currency.code
            }
        }
        for (symbol, code) in preferences {
            map[symbol] = code
        }
        return map
    }()

    private static func extractCurrencyCode(from text: String) -> String? {
        // Try 3-letter words against the full ISO catalog.
        let tokens = text
            .split(whereSeparator: { !$0.isLetter })
            .map { String($0).uppercased() }
        if let hit = tokens.first(where: { $0.count == 3 && CurrencyData.currencies[$0] != nil }) {
            return hit
        }
        // Fall back to symbol matching.
        for (symbol, code) in symbolToCode where text.contains(symbol) {
            return code
        }
        return nil
    }
}

// MARK: - Info popover

struct NormaKnowsInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22))
                    .foregroundColor(NormaPalette.lavender)
                Text("what norma knows")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                    .foregroundColor(.primary)
            }

            Text("a living note of the facts norma uses when she helps you think about money. add, edit, or delete anything in here — it shapes every reply you get from her.")
                .font(.normaInput(14))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                glossaryRow(label: "currency", body: "the currency you think and budget in.")
                glossaryRow(label: "income",   body: "how much you typically bring home per pay cycle.")
                glossaryRow(label: "pay frequency", body: "how often that income arrives — weekly, biweekly, monthly, etc.")
                glossaryRow(label: "payday",   body: "the day of the month your deposit usually lands.")
                glossaryRow(label: "runway floor", body: "the minimum months of bills you want your balance to cover before norma starts nudging.")
            }

            Divider()

            Text("anything else you add becomes a freeform fact — norma will recall it in chats and use it to tailor her replies.")
                .font(.normaInput(13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 320)
        .background(Color("NormaBackground"))
    }

    @ViewBuilder
    private func glossaryRow(label: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.custom(FontFamily.Rubik.semiBold, size: 13))
                .foregroundColor(.primary)
            Text(body)
                .font(.normaInput(13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
