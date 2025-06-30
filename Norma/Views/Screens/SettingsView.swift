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
    @State private var showLogoutAlert = false
    
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
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                        Text("Notifications")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
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
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.red)
                        Text("Privacy & Security")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
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
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SessionViewModel(dataManager: DataManager()))
        .environmentObject(DataManager())
}