//
//  IncomeCadenceEditor.swift
//  Norma
//
//  The progressive income-capture UX (income spec P2). "How often do you get
//  paid?" → only the one detail control that matters appears. Flexible, not a
//  rigid form — weekly, every 2 weeks, twice a month, monthly, or "it varies",
//  with "it varies" a first-class option. Reused by onboarding, the calendar,
//  and the profile editor.
//
//  Pure UI: it reports (amountPerPaycheck, IncomeCadence) via onSave. The
//  hosting sheet persists to UserProfile + syncs settings.monthlyIncome.
//

import SwiftUI
import SwiftData

/// Presents the cadence editor in a dark sheet and persists on save:
/// writes the local `UserProfile` (amount + cadence) and syncs the derived
/// `monthlyEquivalent` into `settings.monthlyIncome` so Forecast/Calendar read
/// the correct monthly figure. Income stays a projection — this never touches
/// the stored balance.
struct IncomeEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @Query private var profiles: [UserProfile]

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)

    private var profile: UserProfile? { profiles.first }
    private var currency: String { sessionViewModel.currentUser?.settings.currency ?? "USD" }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                IncomeCadenceEditor(
                    currencyCode: currency,
                    initialAmount: profile?.incomeAmount,
                    initialCadence: profile?.incomeCadence,
                    onSave: persist
                )
                .padding(24)
            }
            .background(bg.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("your income")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                        .foregroundStyle(cream)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("cancel") { dismiss() }
                        .foregroundStyle(cream.opacity(0.85))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func persist(_ amount: Double, _ cadence: IncomeCadence) {
        let p: UserProfile
        if let existing = profile {
            p = existing
        } else {
            p = UserProfile(currency: currency)
            modelContext.insert(p)
        }
        p.incomeAmount = amount
        p.setIncomeCadence(cadence)
        try? modelContext.save()

        // Sync the derived monthly figure into settings so the existing
        // forecast/calendar math reads the correct number.
        if var server = sessionViewModel.currentUser {
            let monthly = p.monthlyEquivalent ?? amount
            if server.settings.monthlyIncome != monthly {
                server.settings.monthlyIncome = monthly
                Task { await sessionViewModel.updateUserProfile(server) }
            }
        }
        dismiss()
    }
}

struct IncomeCadenceEditor: View {
    let currencyCode: String
    var initialAmount: Double? = nil
    var initialCadence: IncomeCadence? = nil
    var onSave: (Double, IncomeCadence) -> Void

    // The five capture buckets — mirror IncomeCadence, minus the payload.
    private enum CadenceType: String, CaseIterable {
        case weekly, biweekly, semiMonthly, monthly, irregular
        var label: String {
            switch self {
            case .weekly:      return "weekly"
            case .biweekly:    return "every 2 weeks"
            case .semiMonthly: return "twice a month"
            case .monthly:     return "monthly"
            case .irregular:   return "it varies"
            }
        }
    }

    @State private var amountText: String = ""
    @State private var type: CadenceType = .monthly
    @State private var weekday: Int = 6            // Fri
    @State private var anchorDate: Date = Date()
    @State private var day1: Int = 15
    @State private var day2: Int = 31              // "last day"
    @State private var monthlyDay: Int = 1
    @FocusState private var amountFocused: Bool

    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private var accent: Color { NormaPalette.lavender }

    private var symbol: String { NormaPalette.currencySymbol(for: currencyCode) }

