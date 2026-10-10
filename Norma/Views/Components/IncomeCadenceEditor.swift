//
//  IncomeCadenceEditor.swift
//  Norma
//
//  "How often do you get paid?" → only the one detail control that matters
//  for that answer appears: a weekday, the last payday, or days of the month.
//  Shared by onboarding and the income sheet.
//

import SwiftUI
import SwiftData

/// Editable form state for an `IncomeCadence`. Remembers every detail field
/// so switching cadence back and forth doesn't lose what was picked.
struct CadenceDraft: Equatable {
    enum Kind: CaseIterable {
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

    var kind: Kind = .biweekly
    var weekday = 6
    var lastPayday = Date()
    var day1 = 15
    var day2 = 31
    var monthlyDay = 1

    init() {}

    init(_ cadence: IncomeCadence) {
        switch cadence {
        case .weekly(let weekday):        kind = .weekly; self.weekday = weekday
        case .biweekly(let anchor):       kind = .biweekly; lastPayday = anchor
        case .semiMonthly(let a, let b):  kind = .semiMonthly; day1 = a; day2 = b
        case .monthly(let day):           kind = .monthly; monthlyDay = day
        case .irregular:                  kind = .irregular
        }
    }

    var cadence: IncomeCadence {
        switch kind {
        case .weekly:      return .weekly(weekday: weekday)
        case .biweekly:    return .biweekly(anchor: lastPayday)
        case .semiMonthly: return .semiMonthly(day1: min(day1, day2), day2: max(day1, day2))
        case .monthly:     return .monthly(day: monthlyDay)
        case .irregular:   return .irregular
        }
    }
}

struct CadencePicker: View {
    @Binding var draft: CadenceDraft
    /// Onboarding staggers the question and its detail in; sheets show both at once.
    var isRevealed = true
    var revealDelay: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 10) {
                FieldLabel("how often do you get paid?")
                FlowLayout {
                    ForEach(CadenceDraft.Kind.allCases, id: \.self) { kind in
                        ChoicePill(label: kind.label, isActive: draft.kind == kind) { draft.kind = kind }
                    }
                }
            }
            .staggeredAppear(isRevealed, index: 0, baseDelay: revealDelay)

            detail
                .animation(.easeInOut(duration: 0.2), value: draft.kind)
                .staggeredAppear(isRevealed, index: 1, baseDelay: revealDelay)
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch draft.kind {
        case .weekly:
            VStack(alignment: .leading, spacing: 10) {
                FieldLabel("which day?")
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    ForEach(WeekdayOrder.ordered(firstWeekday: Calendar.current.firstWeekday), id: \.self) { weekday in
                        WeekdayChip(weekday: weekday, isActive: draft.weekday == weekday) {
                            draft.weekday = weekday
                        }
                    }
                }
            }
        case .biweekly:
            VStack(alignment: .leading, spacing: 10) {
                FieldLabel("when was your last payday?")
                DatePicker("", selection: $draft.lastPayday, in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
                    .tint(NormaPalette.lavender)
                caption("norma counts every 2 weeks from there.")
            }
        case .semiMonthly:
            VStack(alignment: .leading, spacing: 10) {
                FieldLabel("which two days?")
                HStack(spacing: 10) {
                    dayOfMonthMenu($draft.day1)
                    Text("&").foregroundStyle(NormaPalette.inkSubtle)
                    dayOfMonthMenu($draft.day2)
                }
            }
        case .monthly:
            VStack(alignment: .leading, spacing: 10) {
                FieldLabel("which day of the month?")
                dayOfMonthMenu($draft.monthlyDay)
            }
        case .irregular:
            caption("no fixed schedule. enter about what you make in a typical month.")
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .rubik(FontFamily.Rubik.regular, size: 13, relativeTo: .footnote)
            .foregroundStyle(NormaPalette.inkSubtle)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func dayOfMonthMenu(_ selection: Binding<Int>) -> some View {
        Menu {
            ForEach(1...28, id: \.self) { day in
                Button(Self.dayLabel(day)) { selection.wrappedValue = day }
            }
            Button("last day") { selection.wrappedValue = 31 }
        } label: {
            HStack(spacing: 6) {
                Text(Self.dayLabel(selection.wrappedValue))
                    .rubik(FontFamily.Rubik.semiBold, size: 15, relativeTo: .body)
                    .foregroundStyle(NormaPalette.ink)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold, relativeTo: .caption))
                    .foregroundStyle(NormaPalette.inkSubtle)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(Color.white.opacity(0.05)))
            .overlay(Capsule().strokeBorder(NormaPalette.ink.opacity(0.15)))
        }
    }

    static func dayLabel(_ day: Int) -> String {
        day >= 29 ? "last day" : "the \(day.ordinal)"
    }
}

