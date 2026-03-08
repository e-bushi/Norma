//
//  FinancialOverviewView.swift
//  Norma
//
//  Created by Claude on 12/24/25.
//

import SwiftUI

struct FinancialOverviewView: View {
    @Binding var isMenuOpen: Bool
    var showMenuButton: Bool = true
    var onClose: (() -> Void)? = nil
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var billViewModel: BillViewModel
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel

    @State private var displayedRemaining: Double = 0
    @State private var waveAnimating: Bool = false
    @State private var convertedAmount: Double?
    @State private var exchangeRate: Double?
    @State private var isConverting: Bool = false
    @State private var showCurrencyPicker: Bool = false
    @State private var showCoinInfo: Bool = false
    @State private var countdownText: String = ""
    @State private var currencySectionVisible: Bool = false
    @State private var coinVisible: Bool = false
    @State private var timerVisible: Bool = false

    // MARK: - Computed Properties

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

    private var formattedAmount: String {
        displayedRemaining.formatted(.currency(code: currency).precision(.fractionLength(0)))
    }

    private var amountColor: Color {
        remainingToSpend >= 0 ? Color("NormaPastelPurple") : Color("NormaPastelCoral")
    }

    /// Words for the wave animation with per-word color
    private var waveWords: [(word: String, color: Color)] {
        var words: [(String, Color)] = []
        words.append(("You", .primary))
        words.append(("have", .primary))
        // Split formatted amount in case it has spaces (e.g. "1 234")
        for part in formattedAmount.split(separator: " ").map(String.init) {
            words.append((part, amountColor))
        }
        words.append(("left", .primary))
        words.append(("to", .primary))
        words.append(("spend", .primary))
        words.append(("this", .primary))
        words.append(("month.", .primary))
        return words
    }

    private var spendingCurrency: String? {
        sessionViewModel.currentUser?.settings.spendingCurrency
    }

    /// Spending pace: 0.0 = well under budget, 0.5 = on track, 1.0+ = over budget
    private var spendingPace: Double {
        let budget = max(0, monthlyIncome - totalBills)
        guard budget > 0 else { return 0.5 }

        let calendar = Calendar.current
        let now = Date()
        let day = Double(calendar.component(.day, from: now))
        let daysInMonth = Double(calendar.range(of: .day, in: .month, for: now)?.count ?? 30)

        // Expected spend by this point in the month
        let expectedSpend = budget * (day / daysInMonth)
        guard expectedSpend > 0 else { return 0.5 }

        // Ratio: 1.0 = spent exactly what's expected, >1 = over pace
        let ratio = totalExpenses / expectedSpend

        // Map to 0..1 range: 0.5 at ratio=1.0, 0.0 at ratio=0.0, 1.0 at ratio=2.0
        return min(1.0, max(0.0, ratio * 0.5))
    }

    /// Coin degrades from royalty → basic as spending pace increases
    private var paceCoinFileName: String {
        spendingPace > 0.5 ? "norma-coin" : "norma-coin-royalty"
    }

    /// End of the current month for countdown timer
    private var endOfMonth: Date {
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
        return calendar.date(byAdding: .month, value: 1, to: start) ?? now
    }

    private func formattedCountdown() -> String {
        let remaining = max(0, endOfMonth.timeIntervalSince(Date()))
        let days = Int(remaining) / 86400
        let hours = (Int(remaining) % 86400) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%dd %02d:%02d:%02d", days, hours, minutes, seconds)
    }

    private var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    private var currentYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Month / Year
            Text("\(currentMonth) \(currentYear)".uppercased())
                .font(.normaFinancial(20))
                .foregroundColor(.secondary)
                .padding(.top, 20)

            // Main statement with wave animation
            ColoredWaveTextView(
                words: waveWords,
                font: .normaHeadline(64),
                isAnimating: waveAnimating,
                alignment: .leading
            )
            .padding(.top, 16)

            // Spending currency conversion
            spendingCurrencySection
                .padding(.top, 24)
                .opacity(currencySectionVisible ? 1 : 0)
                .offset(y: currencySectionVisible ? 0 : 12)
                .animation(.easeOut(duration: 0.5), value: currencySectionVisible)

            Spacer()

            // Spending pace coin — royalty when under budget, degrades to basic
            VStack(spacing: 16) {
                CrossfadeView(
                    key: paceCoinFileName,
                    duration: 1.5
                ) { fileName in
                    MotionCoin3DView(fileName: fileName)
                        .id(fileName)
                        .frame(width: 220, height: 220)
                }
                .scaleEffect(coinVisible ? 1 : 0.3)
                .opacity(coinVisible ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: coinVisible)

                // Countdown to end of month + info
                HStack(spacing: 8) {
                    Button {
                        showCoinInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary.opacity(0.6))
                    }

                    Text(countdownText)
                        .font(.normaFinancial(22))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.snappy(duration: 0.3), value: countdownText)
                        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                            countdownText = formattedCountdown()
                        }
                }
                .opacity(timerVisible ? 1 : 0)
                .offset(y: timerVisible ? 0 : 8)
                .animation(.easeOut(duration: 0.4), value: timerVisible)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("NormaBackground").ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showMenuButton {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isMenuOpen = true
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                }
            }

            if onClose != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onClose?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.15))
                            )
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            displayedRemaining = remainingToSpend
            countdownText = formattedCountdown()
            // Wave text starts first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                waveAnimating = true
            }
            // Currency section slides up after wave text begins
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                currencySectionVisible = true
            }
            // Coin pops in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                coinVisible = true
            }
            // Timer fades in last
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                timerVisible = true
            }
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
        .alert("Your Coin", isPresented: $showCoinInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("Your coin starts as Royalty each month. The faster you spend, the faster it fades to a basic coin. Keep your spending in check to hold onto it all month.")
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
                    amount: max(0, displayedRemaining),
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
        // Update session so the UI reacts immediately
        sessionViewModel.currentUser = user
        Task {
            // Persist to backend
            try? await dataManager.updateUserProfile(user)
            fetchConversion()
        }
    }
}

// MARK: - Financial Overview Overlay

struct FinancialOverviewOverlay: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            FinancialOverviewView(
                isMenuOpen: .constant(false),
                showMenuButton: false,
                onClose: {
                    isPresented = false
                }
            )
        }
        .background {
            Rectangle()
                .fill(.clear)
                .glassEffect(in: Rectangle())
                .ignoresSafeArea()
        }
        .persistentSystemOverlays(.hidden)
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
// MARK: - Button Style

struct StatCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let billViewModel = BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let expenseViewModel = ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let challengeViewModel = ChallengeViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)

    NavigationStack {
        FinancialOverviewView(isMenuOpen: .constant(false))
            .environmentObject(sessionViewModel)
            .environmentObject(dataManager)
            .environmentObject(billViewModel)
            .environmentObject(expenseViewModel)
            .environmentObject(challengeViewModel)
            .environmentObject(profileViewModel)
    }
}
