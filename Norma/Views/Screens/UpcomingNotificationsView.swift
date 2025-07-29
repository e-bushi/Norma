//
//  UpcomingNotificationsView.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import SwiftUI
import UserNotifications

struct UpcomingNotificationsView: View {
    @StateObject private var notificationService = NotificationService.shared
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @State private var isLoading = true
    @State private var showPermissionAlert = false
    
    private var sortedNotifications: [UNNotificationRequest] {
        pendingNotifications.sorted { first, second in
            guard let firstTrigger = first.trigger as? UNCalendarNotificationTrigger,
                  let secondTrigger = second.trigger as? UNCalendarNotificationTrigger,
                  let firstDate = firstTrigger.nextTriggerDate(),
                  let secondDate = secondTrigger.nextTriggerDate() else {
                return false
            }
            return firstDate < secondDate
        }
    }
    
    private var groupedNotifications: [(key: Date, value: [UNNotificationRequest])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sortedNotifications) { notification -> Date in
            guard let trigger = notification.trigger as? UNCalendarNotificationTrigger,
                  let date = trigger.nextTriggerDate() else {
                return Date()
            }
            return calendar.startOfDay(for: date)
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading notifications...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !notificationService.isNotificationsEnabled {
                    notificationsDisabledView
                } else if pendingNotifications.isEmpty {
                    emptyStateView
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Upcoming Reminders")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadNotifications()
        }
        .alert("Enable Notifications", isPresented: $showPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Enable notifications in Settings to receive bill reminders.")
        }
    }
    
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(groupedNotifications, id: \.key) { date, notifications in
                    VStack(alignment: .leading, spacing: 12) {
                        // Section header
                        HStack {
                            Text(sectionTitle(for: date))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                                .tracking(1.2)
                            Spacer()
                            Text("\(notifications.count) REMINDERS")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                                .tracking(1.2)
                        }
                        .padding(.horizontal)
                        
                        // Notifications for this date
                        VStack(spacing: 12) {
                            ForEach(notifications, id: \.identifier) { notification in
                                NotificationRowView(notification: notification)
                                    .environmentObject(profileViewModel)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bell.slash")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No Upcoming Reminders")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Your bill reminders will appear here")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var notificationsDisabledView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Notifications Disabled")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Enable notifications to receive bill reminders")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                showPermissionAlert = true
            }) {
                Text("Enable Notifications")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadNotifications() {
        Task {
            isLoading = true
            
            // Check permission status
            await notificationService.checkNotificationPermission()
            
            // Load pending notifications
            let notifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
            
            await MainActor.run {
                pendingNotifications = notifications
                isLoading = false
            }
        }
    }
    
    private var mockNotificationsView: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Today section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("TODAY")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(1.2)
                        Spacer()
                        Text("2 REMINDERS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(1.2)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        NotificationRowView(notification: createMockNotification(
                            title: "Bill Reminder",
                            body: "Electricity Bill ($125.50) is due today",
                            billName: "Electricity Bill",
                            amount: 125.50,
                            identifier: "mock_due_today",
                            daysFromNow: 0
                        ))
                        .environmentObject(profileViewModel)
                        
                        NotificationRowView(notification: createMockNotification(
                            title: "Bill Reminder", 
                            body: "Internet Bill ($89.99) is due today",
                            billName: "Internet Bill",
                            amount: 89.99,
                            identifier: "mock_due_today_2",
                            daysFromNow: 0
                        ))
                        .environmentObject(profileViewModel)
                    }
                }
                
                // Tomorrow section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("TOMORROW")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(1.2)
                        Spacer()
                        Text("1 REMINDER")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(1.2)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        NotificationRowView(notification: createMockNotification(
                            title: "Bill Reminder",
                            body: "Phone Bill ($55.00) is due in 4 days",
                            billName: "Phone Bill", 
                            amount: 55.00,
                            identifier: "mock_reminder_tomorrow",
                            daysFromNow: 1
                        ))
                        .environmentObject(profileViewModel)
                    }
                }
                
                // This week section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("FRIDAY, JANUARY 31")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(1.2)
                        Spacer()
                        Text("1 REMINDER")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(1.2)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        NotificationRowView(notification: createMockNotification(
                            title: "Bill Due Today",
                            body: "Rent ($1,200.00) is due today",
                            billName: "Rent",
                            amount: 1200.00,
                            identifier: "mock_rent_due",
                            daysFromNow: 3
                        ))
                        .environmentObject(profileViewModel)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private func createMockNotification(title: String, body: String, billName: String, amount: Double, identifier: String, daysFromNow: Int) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.userInfo = [
            "billName": billName,
            "amount": amount
        ]
        
        let futureDate = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: futureDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
    
    private func sectionTitle(for date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(date) {
            return "TODAY"
        } else if calendar.isDateInTomorrow(date) {
            return "TOMORROW"
        } else if calendar.isDateInYesterday(date) {
            return "YESTERDAY"
        } else {
            formatter.dateFormat = "EEEE, MMMM d"
            return formatter.string(from: date).uppercased()
        }
    }
}

#Preview {
    UpcomingNotificationsView()
        .environmentObject({
            let dataManager = DataManager()
            let sessionViewModel = SessionViewModel(dataManager: dataManager)
            return ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
        }())
}
