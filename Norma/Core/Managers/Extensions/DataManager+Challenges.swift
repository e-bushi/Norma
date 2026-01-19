//
//  DataManager+Challenges.swift
//  Norma
//
//  Created by Claude on 12/22/25.
//

import Foundation
import SwiftData

extension DataManager {

    // MARK: - Challenge Methods

    func fetchChallenges(userId: String) async throws {
        do {
            // Try to fetch from Supabase first
            let fetchedChallenges = try await supabaseService.fetchChallenges(userId: userId)
            challenges = fetchedChallenges

            // Cache challenges in SwiftData
            await cacheChallenges(fetchedChallenges)

            print("Fetched \(fetchedChallenges.count) challenges from server")
        } catch {
            // If fetch fails (offline), load from cache
            print("Failed to fetch challenges from server: \(error). Loading from cache...")

            // If we have cached data, don't throw the error
            if !challenges.isEmpty {
                print("Loaded \(challenges.count) challenges from cache")
            } else {
                throw error
            }
        }
    }

    func addChallenge(_ challenge: Challenge) async throws {
        do {
            // Don't send ID when creating - let database generate it
            var challengeForCreation = challenge
            challengeForCreation.id = nil

            let createdChallenge = try await supabaseService.createChallenge(challengeForCreation)

            // Add the server-created challenge to local state
            challenges.append(createdChallenge)

            // Cache the challenge locally
            await cacheChallenges([createdChallenge])

            print("Added challenge with amount: \(createdChallenge.amountTotal)")

        } catch {
            print("Failed to create challenge on server: \(error)")

            // Fallback to offline mode
            var challengeToAdd = challenge
            if challengeToAdd.id == nil {
                challengeToAdd.id = UUID().uuidString
            }

            // Add to local state for offline usage
            challenges.append(challengeToAdd)

            // Cache the challenge locally
            await cacheChallenges([challengeToAdd])

            hasUnsyncedChanges = true

            throw error
        }
    }

    func updateChallenge(_ challenge: Challenge) async throws {
        let updatedChallenge = try await supabaseService.updateChallenge(challenge)

        if let index = challenges.firstIndex(where: { $0.id == challenge.id }) {
            challenges[index] = updatedChallenge
            hasUnsyncedChanges = true
        }

        // Update cache
        await updateCachedChallenge(updatedChallenge)

        print("Updated challenge: \(challenge.id ?? "unknown")")
    }

    func deleteChallenge(_ challenge: Challenge) async throws {
        guard let challengeId = challenge.id else {
            throw NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Challenge ID is required for deletion"])
        }

        try await supabaseService.deleteChallenge(challengeId)
        challenges.removeAll { $0.id == challenge.id }
        hasUnsyncedChanges = true

        // Remove from cache
        await deleteCachedChallenge(challengeId)

        print("Deleted challenge: \(challengeId)")
    }

    // MARK: - Challenge Queries

    /// Get the current active challenge (should only be one)
    func getActiveChallenge() -> Challenge? {
        return challenges.first { $0.status == .active }
    }

    /// Get challenges by status
    func getChallenges(byStatus status: ChallengeStatus) -> [Challenge] {
        return challenges.filter { $0.status == status }
            .sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
    }

    /// Get challenge history (completed and failed)
    func getChallengeHistory() -> [Challenge] {
        return challenges.filter { $0.status != .active }
            .sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
    }

    /// Update challenge remaining amount when expense is logged
    func updateChallengeRemaining(challengeId: String, amountSpent: Double) async throws {
        guard let challenge = challenges.first(where: { $0.id == challengeId }) else {
            throw NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Challenge not found"])
        }

        var updatedChallenge = challenge
        updatedChallenge.amountRemaining = challenge.amountRemaining - amountSpent

        // Check if challenge failed (went over budget)
        if updatedChallenge.amountRemaining < 0 {
            updatedChallenge.status = .failed
        }

        try await updateChallenge(updatedChallenge)
    }

    /// Complete the active challenge with success or failure
    func completeActiveChallenge(success: Bool) async throws {
        guard var challenge = getActiveChallenge() else { return }

        challenge.status = success ? .completed : .failed
        try await updateChallenge(challenge)
    }

    // MARK: - SwiftData Caching

    private func cacheChallenges(_ challengesToCache: [Challenge]) async {
        guard let modelContext = modelContext else { return }

        do {
            // First, clear existing cached challenges for this user
            if let userId = currentProfile?.userId {
                let descriptor = FetchDescriptor<CachedChallenge>(
                    predicate: #Predicate { cachedChallenge in
                        cachedChallenge.userId == userId
                    }
                )

                let existingCached = try modelContext.fetch(descriptor)
                for cached in existingCached {
                    modelContext.delete(cached)
                }
            }

            // Then insert new cached challenges
            for challenge in challengesToCache {
                let cachedChallenge = CachedChallenge(from: challenge)
                modelContext.insert(cachedChallenge)
            }

            try modelContext.save()
            print("Successfully cached \(challengesToCache.count) challenges")
        } catch {
            print("Failed to cache challenges: \(error)")
        }
    }

    private func updateCachedChallenge(_ challenge: Challenge) async {
        guard let modelContext = modelContext,
              let challengeId = challenge.id else { return }

        do {
            let descriptor = FetchDescriptor<CachedChallenge>(
                predicate: #Predicate { cachedChallenge in
                    cachedChallenge.id == challengeId
                }
            )

            if let existingCached = try modelContext.fetch(descriptor).first {
                // Update existing cached challenge
                existingCached.amountTotal = challenge.amountTotal
                existingCached.amountRemaining = challenge.amountRemaining
                existingCached.currency = challenge.currency
                existingCached.startDate = challenge.startDate
                existingCached.endDate = challenge.endDate
                existingCached.status = challenge.status.rawValue
                existingCached.updatedAt = Date()
                existingCached.lastSyncedAt = Date()
            } else {
                // Create new cached challenge if not found
                let cachedChallenge = CachedChallenge(from: challenge)
                modelContext.insert(cachedChallenge)
            }

            try modelContext.save()
            print("Updated cached challenge: \(challengeId)")
        } catch {
            print("Failed to update cached challenge: \(error)")
        }
    }

    private func deleteCachedChallenge(_ challengeId: String) async {
        guard let modelContext = modelContext else { return }

        do {
            let descriptor = FetchDescriptor<CachedChallenge>(
                predicate: #Predicate { cachedChallenge in
                    cachedChallenge.id == challengeId
                }
            )

            if let cachedChallenge = try modelContext.fetch(descriptor).first {
                modelContext.delete(cachedChallenge)
                try modelContext.save()
                print("Deleted cached challenge with id: \(challengeId)")
            }
        } catch {
            print("Failed to delete cached challenge: \(error)")
        }
    }
}
