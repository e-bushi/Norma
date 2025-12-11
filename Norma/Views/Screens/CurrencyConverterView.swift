//
//  CurrencyConverterView.swift
//  Norma
//
//  Created by Claude on 12/5/25.
//

import SwiftUI

// MARK: - Conversion Record
struct ConversionRecord: Identifiable {
    let id = UUID()
    let fromCurrency: String
    let toCurrency: String
    let fromAmount: Double
    let toAmount: Double
    let timestamp: Date
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
    @State private var conversionHistory: [ConversionRecord] = []
    @State private var hasPendingConversion: Bool = false
    @State private var hasConverted: Bool = false

    // Purchasing Power Insight State
    @State private var isGeneratingInsight: Bool = false
    @State private var purchasingPowerInsight: String? = nil
    @State private var insightError: String? = nil
    @State private var insightGeneratedAt: Date? = nil
    @State private var insightFromCurrency: String? = nil
    @State private var insightToCurrency: String? = nil

    @FocusState private var isAmountFocused: Bool

    private let maxHistoryItems = 5

    private var isConvertButtonActive: Bool {
        guard let inputAmount = Double(amount), inputAmount > 0 else { return false }
        return hasPendingConversion
    }

    private var isInsightsButtonActive: Bool {
        return hasConverted
    }

    private var currentExchangeRate: Double? {
        guard let fromRate = exchangeRates[fromCurrency],
              let toRate = exchangeRates[toCurrency] else { return nil }
        return toRate / fromRate
    }

