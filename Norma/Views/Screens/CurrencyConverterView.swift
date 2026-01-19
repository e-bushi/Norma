//
//  CurrencyConverterView.swift
//  Norma
//
//  Created by Claude on 12/5/25.
//

import SwiftUI

// MARK: - Insight Record (Persisted)
struct InsightRecord: Identifiable, Codable {
    let id: UUID
    let fromCurrency: String
    let toCurrency: String
    let fromAmount: Double
    let toAmount: Double
    let exchangeRate: Double
    var insight: String
    let timestamp: Date

    init(id: UUID = UUID(), fromCurrency: String, toCurrency: String, fromAmount: Double, toAmount: Double, exchangeRate: Double, insight: String = "", timestamp: Date = Date()) {
        self.id = id
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
        self.fromAmount = fromAmount
        self.toAmount = toAmount
        self.exchangeRate = exchangeRate
        self.insight = insight
        self.timestamp = timestamp
    }
}

// MARK: - Convert Button Style
struct ConvertButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct CurrencyConverterView: View {
    @Binding var isMenuOpen: Bool
    @EnvironmentObject private var sessionViewModel: SessionViewModel

    @State private var amount: String = ""
    @State private var fromCurrency: String = "USD"
    @State private var toCurrency: String = "EUR"
    @State private var convertedAmount: Double? = nil
    @State private var hasPendingConversion: Bool = false
    @State private var hasConverted: Bool = false
    @State private var isConverting: Bool = false
    @State private var conversionError: String? = nil
    @State private var lastExchangeRate: Double? = nil

