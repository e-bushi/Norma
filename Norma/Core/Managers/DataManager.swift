//
//  DataManager.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//
//  Owns the user's financial data. Everything lives on device: the profile
//  in LocalStore, bills in SwiftData (CachedBill).
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class DataManager: ObservableObject {

    // MARK: - Published Properties

    @Published var currentProfile: Profile?
    @Published var income: [Income] = []
    @Published var bills: [Bill] = []
    @Published var isLoading = false

    // MARK: - SwiftData

    var modelContext: ModelContext?

    // MARK: - Initialization

    init() {
        currentProfile = LocalStore.loadProfile()
    }

    /// Hands DataManager the app's ModelContext and loads persisted bills.
    func setModelContext(_ context: ModelContext) {
        modelContext = context
        loadBills()
    }

    // MARK: - Profile

    func saveProfile(_ profile: Profile) {
        currentProfile = profile
        LocalStore.saveProfile(profile)
    }

    // MARK: - Reset

    /// Erases every piece of user data on this device.
    func resetAllData() {
        LocalStore.deleteProfile()
        LocalDataReset.wipeAll()
        clearAllData()
    }

    func clearAllData() {
        currentProfile = nil
        income.removeAll()
        bills.removeAll()
    }

    // MARK: - Computed Properties

    var totalMonthlyIncome: Double {
        getTotalMonthlyIncome()
    }

    var totalMonthlyBills: Double {
        getTotalMonthlyBills()
    }
}
