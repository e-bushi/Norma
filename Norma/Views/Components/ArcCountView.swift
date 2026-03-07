//
//  ArcCountView.swift
//  Norma
//
//  Created by Claude on 12/18/25.
//

import SwiftUI
import SceneKit

struct ArcCountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    let arcCount: Int
    let freedomFund: Double
    let totalMonthlyBills: Double
    let currency: String

    // Sheet state
    @State private var showFreedomFundEdit = false
    @State private var showInfoPopover = false

    // Staggered animation states
    @State private var waveAnimating = false
    @State private var heroVisible = false
    @State private var arcCountVisible = false
    @State private var statsVisible = false
    @State private var monthsHeaderVisible = false
    @State private var coinVisibility: [Bool] = Array(repeating: false, count: 24)

    // Haptic generator
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    // Progress to next arc (0.0 to 1.0)
    private var progressToNextArc: CGFloat {
        guard totalMonthlyBills > 0 else { return 0 }
        let currentArcProgress = freedomFund.truncatingRemainder(dividingBy: totalMonthlyBills)
        return CGFloat(currentArcProgress / totalMonthlyBills)
    }

    // Amount needed for next arc
    private var amountToNextArc: Double {
        guard totalMonthlyBills > 0 else { return 0 }
        let nextArcTarget = Double(arcCount + 1) * totalMonthlyBills
        return max(0, nextArcTarget - freedomFund)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    private var waveWords: [(word: String, color: Color)] {
        var words: [(String, Color)] = []
        words.append(("You", .primary))
        words.append(("can", .primary))
        words.append(("pay", .primary))
        words.append(("\(arcCount)", Color("NormaPastelTeal")))
        words.append((arcCount == 1 ? "month" : "months", Color("NormaPastelTeal")))
        words.append(("of", .primary))
        words.append(("bills.", .primary))
        return words
    }

    // Get months starting from next month
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
            let shortName = formatter.string(from: futureDate)

            let year = calendar.component(.year, from: futureDate)
            let isCovered = offset <= arcCount

            return (name: fullName, shortName: shortName, isCovered: isCovered, year: year)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Wave text headline
                    ColoredWaveTextView(
                        words: waveWords,
                        font: .normaHeadline(64),
                        isAnimating: waveAnimating,
                        alignment: .leading
                    )
                    .padding(.top, 16)
                    .onAppear { waveAnimating = true }

                    // Freedom Fund card with coin + arc count
                    VStack(alignment: .leading, spacing: 12) {
                        // Header row: label + edit
                        HStack {
                            Text("Freedom Fund")
                                .font(.normaInput(13))
                                .foregroundColor(.secondary.opacity(0.6))

                            Spacer()

                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                showFreedomFundEdit = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary.opacity(0.4))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        // Hero amount
                        Text(formatCurrency(freedomFund))
                            .font(.normaHeadline(46))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)

                        // Dashed divider
                        DashedDividerShape()
                            .stroke(Color.gray.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .frame(height: 1)
                            .padding(.vertical, 2)

                        // Coin + arc count + bills info
                        HStack(spacing: 12) {
                            // Spinning coin with glow
                            ZStack {
                                Circle()
                                    .fill(CoinTierService.currentCoinTier(for: arcCount).glowColor.opacity(0.10))
                                    .frame(width: 48, height: 48)
                                    .blur(radius: 10)

                                HeroCoin3DView(fileName: CoinTierService.currentCoinFileName(for: arcCount))
                                    .id(CoinTierService.currentCoinFileName(for: arcCount))
                                    .frame(width: 36, height: 36)
                            }
                            .scaleEffect(heroVisible ? 1 : 0)
                            .opacity(heroVisible ? 1 : 0)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text("\(arcCount)")
                                        .font(.normaFinancial(16))
                                        .foregroundColor(.primary)
                                    Text(arcCount == 1 ? "arc" : "arcs")
                                        .font(.normaInput(13))
                                        .foregroundColor(.secondary.opacity(0.5))
                                }

                                Text("\(formatCurrency(totalMonthlyBills))/mo in bills")
                                    .font(.normaInput(12))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            .opacity(arcCountVisible ? 1 : 0)

                            Spacer()

                            HStack(spacing: 5) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color("NormaPastelTeal"))
                                Text("\(formatCurrency(amountToNextArc)) to next")
                                    .font(.normaInput(12))
                                    .foregroundColor(Color("NormaPastelTeal"))
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.clear)
                                .glassEffect(in: RoundedRectangle(cornerRadius: 20))

                            Canvas { context, size in
                                let origin = CGPoint(x: size.width, y: size.height)
                                let ringCount = 6
                                let maxRadius: CGFloat = 180
                                let ringSpacing = maxRadius / CGFloat(ringCount)
                                let tierColor = CoinTierService.currentCoinTier(for: arcCount).glowColor

                                for i in 1...ringCount {
                                    let radius = CGFloat(i) * ringSpacing
                                    let opacity = 0.12 * (1.0 - CGFloat(i) / CGFloat(ringCount))
                                    let rect = CGRect(
                                        x: origin.x - radius,
                                        y: origin.y - radius,
                                        width: radius * 2,
                                        height: radius * 2
                                    )
                                    context.stroke(
                                        Path(ellipseIn: rect),
                                        with: .color(tierColor.opacity(opacity)),
                                        lineWidth: 1
                                    )
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .allowsHitTesting(false)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.12), lineWidth: 0.5)
                    )
                    .opacity(statsVisible ? 1 : 0)
                    .offset(y: statsVisible ? 0 : 15)

                    // Months covered — timeline calendar
                    ArcTimelineCalendarView(
                        upcomingMonths: upcomingMonths,
                        coinVisibility: coinVisibility,
                        monthsHeaderVisible: monthsHeaderVisible,
                        totalMonthlyBills: totalMonthlyBills,
                        currency: currency
                    )

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            .background(Color("NormaBackground"))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showInfoPopover = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .popover(isPresented: $showInfoPopover, arrowEdge: .top) {
                        ArcInfoPopover()
                            .presentationCompactAdaptation(.popover)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("My Arcs")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 20))
                        .foregroundColor(.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showFreedomFundEdit = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showFreedomFundEdit) {
            FreedomFundEditSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            // Prepare haptic generator
            impactGenerator.prepare()

            // Hero coin bounce in with dramatic entrance
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.15)) {
                heroVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                impactGenerator.impactOccurred(intensity: 1.0)
            }

            // Arc count text fade in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.5)) {
                arcCountVisible = true
            }

            // Stats grid fade in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.7)) {
                statsVisible = true
            }

            // Months header
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.9)) {
                monthsHeaderVisible = true
            }

            // Staggered coin grid animations with haptics
            for index in 0..<24 {
                let delay = 1.1 + (Double(index) * 0.08)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    coinVisibility[index] = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.05) {
                    impactGenerator.impactOccurred(intensity: 0.3)
                }
            }
        }
    }
}

