//
//  NotificationRowView.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import SwiftUI
import UserNotifications

struct NotificationRowView: View {
    let notification: UNNotificationRequest
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    private var notificationDate: Date? {
        guard let trigger = notification.trigger as? UNCalendarNotificationTrigger,
              let date = trigger.nextTriggerDate() else { return nil }
        return date
    }
    
    private var billName: String {
        notification.content.userInfo["billName"] as? String ?? "Unknown Bill"
    }
    
    private var billAmount: Double {
        notification.content.userInfo["amount"] as? Double ?? 0
    }
    
    private var isReminderNotification: Bool {
        notification.identifier.contains("reminder")
    }
    
    private var isDueNotification: Bool {
        notification.identifier.contains("due")
    }
    
    private var timeUntilNotification: String {
        guard let date = notificationDate else { return "Unknown" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private var notificationIcon: String {
        if isDueNotification {
            return "bell.badge.fill"
        } else {
            return "bell.fill"
        }
    }
    
    private var notificationColor: Color {
        if isDueNotification {
            return .red
        } else {
            return .orange
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(notificationColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: notificationIcon)
                    .font(.system(size: 18))
                    .foregroundColor(notificationColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(billName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Text(profileViewModel.formatCurrency(billAmount))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                }
            }
            
            Spacer()
            
            // Time
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeUntilNotification)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(notificationColor)
                
                if let date = notificationDate {
                    Text(date, style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(UIColor.systemBackground),
                            Color.gray.opacity(0.02)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.2),
                                    Color.gray.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

#Preview {
    // Create a mock notification for preview
    let content = UNMutableNotificationContent()
    content.title = "Bill Reminder"
    content.body = "Electricity Bill ($150) is due in 3 days"
    content.userInfo = [
        "billName": "Electricity Bill",
        "amount": 150.0
    ]
    
    let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date().addingTimeInterval(259200)) // 3 days
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    
    let request = UNNotificationRequest(
        identifier: "preview_reminder",
        content: content,
        trigger: trigger
    )
    
    return NotificationRowView(notification: request)
        .environmentObject({
            let dataManager = DataManager()
            let sessionViewModel = SessionViewModel(dataManager: dataManager)
            return ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
        }())
        .padding()
}
