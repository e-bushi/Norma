//
//  RewardQueueManager.swift
//  Norma
//
//  Created by Claude on 12/31/25.
//

import Foundation
import SwiftUI
import UIKit

/// Manages the queue of rewards to display, handling simultaneous triggers
/// Uses user-controlled progression (no auto-advance timers)
/// Syncs with backend pending_rewards table for persistence
@MainActor
class RewardQueueManager: ObservableObject {

    // MARK: - Singleton

    static let shared = RewardQueueManager()

    // MARK: - Published Properties

    /// The current reward being displayed (nil = no celebration showing)
    @Published private(set) var currentReward: Reward?

    /// Whether a celebration is currently visible (bindable for sheet presentation)
    @Published var isShowingCelebration: Bool = false

    /// Number of rewards waiting in queue (not including current)
    @Published private(set) var pendingRewardCount: Int = 0

    /// Animation state for transitions
    @Published var isAnimatingOut: Bool = false

    // MARK: - Private Properties

    private var rewardQueue: [Reward] = []
    private var isProcessing: Bool = false

    /// Maps local Reward IDs to backend PendingReward IDs for sync
    private var rewardIdMapping: [UUID: UUID] = [:]

    /// Current pending reward ID being shown (for marking as dismissed)
    private var currentPendingRewardId: UUID?

    /// Reference to SupabaseService for backend sync
    private weak var supabaseService: SupabaseService?

    /// Current user ID for backend operations
    private var currentUserId: String?

    // MARK: - Initialization

    private init() {}

    // MARK: - Configuration

    /// Configure the manager with dependencies for backend sync
    /// Call this after authentication success
    func configure(supabaseService: SupabaseService, userId: String) {
        self.supabaseService = supabaseService
        self.currentUserId = userId
        print("🎁 RewardQueueManager configured for user: \(userId)")
    }

    /// Clear user configuration (call on logout)
    func clearConfiguration() {
        supabaseService = nil
        currentUserId = nil
        rewardIdMapping.removeAll()
        currentPendingRewardId = nil
    }

    // MARK: - Public Methods

    /// Add a single reward to the queue (with optional backend persistence)
    func enqueue(_ reward: Reward) {
        rewardQueue.append(reward)
        pendingRewardCount = rewardQueue.count

        // Persist to backend in background
        persistRewardToBackend(reward)

        // Start processing if not already showing a celebration
        if !isProcessing {
            processNextReward()
        }
    }

    /// Add multiple rewards at once (for simultaneous triggers)
    func enqueue(_ rewards: [Reward]) {
        guard !rewards.isEmpty else { return }

        rewardQueue.append(contentsOf: rewards)
        pendingRewardCount = rewardQueue.count

        // Persist each to backend in background
        for reward in rewards {
            persistRewardToBackend(reward)
        }

        // Start processing if not already showing a celebration
        if !isProcessing {
            processNextReward()
        }
    }

    /// Add a reward that was fetched from backend (already persisted)
    /// - Parameters:
    ///   - reward: The reward to display
    ///   - pendingRewardId: The backend ID for sync
    func enqueueFromBackend(_ reward: Reward, pendingRewardId: UUID) {
        rewardQueue.append(reward)
        rewardIdMapping[reward.id] = pendingRewardId
        pendingRewardCount = rewardQueue.count

        // Start processing if not already showing a celebration
        if !isProcessing {
            processNextReward()
        }
    }

    /// Fetch and queue any unshown rewards from backend
    /// Call this on app launch/foreground after auth
    func fetchAndQueuePendingRewards() async {
        guard let service = supabaseService, let userId = currentUserId else {
            print("⚠️ RewardQueueManager: Not configured, skipping fetch")
            return
        }

        do {
            let pendingRewards = try await service.fetchUnshownPendingRewards(userId: userId)

            guard !pendingRewards.isEmpty else {
                print("🎁 No pending rewards to display")
                return
            }

            print("🎁 Found \(pendingRewards.count) pending rewards to display")

            await MainActor.run {
                for pending in pendingRewards {
                    if let reward = pending.toReward() {
                        rewardQueue.append(reward)
                        rewardIdMapping[reward.id] = pending.id
                    }
                }
                pendingRewardCount = rewardQueue.count

                if !isProcessing && !rewardQueue.isEmpty {
                    processNextReward()
                }
            }

        } catch {
            print("❌ Failed to fetch pending rewards: \(error)")
        }
    }