// MARK: - Freedom Fund Edit Sheet
struct FreedomFundEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var billViewModel: BillViewModel

    @State private var freedomFundText: String = ""
    @State private var isSaving = false
    @FocusState private var isTextFieldFocused: Bool

    private var currentFreedomFund: Double {
        sessionViewModel.currentUser?.settings.freedomFund ?? 0
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
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color("NormaPastelTeal"))

                    Text("Update Freedom Fund")
                        .font(.custom(FontFamily.Rubik.medium, size: 18))
                        .foregroundColor(.primary)

                    Text("Enter the total amount you have saved for bills")
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

                    TextField("0", text: $freedomFundText)
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
                    Text("Freedom Fund")
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
            if currentFreedomFund > 0 {
                freedomFundText = formatNumberWithoutCurrency(currentFreedomFund)
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

        let newFreedomFund = parseNumber(freedomFundText)

        // Create updated settings
        var updatedSettings = currentUser.settings
        updatedSettings.freedomFund = newFreedomFund

        // Create updated profile - update BOTH settings and direct column
        var updatedProfile = currentUser
        updatedProfile.settings = updatedSettings
        updatedProfile.freedomFund = newFreedomFund  // Also update direct column for Edge Function

        Task {
            // Use arc check version to trigger rewards when arcs increase
            await sessionViewModel.updateUserProfileWithArcCheck(updatedProfile, bills: billViewModel.bills)

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
            // Header
            HStack(spacing: 10) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color("NormaPastelTeal"))

                Text("What are Arcs?")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                    .foregroundColor(.primary)
            }

            // Explanation
            VStack(alignment: .leading, spacing: 12) {
                Text("An arc represents one month of bills covered by your Freedom Fund.")
                    .font(.normaInput(14))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("For example, if your monthly bills are $1,500 and you have $4,500 saved, you have 3 arcs — meaning you're covered for 3 months.")
                    .font(.normaInput(14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            // Coin reward section
            HStack(spacing: 10) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color("NormaPastelPurple"))

                Text("Coin Rewards")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundColor(.primary)
            }

            Text("Each time you earn a new arc, you unlock a new coin. As you save more, your coins evolve — celebrating your progress toward financial freedom.")
                .font(.normaInput(14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            // Remember section
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color("NormaPastelBeige"))

                Text("Remember")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundColor(.primary)
            }

            Text("You'll lose 1 arc each month as bills come due. Keep adding to your Freedom Fund to stay protected.")
                .font(.normaInput(14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 300)
        .background(Color("NormaBackground"))
    }
}

