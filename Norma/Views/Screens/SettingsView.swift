//
//  SettingsView.swift
//  Norma
//
//  Income, currency, accent color, support links, and the reset. Presented
//  as a sheet from the home gear.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppTheme.storageKey) private var selectedAccentThemeID = AppTheme.defaultID

    @State private var showIncomeEditor = false
    @State private var showResetAlert = false
    @State private var webPage: WebPage?

    private struct WebPage: Identifiable {
        let title: String
        let url: String
        var id: String { url }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    HeroTitle(text: "settings")

                    section("money") {
                        row(icon: "banknote", title: "income", detail: incomeSummary) { showIncomeEditor = true }
                        currencyRow
                    }

                    section("look") {
                        themeRow
                    }

                    section("support") {
                        row(icon: "questionmark.circle", title: "help & feedback") {
                            webPage = WebPage(title: "Help & Feedback", url: "https://norma-app.userjot.com")
                        }
                        row(icon: "lock.shield", title: "privacy policy") {
                            webPage = WebPage(title: "Privacy Policy", url: "https://mauldin.xyz/norma/privacy")
                        }
                    }

                    section("your data", tint: NormaPalette.danger.opacity(0.9)) {
                        Text("no account and no servers. your bills and income live only on this iphone.")
                            .font(.custom(FontFamily.Rubik.regular, size: 13).italic())
                            .foregroundStyle(NormaPalette.inkMuted)
                            .padding(.vertical, 8)
                        Button {
                            Haptics.firm()
                            showResetAlert = true
                        } label: {
                            rowLabel(icon: "trash", title: "reset all data", tint: NormaPalette.danger, showsChevron: false)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("norma \(appVersion)")
                        .font(.custom(FontFamily.Rubik.medium, size: 12))
                        .foregroundStyle(NormaPalette.inkMuted)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(NormaPalette.sheet.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(NormaPalette.ink.opacity(0.85))
                }
            }
        }
        .sheet(isPresented: $showIncomeEditor) { IncomeEditSheet() }
        .sheet(item: $webPage) { WebViewSheet(url: $0.url, title: $0.title) }
        .alert("reset all data?", isPresented: $showResetAlert) {
            Button("cancel", role: .cancel) {}
            Button("reset", role: .destructive, action: reset)
        } message: {
            Text("every bill and your income will be erased from this iphone. there's no backup, so this can't be undone.")
        }
    }

    // MARK: - Rows

    private var incomeSummary: String {
        guard profile.hasIncome else { return "add your income" }
        return "\(Money.format(profile.incomeAmount, currency: profile.currency)) · \(profile.incomeCadence.label)"
    }

    private var currencyRow: some View {
        Menu {
            Picker("currency", selection: Binding(
                get: { profile.currency },
                set: { newValue in
                    profile.currency = newValue
                    try? modelContext.save()
                }
            )) {
                ForEach(Money.currencies) { entry in
                    Text("\(entry.flag) \(entry.code)").tag(entry.code)
                }
            }
        } label: {
            rowLabel(icon: "dollarsign.circle", title: "currency", detail: "\(Money.flag(for: profile.currency)) \(profile.currency)")
        }
        .buttonStyle(.plain)
    }

    private var themeRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: "paintpalette")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(NormaPalette.lavender)
                    .frame(width: 22, alignment: .leading)
                Text("accent color")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundStyle(NormaPalette.ink)
            }
            HStack(spacing: 14) {
                ForEach(AppTheme.presets) { theme in
                    themeSwatch(theme)
                }
            }
            .padding(.leading, 36)
        }
        .padding(.vertical, 12)
    }

    private func themeSwatch(_ theme: AccentTheme) -> some View {
        let isSelected = selectedAccentThemeID == theme.id
        return Button {
            Haptics.tap()
            withAnimation(.easeOut(duration: 0.18)) { selectedAccentThemeID = theme.id }
        } label: {
            ZStack {
                Circle().fill(theme.color)
                Circle().strokeBorder(
                    isSelected ? NormaPalette.ink.opacity(0.9) : NormaPalette.inkMuted.opacity(0.4),
                    style: isSelected ? StrokeStyle(lineWidth: 2) : StrokeStyle(lineWidth: 1, dash: [4, 3])
                )
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(NormaPalette.onAccent)
                }
            }
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(theme.name)
    }

    // MARK: - Building blocks

    private func section<Content: View>(_ title: String, tint: Color = NormaPalette.ink, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            FieldLabel(title, color: tint)
                .padding(.bottom, 4)
            content()
        }
    }

    private func row(icon: String, title: String, detail: String? = nil, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            rowLabel(icon: icon, title: title, detail: detail)
        }
        .buttonStyle(.plain)
    }

    private func rowLabel(icon: String, title: String, detail: String? = nil, tint: Color? = nil, showsChevron: Bool = true) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(tint ?? NormaPalette.lavender)
                .frame(width: 22, alignment: .leading)
            Text(title)
                .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                .foregroundStyle(tint ?? NormaPalette.ink)
            Spacer(minLength: 8)
            if let detail {
                Text(detail)
                    .font(.custom(FontFamily.Rubik.regular, size: 13))
                    .foregroundStyle(NormaPalette.inkSubtle)
                    .lineLimit(1)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NormaPalette.inkMuted)
            }
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    // MARK: - Actions

    private func reset() {
        dismiss()
        do {
            try LocalDataReset.wipeAll(in: modelContext)
        } catch {
            assertionFailure("Reset failed: \(error)")
        }
    }
}