    // Common currencies
    private let currencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "MXN", "BRL"]

    // Mock exchange rates (USD base)
    private let exchangeRates: [String: Double] = [
        "USD": 1.0,
        "EUR": 0.92,
        "GBP": 0.79,
        "JPY": 149.50,
        "CAD": 1.36,
        "AUD": 1.53,
        "CHF": 0.88,
        "CNY": 7.24,
        "MXN": 17.15,
        "BRL": 4.97
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Conversion controls (centered)
                    VStack(spacing: 0) {
                        // From currency section
                        VStack(spacing: 8) {
                            // Currency picker
                            Menu {
                                ForEach(currencies, id: \.self) { currency in
                                    Button(currency) {
                                        fromCurrency = currency
                                        resetConversion()
                                        markPendingConversion()
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
                                    performConversion()
                                } label: {
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(isConvertButtonActive ? Color("NormaPastelTeal") : Color.secondary)
                                        .frame(width: 48, height: 48)
                                        .background(
                                            Circle()
                                                .fill(isConvertButtonActive ? Color("NormaPastelTeal").opacity(0.2) : Color.gray.opacity(0.08))
                                                .glassEffect(in: Circle())
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(isConvertButtonActive ? Color("NormaPastelTeal").opacity(0.5) : Color.gray.opacity(0.15), lineWidth: isConvertButtonActive ? 1.5 : 0.5)
                                        )
                                        .shadow(color: isConvertButtonActive ? Color("NormaPastelTeal").opacity(0.4) : Color.clear, radius: 8, x: 0, y: 2)
                                        .scaleEffect(isConvertButtonActive ? 1.12 : 0.88)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0), value: isConvertButtonActive)
                                }
                                .buttonStyle(ConvertButtonStyle(isActive: isConvertButtonActive))
                                .disabled(!isConvertButtonActive)
                            }

                            // Generate Insights button
                            if isInsightsButtonActive {
                                Button {
                                    generateInsights()
                                } label: {
                                    Text("Purchasing Power")
                                        .font(.custom(FontFamily.Rubik.medium, size: 13))
                                        .foregroundColor(Color("NormaPastelPurple"))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule()
                                                .fill(Color("NormaPastelPurple").opacity(0.15))
                                                .glassEffect(in: Capsule())
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(Color("NormaPastelPurple").opacity(0.3), lineWidth: 0.5)
                                        )
                                }
                                .buttonStyle(ConvertButtonStyle(isActive: true))
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, 8)

                        // To currency section
                        VStack(spacing: 8) {
                            // Currency picker
                            Menu {
                                ForEach(currencies, id: \.self) { currency in
                                    Button(currency) {
                                        toCurrency = currency
                                        resetConversion()
                                        markPendingConversion()
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
                            Text(formattedConvertedAmount)
                                .font(.normaHeadline(48))
                                .foregroundColor(hasConverted ? Color("NormaPastelTeal") : Color.secondary.opacity(0.4))
                                .animation(.easeInOut(duration: 0.2), value: hasConverted)
                        }
                        .padding(.vertical, 20)
                    }

                    // History section below
                    VStack(alignment: .leading, spacing: 12) {
                        Text("History")
                            .font(.custom(FontFamily.Rubik.medium, size: 13))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        if conversionHistory.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 28))
                                    .foregroundColor(.secondary.opacity(0.4))

                                VStack(spacing: 4) {
                                    Text("No saved conversions")
                                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                                        .foregroundColor(.secondary)

                                    Text("Tap the arrow button to save a conversion to your history")
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
                                    .fill(Color.gray.opacity(0.03))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.gray.opacity(0.08), lineWidth: 1)
                                    )
                            )
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(conversionHistory) { record in
                                        historyRow(record: record)
                                    }
                                }
                                .padding(.horizontal, 4)
                                .padding(.top, 16)
                                .padding(.bottom, 32)
                            }
                            .scrollClipDisabled()
                            .mask(
                                HStack(spacing: 0) {
                                    LinearGradient(
                                        colors: [.clear, .black],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(width: 20)

                                    Color.black

                                    LinearGradient(
                                        colors: [.black, .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(width: 20)
                                }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)

                    Spacer()
                        .frame(height: 8)

                    // Purchasing Power Insights section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Purchasing Power Insights")
                            .font(.custom(FontFamily.Rubik.medium, size: 13))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        // Content based on state
                        Group {
                            if isGeneratingInsight {
                                // Loading state
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
                                .padding(.horizontal, 24)

                            } else if let error = insightError {
                                // Error state
                                VStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 28))
                                        .foregroundColor(.orange.opacity(0.7))

                                    Text(error)
                                        .font(.custom(FontFamily.Rubik.regular, size: 14))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)

                                    Button {
                                        generateInsights()
                                    } label: {
                                        Text("Try Again")
                                            .font(.custom(FontFamily.Rubik.medium, size: 13))
                                            .foregroundColor(Color("NormaPastelPurple"))
                                    }
                                    .padding(.top, 4)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                                .padding(.horizontal, 24)

                            } else if let insight = purchasingPowerInsight {
                                // Success state
                                VStack(alignment: .leading, spacing: 16) {
                                    // Currency flag stack
                                    if let fromCurrency = insightFromCurrency, let toCurrency = insightToCurrency {
                                        HStack(spacing: 0) {
                                            // First flag (from currency)
                                            Text(flagEmoji(for: fromCurrency))
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
                                            Text(flagEmoji(for: toCurrency))
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
                                        .padding(.bottom, 4)
                                    }

                                    Text(insight)
                                        .font(.custom(FontFamily.Rubik.regular, size: 15))
                                        .foregroundColor(.primary)
                                        .lineSpacing(4)

                                    // Divider and disclaimer
                                    VStack(alignment: .leading, spacing: 8) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.15))
                                            .frame(height: 1)

                                        HStack(spacing: 6) {
                                            if let generatedAt = insightGeneratedAt {
                                                Text(relativeTime(for: generatedAt))
                                                    .font(.custom(FontFamily.Rubik.regular, size: 11))
                                                    .foregroundColor(.secondary.opacity(0.6))

                                                Text("•")
                                                    .font(.custom(FontFamily.Rubik.regular, size: 11))
                                                    .foregroundColor(.secondary.opacity(0.4))
                                            }

                                            Text("Norma can make mistakes. Please double-check insights.")
                                                .font(.custom(FontFamily.Rubik.regular, size: 11))
                                                .foregroundColor(.secondary.opacity(0.6))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 20)
                                .padding(.horizontal, 20)

                            } else {
                                // Empty state
                                VStack(spacing: 12) {
                                    Image(systemName: "chart.bar.doc.horizontal")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color("NormaPastelPurple").opacity(0.4))

                                    VStack(spacing: 4) {
                                        Text("No insights yet")
                                            .font(.custom(FontFamily.Rubik.medium, size: 14))
                                            .foregroundColor(.secondary)

                                        Text("Convert a currency and tap the button above to generate purchasing power insights")
                                            .font(.custom(FontFamily.Rubik.regular, size: 14))
                                            .foregroundColor(.secondary.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                                .padding(.horizontal, 24)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("NormaPastelPurple").opacity(0.02))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color("NormaPastelPurple").opacity(0.08), lineWidth: 1)
                                )
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
                }
                .padding(.horizontal, 24)
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
                    Text("Currency Converter")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 17))
                        .foregroundColor(.primary)
                }
            }
            .onAppear {
                isAmountFocused = true
            }
    }

    private func historyRow(record: ConversionRecord) -> some View {
        let exchangeRate = record.toAmount / record.fromAmount

        return VStack(alignment: .leading, spacing: 8) {
            // Amount conversion (on top)
            Text("\(formatAmount(record.fromAmount)) \(record.fromCurrency) → \(formatAmount(record.toAmount)) \(record.toCurrency)")
                .font(.custom(FontFamily.Rubik.medium, size: 15))
                .foregroundColor(.primary)

            // Exchange rate display
            Text("1 \(record.fromCurrency) = \(formatExchangeRate(exchangeRate)) \(record.toCurrency)")
                .font(.custom(FontFamily.Rubik.regular, size: 13))
                .foregroundColor(Color("NormaPastelTeal"))

            // Timestamp
            Text(relativeTime(for: record.timestamp))
                .font(.custom(FontFamily.Rubik.regular, size: 11))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.gray.opacity(0.05))
                .glassEffect(in: RoundedRectangle(cornerRadius: 14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.12), lineWidth: 0.5)
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

    private func performConversion() {
        guard let inputAmount = Double(amount),
              let fromRate = exchangeRates[fromCurrency],
              let toRate = exchangeRates[toCurrency],
              inputAmount > 0 else { return }

        let impactMedium = UIImpactFeedbackGenerator(style: .medium)
        impactMedium.impactOccurred()

        // Convert to USD first, then to target currency
        let inUSD = inputAmount / fromRate
        let converted = inUSD * toRate

        // Add to history
        let record = ConversionRecord(
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            fromAmount: inputAmount,
            toAmount: converted,
            timestamp: Date()
        )

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            convertedAmount = converted
            hasConverted = true
            hasPendingConversion = false
            conversionHistory.insert(record, at: 0)

            // Remove oldest if over max
            if conversionHistory.count > maxHistoryItems {
                conversionHistory.removeLast()
            }
        }
    }

    private func generateInsights() {
        let impactLight = UIImpactFeedbackGenerator(style: .light)
        impactLight.impactOccurred()

        guard let inputAmount = Double(amount),
              let converted = convertedAmount,
              let exchangeRate = currentExchangeRate else { return }

        // Clear previous state and start loading
        withAnimation(.easeInOut(duration: 0.2)) {
            isGeneratingInsight = true
            insightError = nil
        }

        Task {
            do {
                // Get user's home currency (default to USD)
                let userHomeCurrency = sessionViewModel.currentUser?.settings.currency ?? "USD"

                // Build the prompt
                let systemPrompt = NormaSystemPrompts.purchasingPowerPrompt(
                    fromCurrency: fromCurrency,
                    toCurrency: toCurrency,
                    fromAmount: inputAmount,
                    toAmount: converted,
                    exchangeRate: exchangeRate,
                    userHomeCurrency: userHomeCurrency
                )

                // Call the API
                let messages = [AnthropicMessage(role: "user", content: .text("Generate my purchasing power insight."))]
                let response = try await AnthropicService.shared.sendMessage(
                    messages: messages,
                    systemPrompt: systemPrompt,
                    maxTokens: 250
                )

                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        purchasingPowerInsight = response.trimmingCharacters(in: .whitespacesAndNewlines)
                        insightGeneratedAt = Date()
                        insightFromCurrency = fromCurrency
                        insightToCurrency = toCurrency
                        isGeneratingInsight = false
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        insightError = "Unable to generate insight. Please try again."
                        isGeneratingInsight = false
                    }
                }
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
        default: return "💱"
        }
    }

    private func relativeTime(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        CurrencyConverterView(isMenuOpen: .constant(false))
            .environmentObject(SessionViewModel(dataManager: DataManager()))
    }
}
