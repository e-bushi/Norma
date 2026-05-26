//
//  SettingsView.swift
//  Norma
//
//  Settings sheet — matches the dark editorial language of D10/Forecast.
//  Sectioned list (profile / subscription / support / security / account)
//  with destructive actions in coral. Presented as a sheet from the gear
//  icon in the notes-list bottom bar.
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

    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var plaidService = PlaidService.shared
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showPaywall = false
    @State private var showTermsOfUse = false
    @State private var showPrivacyPolicy = false
    @State private var showHelpSupport = false
    @State private var isDeletingAccount = false
    @State private var showRecoveryPhraseSheet = false

    // UserProfile
    @Query private var userProfiles: [UserProfile]
    private var userProfile: UserProfile? { userProfiles.first }

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
    private let accentPurple = Color(red: 0x96/255, green: 0x76/255, blue: 0xD9/255)
    private let danger = Color(red: 0xE0/255, green: 0x7B/255, blue: 0x6F/255)

    private var heroFont: Font { .system(size: 56, weight: .heavy) }

    var body: some View {
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

                    subscriptionSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)

                    bankingSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)

                    normaKnowsSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)

                    supportSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)

                    securitySection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)

                    accountSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                }
            }
        }
        .background(bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .alert("Sign Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task { await appCoordinator.logout() }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { showDeleteAccountConfirmation = true }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .alert("Are you absolutely sure?", isPresented: $showDeleteAccountConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete My Account", role: .destructive) {
                Task {
                    isDeletingAccount = true
                    do { try await sessionViewModel.deleteAccount() }
                    catch { print("Error deleting account: \(error)") }
                    isDeletingAccount = false
                }
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action CANNOT be undone.")
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showTermsOfUse) {
            WebViewSheet(url: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/", title: "Terms of Use")
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            WebViewSheet(url: "https://mauldin.xyz/norma/privacy", title: "Privacy Policy")
        }
        .sheet(isPresented: $showHelpSupport) {
            WebViewSheet(url: "https://norma-app.userjot.com", title: "Help & Support")
        }
        .sheet(isPresented: $showRecoveryPhraseSheet) {
            RecoveryPhraseSheet(dataManager: dataManager)
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

            if let user = sessionViewModel.currentUser {
                Text(user.email)
                    .font(.custom(FontFamily.Rubik.regular, size: 15).italic())
                    .foregroundStyle(mutedText)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        section(title: "profile") {
            if let user = sessionViewModel.currentUser {
                listRow(
                    icon: "person.crop.circle",
                    iconColor: accentPurple,
                    primary: user.name.lowercased(),
                    secondary: user.email,
                    showChevron: false
                )
            }
        }
    }

    @ViewBuilder
    private var subscriptionSection: some View {
        section(title: "subscription") {
            if subscriptionManager.isInFreeTrial {
                listRow(
                    icon: "sparkles",
                    iconColor: accentPurple,
                    primary: "free trial",
                    secondary: subscriptionManager.trialDaysRemaining.map {
                        "\($0) day\($0 == 1 ? "" : "s") remaining"
                    },
                    trailingLabel: "view plans",
                    showChevron: false,
                    action: { showPaywall = true }
                )
            } else if subscriptionManager.hasActiveSubscription {
                listRow(
                    icon: "checkmark.seal",
                    iconColor: accentPurple,
                    primary: "premium",
                    secondary: subscriptionStatusLine,
                    showChevron: false
                )
                tappableRow(icon: "creditcard", title: "manage subscription") {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }
            } else {
                listRow(
                    icon: "lock",
                    iconColor: dimText,
                    primary: "limited access",
                    secondary: "unlock all norma features",
                    trailingLabel: "subscribe",
                    showChevron: false,
                    action: { showPaywall = true }
                )
                tappableRow(icon: "arrow.clockwise.circle", title: "restore purchases") {
                    Task {
                        do { try await subscriptionManager.restorePurchases() }
                        catch { print("Failed to restore purchases: \(error)") }
                    }
                }
            }
        }
    }

    private var subscriptionStatusLine: String? {
        guard let expirationDate = subscriptionManager.subscriptionStatus.expirationDate else { return nil }
        let f = DateFormatter()
        f.dateStyle = .medium
        let prefix = subscriptionManager.subscriptionStatus.willRenew ? "renews" : "expires"
        return "\(prefix) \(f.string(from: expirationDate).lowercased())"
    }

    @ViewBuilder
    private var bankingSection: some View {
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
        let profile = userProfile
        let hasFixedFields = profile != nil && (
            profile!.currency != "USD" ||
            profile!.incomeAmount != nil ||
            profile!.payday != nil ||
            profile!.runwayFloor != nil
        )
        let hasFacts = profile != nil && !profile!.facts.isEmpty
        let hasAnything = hasFixedFields || hasFacts

        section(title: "what norma knows") {
            if !hasAnything {
                Text("norma hasn't learned anything yet")
                    .font(.custom(FontFamily.Rubik.regular, size: 13).italic())
                    .foregroundStyle(dimText)
                    .padding(.vertical, 10)
            } else {
                // Fixed fields
                if let profile {
                    if profile.currency != "USD" {
                        knowledgeRow(label: "currency", value: profile.currency.lowercased())
                    }
                    if let income = profile.incomeAmount {
                        let freq = profile.incomeFrequency?.lowercased() ?? "unknown"
                        knowledgeRow(label: "income", value: "\(formatBalance(income, currency: profile.currency)) \(freq)")
                    }
                    if let day = profile.payday {
                        knowledgeRow(label: "payday", value: "day \(day) of month")
                    }
                    if let floor = profile.runwayFloor {
                        let months = floor == 1.0 ? "month" : "months"
                        knowledgeRow(label: "runway floor", value: "\(String(format: "%g", floor)) \(months)")
                    }
                }

                // Freeform facts
                if hasFacts {
                    ForEach(profile!.facts) { fact in
                        factRow(fact: fact)
                    }
                }
            }
        }
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

    private var supportSection: some View {
        section(title: "support") {
            tappableRow(icon: "questionmark.circle", title: "help & support") { showHelpSupport = true }
            tappableRow(icon: "doc.text", title: "terms of use") { showTermsOfUse = true }
            tappableRow(icon: "lock.shield", title: "privacy policy") { showPrivacyPolicy = true }
        }
    }

    private var securitySection: some View {
        section(title: "security") {
            tappableRow(icon: "key", title: "view recovery phrase") { showRecoveryPhraseSheet = true }
            Text("your data is encrypted with your personal key. keep your recovery phrase safe to restore access.")
                .font(.custom(FontFamily.Rubik.regular, size: 12).italic())
                .foregroundStyle(dimText)
                .padding(.top, 4)
                .padding(.horizontal, 4)
        }
    }

    private var accountSection: some View {
        section(title: "account", titleColor: danger.opacity(0.9), dividerColor: danger.opacity(0.25)) {
            destructiveRow(icon: "rectangle.portrait.and.arrow.right", title: "sign out") {
                showLogoutAlert = true
            }
            destructiveRow(icon: "trash", title: "delete account") {
                showDeleteAccountAlert = true
            }
            .disabled(isDeletingAccount)
            .opacity(isDeletingAccount ? 0.5 : 1.0)
        }
    }

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
