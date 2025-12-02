//
//  NotificationPermissionView.swift
//  Norma
//
//  Created by Claude on 8/5/25.
//

import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    @State private var animateBell = false
    @State private var animateTitle = false
    @State private var animateContent = false
    @State private var animateButton = false
    @State private var isLoading = false

    let onPermissionGranted: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 3D Bell
            Bell3DView()
                .frame(width: 180, height: 180)
                .scaleEffect(animateBell ? 1.0 : 0.3)
                .opacity(animateBell ? 1.0 : 0.0)

            Text("Stay on Track")
                .font(.normaHeadline(24))
                .multilineTextAlignment(.center)
                .scaleEffect(animateTitle ? 1.0 : 0.8)
                .opacity(animateTitle ? 1.0 : 0.0)

            VStack(alignment: .leading, spacing: 12) {
                Text("Get timely reminders for upcoming bills and never miss a payment:")
                    .normaBody()
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .normaBody()
                    Text("Reminders before bills are due")
                        .normaBody()
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .normaBody()
                    Text("Alerts when you're close to budget limits")
                        .normaBody()
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .normaBody()
                    Text("Weekly spending summaries")
                        .normaBody()
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
            .background(Color("NormaSurface"))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .offset(y: animateContent ? 0 : 20)
            .opacity(animateContent ? 1.0 : 0.0)

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
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("NormaPastelTeal"))
                    .cornerRadius(12)
                }
                .disabled(isLoading)

                Button(action: {
                    onSkip()
                }) {
                    Text("Not Now")
                        .font(.normaHeadline(14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .scaleEffect(animateButton ? 1.0 : 0.8)
            .opacity(animateButton ? 1.0 : 0.0)

            Spacer()
        }
        .padding(.vertical, 32)
        .background(
            Color("NormaBackground")
                .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateBell = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                animateTitle = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                animateContent = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4)) {
                animateButton = true
            }
        }
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

#Preview {
    NotificationPermissionView(
        onPermissionGranted: { print("Permission granted") },
        onSkip: { print("Skipped") }
    )
    .preferredColorScheme(.dark)
}
