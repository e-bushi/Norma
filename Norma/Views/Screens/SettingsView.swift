//
//  SettingsView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

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

    var body: some View {
        ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // User Profile Section
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

                    // Appearance Section
                    SettingsSectionView(title: "Appearance") {
                        HStack {
                            Text("Mode")
                                .font(.normaHeadline(17))

                            Spacer()

                            Picker("", selection: $appearanceMode) {
                                ForEach(AppearanceMode.allCases) { mode in
                                    Text(mode.rawValue)
                                        .tag(mode)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    // Subscription Section
                    SettingsSectionView(title: "Subscription") {
                        if subscriptionManager.isInFreeTrial {
                            // Trial status
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

                                Button("View Plans") {
                                    showPaywall = true
                                }
                                .font(.normaHeadline(13))
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.vertical, 4)
                        } else if subscriptionManager.hasActiveSubscription {
                            // Active subscription
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

                            // Manage subscription button
                            Button(action: {
                                // Open App Store subscription management
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
                        } else {
                            // No subscription
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

                                Button("Subscribe") {
                                    showPaywall = true
                                }
                                .font(.normaHeadline(13))
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.vertical, 4)

                            // Restore purchases option
                            Button(action: {
                                Task {
                                    do {
                                        try await subscriptionManager.restorePurchases()
                                    } catch {
                                        print("Failed to restore purchases: \(error)")
                                    }
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

                    // Support Section
                    SettingsSectionView(title: "Support") {
                        Button(action: {
                            showHelpSupport = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color("NormaPastelPurple"))

                                Text("Help & Support")
                                    .font(.normaHeadline(16))
                                    .foregroundColor(Color("NormaPastelPurple"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("NormaPastelPurple").opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color("NormaPastelPurple").opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            showTermsOfUse = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color("NormaPastelPurple"))

                                Text("Terms of Use")
                                    .font(.normaHeadline(16))
                                    .foregroundColor(Color("NormaPastelPurple"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("NormaPastelPurple").opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color("NormaPastelPurple").opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            showPrivacyPolicy = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color("NormaPastelPurple"))

                                Text("Privacy Policy")
                                    .font(.normaHeadline(16))
                                    .foregroundColor(Color("NormaPastelPurple"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("NormaPastelPurple").opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color("NormaPastelPurple").opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // Account Section
                    SettingsSectionView(title: "Account") {
                        Button(action: {
                            showLogoutAlert = true
                        }) {
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

                        Button(action: {
                            showDeleteAccountAlert = true
                        }) {
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

                        // Open the menu
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
                    Task {
                        await appCoordinator.logout()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    showDeleteAccountConfirmation = true
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .alert("Are you absolutely sure?", isPresented: $showDeleteAccountConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete My Account", role: .destructive) {
                    Task {
                        isDeletingAccount = true
                        do {
                            try await sessionViewModel.deleteAccount()
                        } catch {
                            print("Error deleting account: \(error)")
                            // You might want to show an error alert here
                        }
                        isDeletingAccount = false
                    }
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This action CANNOT be undone.")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showTermsOfUse) {
                WebViewSheet(
                    url: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/",
                    title: "Terms of Use"
                )
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                WebViewSheet(
                    url: "https://mauldin.xyz/norma/privacy",
                    title: "Privacy Policy"
                )
            }
            .sheet(isPresented: $showHelpSupport) {
                WebViewSheet(
                    url: "https://norma-app.userjot.com",
                    title: "Help & Support"
                )
            }
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
    NavigationStack {
        SettingsView(isMenuOpen: .constant(false))
            .environmentObject(SessionViewModel(dataManager: DataManager()))
            .environmentObject(DataManager())
    }
}
