//
//  ActivityView.swift
//  Norma
//
//  Created by Claude on 3/26/26.
//

import SwiftUI

struct ActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var coinColorViewModel: CoinColorViewModel
    @EnvironmentObject private var dataManager: DataManager

    @State private var dayCapsuleVisibility: [Bool] = Array(repeating: false, count: 7)
    @State private var heroTextAnimating = false
    @State private var remainingCapsuleVisible = false
    @State private var currencySectionVisible = false

    // Currency conversion state
    @State private var convertedAmount: Double?
    @State private var exchangeRate: Double?
    @State private var isConverting = false
    @State private var showCurrencyPicker = false

    // MARK: - Financial Computed Properties

    private var monthlyIncome: Double {
        sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
    }

    private var totalBills: Double {
        billViewModel.totalMonthlyBills
    }

    private var totalExpenses: Double {
        expenseViewModel.currentMonthExpenses
    }

    private var remainingToSpend: Double {
        max(0, monthlyIncome - totalBills) - totalExpenses
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private var formattedRemaining: String {
        remainingToSpend.formatted(.currency(code: currency).precision(.fractionLength(0)))
    }

    private var remainingColor: Color {
        remainingToSpend >= 0 ? Color("NormaPastelPurple") : Color("NormaPastelCoral")
    }

    private var spendingCurrency: String? {
        sessionViewModel.currentUser?.settings.spendingCurrency
    }

    private var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    // MARK: - Week Data

    private var currentWeekDays: [(date: Date, label: String, isToday: Bool, isFuture: Bool, spending: Double)] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 2), to: today)! // Monday

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            let label = formatter.string(from: date)
            let isToday = calendar.isDateInToday(date)
            let isFuture = date > today

            // Sum expenses for this day
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let spending = dataManager.expenses.filter { expense in
                guard let expDate = parseDate(expense.expenseDate) else { return false }
                return expDate >= dayStart && expDate < dayEnd
            }.reduce(0) { $0 + $1.amount }

            return (date: date, label: label, isToday: isToday, isFuture: isFuture, spending: spending)
        }
    }

    private var weeklySpend: Double {
        currentWeekDays.reduce(0) { $0 + $1.spending }
    }

    /// Accent color derived from the coin color, tuned to complement the gradient background.
    /// Dark mode: brightened version of the coin hue. Light mode: deepened version.
    private var heroAccentColor: Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(coinColorViewModel.coinColor).getRed(&r, green: &g, blue: &b, alpha: &a)
        if colorScheme == .dark {
            // Brighten to ~55% — visible against the dark gradient without being neon
            return Color(red: r * 0.55, green: g * 0.55, blue: b * 0.55)
        } else {
            // Deepen to ~65% blend toward the coin color — rich but not muddy
            return Color(red: 1 - (1 - r) * 0.65, green: 1 - (1 - g) * 0.65, blue: 1 - (1 - b) * 0.65)
        }
    }

    private var heroWords: [(word: String, color: Color)] {
        var words: [(String, Color)] = []
        words.append(("You", .primary))
        words.append(("spent", .primary))
        for part in formatCurrency(weeklySpend).split(separator: " ").map(String.init) {
            words.append((part, heroAccentColor))
        }
        words.append(("so", .primary))
        words.append(("far", .primary))
        words.append(("this", .primary))
        words.append(("week.", .primary))
        return words
    }

    // MARK: - Helpers

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) { return date }
        if dateString.contains("T") {
            return formatter.date(from: dateString + "Z")
        }
        return formatter.date(from: dateString + "T00:00:00Z")
    }

    private func formatCurrency(_ value: Double) -> String {
        profileViewModel.formatCurrency(value)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    // MARK: - What's Left Capsule
                    HStack(spacing: 8) {
                        Text("\(formattedRemaining) left in \(currentMonth)")
                            .font(.custom(FontFamily.Rubik.medium, size: 14))
                            .foregroundColor(remainingColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(.clear)
                            .glassEffect(in: Capsule())
                    )
                    .overlay(
                        Capsule()
                            .stroke(remainingColor.opacity(0.3), lineWidth: 1)
                    )
                    .opacity(remainingCapsuleVisible ? 1 : 0)
                    .scaleEffect(remainingCapsuleVisible ? 1 : 0.8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: remainingCapsuleVisible)
                    .padding(.top, 8)

                    // MARK: - Hero Text
                    ColoredWaveTextView(
                        words: heroWords,
                        font: .normaHeadline(64),
                        isAnimating: heroTextAnimating,
                        alignment: .leading
                    )

                    // MARK: - Week Day Capsules
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This Week")
                            .font(.custom(FontFamily.Rubik.semiBold, size: 13))
                            .foregroundColor(.secondary.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(0.5)

                        FlowLayout(spacing: 6, verticalSpacing: 6) {
                            ForEach(Array(currentWeekDays.enumerated()), id: \.offset) { index, day in
                                HStack(spacing: 6) {
                                    Text(day.label)
                                        .font(.custom(FontFamily.Rubik.medium, size: 16))
                                        .foregroundColor(day.isToday ? .primary : (day.isFuture ? .secondary.opacity(0.4) : .secondary))

                                    if !day.isFuture && day.spending > 0 {
                                        Text(profileViewModel.formatCurrencyTruncated(day.spending))
                                            .font(.normaFinancial(14))
                                            .foregroundColor(day.isToday ? .primary : .secondary.opacity(0.7))
                                    } else if day.isFuture {
                                        Text("—")
                                            .font(.custom(FontFamily.Rubik.regular, size: 16))
                                            .foregroundColor(.secondary.opacity(0.3))
                                    } else {
                                        Text("$0")
                                            .font(.normaFinancial(14))
                                            .foregroundColor(.secondary.opacity(0.4))
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background {
                                    if !day.isFuture {
                                        Capsule()
                                            .fill(.clear)
                                            .glassEffect(in: Capsule())
                                    }
                                }
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            day.isToday ? Color.primary.opacity(0.3) : (day.isFuture ? Color.secondary.opacity(0.2) : Color.primary.opacity(0.15)),
                                            style: day.isFuture ? StrokeStyle(lineWidth: 1, dash: [5, 4]) : StrokeStyle(lineWidth: day.isToday ? 1.5 : 0.5)
                                        )
                                )
                                .opacity(dayCapsuleVisibility[index] ? 1 : 0)
                                .scaleEffect(dayCapsuleVisibility[index] ? 1 : 0.8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.06), value: dayCapsuleVisibility[index])
                            }
                        }
                    }

                    // MARK: - Currency Conversion
                    spendingCurrencySection
                        .opacity(currencySectionVisible ? 1 : 0)
                        .offset(y: currencySectionVisible ? 0 : 12)
                        .animation(.easeOut(duration: 0.5), value: currencySectionVisible)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background {
                ZStack(alignment: .bottomTrailing) {
                    CoinGradientBackground(coinColor: coinColorViewModel.coinColor, colorScheme: colorScheme)

                    Canvas { context, size in
                        let origin = CGPoint(x: size.width, y: size.height)
                        let ringCount = 8
                        let maxRadius: CGFloat = 220
                        let ringSpacing = maxRadius / CGFloat(ringCount)
                        let tierColor = UIColor(coinColorViewModel.coinColor)
                        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                        tierColor.getRed(&r, green: &g, blue: &b, alpha: &a)

                        for i in 1...ringCount {
                            let radius = CGFloat(i) * ringSpacing
                            let opacity = 0.10 * (1.0 - CGFloat(i) / CGFloat(ringCount))
                            let rect = CGRect(
                                x: origin.x - radius,
                                y: origin.y - radius,
                                width: radius * 2,
                                height: radius * 2
                            )
                            context.stroke(
                                Path(ellipseIn: rect),
                                with: .color(Color(red: r, green: g, blue: b).opacity(opacity)),
                                lineWidth: 1
                            )
                        }
                    }
                    .allowsHitTesting(false)
                }
                .ignoresSafeArea()
            }
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Activity")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 20))
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            startAnimations()
            fetchConversion()
        }
        .sheet(isPresented: $showCurrencyPicker) {
            SpendingCurrencyPicker(
                currentSpendingCurrency: spendingCurrency,
                homeCurrency: currency,
                onSelect: { selected in
                    updateSpendingCurrency(selected)
                },
                onClear: {
                    updateSpendingCurrency(nil)
                }
            )
            .presentationDetents([.large])
        }
    }

    // MARK: - Spending Currency Section

    @ViewBuilder
    private var spendingCurrencySection: some View {
        if let spending = spendingCurrency, spending != currency {
            VStack(alignment: .leading, spacing: 16) {
                // Converted amount
                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showCurrencyPicker = true
                } label: {
                    HStack(spacing: 8) {
                        if isConverting {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.secondary)
                        } else if let converted = convertedAmount {
                            Text("≈ \(converted.formatted(.currency(code: spending).precision(.fractionLength(0))))")
                                .font(.normaHeadline(36))
                                .foregroundColor(.secondary)
                                .contentTransition(.numericText(value: converted))
                        }

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
                .buttonStyle(.plain)

                // Exchange rate + daily budget
                if let rate = exchangeRate, let converted = convertedAmount {
                    HStack(spacing: 8) {
                        let spendingSymbol = CurrencyData.getCurrency(for: spending).symbol
                        let homeSymbol = CurrencyData.getCurrency(for: currency).symbol
                        let daysLeft = daysRemainingInMonth
                        let dailyBudget = daysLeft > 0 ? converted / Double(daysLeft) : 0

                        Text("\(homeSymbol)1 = \(spendingSymbol)\(formatRate(rate))")
                            .font(.normaFinancial(16))
                            .foregroundColor(.secondary.opacity(0.6))

                        Text("·")
                            .font(.normaFinancial(16))
                            .foregroundColor(.secondary.opacity(0.3))

                        Text("~\(dailyBudget.formatted(.currency(code: spending).precision(.fractionLength(0))))/day")
                            .font(.normaFinancial(16))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
            }
        } else {
            HStack(spacing: 10) {
                // Primary currency capsule
                HStack(spacing: 6) {
                    Text(flagEmoji(for: currency))
                        .font(.system(size: 14))
                    Text(currency)
                        .font(.normaFinancial(14))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                )

                // Add spending currency capsule
                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showCurrencyPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .medium))
                        Text("Spending currency")
                            .font(.normaFinancial(14))
                    }
                    .foregroundColor(.secondary.opacity(0.5))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Conversion

    private func fetchConversion() {
        guard let spending = spendingCurrency, spending != currency else {
            convertedAmount = nil
            return
        }

        isConverting = true
        Task {
            do {
                let response = try await CurrencyConversionService.shared.convert(
                    amount: weeklySpend,
                    from: currency,
                    to: spending
                )
                await MainActor.run {
                    withAnimation(.snappy(duration: 0.4)) {
                        convertedAmount = response.convertedValue
                        exchangeRate = response.exchangeRate
                        isConverting = false
                    }
                }
            } catch {
                await MainActor.run {
                    isConverting = false
                }
                print("Currency conversion failed: \(error)")
            }
        }
    }

    private var daysRemainingInMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let range = calendar.range(of: .day, in: .month, for: now) else { return 1 }
        let today = calendar.component(.day, from: now)
        return max(1, range.count - today)
    }

    private func formatRate(_ rate: Double) -> String {
        if rate >= 100 {
            return String(format: "%.0f", rate)
        } else if rate >= 1 {
            return String(format: "%.2f", rate)
        } else {
            return String(format: "%.4f", rate)
        }
    }

    private func flagEmoji(for code: String) -> String {
        let base: UInt32 = 127397
        switch code {
        case "EUR": return "🇪🇺"
        default:
            let countryCode = String(code.prefix(2))
            return countryCode.unicodeScalars.compactMap { UnicodeScalar(base + $0.value) }.map { String($0) }.joined()
        }
    }

    private func updateSpendingCurrency(_ newCurrency: String?) {
        guard var user = sessionViewModel.currentUser else { return }
        user.settings.spendingCurrency = newCurrency
        sessionViewModel.currentUser = user
        Task {
            try? await dataManager.updateUserProfile(user)
            fetchConversion()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Remaining capsule first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            remainingCapsuleVisible = true
        }

        // Hero text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            heroTextAnimating = true
        }

        // Day capsules stagger in after hero text
        for index in 0..<7 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2 + (Double(index) * 0.06)) {
                dayCapsuleVisibility[index] = true
            }
        }

        // Currency section slides up after capsules
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            currencySectionVisible = true
        }
    }
}

