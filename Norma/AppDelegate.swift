//
//  AppDelegate.swift
//  Norma
//
//  App Delegate for handling push notifications
//

import UIKit
import UserNotifications
import GoogleSignIn
//Plaid recovery code: L6YR3QSTL42LNDZPYV4CW6ZBPU
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    // MARK: - Application Lifecycle

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        UNUserNotificationCenter.current().delegate = self
        registerForPushNotifications()

        return true
    }

    // MARK: - URL Handling for Google Sign-In

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Push Notification Registration

    private func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Failed to request notification authorization: \(error)")
                return
            }

            guard granted else {
                print("User denied notification permissions")
                return
            }

            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    // MARK: - Device Token Handling

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(token)")

        // Store token in shared keychain for Share Extension access
        let stored = SharedKeychainHelper.storeDeviceToken(token)
        print("Device token stored in shared keychain: \(stored)")
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    // MARK: - Handle Notification Tap

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo

        // Check if this is a pending transaction notification
        if let type = userInfo["type"] as? String, type == "pending_transaction" {
            // Post notification to show pending transactions popover
            await MainActor.run {
                NotificationCenter.default.post(
                    name: Notification.Name("ShowPendingTransactions"),
                    object: nil,
                    userInfo: userInfo
                )
            }
        }
    }

    // MARK: - Handle Foreground Notification

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound, .badge]
    }
}
