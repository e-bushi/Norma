//
//  NotificationService.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    // MARK: - Published Properties
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingNotifications: [UNNotificationRequest] = []
    @Published var isNotificationsEnabled: Bool = false
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Notification Categories
    private let billReminderCategory = "BILL_REMINDER"
    private let markPaidAction = "MARK_PAID"
    private let snoozeAction = "SNOOZE"
    
    // MARK: - Initialization
    override init() {
        super.init()
        notificationCenter.delegate = self
        setupNotificationCategories()
        checkNotificationPermission()
    }
    
    // MARK: - Permission Management
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await checkNotificationPermission()
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    func checkNotificationPermission() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            await MainActor.run {
                notificationPermissionStatus = settings.authorizationStatus
                isNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notification Categories Setup
    private func setupNotificationCategories() {
        let markPaidAction = UNNotificationAction(
            identifier: markPaidAction,
            title: "Mark as Paid",
            options: [.authenticationRequired]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: snoozeAction,
            title: "Remind Later",
            options: []
        )
        
        let billCategory = UNNotificationCategory(
            identifier: billReminderCategory,
            actions: [markPaidAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([billCategory])
    }
    
    // MARK: - Bill Reminder Scheduling
    func scheduleBillReminders(for bill: Bill) async {
        guard isNotificationsEnabled else { return }
        
        // Remove existing notifications for this bill
        await cancelNotifications(for: bill)
        
        // Use the bill's own reminder preference, default to 3 if not set
        let reminderDays = bill.reminderDays ?? 3
        
        // Calculate notification dates based on bill frequency
        let notificationDates = calculateNotificationDates(for: bill, reminderDays: reminderDays)
        
        for (index, date) in notificationDates.enumerated() {
            let content = createBillReminderContent(for: bill, dueDate: date.dueDate, isOnDueDate: date.isOnDueDate)
            
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date.notificationDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let identifier = "\(bill.id ?? "")_\(index)_\(date.isOnDueDate ? "due" : "reminder")"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            do {
                try await notificationCenter.add(request)
                print("Scheduled notification for \(bill.name) on \(date.notificationDate)")
            } catch {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    private func createBillReminderContent(for bill: Bill, dueDate: Date, isOnDueDate: Bool) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let amount = formatter.string(from: NSNumber(value: bill.amount)) ?? "$\(bill.amount)"
        
        if isOnDueDate {
            content.title = "Bill Due Today"
            content.body = "\(bill.name) (\(amount)) is due today"
        } else {
            let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
            content.title = "Bill Reminder"
            content.body = "\(bill.name) (\(amount)) is due in \(daysUntilDue) days"
        }
        
        content.sound = .default
        content.categoryIdentifier = billReminderCategory
        content.userInfo = [
            "billId": bill.id ?? "",
            "billName": bill.name,
            "amount": bill.amount,
            "dueDate": dueDate.timeIntervalSince1970
        ]
        
        return content
    }
    
    private func calculateNotificationDates(for bill: Bill, reminderDays: Int) -> [(notificationDate: Date, dueDate: Date, isOnDueDate: Bool)] {
        var dates: [(Date, Date, Bool)] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Use the bill's current due date
        let dueDateStart = calendar.startOfDay(for: bill.dueDate)
        
        // If today > bill due date, do nothing for now
        if today > dueDateStart {
            return dates
        }
        
        // Calculate reminder date (due date - reminder days)
        if reminderDays > 0 {
            if let reminderDate = calendar.date(byAdding: .day, value: -reminderDays, to: dueDateStart) {
                let reminderDateStart = calendar.startOfDay(for: reminderDate)
                
                if reminderDateStart > today {
                    // If reminderDate > today, schedule notification to trigger on reminderDate
                    if let notificationTime = setNotificationTime(for: reminderDateStart, hour: 9) {
                        dates.append((notificationTime, bill.dueDate, false))
                    }
                }
            }
        }
        
        // Add due date notification if it's in the future
        if dueDateStart > today {
            if let notificationTime = setNotificationTime(for: dueDateStart, hour: 9) {
                dates.append((notificationTime, bill.dueDate, true))
            }
        }
        
        return dates
    }
    
    private func setNotificationTime(for date: Date, hour: Int) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components)
    }
    
    // MARK: - Notification Management
    func cancelNotifications(for bill: Bill) async {
        let identifiers = await getPendingNotificationIdentifiers(for: bill)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func getPendingNotificationIdentifiers(for bill: Bill) async -> [String] {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests
            .filter { $0.identifier.starts(with: bill.id ?? "") }
            .map { $0.identifier }
    }
    
    func refreshPendingNotifications() async {
        pendingNotifications = await notificationCenter.pendingNotificationRequests()
    }
    
    // MARK: - Schedule All Bill Reminders
    func scheduleAllBillReminders(bills: [Bill]) async {
        for bill in bills {
            if bill.status == .scheduled {
                await scheduleBillReminders(for: bill)
            }
        }
    }
    
    // MARK: - Handle Notification Actions
    func handleNotificationAction(_ actionIdentifier: String, userInfo: [AnyHashable: Any]) async {
        guard let billId = userInfo["billId"] as? String else { return }
        
        switch actionIdentifier {
        case markPaidAction:
            // This would need to be handled by the BillViewModel
            NotificationCenter.default.post(
                name: Notification.Name("MarkBillAsPaid"),
                object: nil,
                userInfo: ["billId": billId]
            )
            
        case snoozeAction:
            // Reschedule for tomorrow at the same time
            if let billName = userInfo["billName"] as? String,
               let amount = userInfo["amount"] as? Double {
                await scheduleSnoozeReminder(billId: billId, billName: billName, amount: amount)
            }
            
        default:
            break
        }
    }
    
    private func scheduleSnoozeReminder(billId: String, billName: String, amount: Double) async {
        let content = UNMutableNotificationContent()
        content.title = "Snoozed Bill Reminder"
        content.body = "\(billName) - Don't forget to pay this bill!"
        content.sound = .default
        content.categoryIdentifier = billReminderCategory
        content.userInfo = [
            "billId": billId,
            "billName": billName,
            "amount": amount
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false) // 24 hours
        let request = UNNotificationRequest(
            identifier: "\(billId)_snooze_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule snooze notification: \(error)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Show notifications even when app is in foreground
        return [.banner, .sound, .badge]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case markPaidAction, snoozeAction:
            await handleNotificationAction(response.actionIdentifier, userInfo: userInfo)
        case UNNotificationDefaultActionIdentifier:
            // User tapped on the notification
            NotificationCenter.default.post(
                name: Notification.Name("OpenBillDetail"),
                object: nil,
                userInfo: userInfo
            )
        default:
            break
        }
    }
}

// MARK: - Bill Extension for Notification Support
extension Bill {
    func getNextDueDates(count: Int, from startDate: Date) -> [Date] {
        guard count > 0 else { return [] }
        
        var dates: [Date] = []
        var currentDate = startDate
        let calendar = Calendar.current
        
        while dates.count < count {
            if let nextDue = getNextDueDate(from: currentDate) {
                dates.append(nextDue)
                currentDate = calendar.date(byAdding: .day, value: 1, to: nextDue) ?? nextDue
            } else {
                break
            }
        }
        
        return dates
    }
    
    private func getNextDueDate(from date: Date) -> Date? {
        let calendar = Calendar.current
        
        var nextDate = self.dueDate
        
        // Calculate next occurrence based on frequency
        switch self.frequency {
        case .monthly:
            while nextDate < date {
                nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate) ?? nextDate
            }
            
        case .quarterly:
            while nextDate < date {
                nextDate = calendar.date(byAdding: .month, value: 3, to: nextDate) ?? nextDate
            }
            
        case .yearly:
            while nextDate < date {
                nextDate = calendar.date(byAdding: .year, value: 1, to: nextDate) ?? nextDate
            }
        }
        
        return nextDate
    }
}
