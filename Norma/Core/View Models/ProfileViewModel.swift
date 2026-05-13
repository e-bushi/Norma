//
//  ProfileViewModel.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var profile: Profile?
    @Published var currencyInfo: (name: String, code: String, symbol: String)?

    // UI State
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isEditingProfile = false
    @Published var hasUnsavedChanges = false

    // Profile Form Data
    @Published var editableProfile: Profile?
    @Published var profileImageData: Data?

    // MARK: - Dependencies

    private let dataManager: DataManager
    private let sessionViewModel: SessionViewModel

    // MARK: - Initialization

    init(dataManager: DataManager, sessionViewModel: SessionViewModel) {
        self.dataManager = dataManager
        self.sessionViewModel = sessionViewModel

        setupObservers()
        loadProfile()
    }

    // MARK: - Setup

    private func setupObservers() {
        sessionViewModel.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                if user != nil {
                    self?.loadProfile()
                }
            }
            .store(in: &cancellables)

        dataManager.$profiles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] profiles in
                if let userId = self?.sessionViewModel.currentUser?.userId,
                   let userProfile = profiles.first(where: { $0.userId == userId }) {
                    self?.profile = userProfile
                    self?.editableProfile = userProfile
                    self?.updateCurrencyInfo()
                }
            }
            .store(in: &cancellables)

        $editableProfile
            .combineLatest($profile)
            .sink { [weak self] editable, original in
                self?.hasUnsavedChanges = editable != original
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Data Loading

    func loadProfile() {
        guard let userId = sessionViewModel.currentUser?.userId else { return }

        isLoading = true
        clearError()

        Task {
            if let existingProfile = dataManager.profiles.first(where: { $0.userId == userId }) {
                profile = existingProfile
                editableProfile = existingProfile
            } else {
                let defaultProfile = Profile(
                    userId: userId,
                    email: sessionViewModel.currentUser?.email ?? "",
                    name: sessionViewModel.currentUser?.name ?? "User"
                )
                profile = defaultProfile
                editableProfile = defaultProfile
            }
            updateCurrencyInfo()

            await MainActor.run {
                isLoading = false
            }
        }
    }

    // MARK: - Profile Management

    func updateProfile(_ updatedProfile: Profile) async {
        isLoading = true
        clearError()

        if let index = dataManager.profiles.firstIndex(where: { $0.userId == updatedProfile.userId }) {
            dataManager.profiles[index] = updatedProfile
        } else {
            dataManager.profiles.append(updatedProfile)
        }
        profile = updatedProfile
        editableProfile = updatedProfile
        hasUnsavedChanges = false
        isEditingProfile = false
        updateCurrencyInfo()

        // Keep SessionViewModel.currentUser in sync — views read settings from
        // it and stale reads make changes look like nothing happened.
        if sessionViewModel.currentUser?.userId == updatedProfile.userId {
            sessionViewModel.currentUser = updatedProfile
        }

        isLoading = false
    }

    func saveProfileChanges() async {
        guard let updatedProfile = editableProfile else { return }
        await updateProfile(updatedProfile)
    }

    func discardProfileChanges() {
        editableProfile = profile
        hasUnsavedChanges = false
        isEditingProfile = false
    }

    func updateProfileImage(_ imageData: Data) async {
        guard var currentProfile = profile else { return }

        isLoading = true
        clearError()

        let imageUrl = "local://profile_image_\(currentProfile.userId)"
        currentProfile.profileImageUrl = imageUrl
        await updateProfile(currentProfile)

        isLoading = false
    }

    // MARK: - Currency Management

    private func updateCurrencyInfo() {
        guard let profile = profile else { return }
        currencyInfo = CurrencyData.getCurrencyTuple(for: profile.settings.currency)
    }

    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency

        if let currencyInfo = currencyInfo {
            formatter.currencyCode = currencyInfo.code
            formatter.currencySymbol = currencyInfo.symbol
            return formatter.string(from: NSNumber(value: amount)) ?? "\(currencyInfo.symbol)\(amount)"
        } else {
            let currencyCode = profile?.settings.currency ?? "USD"
            let symbol = CurrencyData.getSymbol(for: currencyCode)
            formatter.currencyCode = currencyCode
            formatter.currencySymbol = symbol
            return formatter.string(from: NSNumber(value: amount)) ?? "\(symbol)\(amount)"
        }
    }

    func formatCurrencyTruncated(_ amount: Double) -> String {
        let symbol = currencyInfo?.symbol ?? CurrencyData.getSymbol(for: profile?.settings.currency ?? "USD")

        if amount < 1000 {
            let hasDecimals = amount.truncatingRemainder(dividingBy: 1) > 0
            return "\(symbol)\(Int(amount))" + (hasDecimals ? "+" : "")
        } else if amount < 10000 {
            return "\(symbol)\(String(format: "%.1f", amount / 1000))K"
        } else if amount < 100000 {
            return "\(symbol)\(Int(amount / 1000))K"
        } else if amount < 1000000 {
            return "\(symbol)\(Int(amount / 1000))K"
        } else {
            if amount < 10000000 {
                return "\(symbol)\(String(format: "%.1f", amount / 1000000))M"
            } else {
                return "\(symbol)\(Int(amount / 1000000))M"
            }
        }
    }

    func updateCurrency(_ newCurrencyCode: String) {
        guard var currentProfile = profile else { return }
        currentProfile.settings.currency = newCurrencyCode
        Task {
            await updateProfile(currentProfile)
        }
    }

    func updateMonthlyIncome(_ newIncome: Double) {
        guard var currentProfile = profile else { return }
        currentProfile.settings.monthlyIncome = newIncome
        Task {
            await updateProfile(currentProfile)
        }
    }

    /// Sets the user's daily-rate baseline used to fill empty days in the
    /// forecast. Pass `nil` to revert to the auto-calculated default
    /// (breathing room ÷ days left in month).
    func updateDailyRate(_ newRate: Double?) {
        guard var currentProfile = profile else { return }
        currentProfile.settings.dailyRate = newRate
        Task {
            await updateProfile(currentProfile)
        }
    }

    // MARK: - Error Handling

    private func clearError() {
        showError = false
        errorMessage = ""
    }

    private func showError(_ message: String) {
        errorMessage = message
        showError = true

        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await MainActor.run {
                clearError()
            }
        }
    }
}