// MARK: - Arc Timeline Calendar

struct ArcTimelineCalendarView: View {
    let upcomingMonths: [(name: String, shortName: String, isCovered: Bool, year: Int)]
    let coinVisibility: [Bool]
    let monthsHeaderVisible: Bool
    let totalMonthlyBills: Double
    let currency: String

    private func formatCumulativeAmount(for monthNumber: Int) -> String {
        let cumulative = totalMonthlyBills * Double(monthNumber)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: cumulative)) ?? "$\(Int(cumulative))"
    }

    // Group months by year, preserving index
    private var yearSections: [(year: Int, months: [(index: Int, month: (name: String, shortName: String, isCovered: Bool, year: Int))])] {
        var sections: [(Int, [(Int, (String, String, Bool, Int))])] = []
        var currentYear: Int? = nil
        var currentGroup: [(Int, (String, String, Bool, Int))] = []

        for i in 0..<upcomingMonths.count {
            let month = upcomingMonths[i]
            if month.year != currentYear {
                if let cy = currentYear, !currentGroup.isEmpty {
                    sections.append((cy, currentGroup))
                }
                currentYear = month.year
                currentGroup = [(i, month)]
            } else {
                currentGroup.append((i, month))
            }
        }
        if let cy = currentYear, !currentGroup.isEmpty {
            sections.append((cy, currentGroup))
        }
        return sections
    }

    @State private var deckIndices: [Int: Int] = [:]

    private func isYearFullyCovered(_ section: (year: Int, months: [(index: Int, month: (name: String, shortName: String, isCovered: Bool, year: Int))])) -> Bool {
        section.months.allSatisfy { $0.month.isCovered }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(yearSections.enumerated()), id: \.element.year) { sectionIndex, section in
                let isLastSection = sectionIndex == yearSections.count - 1
                let fullyCovers = isYearFullyCovered(section)

                HStack(alignment: .top, spacing: 0) {
                    // Timeline column — one dot per year
                    VStack(spacing: 0) {
                        Circle()
                            .fill(yearDotColor(for: section))
                            .frame(width: 10, height: 10)
                            .padding(.top, 4)

                        if !isLastSection {
                            Rectangle()
                                .fill(Color.gray.opacity(0.12))
                                .frame(width: 1.5)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 20)

                    // Year label + content
                    VStack(alignment: .leading, spacing: 12) {
                        // Year header
                        Text(String(section.year))
                            .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                            .foregroundColor(.secondary.opacity(0.5))
                            .opacity(monthsHeaderVisible ? 1 : 0)

                        if fullyCovers {
                            // Entire year covered — card deck
                            ArcYearDeckView(
                                months: section.months,
                                currentIndex: Binding(
                                    get: { deckIndices[section.year] ?? 0 },
                                    set: { deckIndices[section.year] = $0 }
                                ),
                                coinVisibility: coinVisibility,
                                formatAmount: formatCumulativeAmount
                            )
                        } else {
                            // Individual month cards
                            ForEach(section.months, id: \.index) { item in
                                let globalIndex = item.index
                                let month = item.month
                                let isVisible = globalIndex < coinVisibility.count && coinVisibility[globalIndex]

                                ArcMonthCard(
                                    monthName: month.name,
                                    isCovered: month.isCovered,
                                    monthNumber: globalIndex + 1,
                                    isVisible: isVisible,
                                    billAmount: formatCumulativeAmount(for: globalIndex + 1)
                                )
                            }
                        }
                    }
                    .padding(.leading, 14)
                }
                .padding(.bottom, isLastSection ? 0 : 24)
            }
        }
    }

    private func yearDotColor(for section: (year: Int, months: [(index: Int, month: (name: String, shortName: String, isCovered: Bool, year: Int))])) -> Color {
        if let firstCovered = section.months.first(where: { $0.month.isCovered }) {
            return ArcMonthCard.stateColorForMonth(firstCovered.index + 1)
        }
        return Color.gray.opacity(0.25)
    }
}