    /// Dismiss current reward and show next (called when user taps Continue/Next)
    func dismissCurrent() {
        // Haptic for button tap
        let lightFeedback = UIImpactFeedbackGenerator(style: .light)
        lightFeedback.impactOccurred()

        // Mark as dismissed on backend
        if let pendingId = currentPendingRewardId {
            markRewardAsDismissed(pendingId)
        }

        // Start animate-out
        isAnimatingOut = true

        // Wait for animation to complete, then process next
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s for animate-out

            await MainActor.run {
                isAnimatingOut = false
                currentReward = nil
                currentPendingRewardId = nil

                // Check if there are more rewards
                if rewardQueue.isEmpty {
                    // Final dismiss - success haptic
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)

                    isShowingCelebration = false
                    isProcessing = false
                    pendingRewardCount = 0
                } else {
                    // Brief pause before showing next reward
                    Task {
                        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15s pause
                        await MainActor.run {
                            processNextReward()
                        }
                    }
                }
            }
        }
    }

    /// Clear all pending rewards (e.g., on logout)
    func clearQueue() {
        rewardQueue.removeAll()
        currentReward = nil
        isShowingCelebration = false
        isProcessing = false
        isAnimatingOut = false
        pendingRewardCount = 0
        rewardIdMapping.removeAll()
        currentPendingRewardId = nil
        clearConfiguration()
    }

    // MARK: - Private Methods

    private func processNextReward() {
        guard !rewardQueue.isEmpty else {
            isProcessing = false
            pendingRewardCount = 0
            return
        }

        isProcessing = true
        let nextReward = rewardQueue.removeFirst()
        pendingRewardCount = rewardQueue.count

        // Track the pending reward ID for this reward
        currentPendingRewardId = rewardIdMapping[nextReward.id]

        // Mark as shown on backend
        if let pendingId = currentPendingRewardId {
            markRewardAsShown(pendingId)
        }

        // Haptic for reward appear
        let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
        mediumFeedback.impactOccurred()

        // Show the reward
        currentReward = nextReward
        isShowingCelebration = true
    }

    /// Persist a reward to the backend pending_rewards table
    private func persistRewardToBackend(_ reward: Reward) {
        guard let service = supabaseService, let userId = currentUserId else {
            print("⚠️ RewardQueueManager: Not configured, skipping persist")
            return
        }

        Task {
            do {
                let pendingReward = PendingReward.from(reward: reward, userId: userId)
                let saved = try await service.insertPendingReward(pendingReward)
                await MainActor.run {
                    rewardIdMapping[reward.id] = saved.id
                }
                print("🎁 Reward persisted to backend: \(reward.type.rawValue)")
            } catch {
                print("❌ Failed to persist reward: \(error)")
            }
        }
    }

    /// Mark a reward as shown on the backend
    private func markRewardAsShown(_ pendingRewardId: UUID) {
        guard let service = supabaseService else { return }

        Task {
            do {
                try await service.markPendingRewardAsShown(rewardId: pendingRewardId)
                print("🎁 Reward marked as shown: \(pendingRewardId)")
            } catch {
                print("❌ Failed to mark reward as shown: \(error)")
            }
        }
    }

    /// Mark a reward as dismissed on the backend
    private func markRewardAsDismissed(_ pendingRewardId: UUID) {
        guard let service = supabaseService else { return }

        Task {
            do {
                try await service.markPendingRewardAsDismissed(rewardId: pendingRewardId)
                print("🎁 Reward marked as dismissed: \(pendingRewardId)")
            } catch {
                print("❌ Failed to mark reward as dismissed: \(error)")
            }
        }
    }

    // MARK: - Computed Properties

    /// Whether there are more rewards after the current one
    var hasMoreRewards: Bool {
        !rewardQueue.isEmpty
    }

    /// Button text based on queue state
    var buttonText: String {
        hasMoreRewards ? "Next" : "Continue"
    }
}