    private var parsedAmount: Double { Double(amountText.filter { $0.isNumber || $0 == "." }) ?? 0 }
    private var canSave: Bool { parsedAmount > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            amountField
            cadencePicker
            detailControl
                .animation(.easeInOut(duration: 0.2), value: type)
            saveButton
        }
        .onAppear(perform: hydrate)
    }

    // MARK: - Amount

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("amount per paycheck")
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(symbol)
                    .font(.custom(FontFamily.Rubik.bold, size: 34))
                    .foregroundStyle(mutedText)
                TextField("0", text: $amountText)
                    .font(.custom(FontFamily.Rubik.bold, size: 44))
                    .foregroundStyle(cream)
                    .tint(accent)
                    .keyboardType(.decimalPad)
                    .focused($amountFocused)
            }
        }
    }

    // MARK: - Cadence

    private var cadencePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("how often do you get paid?")
            FlowChips(items: CadenceType.allCases, selected: type) { t in
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                withAnimation(.easeInOut(duration: 0.2)) { type = t }
            } label: { $0.label }
        }
    }

    @ViewBuilder
    private var detailControl: some View {
        switch type {
        case .weekly:
            VStack(alignment: .leading, spacing: 10) {
                fieldLabel("which day?")
                HStack(spacing: 6) {
                    ForEach(1...7, id: \.self) { wd in
                        dayLetterChip(wd)
                    }
                }
            }
        case .biweekly:
            VStack(alignment: .leading, spacing: 10) {
                fieldLabel("when was your last payday?")
                DatePicker("", selection: $anchorDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(accent)
                Text("we'll count every 2 weeks from there.")
                    .font(.custom(FontFamily.Rubik.regular, size: 12))
                    .foregroundStyle(dimText)
            }
        case .semiMonthly:
            VStack(alignment: .leading, spacing: 10) {
                fieldLabel("which two days?")
                HStack(spacing: 10) {
                    dayOfMonthMenu(selection: $day1)
                    Text("&").foregroundStyle(mutedText)
                    dayOfMonthMenu(selection: $day2)
                }
            }
        case .monthly:
            VStack(alignment: .leading, spacing: 10) {
                fieldLabel("which day of the month?")
                dayOfMonthMenu(selection: $monthlyDay)
            }
        case .irregular:
            Text("no fixed schedule — we'll estimate from what lands and nudge you to check in.")
                .font(.custom(FontFamily.Rubik.regular, size: 13))
                .foregroundStyle(mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var saveButton: some View {
        Button {
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
            amountFocused = false
            onSave(parsedAmount, assembledCadence)
        } label: {
            Text("save")
                .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                .foregroundStyle(cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Capsule().fill(canSave ? accent.opacity(0.18) : accent.opacity(0.06)))
                .overlay(Capsule().stroke(accent.opacity(canSave ? 0.6 : 0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
    }

    // MARK: - Building blocks

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom(FontFamily.Rubik.semiBold, size: 11))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(mutedText)
    }

    private func dayLetterChip(_ wd: Int) -> some View {
        let letters = ["S", "M", "T", "W", "T", "F", "S"]
        let active = weekday == wd
        return Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            weekday = wd
        } label: {
            Text(letters[wd - 1])
                .font(.custom(FontFamily.Rubik.semiBold, size: 14))
                .foregroundStyle(active ? NormaPalette.canvas : cream)
                .frame(width: 36, height: 36)
                .background(Circle().fill(active ? accent : Color.white.opacity(0.05)))
                .overlay(Circle().stroke(active ? accent : cream.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func dayOfMonthMenu(selection: Binding<Int>) -> some View {
        Menu {
            ForEach(1...28, id: \.self) { d in
                Button("day \(d)") { selection.wrappedValue = d }
            }
            Button("last day") { selection.wrappedValue = 31 }
        } label: {
            HStack(spacing: 6) {
                Text(selection.wrappedValue >= 29 ? "last day" : "day \(selection.wrappedValue)")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                    .foregroundStyle(cream)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(mutedText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(Color.white.opacity(0.05)))
            .overlay(Capsule().stroke(cream.opacity(0.15), lineWidth: 1))
        }
    }

    // MARK: - Logic

    private var assembledCadence: IncomeCadence {
        switch type {
        case .weekly:      return .weekly(weekday: weekday)
        case .biweekly:    return .biweekly(anchor: anchorDate)
        case .semiMonthly: return .semiMonthly(day1: day1, day2: day2)
        case .monthly:     return .monthly(day: monthlyDay)
        case .irregular:   return .irregular
        }
    }

    private func hydrate() {
        if let amount = initialAmount, amount > 0 {
            let whole = amount.truncatingRemainder(dividingBy: 1) == 0
            amountText = String(format: whole ? "%.0f" : "%.2f", amount)
        }
        guard let cadence = initialCadence else { return }
        switch cadence {
        case .weekly(let wd):        type = .weekly;      weekday = wd
        case .biweekly(let anchor):  type = .biweekly;    anchorDate = anchor
        case .semiMonthly(let a, let b): type = .semiMonthly; day1 = a; day2 = b
        case .monthly(let d):        type = .monthly;     monthlyDay = d
        case .irregular:             type = .irregular
        }
    }
}

/// Small wrapping chip row with a solid/dashed capsule pattern (active = solid
/// accent fill). Generic so the cadence picker and future pickers can reuse it.
private struct FlowChips<Item: Hashable>: View {
    let items: [Item]
    let selected: Item
    let onTap: (Item) -> Void
    let label: (Item) -> String

    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private var accent: Color { NormaPalette.lavender }
    private var onAccent: Color { NormaPalette.canvas }

    var body: some View {
        FlexWrap(spacing: 8, lineSpacing: 8) {
            ForEach(items, id: \.self) { item in
                let active = item == selected
                Button { onTap(item) } label: {
                    Text(label(item))
                        .font(.custom(active ? FontFamily.Rubik.semiBold : FontFamily.Rubik.medium, size: 14))
                        .foregroundStyle(active ? onAccent : cream)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 9)
                        .background { if active { Capsule().fill(accent) } }
                        .overlay(
                            Capsule().stroke(
                                active ? accent : cream.opacity(0.28),
                                style: active ? StrokeStyle(lineWidth: 1) : StrokeStyle(lineWidth: 1, dash: [3, 3])
                            )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Minimal wrapping HStack (chips flow onto new lines).
private struct FlexWrap: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0; y += lineHeight + lineSpacing; lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x - bounds.minX + size.width > maxWidth && x > bounds.minX {
                x = bounds.minX; y += lineHeight + lineSpacing; lineHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