// MARK: - Arc Year Deck (Swipeable Stack for fully covered year)

struct ArcYearDeckView: View {
    let months: [(index: Int, month: (name: String, shortName: String, isCovered: Bool, year: Int))]
    @Binding var currentIndex: Int
    let coinVisibility: [Bool]
    let formatAmount: (Int) -> String

    @State private var dragOffset: CGFloat = 0

    private let peekOffset: CGFloat = 8
    private let peekScale: CGFloat = 0.04

    private var visibleCards: [(index: Int, month: (name: String, shortName: String, isCovered: Bool, year: Int))] {
        let start = currentIndex
        let end = min(currentIndex + 3, months.count)
        guard start < end else { return [] }
        return Array(months[start..<end])
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(Array(visibleCards.enumerated().reversed()), id: \.element.index) { stackIndex, item in
                    let isTop = stackIndex == 0
                    let globalIndex = item.index
                    let isVisible = globalIndex < coinVisibility.count && coinVisibility[globalIndex]

                    ArcMonthCard(
                        monthName: item.month.name,
                        isCovered: item.month.isCovered,
                        monthNumber: globalIndex + 1,
                        isVisible: isVisible,
                        billAmount: formatAmount(globalIndex + 1)
                    )
                    .scaleEffect(1 - CGFloat(stackIndex) * peekScale)
                    .offset(y: -CGFloat(stackIndex) * peekOffset)
                    .offset(x: isTop ? dragOffset : 0)
                    .rotationEffect(isTop ? .degrees(Double(dragOffset) / 20) : .zero)
                    .opacity(stackIndex == 2 ? 0.5 : 1)
                    .zIndex(Double(3 - stackIndex))
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentIndex)
                }
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 15)
                    .onChanged { value in
                        if abs(value.translation.width) > abs(value.translation.height) {
                            dragOffset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            if value.translation.width < -threshold && currentIndex < months.count - 1 {
                                currentIndex += 1
                            } else if value.translation.width > threshold && currentIndex > 0 {
                                currentIndex -= 1
                            }
                            dragOffset = 0
                        }
                    }
            )

            // Month counter
            if months.count > 1 {
                Text("\(currentIndex + 1) of \(months.count)")
                    .font(.normaInput(12))
                    .foregroundColor(.secondary.opacity(0.4))
                    .padding(.top, 10)
            }
        }
    }
}

// MARK: - Arc Month Card

struct ArcMonthCard: View {
    let monthName: String
    let isCovered: Bool
    let monthNumber: Int
    var isVisible: Bool = true
    var billAmount: String = ""

    private var coinTier: CoinTier {
        CoinTierService.currentCoinTier(for: monthNumber)
    }

    private var coinFileName: String {
        coinTier.fileName
    }

    private var stateDescription: String {
        if isCovered {
            switch monthNumber {
            case 1: return "urgency"
            case 2: return "caution"
            case 3: return "stable"
            case 4: return "calm"
            case 5: return "steady"
            case 6: return "secure"
            case 7: return "balanced"
            case 8: return "thriving"
            case 9: return "flourishing"
            case 10: return "abundant"
            case 11: return "liberated"
            case 12: return "free"
            case 13: return "fortified"
            case 14: return "resilient"
            case 15: return "unshakable"
            case 16: return "sovereign"
            case 17: return "powerful"
            case 18: return "legendary"
            case 19: return "transcendent"
            case 20: return "infinite"
            case 21: return "mythic"
            case 22: return "eternal"
            case 23: return "ascended"
            case 24: return "untouchable"
            default: return "covered"
            }
        } else {
            return ""
        }
    }

