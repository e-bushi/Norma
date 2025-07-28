//
//  PopupExamples.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import SwiftUI

// This file demonstrates how to use the reusable InformationalPopup component
struct PopupExamples: View {
    @State private var showEncryptionPopup = false
    @State private var showUpdatePopup = false
    @State private var showBackupPopup = false
    @State private var showFeaturePopup = false
    @State private var showNoticePopup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Button("Show Encryption Migration") {
                    showEncryptionPopup = true
                }
                .buttonStyle(.borderedProminent)
                
                Button("Show App Update") {
                    showUpdatePopup = true
                }
                .buttonStyle(.borderedProminent)
                
                Button("Show Data Backup") {
                    showBackupPopup = true
                }
                .buttonStyle(.borderedProminent)
                
                Button("Show New Feature") {
                    showFeaturePopup = true
                }
                .buttonStyle(.borderedProminent)
                
                Button("Show Critical Notice") {
                    showNoticePopup = true
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Popup Examples")
        }
        .overlay(
            Group {
                // Encryption Migration Popup
                if showEncryptionPopup {
                    EncryptionMigrationPopup(
                        isPresented: $showEncryptionPopup,
                        onMigrate: { password in
                            print("Starting encryption migration with password...")
                            // Simulate migration for example
                            try await Task.sleep(nanoseconds: 2_000_000_000)
                            showEncryptionPopup = false
                        },
                        onDismiss: {
                            showEncryptionPopup = false
                        },
                        userEmail: "example@email.com"
                    )
                }
                
                // App Update Popup
                if showUpdatePopup {
                    InformationalPopup(
                        isPresented: $showUpdatePopup,
                        config: .appUpdate(
                            version: "2.1.0",
                            features: [
                                "Improved expense tracking",
                                "New budget insights",
                                "Performance enhancements"
                            ],
                            onUpdate: {
                                print("Updating app...")
                                showUpdatePopup = false
                            },
                            onDismiss: {
                                showUpdatePopup = false
                            }
                        ),
                        onPrimaryAction: {
                            print("Updating app...")
                            showUpdatePopup = false
                        },
                        onSecondaryAction: {
                            showUpdatePopup = false
                        },
                        onDismiss: {
                            showUpdatePopup = false
                        }
                    )
                }
                
                // Data Backup Popup
                if showBackupPopup {
                    InformationalPopup(
                        isPresented: $showBackupPopup,
                        config: .dataBackup(
                            lastBackup: "3 days ago",
                            onBackup: {
                                print("Starting backup...")
                                showBackupPopup = false
                            },
                            onDismiss: {
                                showBackupPopup = false
                            }
                        ),
                        onPrimaryAction: {
                            print("Starting backup...")
                            showBackupPopup = false
                        },
                        onSecondaryAction: {
                            showBackupPopup = false
                        },
                        onDismiss: {
                            showBackupPopup = false
                        }
                    )
                }
                
                // New Feature Popup
                if showFeaturePopup {
                    InformationalPopup(
                        isPresented: $showFeaturePopup,
                        config: .featureIntroduction(
                            featureTitle: "Smart Budget Insights",
                            description: "Get personalized recommendations to optimize your spending",
                            benefits: [
                                PopupFeature(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "Spending Trends",
                                    description: "Visualize your spending patterns over time",
                                    iconColor: .blue
                                ),
                                PopupFeature(
                                    icon: "lightbulb.fill",
                                    title: "Smart Suggestions",
                                    description: "AI-powered recommendations for better budgeting",
                                    iconColor: .orange
                                )
                            ],
                            onTryNow: {
                                print("Trying new feature...")
                                showFeaturePopup = false
                            },
                            onDismiss: {
                                showFeaturePopup = false
                            }
                        ),
                        onPrimaryAction: {
                            print("Trying new feature...")
                            showFeaturePopup = false
                        },
                        onSecondaryAction: {
                            showFeaturePopup = false
                        },
                        onDismiss: {
                            showFeaturePopup = false
                        }
                    )
                }
                
                // Critical Notice Popup
                if showNoticePopup {
                    InformationalPopup(
                        isPresented: $showNoticePopup,
                        config: .criticalNotice(
                            title: "Service Maintenance",
                            message: "We'll be performing scheduled maintenance tonight from 2-4 AM EST. Some features may be temporarily unavailable.",
                            actionTitle: "Understood",
                            isDestructive: false,
                            onAction: {
                                showNoticePopup = false
                            }
                        ),
                        onPrimaryAction: {
                            showNoticePopup = false
                        },
                        onDismiss: {
                            showNoticePopup = false
                        }
                    )
                }
            }
        )
    }
}

#Preview {
    PopupExamples()
        .preferredColorScheme(.light)
}
