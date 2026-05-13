//
//  DailyRateSheet.swift
//  Norma
//
//  D13 — Daily rate setting. Presented over the forecast sheet from a button
//  in its nav bar. Sets the baseline daily spend used to fill empty days in
//  the spending pace forecast. When unset (nil), falls back to an auto-calc:
//  breathing room ÷ days left in month.
//

import SwiftUI

struct DailyRateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var billViewModel: BillViewModel

    @State private var showingEditor = false
    @State private var editorText: String = ""
    @State private var showingInfo = false

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private let accentPurple = Color(red: 0x96/255, green: 0x76/255, blue: 0xD9/255)

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroBlock
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 32)

                    explanationBlock
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)

                    coverageBlock
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)

                    mathFooter
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
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
                        showingInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(cream.opacity(0.85))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Set daily rate", isPresented: $showingEditor) {
            TextField("$0", text: $editorText)
                .keyboardType(.decimalPad)
            Button("Auto", role: .cancel) { profileViewModel.updateDailyRate(nil) }
            Button("Save") {
                if let value = Double(editorText.trimmingCharacters(in: .whitespaces)), value > 0 {
                    profileViewModel.updateDailyRate(value)
                }
            }
        } message: {
            Text("Tap Auto to revert to breathing room ÷ days left in month.")
        }
        .alert("About your daily rate", isPresented: $showingInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("Your daily rate is the baseline spend we use to fill in days you didn't write a note. By default it's your breathing room split across the days left in the month, so the forecast stays honest even when you skip a day. It only covers variable life — food, coffee, transit. Bills, commitments, and intentions are tracked separately.")
        }
    }

    // MARK: - Hero

    private var heroBlock: some View {
        Button {
            editorText = effectiveRate.map { String(format: "%.0f", $0) } ?? ""
            showingEditor = true
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                Text("YOUR DAILY RATE")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                    .tracking(0.66)
                    .foregroundStyle(mutedText)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(formatCurrency(effectiveRate ?? 0))
                        .font(.system(size: 88, weight: .heavy))
                        .tracking(-3.96)
                        .foregroundStyle(cream)
                    Text(".")
                        .font(.system(size: 88, weight: .heavy))
                        .tracking(-3.96)
                        .foregroundStyle(accentPurple)
                    Text("/ day")
                        .font(.custom(FontFamily.Rubik.medium, size: 18))
                        .foregroundStyle(mutedText)
                        .padding(.leading, 8)
                }

                if isAuto {
                    HStack(spacing: 6) {
                        Text("AUTO")
                            .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                            .tracking(0.66)
                            .foregroundStyle(accentPurple)
                        Text(autoFormulaLabel)
                            .font(.custom(FontFamily.Rubik.regular, size: 13))
                            .foregroundStyle(mutedText)
                    }
                } else {
                    HStack(spacing: 6) {
                        Text("MANUAL")
                            .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                            .tracking(0.66)
                            .foregroundStyle(cream)
                        Text("tap auto to revert")
                            .font(.custom(FontFamily.Rubik.regular, size: 13))
                            .foregroundStyle(mutedText)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Explanation

    private var explanationBlock: some View {
        Text("Defaults to your breathing room split across the days left in the month. We'll fill in empty days at this rate so the forecast stays honest. Tap to set manually.")
            .font(.custom(FontFamily.Rubik.regular, size: 15))
            .foregroundStyle(cream.opacity(0.7))
            .lineSpacing(8)
            .frame(maxWidth: 340, alignment: .leading)
    }

    // MARK: - Coverage

    private var coverageBlock: some View {
        VStack(alignment: .leading, spacing: 24) {
            coverageGroup(label: "covers", items: ["food", "coffee", "transit", "small stuff"], solid: true)
            coverageGroup(label: "doesn't cover", items: ["bills", "commitments", "intentions"], solid: false)
        }
    }

    @ViewBuilder
    private func coverageGroup(label: String, items: [String], solid: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label.uppercased())
                .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                .tracking(0.66)
                .foregroundStyle(mutedText)

            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(items, id: \.self) { item in
                    coverageChip(item, solid: solid)
                }
            }
        }
    }

    @ViewBuilder
    private func coverageChip(_ label: String, solid: Bool) -> some View {
        let dotColor: Color = solid ? cream : dimText
        let textColor: Color = solid ? cream : mutedText
        HStack(spacing: 8) {
            Circle()
                .strokeBorder(dotColor, lineWidth: solid ? 0 : 1)
                .background(Circle().fill(solid ? dotColor : Color.clear))
                .frame(width: 5, height: 5)
            Text(label)
                .font(.custom(FontFamily.Rubik.medium, size: 13))
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .overlay(
            Capsule().stroke(
                solid ? cream.opacity(0.2) : dimText,
                style: StrokeStyle(lineWidth: 1, dash: solid ? [] : [3, 3])
            )
        )
    }

    // MARK: - Math footer

    private var mathFooter: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MONTHLY EQUIVALENT")
                .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                .tracking(0.66)
                .foregroundStyle(mutedText)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("~\(formatCurrency((effectiveRate ?? 0) * 30))")
                    .font(.system(size: 24, weight: .semibold))
                    .tracking(-0.48)
                    .foregroundStyle(cream)
                Text("if no day is logged")
                    .font(.custom(FontFamily.Rubik.regular, size: 13))
                    .foregroundStyle(mutedText)
            }
        }
    }

    // MARK: - Computed

    private var isAuto: Bool {
        sessionViewModel.currentUser?.settings.dailyRate == nil
    }

    private var monthlyIncome: Double {
        sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private var totalBillsForMonth: Double {
        let cal = Calendar.current
        let monthStart = monthStartDate
        return billViewModel.bills
            .filter { cal.isDate($0.effectiveDueDate, equalTo: monthStart, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    private var breathingRoom: Double {
        max(0, monthlyIncome - totalBillsForMonth)
    }

    private var monthStartDate: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        return cal.date(from: comps) ?? Date()
    }

    /// Number of days remaining in the current month, including today.
    private var daysLeftInMonth: Int {
        let cal = Calendar.current
        let now = Date()
        let totalDays = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let currentDay = cal.component(.day, from: now)
        return max(1, totalDays - currentDay + 1)
    }

    private var autoCalculatedRate: Double {
        breathingRoom / Double(daysLeftInMonth)
    }

    private var effectiveRate: Double? {
        sessionViewModel.currentUser?.settings.dailyRate ?? autoCalculatedRate
    }

    private var autoFormulaLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        let monthName = f.string(from: Date()).lowercased()
        return "\(formatCurrency(breathingRoom)) ÷ \(daysLeftInMonth) days left in \(monthName)"
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(Int(amount))"
    }
}