    static func stateColorForMonth(_ monthNumber: Int) -> Color {
        switch monthNumber {
        case 1: return Color("NormaPastelCoral")
        case 2: return Color(red: 1.0, green: 0.7, blue: 0.3)
        case 3: return Color(red: 0.9, green: 0.75, blue: 0.4)
        case 4: return Color(red: 0.8, green: 0.8, blue: 0.45)
        case 5: return Color(red: 0.65, green: 0.8, blue: 0.5)
        case 6: return Color("NormaPastelTeal")
        case 7: return Color(red: 0.4, green: 0.75, blue: 0.8)
        case 8: return Color(red: 0.4, green: 0.7, blue: 0.9)
        case 9: return Color(red: 0.5, green: 0.6, blue: 0.9)
        case 10: return Color(red: 0.6, green: 0.5, blue: 0.85)
        case 11: return Color(red: 0.65, green: 0.4, blue: 0.8)
        case 12: return Color(red: 0.7, green: 0.35, blue: 0.75)
        case 13: return Color(red: 0.75, green: 0.3, blue: 0.7)
        case 14: return Color(red: 0.6, green: 0.3, blue: 0.75)
        case 15: return Color(red: 0.45, green: 0.35, blue: 0.8)
        case 16: return Color(red: 0.35, green: 0.4, blue: 0.85)
        case 17: return Color(red: 0.3, green: 0.5, blue: 0.9)
        case 18: return Color(red: 0.25, green: 0.6, blue: 0.85)
        case 19: return Color(red: 0.2, green: 0.65, blue: 0.75)
        case 20: return Color(red: 0.2, green: 0.7, blue: 0.65)
        case 21: return Color(red: 0.25, green: 0.75, blue: 0.55)
        case 22: return Color(red: 0.3, green: 0.8, blue: 0.45)
        case 23: return Color(red: 0.4, green: 0.85, blue: 0.4)
        case 24: return Color(red: 0.5, green: 0.9, blue: 0.35)
        default: return Color("NormaPastelTeal")
        }
    }

    private var stateColor: Color {
        isCovered ? Self.stateColorForMonth(monthNumber) : Color.secondary
    }

    private var coinAnimation: Animation {
        .spring(response: 0.7, dampingFraction: 0.6)
    }

    var body: some View {
        HStack(spacing: 14) {
            // 3D Coin
            ZStack {
                if isCovered {
                    Circle()
                        .fill(coinTier.glowColor.opacity(0.10))
                        .frame(width: 52, height: 52)
                        .blur(radius: 10)

                    StaticCoin3DView(fileName: coinFileName)
                        .id(coinFileName)
                        .frame(width: 44, height: 44)
                } else {
                    StaticCoin3DView(fileName: coinFileName)
                        .id("\(coinFileName)-locked")
                        .frame(width: 44, height: 44)
                        .saturation(0)
                        .opacity(0.3)
                }
            }
            .scaleEffect(isVisible ? 1 : 0)
            .opacity(isVisible ? 1 : 0)
            .animation(coinAnimation, value: isVisible)

            // Month name + state
            VStack(alignment: .leading, spacing: 3) {
                Text(monthName)
                    .font(.custom(FontFamily.Rubik.medium, size: 16))
                    .foregroundColor(isCovered ? .primary : .secondary.opacity(0.4))

                if isCovered {
                    Text(stateDescription)
                        .font(.custom(FontFamily.Rubik.regular, size: 12))
                        .foregroundColor(stateColor)
                }
            }

            Spacer()

            // Bill amount
            if !billAmount.isEmpty {
                Text(billAmount)
                    .font(.normaFinancial(16))
                    .foregroundColor(isCovered ? .primary : .secondary.opacity(0.25))
                    .strikethrough(!isCovered, color: .secondary.opacity(0.3))
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.clear)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 16))

