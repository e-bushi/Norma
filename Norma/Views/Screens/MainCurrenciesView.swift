//
//  MainCurrenciesView.swift
//  Norma
//
//  Created by Claude on 12/12/25.
//

import SwiftUI

struct MainCurrenciesView: View {
    @Binding var selectedCurrencies: [String]
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    // Selection mode state
    @State private var isSelectionMode: Bool = false
    @State private var currencyToReplace: String? = nil
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool

    private let maxResults = 10

    private var filteredCurrencies: [Currency] {
        CurrencyData.allCurrencies
            .filter { !selectedCurrencies.contains($0.code) }
            .filter { searchText.isEmpty ||
                      $0.name.localizedCaseInsensitiveContains(searchText) ||
                      $0.code.localizedCaseInsensitiveContains(searchText) }
            .prefix(maxResults)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if isSelectionMode {
                        // MARK: - Selection Mode UI
                        selectionModeContent
                    } else {
                        // MARK: - Default List View
                        defaultListContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Color("NormaBackground"))
            .navigationTitle(isSelectionMode ? "Select Currency" : "Main Currencies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isSelectionMode {
                        Button("Cancel") {
                            cancelSelection()
                        }
                        .font(.custom(FontFamily.Rubik.regular, size: 16))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if !isSelectionMode {
                        Button("Done") {
                            dismiss()
                        }
                        .font(.custom(FontFamily.Rubik.medium, size: 16))
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelectionMode)
        }
    }

    // MARK: - Default List Content

    @ViewBuilder
    private var defaultListContent: some View {
        // Explanation text
        Text("Tap a currency to swap it for another")
            .font(.custom(FontFamily.Rubik.regular, size: 14))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)

        // Currency list card
        VStack(spacing: 0) {
            ForEach(Array(selectedCurrencies.enumerated()), id: \.element) { index, code in
                currencyRow(code: code, isLast: index == selectedCurrencies.count - 1)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("NormaBackground"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Selection Mode Content

    @ViewBuilder
    private var selectionModeContent: some View {
        VStack(spacing: 20) {
            // Header showing currency being replaced
            if let code = currencyToReplace {
                replacingHeader(code: code)
            }

            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                TextField("Search currencies", text: $searchText)
                    .font(.custom(FontFamily.Rubik.regular, size: 16))
                    .focused($isSearchFocused)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )

            // Filtered results
            if filteredCurrencies.isEmpty {
                emptyResultsView
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredCurrencies.enumerated()), id: \.element.code) { index, currency in
                        selectableCurrencyRow(currency: currency, isLast: index == filteredCurrencies.count - 1)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("NormaBackground"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
        }
    }

    // MARK: - Replacing Header

    @ViewBuilder
    private func replacingHeader(code: String) -> some View {
        let currency = CurrencyData.getCurrency(for: code)

        HStack(spacing: 12) {
            Text(flagEmoji(for: code))
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 2) {
                Text("Replacing")
                    .font(.custom(FontFamily.Rubik.regular, size: 12))
                    .foregroundColor(.secondary)
                Text("\(code) - \(currency.name)")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("NormaPastelTeal").opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("NormaPastelTeal").opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Empty Results View

    @ViewBuilder
    private var emptyResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No currencies found")
                .font(.custom(FontFamily.Rubik.medium, size: 14))
                .foregroundColor(.secondary)

            Text("Try a different search term")
                .font(.custom(FontFamily.Rubik.regular, size: 13))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Currency Row (Default List)

    @ViewBuilder
    private func currencyRow(code: String, isLast: Bool) -> some View {
        let currency = CurrencyData.getCurrency(for: code)

        Button {
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()
            enterSelectionMode(for: code)
        } label: {
            HStack(spacing: 12) {
                Text(flagEmoji(for: code))
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 2) {
                    Text(code)
                        .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                        .foregroundColor(.primary)
                    Text(currency.name)
                        .font(.custom(FontFamily.Rubik.regular, size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        if !isLast {
            Divider()
                .padding(.leading, 52)
        }
    }

    // MARK: - Selectable Currency Row (Selection Mode)

    @ViewBuilder
    private func selectableCurrencyRow(currency: Currency, isLast: Bool) -> some View {
        Button {
            let impactMedium = UIImpactFeedbackGenerator(style: .medium)
            impactMedium.impactOccurred()
            selectCurrency(currency.code)
        } label: {
            HStack(spacing: 12) {
                Text(flagEmoji(for: currency.code))
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.code)
                        .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                        .foregroundColor(.primary)
                    Text(currency.name)
                        .font(.custom(FontFamily.Rubik.regular, size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(currency.symbol)
                    .font(.custom(FontFamily.Rubik.medium, size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        if !isLast {
            Divider()
                .padding(.leading, 52)
        }
    }

    // MARK: - Actions

    private func enterSelectionMode(for code: String) {
        currencyToReplace = code
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isSelectionMode = true
        }
    }

    private func cancelSelection() {
        isSearchFocused = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isSelectionMode = false
            currencyToReplace = nil
            searchText = ""
        }
    }

    private func selectCurrency(_ newCode: String) {
        guard let oldCode = currencyToReplace,
              let index = selectedCurrencies.firstIndex(of: oldCode) else { return }

        isSearchFocused = false

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedCurrencies[index] = newCode
            isSelectionMode = false
            currencyToReplace = nil
            searchText = ""
        }

        onSave()
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
}

#Preview {
    MainCurrenciesView(
        selectedCurrencies: .constant(["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "MXN", "BRL"]),
        onSave: {}
    )
}
