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
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showRecoveryPhrase = false
    @State private var showSecurityOptions = false
    @State private var showPaywall = false
    @State private var showTermsOfUse = false
    @State private var showPrivacyPolicy = false
    @State private var showHelpSupport = false
    @State private var isDeletingAccount = false
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @Environment(\.colorScheme) private var colorScheme

    private var hasEncryptionEnabled: Bool {
        guard let userId = sessionViewModel.currentUser?.userId else { return false }
        let userKeyManager = UserKeyManager(supabaseService: dataManager.supabaseService)
        return userKeyManager.hasStoredRecoveryPhrase(for: userId)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // User Profile Section
                Section("Profile") {
                    if let user = sessionViewModel.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.normaHeadline(17))
                                Text(user.email)
                                    .font(.normaHeadline(13))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Appearance Section
                Section("Appearance") {
                    ForEach(AppearanceMode.allCases) { mode in
                        Button(action: {
                            appearanceMode = mode
                        }) {
                            HStack {
                                Image(systemName: mode.icon)
                                    .foregroundColor(appearanceMode == mode ? .blue : .secondary)

                                Text(mode.rawValue)
                                    .font(.normaHeadline(17))
                                    .foregroundColor(.primary)

                                Spacer()

                                if appearanceMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Subscription Section
                Section("Subscription") {
                    if subscriptionManager.isInFreeTrial {
                        // Trial status
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            
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
                                .foregroundColor(.green)
                            
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
                                    .foregroundColor(.blue)
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
                                    .foregroundColor(.blue)
                                Text("Restore Purchases")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                }
                
                // App Settings Section
                Section("App Settings") {
                    // Notifications row - different behavior based on permission status
                    if notificationService.isNotificationsEnabled {
                        NavigationLink(destination: UpcomingNotificationsView()) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.orange)
                                Text("Notifications")
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.normaHeadline(13))
                            }
                        }
                    } else {
                        Button(action: {
                            Task {
                                await requestNotificationPermission()
                            }
                        }) {
                            HStack {
                                Image(systemName: "bell.slash.fill")
                                    .foregroundColor(.red)
                                Text("Enable Notifications")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.normaHeadline(13))
                            }
                        }
                    }
                    
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.green)
                        Text("Payment Methods")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.normaHeadline(13))
                    }
                    
                }
                
                // Security Section
                Section("Security") {
                    if hasEncryptionEnabled {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Encryption Enabled")
                                    .font(.normaHeadline(17))
                                Text("Your data is protected")
                                    .font(.normaHeadline(13))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 2)
                        
                        Button(action: {
                            showRecoveryPhrase = true
                        }) {
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundColor(.blue)
                                Text("View Recovery Phrase")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.normaHeadline(13))
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("Encryption Disabled")
                                    .font(.normaHeadline(17))
                                Text("Enable encryption to protect your data")
                                    .font(.normaHeadline(13))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                // Data Section
                Section("Data") {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                        Text("Sync Data")
                        Spacer()
                        if dataManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .onTapGesture {
                        Task {
                            try? await dataManager.syncAllData()
                        }
                    }
                    
                    if let lastSync = dataManager.lastSyncDate {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            Text("Last synced")
                            Spacer()
                            Text(lastSync, style: .relative)
                                .font(.normaHeadline(13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Support Section
                Section("Support") {
                    Button(action: {
                        showHelpSupport = true
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.blue)
                            Text("Help & Support")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.normaHeadline(13))
                        }
                    }
                    
                    Button(action: {
                        showTermsOfUse = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                            Text("Terms of Use")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.normaHeadline(13))
                        }
                    }
                    
                    Button(action: {
                        showPrivacyPolicy = true
                    }) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.blue)
                            Text("Privacy Policy")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.normaHeadline(13))
                        }
                    }
                }
                
                // Account Section
                Section("Account") {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: {
                        showDeleteAccountAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Delete Account")
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(isDeletingAccount)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("NormaBackground"))
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.clear)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 12))
            )
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        let impactMedium = UIImpactFeedbackGenerator(style: .medium)
                        impactMedium.impactOccurred()

                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isMenuOpen.toggle()
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
                        await sessionViewModel.logout()
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
            .sheet(isPresented: $showRecoveryPhrase) {
                RecoveryPhraseView(userId: sessionViewModel.currentUser?.userId ?? "")
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
                    url: "https://whop.com/norma-ai",
                    title: "Help & Support"
                )
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
    }

    private func requestNotificationPermission() async {
        let granted = await notificationService.requestNotificationPermission()
        print("🔔 Notification permission granted: \(granted)")
        
        if !granted {
            // If permission was denied, we could show an alert directing them to Settings
            // But the NotificationService already handles this via the permission status
        }
    }
}

// MARK: - Supporting Types

enum AppearanceMode: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

#Preview {
    SettingsView( isMenuOpen: .constant(false))
        .environmentObject(SessionViewModel(dataManager: DataManager()))
        .environmentObject(DataManager())
}
