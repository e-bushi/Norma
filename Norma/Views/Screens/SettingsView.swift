//
//  SettingsView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var notificationService = NotificationService.shared
    @State private var showLogoutAlert = false
    @State private var showRecoveryPhrase = false
    @State private var showSecurityOptions = false
    
    private var hasEncryptionEnabled: Bool {
        guard let userId = sessionViewModel.currentUser?.userId else { return false }
        let userKeyManager = UserKeyManager(supabaseService: dataManager.supabaseService)
        return userKeyManager.hasStoredRecoveryPhrase(for: userId)
    }
    
    var body: some View {
        NavigationView {
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
                                    .font(.headline)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
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
                                    .font(.caption)
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
                                    .font(.caption)
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
                            .font(.caption)
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
                                    .font(.headline)
                                Text("Your data is protected")
                                    .font(.caption)
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
                                    .font(.caption)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("Encryption Disabled")
                                    .font(.headline)
                                Text("Enable encryption to protect your data")
                                    .font(.caption)
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
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Support Section
                Section("Support") {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.blue)
                        Text("Help & Support")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        Text("Contact Us")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
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
                }
            }
            .navigationTitle("Settings")
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
            .sheet(isPresented: $showRecoveryPhrase) {
                RecoveryPhraseView(userId: sessionViewModel.currentUser?.userId ?? "")
            }
        }
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

#Preview {
    SettingsView()
        .environmentObject(SessionViewModel(dataManager: DataManager()))
        .environmentObject(DataManager())
}