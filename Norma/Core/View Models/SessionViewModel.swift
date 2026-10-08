//
//  SessionViewModel.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//
//  Holds the on-device user profile and whether onboarding is finished.
//  There are no accounts: a saved profile *is* the session.
//

import Foundation
import SwiftUI

@MainActor
class SessionViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentUser: Profile?
    @Published var hasCompletedOnboarding: Bool

    // MARK: - Services

    private let dataManager: DataManager

    // MARK: - Initialization

    init(dataManager: DataManager) {
        self.dataManager = dataManager
        self.currentUser = dataManager.currentProfile
        self.hasCompletedOnboarding = dataManager.currentProfile != nil
    }

    // MARK: - Profile

    func updateUserProfile(_ profile: Profile) {
        currentUser = profile
        dataManager.saveProfile(profile)
    }

    // MARK: - Onboarding

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    // MARK: - Reset

    /// Erases all on-device data and returns the app to onboarding.
    func resetAllData() {
        dataManager.resetAllData()
        currentUser = nil
        hasCompletedOnboarding = false
        AnalyticsService.shared.reset()
    }
}
