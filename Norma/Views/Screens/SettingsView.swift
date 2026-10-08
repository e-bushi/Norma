//
//  SettingsView.swift
//  Norma
//
//  Settings sheet — matches the dark editorial language of D10/Forecast.
//  Sectioned list (profile / preferences / support / data) with the
//  destructive reset in coral. Presented as a sheet from the home gear.
//

import SwiftUI
import SwiftData
import UIKit
import LinkKit

struct SettingsView: View {
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appCoordinator: AppCoordinator
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @SwiftUI.Environment(\.dismiss) private var dismiss

    @StateObject private var plaidService = PlaidService.shared
    @State private var showResetAlert = false
    @State private var showTermsOfUse = false
    @State private var showPrivacyPolicy = false
    @State private var showHelpSupport = false
    @State private var showNormaKnowsEdit = false
    @State private var showNameEdit = false
    @State private var showIncomeEditor = false

    #if DEBUG
    @State private var showFundResetConfirmation = false
    #endif

    // UserProfile
    @Query private var userProfiles: [UserProfile]
    private var userProfile: UserProfile? { userProfiles.first }

    // Preferences — the in-note extraction haptic plays while norma is
    // "thinking" on a note. Some users find the continuous buzz distracting,
    // so it can be turned off here. Read by NoteCanvasView via the same key.
    @AppStorage("extractionHapticsEnabled") private var extractionHapticsEnabled = true

    // Accent theme — the app's purplish color, user-selectable. The dark
    // background/canvas stays static; this only swaps NormaPalette.lavender,
    // which every purple-tinted view already reads from.
    @AppStorage(AppTheme.storageKey) private var selectedAccentThemeID = AppTheme.defaultID