// MARK: - Spending Currency Picker

private struct SpendingCurrencyPicker: View {
    let currentSpendingCurrency: String?
    let homeCurrency: String
    let onSelect: (String) -> Void
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var visibleCount: Int = 0
    @FocusState private var isSearchFocused: Bool

    private let travelCurrencies = [
        "EUR", "GBP", "JPY", "THB", "MXN", "BRL",
        "KRW", "IDR", "COP", "TRY", "INR", "AED"
    ]

    private var displayCurrencies: [String] {
        if searchText.isEmpty {
            return Array(travelCurrencies.filter { $0 != homeCurrency }.prefix(7))
        }
        let query = searchText.lowercased()
        return Array(
            CurrencyData.currencies.keys
                .sorted()
                .filter { $0 != homeCurrency }
                .filter { code in
                    code.lowercased().contains(query) ||
                    CurrencyData.getCurrency(for: code).name.lowercased().contains(query)
                }
                .prefix(7)
        )
    }

    private func flagEmoji(for code: String) -> String {
        let base: UInt32 = 127397
        switch code {
        case "EUR": return "🇪🇺"
        default:
            let countryCode = String(code.prefix(2))
            return countryCode.unicodeScalars.compactMap { UnicodeScalar(base + $0.value) }.map { String($0) }.joined()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title + subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text("Spending Currency")
                    .font(.normaHeadline(34))
                    .foregroundColor(.primary)

                Text("Choose the currency where you're spending")
                    .font(.normaFinancial(14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)

                TextField("Search", text: $searchText)
                    .font(.normaFinancial(16))
                    .focused($isSearchFocused)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
            .padding(.bottom, 20)

            // Currency capsules
            CurrencyCapsuleFlow(spacing: 10, lineSpacing: 10) {
                ForEach(Array(displayCurrencies.enumerated()), id: \.element) { index, code in
                    let isSelected = code == currentSpendingCurrency

                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        onSelect(code)
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Text(flagEmoji(for: code))
                                .font(.system(size: 16))
                            Text(CurrencyData.getCurrency(for: code).name)
                                .font(.normaFinancial(15))
                                .foregroundColor(isSelected ? Color("NormaPastelPurple") : .primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color("NormaPastelPurple").opacity(0.12) : Color.gray.opacity(0.08))
                        )
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color("NormaPastelPurple").opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(CapsulePressStyle())
                    .opacity(index < visibleCount ? 1 : 0)
                    .scaleEffect(index < visibleCount ? 1.0 : 0.5)
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.7).delay(Double(index) * 0.04),
                        value: visibleCount
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Remove option
            if currentSpendingCurrency != nil {
                Button {
                    onClear()
                    dismiss()
                } label: {
                    Text("Remove spending currency")
                        .font(.normaFinancial(14))
                        .foregroundColor(Color("NormaPastelCoral").opacity(0.8))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(Color("NormaBackground"))
        .onChange(of: searchText) { _, _ in
            animateCapsules()
        }
        .onAppear {
            animateCapsules()
        }
    }

    private func animateCapsules() {
        visibleCount = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            visibleCount = displayCurrencies.count
        }
    }
}

// MARK: - Capsule Flow Layout

private struct CurrencyCapsuleFlow: Layout {
    let spacing: CGFloat
    let lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalWidth = max(totalWidth, x - spacing)
        }

        return (size: CGSize(width: totalWidth, height: y + lineHeight), positions: positions)
    }
}
