//
//  NotificationPermissionView.swift
//  Norma
//
//  Created by Claude on 8/5/25.
//

import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    @State private var titleOpacity = 0.0
    @State private var titleOffset: CGFloat = 30
    @State private var descriptionOpacity = 0.0
    @State private var descriptionOffset: CGFloat = 30
    @State private var miniViewOpacity = 0.0
    @State private var miniViewScale = 0.8
    @State private var notificationOpacity = 0.0
    @State private var notificationScale = 0.8
    @State private var buttonOpacity = 0.0
    @State private var buttonScale = 0.9
    @State private var isLoading = false
    
    let onPermissionGranted: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Stay on Track")
                .font(.normaTitle(28))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .offset(y: titleOffset)
                .opacity(titleOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                        titleOffset = 0
                        titleOpacity = 1.0
                    }
                }
                .padding(.top, 40)

            // Description
            Text("Get timely reminders for upcoming bills and never miss a payment again.")
                .font(.normaInput(16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
                .offset(y: descriptionOffset)
                .opacity(descriptionOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                        descriptionOffset = 0
                        descriptionOpacity = 1.0
                    }
                }
            
            Spacer()
            
            // Mini Expense View
            MiniExpenseDisclosureView(appeared: true)
                .scaleEffect(0.8)
                .padding(.horizontal, 24)
                .scaleEffect(miniViewScale)
                .opacity(miniViewOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.5)) {
                        miniViewScale = 1.0
                        miniViewOpacity = 1.0
                    }
                }
            
            // Mock Notification Card
            MockNotificationCard()
                .padding(.horizontal, 32)
                .scaleEffect(notificationScale)
                .opacity(notificationOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.7)) {
                        notificationScale = 1.0
                        notificationOpacity = 1.0
                    }
                }
            
            Spacer()
            
            // Permission Button
            VStack(spacing: 16) {
                Button(action: {
                    requestNotificationPermission()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Enable Notifications")
                                .font(.normaHeadline(16))
                            Image(systemName: "bell.fill")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color("NormaPastelTeal"),
                                        Color("NormaPastelTeal").opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color("NormaPastelTeal").opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                }
                .disabled(isLoading)
                .scaleEffect(buttonScale)
                .opacity(buttonOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.9)) {
                        buttonScale = 1.0
                        buttonOpacity = 1.0
                    }
                }
                
                // Skip button
                Button(action: {
                    onSkip()
                }) {
                    Text("Not Now")
                        .font(.normaHeadline(16))
                        .foregroundColor(.secondary)
                }
                .opacity(buttonOpacity)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .background(
            Color("NormaBackground")
                .ignoresSafeArea()
        )
    }
    
    private func requestNotificationPermission() {
        isLoading = true
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if granted {
                    onPermissionGranted()
                } else {
                    // User denied permission, still continue
                    onPermissionGranted()
                }
            }
        }
    }
}

struct MockNotificationCard: View {
    @State private var pulseAnimation = false
    
    var body: some View {
        HStack {
            // Icon and Bill Name Section
            HStack(spacing: 12) {
                Image(systemName: "bell.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                    .frame(width: 40, height: 40)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple iCloud")
                        .font(.normaHeadline(16))
                        .foregroundColor(.primary)
                    HStack(spacing: 8) {
                        Text("Dec 8")
                        Text("•")
                        Text("Monthly")
                    }
                    .font(.normaInput(14))
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Amount Section
            VStack(alignment: .trailing, spacing: 4) {
                Text("$9.99")
                    .font(.normaFinancial(16))
                    .foregroundColor(.primary)
                Text("Due Soon")
                    .font(.normaInput(12))
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemFill).opacity(0.2))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(pulseAnimation ? 1.02 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

#Preview {
    NotificationPermissionView(
        onPermissionGranted: { print("Permission granted") },
        onSkip: { print("Skipped") }
    )
    .preferredColorScheme(.dark)
}