    // Plaid state
    @State private var isLoadingLinkToken = false
    @State private var isExchangingToken = false
    @State private var plaidHandler: Handler?
    @State private var showPlaidError = false
    @State private var plaidErrorMessage = ""
    @State private var showDisconnectConfirmation = false
    @State private var isInstitutionExpanded = false

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private let onAccentText = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255)
    private var accentPurple: Color { NormaPalette.lavender }
    private let danger = Color(red: 0xE0/255, green: 0x7B/255, blue: 0x6F/255)

    private var heroFont: Font { .system(size: 56, weight: .heavy) }

    var body: some View {
        settingsContent
        .sheet(isPresented: $showIncomeEditor) {
            IncomeEditSheet()
                .environmentObject(sessionViewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showNormaKnowsEdit) {
            NormaKnowsEditSheet(profile: userProfile)
        }
        .sheet(isPresented: $showNameEdit) {
            ProfileSignupInfoSheet()
                .environmentObject(sessionViewModel)
        }
    }

    private var settingsContent: some View {
        VStack(spacing: 0) {
            navBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroBlock
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                    profileSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)

                    bankingSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)

                    normaKnowsSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)

                    preferencesSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)

                    supportSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)

                    dataSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                    #if DEBUG
                    debugSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    #endif
                }
            }
        }
        .background(bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .alert("Reset all data?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                dismiss()
                appCoordinator.resetAllData()
            }
        } message: {
            Text("Your balance, bills, history, and everything norma knows will be erased from this iPhone. There's no backup, so this can't be undone.")
        }
        #if DEBUG
        .alert("Balance reset", isPresented: $showFundResetConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Balance, linked account, and local ledger cleared. Reopen the runway view to see the first-time state.")
        }
        #endif
        .sheet(isPresented: $showTermsOfUse) {
            WebViewSheet(url: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/", title: "Terms of Use")
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            WebViewSheet(url: "https://mauldin.xyz/norma/privacy", title: "Privacy Policy")
        }
        .sheet(isPresented: $showHelpSupport) {
            WebViewSheet(url: "https://norma-app.userjot.com", title: "Help & Support")
        }
        .alert("Connection Error", isPresented: $showPlaidError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(plaidErrorMessage)
        }
        .alert("Disconnect Bank", isPresented: $showDisconnectConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect", role: .destructive) { disconnectBank() }
        } message: {
            Text("Disconnect \(plaidService.institutionName ?? "your bank")? Your existing data will be kept.")
        }
    }

    // MARK: - Nav

    private var navBar: some View {
        HStack {
            Spacer()
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(cream.opacity(0.85))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("account")
                .font(.custom(FontFamily.Rubik.medium, size: 13))
                .foregroundStyle(mutedText)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("settings")
                    .font(heroFont)
                    .tracking(-2.24)
                    .foregroundStyle(cream)
                Text(".")
                    .font(heroFont)
                    .tracking(-2.24)
                    .foregroundStyle(accentPurple)
            }
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        section(title: "profile") {
            let trimmedName = (sessionViewModel.currentUser?.name ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedName.isEmpty {
                listRow(
                    icon: "person.crop.circle.badge.questionmark",
                    iconColor: accentPurple,
                    primary: "what should norma call you?",
                    trailingLabel: "add",
                    showChevron: false,
                    action: { showNameEdit = true }
                )
            } else {
                listRow(
                    icon: "person.crop.circle",
                    iconColor: accentPurple,
                    primary: trimmedName.lowercased(),
                    showChevron: true,
                    action: { showNameEdit = true }
                )
            }

            listRow(
                icon: "banknote",
                iconColor: accentPurple,
                primary: "income",
                secondary: incomeRowSummary,
                showChevron: true,
                action: { showIncomeEditor = true }
            )
        }
    }

    /// Per-paycheck amount + cadence for the profile income row.
    private var incomeRowSummary: String {
        guard let profile = userProfile,
              let amount = profile.incomeAmount, amount > 0,
              let cadence = profile.incomeCadence else {
            return "add your income"
        }
        let currency = sessionViewModel.currentUser?.settings.currency ?? profile.currency
        return "\(formatBalance(amount, currency: currency)) · \(cadence.label)"
    }

    @ViewBuilder
    private var bankingSection: some View {
        // Whole section disappears while Plaid is dormant — this is the only
        // entry point into the Link flow, so hiding it stops new connections.
        if FeatureFlags.plaidEnabled {
            bankingSectionContent
        }
    }

    @ViewBuilder
    private var bankingSectionContent: some View {
        section(title: "banking") {
            if !plaidService.connectedAccounts.isEmpty {
                connectedBankRow
                if isInstitutionExpanded {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(plaidService.connectedAccounts) { account in
                            accountRow(account: account)
                        }
                        destructiveRow(icon: "link.badge.plus", title: "disconnect bank") {
                            showDisconnectConfirmation = true
                        }
                    }
                    .padding(.leading, 36)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Always-visible affordance to add another institution.
                tappableRow(
                    icon: isLoadingLinkToken ? "ellipsis" : "plus",
                    title: isLoadingLinkToken ? "preparing link…" : "connect another bank",
                    action: { if !isLoadingLinkToken { connectBank() } }
                )
            } else if isExchangingToken {
                connectingBankRow
            } else {
                listRow(
                    icon: "building.columns",
                    iconColor: accentPurple,
                    primary: "connect your bank",
                    secondary: "u.s. only · for savings tracking",
                    trailingLabel: isLoadingLinkToken ? nil : "connect",
                    showChevron: false,
                    action: isLoadingLinkToken ? nil : { connectBank() }
                )
                if isLoadingLinkToken {
                    HStack(spacing: 10) {
                        ProgressView().tint(accentPurple)
                        Text("preparing link…")
                            .font(.custom(FontFamily.Rubik.regular, size: 12).italic())
                            .foregroundStyle(mutedText)
                    }
                    .padding(.leading, 36)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private var connectedBankRow: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isInstitutionExpanded.toggle()
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accentPurple)
                    .frame(width: 22, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text((plaidService.institutionName ?? "bank").lowercased())
                        .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                        .foregroundStyle(cream)
                    Text(formatBalance(totalFunds, currency: plaidService.connectedAccounts.first?.balances.isoCurrencyCode ?? "USD"))
                        .font(.custom(FontFamily.Rubik.regular, size: 12))
                        .foregroundStyle(mutedText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(dimText)
                    .rotationEffect(.degrees(isInstitutionExpanded ? 90 : 0))
                    .frame(width: 16, alignment: .trailing)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var connectingBankRow: some View {
        HStack(spacing: 14) {
            ProgressView()
                .tint(accentPurple)
                .frame(width: 22, alignment: .leading)
            Text("connecting account…")
                .font(.custom(FontFamily.Rubik.medium, size: 15))
                .foregroundStyle(cream)
            Spacer()
        }
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func accountRow(account: PlaidService.PlaidAccount) -> some View {
        HStack(spacing: 12) {
            Text(account.name.lowercased())
                .font(.custom(FontFamily.Rubik.regular, size: 13))
                .foregroundStyle(cream)
                .lineLimit(1)
                .truncationMode(.tail)
            if let mask = account.mask {
                Text("··\(mask)")
                    .font(.custom(FontFamily.Rubik.regular, size: 11))
                    .foregroundStyle(mutedText)
            }
            Spacer(minLength: 8)
            if let current = account.balances.current {
                Text(formatBalance(current, currency: account.balances.isoCurrencyCode ?? "USD"))
                    .font(.custom(FontFamily.Rubik.medium, size: 12))
                    .foregroundStyle(mutedText)
            }
        }
        .padding(.vertical, 8)
    }

    private var totalFunds: Double {
        plaidService.connectedAccounts.compactMap { $0.balances.current }.reduce(0, +)
    }

    private func formatBalance(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }

    // MARK: - What Norma Knows

    @ViewBuilder
    private var normaKnowsSection: some View {
        section(title: "what norma knows") {
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                showNormaKnowsEdit = true
            } label: {
                normaKnowsProse
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    /// Third-person summary read back from the user's UserProfile. Voice is
    /// intentionally observational ("they use USD") to match the section
    /// title — these are facts *norma* has learned, not first-person notes.
    private var normaKnowsProse: some View {
        let profile = userProfile
        // Income and currency are canonical on the server profile — the
        // forecast, arc, and chat all read/write settings.monthlyIncome.
        // The local UserProfile mirror is only a fallback so the prose
        // still renders in signed-out/preview contexts.
        let settings = sessionViewModel.currentUser?.settings
        let currency = (settings?.currency ?? profile?.currency ?? "USD").lowercased()
        let incomeText: String = {
            let serverAmount = settings?.monthlyIncome ?? 0
            let amount = serverAmount > 0 ? serverAmount : (profile?.incomeAmount ?? 0)
            guard amount > 0 else { return "—" }
            return formatBalance(amount, currency: currency.uppercased())
        }()
        let payDescription: String = {
            guard let cadence = profile?.incomeCadence else { return "—" }
            switch cadence {
            case .weekly:                 return "weekly"
            case .biweekly:               return "every 2 weeks"
            case .semiMonthly(let a, let b):
                let bLabel = b >= 29 ? "last day" : "the \(b)th"
                return "on the \(a)th & \(bLabel)"
            case .monthly(let day):       return "monthly on day \(day)"
            case .irregular:              return "when it comes"
            }
        }()
        let runwayText: String = {
            guard let floor = profile?.runwayFloor else { return "—" }
            let unit = floor == 1.0 ? "month" : "months"
            return "\(String(format: "%g", floor)) \(unit)"
        }()

        return (
            Text("you think in ")
                .foregroundStyle(mutedText)
            + Text(currency).foregroundStyle(cream)
            + Text(". you bring in about ")
                .foregroundStyle(mutedText)
            + Text(incomeText).foregroundStyle(cream)
            + Text(", paid ")
                .foregroundStyle(mutedText)
            + Text(payDescription).foregroundStyle(cream)
            + Text(". your runway floor is ")
                .foregroundStyle(mutedText)
            + Text(runwayText).foregroundStyle(cream)
            + Text(". ")
                .foregroundStyle(mutedText)
            + Text("tap to edit")
                .foregroundStyle(accentPurple)
        )
        .font(.custom(FontFamily.Rubik.regular, size: 15).italic())
        .lineSpacing(4)
    }

    @ViewBuilder
    private func knowledgeRow(label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(accentPurple)
                .frame(width: 22, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.custom(FontFamily.Rubik.regular, size: 12))
                    .foregroundStyle(mutedText)
                Text(value)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                    .foregroundStyle(cream)
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func factRow(fact: FinancialFact) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "lightbulb")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(accentPurple)
                .frame(width: 22, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(fact.fact.lowercased())
                    .font(.custom(FontFamily.Rubik.medium, size: 14))
                    .foregroundStyle(cream)
                Text(fact.source.lowercased())
                    .font(.custom(FontFamily.Rubik.regular, size: 11))
                    .foregroundStyle(dimText)
            }
            Spacer(minLength: 8)
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                withAnimation(.easeInOut(duration: 0.25)) {
                    userProfile?.removeFact(id: fact.id)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(dimText)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
    }

    private var preferencesSection: some View {
        section(title: "preferences") {
            toggleRow(
                icon: "iphone.radiowaves.left.and.right",
                title: "extraction haptics",
                subtitle: "buzz while norma reads a note",
                isOn: $extractionHapticsEnabled
            )
            Divider().overlay(dimText.opacity(0.25)).padding(.vertical, 4)
            themeRow
        }
    }

    private var themeRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                Image(systemName: "paintpalette")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accentPurple)
                    .frame(width: 22, alignment: .leading)
                Text("accent color")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundStyle(cream)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 30), spacing: 14)], spacing: 14) {
                ForEach(AppTheme.presets) { theme in
                    themeSwatch(theme)
                }
            }
            .padding(.leading, 36)
            .padding(.trailing, 36)
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func themeSwatch(_ theme: AccentTheme) -> some View {
        let isSelected = selectedAccentThemeID == theme.id
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.easeOut(duration: 0.18)) {
                selectedAccentThemeID = theme.id
            }
            AppTheme.mirrorToSharedDefaults()
        } label: {
            ZStack {
                Circle()
                    .fill(theme.color)
                Circle()
                    .strokeBorder(
                        isSelected ? cream.opacity(0.9) : dimText.opacity(0.4),
                        style: isSelected
                            ? StrokeStyle(lineWidth: 2)
                            : StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(onAccentText)
                }
            }
            .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(theme.name)
    }

    private var supportSection: some View {
        section(title: "support") {
            tappableRow(icon: "questionmark.circle", title: "help & support") { showHelpSupport = true }
            tappableRow(icon: "doc.text", title: "terms of use") { showTermsOfUse = true }
            tappableRow(icon: "lock.shield", title: "privacy policy") { showPrivacyPolicy = true }
        }
    }

    private var dataSection: some View {
        section(title: "your data", titleColor: danger.opacity(0.9), dividerColor: danger.opacity(0.25)) {
            Text("no account, no servers. everything norma knows lives only on this iPhone, and norma thinks with apple's on-device model.")
                .font(.custom(FontFamily.Rubik.regular, size: 12).italic())
                .foregroundStyle(dimText)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            destructiveRow(icon: "trash", title: "reset all data") {
                showResetAlert = true
            }
        }
    }

    #if DEBUG
    // Debug-only. Surgically returns the freedom fund to its untouched "first
    // time" state without nuking the rest of the account: zeroes the balance,
    // unlinks any arc account, and clears the local FreedomFundEntry ledger.
    // Stripped from release builds by the surrounding #if DEBUG.
    private var debugSection: some View {
        section(title: "debug", titleColor: mutedText, dividerColor: mutedText.opacity(0.25)) {
            destructiveRow(icon: "arrow.counterclockwise", title: "reset balance") {
                resetFreedomFund()
            }
        }
    }

    private func resetFreedomFund() {
        // 1. Server-side profile: zero the balance and unlink the arc account.
        //    Mirrors both the top-level column and the settings blob, exactly
        //    as FreedomFundEditSheet.saveChanges() does.
        if let currentUser = sessionViewModel.currentUser {
            var updatedProfile = currentUser
            var updatedSettings = currentUser.settings
            updatedSettings.freedomFund = 0
            updatedSettings.arcAccountId = nil
            updatedProfile.settings = updatedSettings
            updatedProfile.freedomFund = 0
            sessionViewModel.updateUserProfile(updatedProfile)
        }

        // 2. Local ledger: drop every FreedomFundEntry so activity is empty.
        do {
            try modelContext.delete(model: FreedomFundEntry.self)
            try modelContext.save()
        } catch {
            print("[debug] failed to clear FreedomFundEntry ledger: \(error)")
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        showFundResetConfirmation = true
    }
    #endif

    // MARK: - Section + row helpers

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        titleColor: Color? = nil,
        dividerColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                .tracking(0.88)
                .textCase(.uppercase)
                .foregroundStyle(titleColor ?? cream)
                .padding(.bottom, 6)

            content()
        }
    }

    @ViewBuilder
    private func listRow(
        icon: String,
        iconColor: Color,
        primary: String,
        secondary: String? = nil,
        trailingLabel: String? = nil,
        showChevron: Bool = true,
        action: (() -> Void)? = nil
    ) -> some View {
        let content = HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 22, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(primary)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                    .foregroundStyle(cream)
                if let secondary {
                    Text(secondary)
                        .font(.custom(FontFamily.Rubik.regular, size: 12))
                        .foregroundStyle(mutedText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let trailingLabel {
                Text(trailingLabel)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 12))
                    .foregroundStyle(onAccentText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(accentPurple))
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(dimText)
                    .frame(width: 16, alignment: .trailing)
            }
        }
        .padding(.vertical, 14)

        if let action {
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                action()
            } label: {
                content.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }

    @ViewBuilder
    private func tappableRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accentPurple)
                    .frame(width: 22, alignment: .leading)
                Text(title)
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundStyle(cream)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(dimText)
                    .frame(width: 16, alignment: .trailing)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func toggleRow(icon: String, title: String, subtitle: String? = nil, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(accentPurple)
                .frame(width: 22, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundStyle(cream)
                if let subtitle {
                    Text(subtitle)
                        .font(.custom(FontFamily.Rubik.regular, size: 12))
                        .foregroundStyle(mutedText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(accentPurple)
        }
        .padding(.vertical, 14)
    }

    // MARK: - Plaid actions

    private func connectBank() {
        guard let userId = sessionViewModel.currentUser?.userId else {
            plaidErrorMessage = "Please sign in to connect your bank."
            showPlaidError = true
            return
        }

        isLoadingLinkToken = true
        Task {
            do {
                let linkToken = try await PlaidService.shared.createLinkToken(userId: userId)
                await MainActor.run {
                    isLoadingLinkToken = false
                    openPlaidLink(with: linkToken)
                }
            } catch {
                await MainActor.run {
                    isLoadingLinkToken = false
                    plaidErrorMessage = error.localizedDescription
                    showPlaidError = true
                }
            }
        }
    }

    private func openPlaidLink(with linkToken: String) {
        var config = LinkTokenConfiguration(token: linkToken) { success in
            let institutionName = success.metadata.institution.name
            self.handleLinkSuccess(publicToken: success.publicToken, institutionName: institutionName)
        }

        config.onExit = { exit in
            if let error = exit.error {
                self.plaidErrorMessage = "Link exited: \(error.localizedDescription)"
                self.showPlaidError = true
            }
            self.plaidHandler = nil
        }

        let result = Plaid.create(config)
        switch result {
        case .success(let handler):
            self.plaidHandler = handler
            handler.open(presentUsing: .viewController(UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
                .first!))
        case .failure(let error):
            plaidErrorMessage = "Failed to open Plaid Link: \(error.localizedDescription)"
            showPlaidError = true
        }
    }

    private func handleLinkSuccess(publicToken: String, institutionName: String? = nil) {
        guard let userId = sessionViewModel.currentUser?.userId else { return }

        isExchangingToken = true
        plaidHandler = nil

        Task {
            do {
                let itemId = try await plaidService.exchangeToken(userId: userId, publicToken: publicToken, institutionName: institutionName)
                let accounts = try await plaidService.fetchBalances(userId: userId)

                await MainActor.run {
                    plaidService.connectedAccounts = accounts
                    plaidService.isConnected = true
                    plaidService.institutionName = institutionName
                    plaidService.itemId = itemId
                    isExchangingToken = false

                    // If the freedom fund is wired to a Plaid account, log
                    // any balance change for the activity ledger.
                    if let arcAccountId = sessionViewModel.currentUser?.settings.arcAccountId,
                       let account = accounts.first(where: { $0.accountId == arcAccountId }),
                       let balance = account.balances.current {
                        FreedomFundLedger.recordIfChanged(
                            in: modelContext,
                            userId: userId,
                            newBalance: balance,
                            source: .linkedAccountSync
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    isExchangingToken = false
                    plaidErrorMessage = error.localizedDescription
                    showPlaidError = true
                }
            }
        }
    }

    private func disconnectBank() {
        guard let userId = sessionViewModel.currentUser?.userId,
              let itemId = plaidService.itemId else { return }

        Task {
            do {
                try await plaidService.disconnect(userId: userId, itemId: itemId)
            } catch {
                await MainActor.run {
                    plaidErrorMessage = error.localizedDescription
                    showPlaidError = true
                }
            }
        }
    }

    @ViewBuilder
    private func destructiveRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(danger)
                    .frame(width: 22, alignment: .leading)
                Text(title)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                    .foregroundStyle(danger)
                Spacer()
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    Color.black
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            SettingsView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
}