    // Main Currencies State
    @State private var showMainCurrenciesView: Bool = false
    @State private var mainCurrencies: [String] = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "MXN", "BRL"]
    private let mainCurrenciesKey = "mainCurrencies"

    // Purchasing Power Insights List State
    @State private var insights: [InsightRecord] = []
    @State private var currentLoadingInsightId: UUID? = nil
    @State private var visibleWordCounts: [UUID: Int] = [:]
    @State private var insightError: String? = nil

    @FocusState private var isAmountFocused: Bool

    // Appearance animation
    @State private var hasAppeared = false

    private let maxInsights = 6
    private let insightsStorageKey = "purchasingPowerInsights"

    private var isConvertButtonActive: Bool {
        guard let inputAmount = Double(amount), inputAmount > 0 else { return false }
        return hasPendingConversion && !isConverting
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Conversion controls (centered)
                    VStack(spacing: 0) {
                        // From currency section
                        VStack(spacing: 8) {
                            // Currency picker
                            Menu {
                                ForEach(mainCurrencies, id: \.self) { currency in
                                    Button {
                                        fromCurrency = currency
                                        resetConversion()
                                        markPendingConversion()
                                    } label: {
                                        Text("\(flagEmoji(for: currency)) \(currency)")
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(flagEmoji(for: fromCurrency))
                                        .font(.system(size: 18))
                                    Text(fromCurrency)
                                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                                        .foregroundColor(.primary)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.gray.opacity(0.1))
                                        .glassEffect(in: Capsule())
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                )
                            }

                            // Amount input
                            TextField("0", text: $amount)
                                .font(.normaHeadline(48))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .focused($isAmountFocused)
                                .onChange(of: amount) { _, _ in
                                    resetConversion()
                                    markPendingConversion()
                                }
                        }
                        .padding(.vertical, 20)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: hasAppeared)

                        // Action buttons row
                        VStack(spacing: 12) {
                            HStack(spacing: 16) {
                                // Flip button
                                Button {
                                    flipCurrencies()
                                } label: {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(Color.gray.opacity(0.08))
                                                .glassEffect(in: Circle())
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                                        )
                                }
                                .buttonStyle(ConvertButtonStyle(isActive: true))

                                // Convert button
                                Button {
                                    Task {
                                        await performConversion()
                                    }
                                } label: {
                                    Group {
                                        if isConverting {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(Color("NormaPastelTeal"))
                                        } else {
                                            Image(systemName: "arrow.down")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(isConvertButtonActive ? Color("NormaPastelTeal") : Color.secondary)
                                        }
                                    }
                                    .frame(width: 48, height: 48)
                                    .background(
                                        Circle()
                                            .fill(isConvertButtonActive || isConverting ? Color("NormaPastelTeal").opacity(0.2) : Color.gray.opacity(0.08))
                                            .glassEffect(in: Circle())
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(isConvertButtonActive || isConverting ? Color("NormaPastelTeal").opacity(0.5) : Color.gray.opacity(0.15), lineWidth: isConvertButtonActive || isConverting ? 1.5 : 0.5)
                                    )
                                    .shadow(color: isConvertButtonActive || isConverting ? Color("NormaPastelTeal").opacity(0.4) : Color.clear, radius: 8, x: 0, y: 2)
                                    .scaleEffect(isConvertButtonActive || isConverting ? 1.12 : 0.88)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0), value: isConvertButtonActive)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0), value: isConverting)
                                }
                                .buttonStyle(ConvertButtonStyle(isActive: isConvertButtonActive))
                                .disabled(!isConvertButtonActive)
                            }

                        }
                        .padding(.vertical, 8)
                        .opacity(hasAppeared ? 1 : 0)
                        .scaleEffect(hasAppeared ? 1 : 0.8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: hasAppeared)

                        // To currency section
                        VStack(spacing: 8) {
                            // Currency picker
                            Menu {
                                ForEach(mainCurrencies, id: \.self) { currency in
                                    Button {
                                        toCurrency = currency
                                        resetConversion()
                                        markPendingConversion()
                                    } label: {
                                        Text("\(flagEmoji(for: currency)) \(currency)")
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(flagEmoji(for: toCurrency))
                                        .font(.system(size: 18))
                                    Text(toCurrency)
                                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                                        .foregroundColor(.primary)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.gray.opacity(0.1))
                                        .glassEffect(in: Capsule())
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                )
                            }

                            // Converted amount display
                            if let error = conversionError {
                                Text(error)
                                    .font(.custom(FontFamily.Rubik.regular, size: 14))
                                    .foregroundColor(.red.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            } else {
                                Text(formattedConvertedAmount)
                                    .font(.normaHeadline(48))
                                    .foregroundColor(hasConverted ? Color("NormaPastelTeal") : Color.secondary.opacity(0.4))
                                    .animation(.easeInOut(duration: 0.2), value: hasConverted)
                            }
                        }
                        .padding(.vertical, 20)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: hasAppeared)
                    }

                    // Purchasing Power Insights section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Purchasing Power Insights")
                            .font(.custom(FontFamily.Rubik.medium, size: 13))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 15)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: hasAppeared)

                    // Horizontal insights list
                    Group {
                        if insights.isEmpty {
                            // Empty state
                            VStack(spacing: 12) {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color("NormaPastelPurple").opacity(0.4))

                                VStack(spacing: 4) {
                                    Text("No insights yet")
                                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                                        .foregroundColor(.secondary)

                                    Text("Convert a currency to generate purchasing power insights")
                                        .font(.custom(FontFamily.Rubik.regular, size: 14))
                                        .foregroundColor(.secondary.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("NormaPastelPurple").opacity(0.02))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color("NormaPastelPurple").opacity(0.08), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 24)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 16) {
                                    ForEach(insights) { record in
                                        insightCard(record: record)
                                            .frame(width: 350)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: hasAppeared)

                    // Error message if any
                    if let error = insightError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.custom(FontFamily.Rubik.regular, size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.horizontal, 0)
                .padding(.top, 4)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color("NormaBackground"))
            .contentShape(Rectangle())
            .onTapGesture {
                isAmountFocused = false
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        let impactLight = UIImpactFeedbackGenerator(style: .light)
                        impactLight.impactOccurred()

                        // Open the menu
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isMenuOpen = true
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Purchasing Power")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 17))
                        .foregroundColor(.primary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let impactLight = UIImpactFeedbackGenerator(style: .light)
                        impactLight.impactOccurred()
                        showMainCurrenciesView = true
                    } label: {
                        Text("💱")
                            .font(.system(size: 20))
                    }
                }
            }
            .onAppear {
                isAmountFocused = true
                loadInsights()
                loadMainCurrencies()

                // Trigger appearance animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    hasAppeared = true
                }
            }
            .sheet(isPresented: $showMainCurrenciesView) {
                MainCurrenciesView(
                    selectedCurrencies: $mainCurrencies,
                    onSave: saveMainCurrencies
                )
            }
    }

    // MARK: - Insight Card View

    @ViewBuilder
    private func insightCard(record: InsightRecord) -> some View {
        let isLoading = currentLoadingInsightId == record.id
        let fromSymbol = CurrencyData.getCurrency(for: record.fromCurrency).symbol
        let toSymbol = CurrencyData.getCurrency(for: record.toCurrency).symbol

        VStack(alignment: .leading, spacing: 0) {
            // Currency flag stack with exchange info
            HStack(spacing: 12) {
                HStack(spacing: 0) {
                    // First flag (from currency)
                    Text(flagEmoji(for: record.fromCurrency))
                        .font(.system(size: 24))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color("NormaBackground"))
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                        .zIndex(1)

                    // Second flag (to currency) - overlapping
                    Text(flagEmoji(for: record.toCurrency))
                        .font(.system(size: 24))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color("NormaBackground"))
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                        .offset(x: -12)
                }

                // Exchange info
                HStack(spacing: 6) {
                    Text(record.fromCurrency)
                        .font(.normaHeadline(36))
                        .foregroundColor(.primary)
                    Text("→")
                        .font(.normaHeadline(36))
                        .foregroundColor(.secondary)
                    Text(record.toCurrency)
                        .font(.normaHeadline(36))
                        .foregroundColor(Color("NormaPastelTeal"))
                }
            }
            .padding(.bottom, 20)

            // Content: Loading or Insight text
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(Color("NormaPastelPurple"))

                    Text("Analyzing purchasing power...")
                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                        .foregroundColor(Color("NormaPastelPurple"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Insight text
                Text(displayText(for: record))
                    .font(.custom(FontFamily.Rubik.regular, size: 15))
                    .foregroundColor(.primary)
                    .lineSpacing(5)
                    .padding(.bottom, 20)

                // Conversion badges
                HStack(spacing: 10) {
                    // Converted amounts badge
                    Text("\(fromSymbol)\(abbreviatedAmount(record.fromAmount)) → \(toSymbol)\(abbreviatedAmount(record.toAmount))")
                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.08))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                        )

                    // Exchange rate badge
                    Text("\(fromSymbol)1 = \(toSymbol)\(String(format: "%.2f", record.exchangeRate))")
                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.08))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                        )
                }
                .padding(.bottom, 20)

                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(height: 1)
                    .padding(.bottom, 12)

                // Timestamp and disclaimer
                HStack(spacing: 6) {
                    Text(relativeTime(for: record.timestamp))
                        .font(.custom(FontFamily.Rubik.regular, size: 11))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("•")
                        .font(.custom(FontFamily.Rubik.regular, size: 11))
                        .foregroundColor(.secondary.opacity(0.3))

                    Text("Norma can make mistakes.")
                        .font(.custom(FontFamily.Rubik.regular, size: 11))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("NormaPastelPurple").opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color("NormaPastelPurple").opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func formatExchangeRate(_ rate: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: rate)) ?? "\(rate)"
    }

    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private var formattedConvertedAmount: String {
        guard hasConverted, let converted = convertedAmount else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: converted)) ?? "0"
    }

    private func resetConversion() {
        withAnimation(.easeInOut(duration: 0.2)) {
            hasConverted = false
            convertedAmount = nil
            conversionError = nil
            lastExchangeRate = nil
        }
    }

    private func markPendingConversion() {
        guard let inputAmount = Double(amount), inputAmount > 0 else { return }
        if !hasPendingConversion {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                hasPendingConversion = true
            }
        }
    }

    private func flipCurrencies() {
        let impactLight = UIImpactFeedbackGenerator(style: .light)
        impactLight.impactOccurred()

        let temp = fromCurrency
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            fromCurrency = toCurrency
            toCurrency = temp
            resetConversion()
            markPendingConversion()
        }
    }

    private func performConversion() async {
        guard let inputAmount = Double(amount), inputAmount > 0 else { return }

        let impactMedium = UIImpactFeedbackGenerator(style: .medium)
        impactMedium.impactOccurred()

        // Set loading state
        withAnimation(.easeInOut(duration: 0.2)) {
            isConverting = true
            conversionError = nil
        }

        do {
            let response = try await CurrencyConversionService.shared.convert(
                amount: inputAmount,
                from: fromCurrency,
                to: toCurrency
            )

            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    convertedAmount = response.convertedValue
                    lastExchangeRate = response.exchangeRate
                    hasConverted = true
                    hasPendingConversion = false
                    isConverting = false
                }

                // Auto-generate insight
                generateInsight(
                    fromCurrency: fromCurrency,
                    toCurrency: toCurrency,
                    fromAmount: inputAmount,
                    toAmount: response.convertedValue,
                    exchangeRate: response.exchangeRate
                )
            }
        } catch {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isConverting = false
                    conversionError = "Conversion failed. Please try again."
                }
            }
        }
    }

    private func generateInsight(fromCurrency: String, toCurrency: String, fromAmount: Double, toAmount: Double, exchangeRate: Double) {
        // Create placeholder record
        let recordId = UUID()
        let record = InsightRecord(
            id: recordId,
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            fromAmount: fromAmount,
            toAmount: toAmount,
            exchangeRate: exchangeRate,
            insight: "",
            timestamp: Date()
        )

        // Add to front of list with loading state
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            insights.insert(record, at: 0)
            currentLoadingInsightId = recordId
            insightError = nil

            // Enforce max items
            while insights.count > maxInsights {
                insights.removeLast()
            }
        }

        Task {
            do {
                // Get user's home currency (default to USD)
                let userHomeCurrency = sessionViewModel.currentUser?.settings.currency ?? "USD"

                // Build the prompt
                let systemPrompt = NormaSystemPrompts.purchasingPowerPrompt(
                    fromCurrency: fromCurrency,
                    toCurrency: toCurrency,
                    fromAmount: fromAmount,
                    toAmount: toAmount,
                    exchangeRate: exchangeRate,
                    userHomeCurrency: userHomeCurrency
                )

                // Call the API
                let messages = [AnthropicMessage(role: "user", content: .text("Generate my purchasing power insight."))]
                let response = try await AnthropicService.shared.sendMessage(
                    messages: messages,
                    systemPrompt: systemPrompt,
                    maxTokens: 120
                )

                let insightText = response.trimmingCharacters(in: .whitespacesAndNewlines)

                await MainActor.run {
                    // Update the record with the insight text
                    if let index = insights.firstIndex(where: { $0.id == recordId }) {
                        insights[index].insight = insightText
                    }
                    currentLoadingInsightId = nil

                    // Start typing animation
                    startTypingAnimation(for: recordId, text: insightText)

                    // Save to persistence
                    saveInsights()
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        // Remove the failed record
                        insights.removeAll { $0.id == recordId }
                        insightError = "Unable to generate insight. Please try again."
                        currentLoadingInsightId = nil
                    }
                }
            }
        }
    }

    // MARK: - Typing Animation

    private func startTypingAnimation(for insightId: UUID, text: String) {
        let words = text.split(separator: " ").map(String.init)
        visibleWordCounts[insightId] = 0

        for index in 0...words.count {
            let delay = Double(index) * 0.05 // 50ms per word
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.15)) {
                    visibleWordCounts[insightId] = index
                }
            }
        }
    }

    private func displayText(for record: InsightRecord) -> String {
        let words = record.insight.split(separator: " ").map(String.init)
        let count = visibleWordCounts[record.id] ?? words.count
        return words.prefix(count).joined(separator: " ")
    }

    // MARK: - Persistence

    private func saveInsights() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(insights) {
            UserDefaults.standard.set(data, forKey: insightsStorageKey)
        }
    }

    private func saveMainCurrencies() {
        UserDefaults.standard.set(mainCurrencies, forKey: mainCurrenciesKey)
    }

    private func loadMainCurrencies() {
        if let saved = UserDefaults.standard.stringArray(forKey: mainCurrenciesKey) {
            mainCurrencies = saved
        }
    }

    private func loadInsights() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: insightsStorageKey),
           let loaded = try? decoder.decode([InsightRecord].self, from: data) {
            insights = loaded
            // Set all word counts to full so persisted insights show completely
            for record in insights {
                let wordCount = record.insight.split(separator: " ").count
                visibleWordCounts[record.id] = wordCount
            }
        }
    }

    private func flagEmoji(for currencyCode: String) -> String {
        switch currencyCode {
        case "USD": return "🇺🇸"
        case "EUR": return "🇪🇺"
        case "GBP": return "🇬🇧"
        case "JPY": return "🇯🇵"
        case "CAD": return "🇨🇦"
        case "AUD": return "🇦🇺"
        case "CHF": return "🇨🇭"
        case "CNY": return "🇨🇳"
        case "MXN": return "🇲🇽"
        case "BRL": return "🇧🇷"
        case "SEK": return "🇸🇪"
        case "NZD": return "🇳🇿"
        case "SGD": return "🇸🇬"
        case "HKD": return "🇭🇰"
        case "NOK": return "🇳🇴"
        case "KRW": return "🇰🇷"
        case "TRY": return "🇹🇷"
        case "INR": return "🇮🇳"
        case "RUB": return "🇷🇺"
        case "ZAR": return "🇿🇦"
        case "DKK": return "🇩🇰"
        case "PLN": return "🇵🇱"
        case "THB": return "🇹🇭"
        case "IDR": return "🇮🇩"
        case "HUF": return "🇭🇺"
        case "CZK": return "🇨🇿"
        case "ILS": return "🇮🇱"
        case "CLP": return "🇨🇱"
        case "PHP": return "🇵🇭"
        case "AED": return "🇦🇪"
        case "COP": return "🇨🇴"
        case "SAR": return "🇸🇦"
        case "MYR": return "🇲🇾"
        case "RON": return "🇷🇴"
        default: return "💱"
        }
    }

    private func relativeTime(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func abbreviatedAmount(_ value: Double) -> String {
        let absValue = abs(value)

        if absValue >= 1_000_000_000 {
            let billions = value / 1_000_000_000
            // If 3+ digits, no decimals
            if Int(billions) >= 100 || billions.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0fB", billions)
            }
            return String(format: "%.2fB", billions).replacingOccurrences(of: ".00B", with: "B")
        } else if absValue >= 1_000_000 {
            let millions = value / 1_000_000
            if Int(millions) >= 100 || millions.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0fM", millions)
            }
            return String(format: "%.2fM", millions).replacingOccurrences(of: ".00M", with: "M")
        } else if absValue >= 1_000 {
            let thousands = value / 1_000
            if Int(thousands) >= 100 || thousands.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0fK", thousands)
            }
            return String(format: "%.2fK", thousands).replacingOccurrences(of: ".00K", with: "K")
        } else {
            if Int(value) >= 100 || value.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0f", value)
            }
            return String(format: "%.2f", value)
        }
    }
}

#Preview {
    NavigationStack {
        CurrencyConverterView(isMenuOpen: .constant(false))
            .environmentObject(SessionViewModel(dataManager: DataManager()))
    }
}
