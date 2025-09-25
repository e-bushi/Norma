//
//  TrialStatusBanner.swift
//  Norma
//
//  Created by Assistant on 12/17/24.
//

import SwiftUI

struct TrialStatusBanner: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    @State private var isPressed = false
    
    private enum BannerState {
        case noTrial          // User hasn't started trial
        case activeTrial      // User is in trial
        case expiredTrial     // Trial ended, no subscription
        case activeSubscription // Has active subscription (don't show banner)
    }
    
    private var bannerState: BannerState {
        if subscriptionManager.hasActiveSubscription && !subscriptionManager.isInFreeTrial {
            return .activeSubscription
        } else if subscriptionManager.isInFreeTrial {
            return .activeTrial
        } else if subscriptionManager.hasUsedFreeTrial {
            return .expiredTrial
        } else {
            return .noTrial
        }
    }
    
    var body: some View {
        let _ = print("🎯 TrialStatusBanner - State: \(bannerState), isInFreeTrial: \(subscriptionManager.isInFreeTrial), hasActiveSubscription: \(subscriptionManager.hasActiveSubscription), hasUsedTrial: \(subscriptionManager.hasUsedFreeTrial)")
        
        // Don't show banner for active subscribers
        if bannerState != .activeSubscription {
            Button {
                print("🎯 Trial banner tapped - Opening paywall")
                showPaywall = true
            } label: {
                HStack(spacing: 16) {
                    // Status icon
                    ZStack {
                        Circle()
                            .fill(iconBackgroundColor.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: iconName)
                            .font(.system(size: 18))
                            .foregroundColor(iconColor)
                    }
                    
                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(titleText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(subtitleText)
                            .font(.system(size: 12))
                            .foregroundColor(subtitleColor)
                    }
                    
                    Spacer()
                    
                    // Call to action
                    Text(actionText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(actionColor)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(backgroundColorForState.opacity(isPressed ? 0.15 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColorForState.opacity(isPressed ? 0.4 : 0.2), lineWidth: 1)
                )
                .cornerRadius(16)
                .scaleEffect(isPressed ? 0.98 : 1.0)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle()) // Ensure entire area is tappable
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }, perform: {})
            .padding(.horizontal, 42)
            .padding(.bottom, 8)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Computed Properties for Each State
    
    private var iconName: String {
        switch bannerState {
        case .noTrial: return "gift.fill"
        case .activeTrial: return "sparkles"
        case .expiredTrial: return "clock.badge.exclamationmark.fill"
        case .activeSubscription: return "checkmark.seal.fill"
        }
    }
    
    private var iconColor: Color {
        switch bannerState {
        case .noTrial: return .purple
        case .activeTrial: return .purple
        case .expiredTrial: return .orange
        case .activeSubscription: return .green
        }
    }
    
    private var iconBackgroundColor: Color {
        switch bannerState {
        case .noTrial: return .purple
        case .activeTrial: return .purple
        case .expiredTrial: return .orange
        case .activeSubscription: return .green
        }
    }
    
    private var titleText: String {
        switch bannerState {
        case .noTrial: return "Start Your Free Trial"
        case .activeTrial: return "Free Trial Active"
        case .expiredTrial: return "Trial Ended"
        case .activeSubscription: return "Pro Active"
        }
    }
    
    private var subtitleText: String {
        switch bannerState {
        case .noTrial:
            return "Get 3 days free"
        case .activeTrial:
            let daysRemaining = subscriptionManager.trialDaysRemaining ?? 0
            return getSimpleTrialText(daysRemaining: daysRemaining)
        case .expiredTrial:
            return "Subscribe to continue"
        case .activeSubscription:
            return "All features unlocked"
        }
    }
    
    private var subtitleColor: Color {
        switch bannerState {
        case .expiredTrial: return .orange
        default: return .secondary
        }
    }
    
    private var actionText: String {
        switch bannerState {
        case .noTrial: return "Start Free"
        case .activeTrial: return "View Plans"
        case .expiredTrial: return "Subscribe"
        case .activeSubscription: return "Manage"
        }
    }
    
    private var actionColor: Color {
        switch bannerState {
        case .noTrial: return .purple
        case .activeTrial: return .purple
        case .expiredTrial: return .orange
        case .activeSubscription: return .green
        }
    }
    
    private var backgroundColorForState: Color {
        switch bannerState {
        case .noTrial: return .purple
        case .activeTrial: return .purple
        case .expiredTrial: return .orange
        case .activeSubscription: return .green
        }
    }
    
    private var borderColorForState: Color {
        switch bannerState {
        case .noTrial: return .purple
        case .activeTrial: return .purple
        case .expiredTrial: return .orange
        case .activeSubscription: return .green
        }
    }
    
    // MARK: - Helper Functions
    
    private func getTrialText(daysRemaining: Int) -> String {
        switch daysRemaining {
        case 0:
            return "Free trial ends today!"
        case 1:
            return "Free trial - 1 day left"
        default:
            return "Free trial - \(daysRemaining) days left"
        }
    }
    
    private func getTrialDetailText(daysRemaining: Int) -> String {
        switch daysRemaining {
        case 0:
            return "Your free trial ends today"
        case 1:
            return "You have 1 day left in your free trial"
        default:
            return "You have \(daysRemaining) days left in your free trial"
        }
    }
    
    private func getSimpleTrialText(daysRemaining: Int) -> String {
        switch daysRemaining {
        case 0:
            return "Ends today"
        case 1:
            return "1 day remaining"
        default:
            return "\(daysRemaining) days remaining"
        }
    }
}

#Preview {
    VStack {
        TrialStatusBanner()
        Spacer()
    }
}
