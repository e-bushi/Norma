//
//  SettingsView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @Binding var isMenuOpen: Bool

    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appCoordinator: AppCoordinator
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showPaywall = false
    @State private var showTermsOfUse = false
    @State private var showPrivacyPolicy = false
    @State private var showHelpSupport = false
    @State private var isDeletingAccount = false
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    // Security/Encryption states
    @State private var showRecoveryPhraseSheet = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                welcomeSection
                profileSection
                appearanceSection
                subscriptionSection
                supportSection
                securitySection
                accountSection
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(Color("NormaBackground"))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    let impactMedium = UIImpactFeedbackGenerator(style: .medium)
                    impactMedium.impactOccurred()
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
    }

    // MARK: - Extracted Sections

    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                // Royalty coin with device motion effect
                MotionCoin3DView(fileName: "norma-coin-royalty")
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Norma")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 24))
                        .foregroundColor(.primary)
                    Text("Thanks for joining us!")
                        .font(.normaHeadline(18))
                        .foregroundColor(Color("NormaPastelPurple"))
                }

                Spacer()
            }

            Text("We're so glad you're here. Your path to financial peace of mind matters to us — and we'll be with you every step of the way.")
                .font(.normaInput(16))
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("NormaPastelPurple").opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("NormaPastelPurple").opacity(0.15), lineWidth: 1)
        )
    }

    private var profileSection: some View {
        SettingsSectionView(title: "Profile") {
            if let user = sessionViewModel.currentUser {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("NormaPastelPurple"))
                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(.normaHeadline(17))
                        Text(user.email)
                            .font(.normaHeadline(13))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var appearanceSection: some View {
        SettingsSectionView(title: "Appearance") {
            HStack {
                Text("Mode")
                    .font(.normaHeadline(17))
                Spacer()
                Picker("", selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var subscriptionSection: some View {
        SettingsSectionView(title: "Subscription") {
            subscriptionContent
        }
    }

    @ViewBuilder
    private var subscriptionContent: some View {
        if subscriptionManager.isInFreeTrial {
            trialStatusView
        } else if subscriptionManager.hasActiveSubscription {
            activeSubscriptionView
        } else {
            noSubscriptionView
        }
    }

    private var trialStatusView: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(Color("NormaPastelPurple"))
            VStack(alignment: .leading, spacing: 4) {
                Text("Free Trial")
                    .font(.normaHeadline(17))
                if let daysRemaining = subscriptionManager.trialDaysRemaining {
                    Text("\(daysRemaining) day\(daysRemaining == 1 ? "" : "s") remaining")
                        .font(.normaHeadline(13))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button("View Plans") { showPaywall = true }
                .font(.normaHeadline(13))
                .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 4)
    }

    private var activeSubscriptionView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(Color("NormaPastelTeal"))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pro Subscription")
                        .font(.normaHeadline(17))
                    if let expirationDate = subscriptionManager.subscriptionStatus.expirationDate {
                        if subscriptionManager.subscriptionStatus.willRenew {
                            Text("Renews \(expirationDate, style: .date)")
                                .font(.normaHeadline(13))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Expires \(expirationDate, style: .date)")
                                .font(.normaHeadline(13))
                                .foregroundColor(.orange)
                        }
                    }
                }
                Spacer()
            }
            .padding(.vertical, 4)

            Button(action: {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "creditcard")
                        .foregroundColor(Color("NormaPastelPurple"))
                    Text("Manage Subscription")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.forward.square")
                        .foregroundColor(.secondary)
                        .font(.normaHeadline(13))
                }
            }
        }
    }

    private var noSubscriptionView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Limited Access")
                        .font(.normaHeadline(17))
                    Text("Unlock all features with Pro")
                        .font(.normaHeadline(13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Subscribe") { showPaywall = true }
                    .font(.normaHeadline(13))
                    .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 4)

            Button(action: {
                Task {
                    do { try await subscriptionManager.restorePurchases() }
                    catch { print("Failed to restore purchases: \(error)") }
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise.circle")
                        .foregroundColor(Color("NormaPastelPurple"))
                    Text("Restore Purchases")
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
        }
    }

    private var supportSection: some View {
        SettingsSectionView(title: "Support") {
            settingsButton(icon: "questionmark.circle.fill", title: "Help & Support", color: Color("NormaPastelPurple")) {
                showHelpSupport = true
            }
            settingsButton(icon: "doc.text.fill", title: "Terms of Use", color: Color("NormaPastelPurple")) {
                showTermsOfUse = true
            }
            settingsButton(icon: "lock.shield.fill", title: "Privacy Policy", color: Color("NormaPastelPurple")) {
                showPrivacyPolicy = true
            }
        }
    }

    private var securitySection: some View {
        SettingsSectionView(title: "Security") {
            settingsButton(icon: "key.fill", title: "View Recovery Phrase", color: Color("NormaPastelTeal")) {
                showRecoveryPhraseSheet = true
            }

            Text("Your data is encrypted with your personal key. Keep your recovery phrase safe to restore access.")
                .font(.normaHeadline(12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
    }

    private var accountSection: some View {
        SettingsSectionView(title: "Account") {
            Button(action: { showLogoutAlert = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                    Text("Sign Out")
                        .font(.normaHeadline(16))
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { showDeleteAccountAlert = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                    Text("Delete Account")
                        .font(.normaHeadline(16))
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .disabled(isDeletingAccount)
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Helper Views

    private func settingsButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(title)
                    .font(.normaHeadline(16))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Views

struct SettingsSectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.normaHeadline(13))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                content
            }
            .padding()
            .background(Color("NormaBackground"))
        }
    }
}

#Preview {
    let appCoordinator = AppCoordinator()
    NavigationStack {
        SettingsView(isMenuOpen: .constant(false))
            .environmentObject(appCoordinator.sessionViewModel)
            .environmentObject(appCoordinator.dataManager)
            .environmentObject(appCoordinator)
    }
}
