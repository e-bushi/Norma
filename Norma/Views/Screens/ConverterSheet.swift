//
//  ConverterSheet.swift
//  Norma
//
//  D8 — Currency converter sheet. Live rates fetched once per (source, target)
//  pair via CurrencyConversionService and cached for 30 min so each keystroke
//  re-renders locally instead of round-tripping. Source currency and the list
//  of target currencies are user-editable and persisted via @AppStorage,
//  intentionally separate from Profile.UserSettings.currency.
//

import SwiftUI

struct ConverterSheet: View {
    @AppStorage("converter.source") private var sourceCode: String = "USD"
    @AppStorage("converter.targets") private var targetsRaw: String = "EUR,JPY,GBP,MXN"

    @State private var amountText: String = "100"
    @State private var rates: [String: CachedRate] = [:]
    @State private var loading: Set<String> = []
    @State private var lastError: String?
    @State private var showSourcePicker = false
    @State private var showAddPicker = false
    @FocusState private var amountFocused: Bool

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cardBg = Color(red: 0x1C/255, green: 0x1C/255, blue: 0x20/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private let accentPurple = Color(red: 0x96/255, green: 0x76/255, blue: 0xD9/255)
    private let danger = Color(red: 0xE0/255, green: 0x7B/255, blue: 0x6F/255)

    private struct CachedRate {
        let rate: Double
        let fetchedAt: Date
    }

    /// Rates are cached for 30 minutes — re-fetched lazily after that.
    private static let cacheTTL: TimeInterval = 30 * 60

    var body: some View {
        VStack(spacing: 0) {
            dragHandle

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroBlock
                        .padding(.horizontal, 24)

                    conversionList
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    addCurrencyPill
                        .padding(.top, 18)
                        .padding(.bottom, 32)
                }
            }
        }
        .background(bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task {
            // Refresh stale rates on appear; fetch missing ones.
            for code in targets where freshRate(for: code) == nil {
                fetchRate(for: code)
            }
        }
        .sheet(isPresented: $showSourcePicker) {
            CurrencyPickerSheet(
                title: "main currency",
                exclude: [],
                onSelect: { setSource($0) }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showAddPicker) {
            CurrencyPickerSheet(
                title: "add currency",
                exclude: Set(targets + [sourceCode]),
                onSelect: { addTarget($0) }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Drag handle

    private var dragHandle: some View {
        Capsule()
            .fill(cream.opacity(0.2))
            .frame(width: 36, height: 4)
            .padding(.top, 6)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("convert")
                .font(.custom(FontFamily.Rubik.medium, size: 13))
                .foregroundStyle(mutedText)

            sourceCapsule

            HStack(alignment: .center, spacing: 6) {
                TextField("0", text: $amountText)
                    .font(.system(size: 72, weight: .heavy))
                    .tracking(-2.88)
                    .monospacedDigit()
                    .foregroundStyle(cream)
                    .tint(accentPurple)
                    .keyboardType(.decimalPad)
                    .focused($amountFocused)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 72)

            HStack(spacing: 8) {
                Circle()
                    .fill(lastError == nil ? accentPurple : danger)
                    .frame(width: 6, height: 6)
                Text(statusLine)
                    .font(.custom(FontFamily.Rubik.medium, size: 11))
                    .tracking(0.44)
                    .textCase(.uppercase)
                    .foregroundStyle(mutedText)
            }
            .padding(.top, 4)
        }
    }

    private var sourceCapsule: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            showSourcePicker = true
        } label: {
            HStack(spacing: 8) {
                Text(flag(for: sourceCode))
                    .font(.system(size: 16))
                Text(sourceCode)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 12))
                    .tracking(0.48)
                    .foregroundStyle(cream)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(cream.opacity(0.7))
            }
            .padding(.leading, 8)
            .padding(.trailing, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(accentPurple.opacity(0.08)))
            .overlay(Capsule().stroke(accentPurple.opacity(0.4), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Conversion list

    private var conversionList: some View {
        VStack(spacing: 0) {
            if targets.isEmpty {
                Text("add a currency to start converting.")
                    .font(.custom(FontFamily.Rubik.regular, size: 13).italic())
                    .foregroundStyle(dimText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 28)
            } else {
                ForEach(targets, id: \.self) { code in
                    conversionRow(code)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, targets.isEmpty ? 0 : 18)
        .padding(.bottom, targets.isEmpty ? 0 : 4)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(cream.opacity(0.04), lineWidth: 1))
    }

    @ViewBuilder
    private func conversionRow(_ code: String) -> some View {
        let info = CurrencyData.getCurrency(for: code)
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(cream.opacity(0.06))
                Text(flag(for: code))
                    .font(.system(size: 18))
            }
            .frame(width: 32, height: 32)
            .overlay(Circle().stroke(cream.opacity(0.06), lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text(code)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 13))
                    .tracking(0.52)
                    .foregroundStyle(cream)
                Text(info.name.lowercased())
                    .font(.custom(FontFamily.Rubik.regular, size: 11))
                    .foregroundStyle(dimText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            convertedValueText(for: code, symbol: info.symbol)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                removeTarget(code)
            } label: {
                Label("remove", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private func convertedValueText(for code: String, symbol: String) -> some View {
        if let rate = freshRate(for: code) {
            Text(formatted(amountValue * rate, symbol: symbol, decimals: decimals(for: code)))
                .font(.system(size: 22, weight: .semibold))
                .tracking(-0.44)
                .monospacedDigit()
                .foregroundStyle(cream)
        } else if loading.contains(code) {
            Text("…")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(dimText)
        } else {
            Button {
                fetchRate(for: code)
            } label: {
                Text("retry")
                    .font(.custom(FontFamily.Rubik.medium, size: 12))
                    .foregroundStyle(accentPurple)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Add currency pill

    private var addCurrencyPill: some View {
        HStack {
            Spacer()
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                showAddPicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(cream.opacity(0.85))
                    Text("add currency")
                        .font(.custom(FontFamily.Rubik.medium, size: 12))
                        .foregroundStyle(cream)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .overlay(
                    Capsule().stroke(cream.opacity(0.32), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                )
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: - Status line

    private var statusLine: String {
        if let lastError, rates.isEmpty {
            return "rates unavailable · \(lastError.lowercased())"
        }
        guard let mostRecent = rates.values.map(\.fetchedAt).max() else {
            return "fetching rates…"
        }
        let secs = Int(Date().timeIntervalSince(mostRecent))
        if secs < 60 { return "live · just now" }
        let mins = secs / 60
        return "live · refreshed \(mins)m ago"
    }

    // MARK: - State helpers

    private var targets: [String] {
        targetsRaw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
            .filter { !$0.isEmpty }
    }

    private var amountValue: Double {
        Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private func freshRate(for code: String) -> Double? {
        guard let cached = rates[code],
              Date().timeIntervalSince(cached.fetchedAt) < Self.cacheTTL
        else { return nil }
        return cached.rate
    }

    private func decimals(for code: String) -> Int {
        // Currencies traditionally rendered without minor units.
        let zeroDecimal: Set<String> = ["JPY", "KRW", "VND", "CLP", "ISK", "HUF", "IDR"]
        return zeroDecimal.contains(code) ? 0 : 2
    }

    private func formatted(_ value: Double, symbol: String, decimals: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = decimals
        f.minimumFractionDigits = decimals
        let num = f.string(from: NSNumber(value: value)) ?? String(value)
        return "\(symbol)\(num)"
    }

    // MARK: - Mutations

    private func setSource(_ code: String) {
        guard code != sourceCode else { return }
        sourceCode = code
        rates.removeAll()
        // If the user just promoted one of their target currencies to source,
        // drop it from the target list so they don't see X→X = same number.
        if targets.contains(code) {
            targetsRaw = targets.filter { $0 != code }.joined(separator: ",")
        }
        for c in targets { fetchRate(for: c) }
    }

    private func addTarget(_ code: String) {
        guard !targets.contains(code), code != sourceCode else { return }
        let next = targets + [code]
        targetsRaw = next.joined(separator: ",")
        fetchRate(for: code)
    }

    private func removeTarget(_ code: String) {
        let next = targets.filter { $0 != code }
        targetsRaw = next.joined(separator: ",")
        rates.removeValue(forKey: code)
    }

    // MARK: - Network

    private func fetchRate(for code: String) {
        guard !loading.contains(code) else { return }
        loading.insert(code)
        let from = sourceCode
        Task {
            do {
                let resp = try await CurrencyConversionService.shared.convert(
                    amount: 1,
                    from: from,
                    to: code
                )
                await MainActor.run {
                    // Guard against stale callbacks if the user changed source mid-flight.
                    if from == sourceCode {
                        rates[code] = CachedRate(rate: resp.exchangeRate, fetchedAt: Date())
                        lastError = nil
                    }
                    loading.remove(code)
                }
            } catch {
                await MainActor.run {
                    loading.remove(code)
                    lastError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Flag derivation

    /// Map an ISO 4217 currency code to a flag emoji. Most codes share the
    /// first two letters with their ISO 3166 country code, which we convert
    /// to a flag via regional indicator math. Special cases handled inline.
    private func flag(for code: String) -> String {
        let specials: [String: String] = [
            "EUR": "🇪🇺",
            "USD": "🇺🇸",
            "GBP": "🇬🇧",
            "JPY": "🇯🇵",
            "CHF": "🇨🇭",
            "CNY": "🇨🇳",
            "DKK": "🇩🇰",
            "NOK": "🇳🇴",
            "SEK": "🇸🇪",
            "AED": "🇦🇪",
            "SAR": "🇸🇦",
            "KWD": "🇰🇼",
            "ILS": "🇮🇱",
            "INR": "🇮🇳",
            "KRW": "🇰🇷",
            "VND": "🇻🇳",
            "PHP": "🇵🇭",
            "IDR": "🇮🇩",
            "ANG": "🇨🇼",
            "XAF": "🌍",
            "XOF": "🌍",
            "XCD": "🌎"
        ]
        if let s = specials[code] { return s }
        let countryCode = String(code.prefix(2)).uppercased()
        var flag = ""
        for scalar in countryCode.unicodeScalars {
            if let s = UnicodeScalar(127397 + Int(scalar.value)) {
                flag.append(String(s))
            }
        }
        return flag.isEmpty ? "🏳️" : flag
    }
}

// MARK: - Currency picker

struct CurrencyPickerSheet: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss
    let title: String
    let exclude: Set<String>
    let onSelect: (String) -> Void

    @State private var query: String = ""
    @FocusState private var searchFocused: Bool

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cardBg = Color(red: 0x1C/255, green: 0x1C/255, blue: 0x20/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private let accentPurple = Color(red: 0x96/255, green: 0x76/255, blue: 0xD9/255)

    private var heroFont: Font { .system(size: 56, weight: .heavy) }

    private var filtered: [Currency] {
        let all = CurrencyData.currencies.values
            .filter { !exclude.contains($0.code) }
            .sorted { $0.code < $1.code }
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return all }
        let q = query.lowercased()
        return all.filter {
            $0.code.lowercased().contains(q) || $0.name.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            dragHandle

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroBlock
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)

                    searchField
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)

                    listBody
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                }
            }
        }
        .background(bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var dragHandle: some View {
        Capsule()
            .fill(cream.opacity(0.2))
            .frame(width: 36, height: 4)
            .padding(.top, 6)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity)
    }

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("converter")
                .font(.custom(FontFamily.Rubik.medium, size: 13))
                .foregroundStyle(mutedText)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(title)
                    .font(heroFont)
                    .tracking(-2.24)
                    .foregroundStyle(cream)
                Text(".")
                    .font(heroFont)
                    .tracking(-2.24)
                    .foregroundStyle(accentPurple)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(mutedText)
            TextField("", text: $query, prompt: Text("search by code or name").foregroundColor(dimText))
                .font(.custom(FontFamily.Rubik.medium, size: 14))
                .foregroundStyle(cream)
                .tint(accentPurple)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($searchFocused)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(dimText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Capsule().fill(cardBg))
        .overlay(Capsule().stroke(cream.opacity(0.06), lineWidth: 1))
    }

    @ViewBuilder
    private var listBody: some View {
        if filtered.isEmpty {
            Text("no matches.")
                .font(.custom(FontFamily.Rubik.regular, size: 13).italic())
                .foregroundStyle(dimText)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 28)
        } else {
            VStack(spacing: 0) {
                ForEach(filtered, id: \.code) { currency in
                    pickerRow(currency)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(cream.opacity(0.04), lineWidth: 1))
        }
    }

    @ViewBuilder
    private func pickerRow(_ currency: Currency) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onSelect(currency.code)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(cream.opacity(0.06))
                    Text(flag(for: currency.code))
                        .font(.system(size: 18))
                }
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(cream.opacity(0.06), lineWidth: 1))

                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.code)
                        .font(.custom(FontFamily.Rubik.semiBold, size: 13))
                        .tracking(0.52)
                        .foregroundStyle(cream)
                    Text(currency.name.lowercased())
                        .font(.custom(FontFamily.Rubik.regular, size: 11))
                        .foregroundStyle(dimText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(currency.symbol)
                    .font(.custom(FontFamily.Rubik.medium, size: 13))
                    .foregroundStyle(mutedText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func flag(for code: String) -> String {
        let specials: [String: String] = [
            "EUR": "🇪🇺", "USD": "🇺🇸", "GBP": "🇬🇧", "JPY": "🇯🇵", "CHF": "🇨🇭",
            "CNY": "🇨🇳", "DKK": "🇩🇰", "NOK": "🇳🇴", "SEK": "🇸🇪", "AED": "🇦🇪",
            "SAR": "🇸🇦", "KWD": "🇰🇼", "ILS": "🇮🇱", "INR": "🇮🇳", "KRW": "🇰🇷",
            "VND": "🇻🇳", "PHP": "🇵🇭", "IDR": "🇮🇩", "ANG": "🇨🇼",
            "XAF": "🌍", "XOF": "🌍", "XCD": "🌎"
        ]
        if let s = specials[code] { return s }
        let countryCode = String(code.prefix(2)).uppercased()
        var flag = ""
        for scalar in countryCode.unicodeScalars {
            if let s = UnicodeScalar(127397 + Int(scalar.value)) {
                flag.append(String(s))
            }
        }
        return flag.isEmpty ? "🏳️" : flag
    }
}

#Preview {
    Color.black
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ConverterSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
}