                if isCovered {
                    DiagonalLinesPattern(
                        lineColor: stateColor,
                        spacing: 10,
                        lineWidth: 0.8
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .mask(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.25),
                                .white.opacity(0.08),
                                .clear
                            ],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                    )
                    .allowsHitTesting(false)
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -10)
        .animation(coinAnimation, value: isVisible)
    }
}

// MARK: - Hero Coin 3D View (Spinning)
/// Large spinning 3D coin for hero display
struct HeroCoin3DView: UIViewRepresentable {
    var fileName: String = "norma-coin"

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = false
        scnView.isUserInteractionEnabled = false
        scnView.antialiasingMode = .multisampling4X

        if !loadScene(into: scnView) {
            createFallbackScene(into: scnView)
        }

        scnView.isPlaying = true

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // No updates needed
    }

    private func loadScene(into scnView: SCNView) -> Bool {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "usdz") else {
            print("HeroCoin3DView: Could not find \(fileName).usdz")
            return false
        }

        guard let scene = try? SCNScene(url: url, options: [.checkConsistency: true]) else {
            print("HeroCoin3DView: Failed to load scene from URL")
            return false
        }

        scene.background.contents = UIColor.clear

        // Create container for the model
        let containerNode = SCNNode()

        // Clone all child nodes from the loaded scene
        for childNode in scene.rootNode.childNodes {
            containerNode.addChildNode(childNode.clone())
        }

        // Remove original nodes to prevent static coin overlay
        scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }

        // Calculate bounding box and center the model
        let (minBound, maxBound) = containerNode.boundingBox
        let centerX = (minBound.x + maxBound.x) / 2
        let centerY = (minBound.y + maxBound.y) / 2
        let centerZ = (minBound.z + maxBound.z) / 2
        containerNode.position = SCNVector3(-centerX, -centerY, -centerZ)

        // Calculate model dimensions
        let width = maxBound.x - minBound.x
        let height = maxBound.y - minBound.y
        let depth = maxBound.z - minBound.z
        let maxDimension = max(width, max(height, depth))

        scene.rootNode.addChildNode(containerNode)

        // Setup camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = Double(maxDimension * 0.6)
        cameraNode.position = SCNVector3(0, 0, maxDimension * 2)
        scene.rootNode.addChildNode(cameraNode)

        // Slow rotation for hero coin (10 seconds for full rotation)
        let rotation = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 10)
        let repeatRotation = SCNAction.repeatForever(rotation)
        containerNode.runAction(repeatRotation)

        scnView.scene = scene
        return true
    }

    private func createFallbackScene(into scnView: SCNView) {
        let fallbackScene = SCNScene()
        fallbackScene.background.contents = UIColor.clear

        let torus = SCNTorus(ringRadius: 0.4, pipeRadius: 0.15)
        torus.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0)
        torus.firstMaterial?.specular.contents = UIColor.white
        let torusNode = SCNNode(geometry: torus)
        torusNode.eulerAngles.x = .pi / 4

        fallbackScene.rootNode.addChildNode(torusNode)

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 1.0
        camera.position = SCNVector3(0, 0, 3)
        fallbackScene.rootNode.addChildNode(camera)

        let rotation = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 10)
        torusNode.runAction(SCNAction.repeatForever(rotation))

        scnView.scene = fallbackScene
    }
}

// MARK: - Dashed Divider Shape

// MARK: - Diagonal Lines Pattern

private struct DiagonalLinesPattern: View {
    var lineColor: Color = .gray
    var spacing: CGFloat = 10
    var lineWidth: CGFloat = 0.8

    var body: some View {
        Canvas { context, size in
            let totalLines = Int((size.width + size.height) / spacing) + 1

            for i in 0..<totalLines {
                let offset = CGFloat(i) * spacing

                var path = Path()
                // Lines go from top-right to bottom-left
                let startX = offset
                let startY: CGFloat = 0
                let endX = offset - size.height
                let endY = size.height

                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))

                context.stroke(
                    path,
                    with: .color(lineColor),
                    lineWidth: lineWidth
                )
            }
        }
    }
}

private struct DashedDividerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
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
