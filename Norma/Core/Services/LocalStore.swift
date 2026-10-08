//
//  LocalStore.swift
//  Norma
//
//  On-device persistence for the user profile. Norma has no accounts: the
//  profile is a JSON blob in UserDefaults, and every SwiftData row is scoped
//  to a stable per-install user ID generated on first launch.
//

import Foundation

enum LocalStore {

    private static let userIdKey = "norma.localUserId"
    private static let profileKey = "norma.localProfile"

    /// Stable identifier for this install. Adopts the ID of a previously
    /// signed-in account on this device, if any, so its local SwiftData rows
    /// (ledger, tokens, insights) stay attached after the move to local-only.
    static var userId: String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: userIdKey) {
            return existing
        }
        let id = SharedKeychainHelper.getUserId() ?? UUID().uuidString.lowercased()
        defaults.set(id, forKey: userIdKey)
        return id
    }

    static func loadProfile() -> Profile? {
        guard let data = UserDefaults.standard.data(forKey: profileKey) else { return nil }
        do {
            return try JSONDecoder().decode(Profile.self, from: data)
        } catch {
            print("LocalStore: failed to decode profile — \(error)")
            return nil
        }
    }

    static func saveProfile(_ profile: Profile) {
        do {
            let data = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(data, forKey: profileKey)
        } catch {
            print("LocalStore: failed to encode profile — \(error)")
        }
    }

    static func deleteProfile() {
        UserDefaults.standard.removeObject(forKey: profileKey)
    }
}