/// Edits the profile's income from Settings, Home, or the calendar.
struct IncomeEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var amountText = ""
    @State private var draft = CadenceDraft()
    @FocusState private var amountFocused: Bool

    private var profile: UserProfile? { profiles.first }
    private var currency: String { profile?.currency ?? "USD" }
    private var amount: Double? { Money.parse(amountText) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    HeroTitle(text: "your income", size: 44)

                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel(draft.kind == .irregular ? "about how much a month?" : "amount per paycheck, after tax")
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(Money.symbol(for: currency))
                                .rubik(FontFamily.Rubik.bold, size: 34, relativeTo: .largeTitle)
                                .foregroundStyle(NormaPalette.inkMuted)
                            TextField("0", text: $amountText)
                                .rubik(FontFamily.Rubik.bold, size: 44, relativeTo: .largeTitle)
                                .foregroundStyle(NormaPalette.ink)
                                .tint(NormaPalette.lavender)
                                .keyboardType(.decimalPad)
                                .focused($amountFocused)
                        }
                    }

                    CadencePicker(draft: $draft)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(NormaPalette.sheet.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                        .foregroundStyle(NormaPalette.ink.opacity(0.85))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save", action: save)
                        .fontWeight(.semibold)
                        .foregroundStyle(amount == nil ? NormaPalette.inkMuted : NormaPalette.lavender)
                        .disabled(amount == nil)
                }
            }
        }
        .onAppear {
            guard let profile else { return }
            amountText = Money.editableText(profile.incomeAmount)
            draft = CadenceDraft(profile.incomeCadence)
        }
    }

    private func save() {
        guard let amount, let profile else { return }
        profile.incomeAmount = amount
        profile.incomeCadence = draft.cadence
        try? modelContext.save()
        Haptics.success()
        dismiss()
    }
}

/// One weekday chip. `weekday` is the Gregorian value (Sunday = 1), not the
/// chip's position, so the stored cadence doesn't change with locale.
private struct WeekdayChip: View {
    let weekday: Int
    let isActive: Bool
    let action: () -> Void

    @ScaledMetric(relativeTo: .body) private var side: CGFloat = 38

    var body: some View {
        let symbol = Calendar.current.veryShortWeekdaySymbols[weekday - 1]
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(symbol)
                .rubik(FontFamily.Rubik.semiBold, size: 14, relativeTo: .body)
                .foregroundStyle(isActive ? NormaPalette.onAccent : NormaPalette.ink)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .frame(width: side, height: side)
                .background(Circle().fill(isActive ? NormaPalette.lavender : Color.white.opacity(0.05)))
                .overlay(Circle().strokeBorder(isActive ? NormaPalette.lavender : NormaPalette.ink.opacity(0.15)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Calendar.current.weekdaySymbols[weekday - 1])
    }
}

extension Int {
    /// "1st", "2nd", "11th", "23rd".
    var ordinal: String {
        let suffix: String
        switch (self % 100, self % 10) {
        case (11...13, _): suffix = "th"
        case (_, 1):       suffix = "st"
        case (_, 2):       suffix = "nd"
        case (_, 3):       suffix = "rd"
        default:           suffix = "th"
        }
        return "\(self)\(suffix)"
    }
}
