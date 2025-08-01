//
//  SubscriptionManager.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import Foundation
import RevenueCat
import SwiftUI

@MainActor
class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var subscriptionStatus = SubscriptionStatus.inactive
    @Published var availableProducts: [SubscriptionProduct] = []
    @Published var isLoadingProducts = false
    @Published var purchaseError: Error?
    
    private override init() {
        super.init()
        
        // Skip initialization in preview mode
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // Set mock data for previews
            self.isLoadingProducts = false
            self.availableProducts = []
            self.subscriptionStatus = .inactive
            return
        }
        #endif
        
        Task {
            await checkSubscriptionStatus()
            await loadProducts()
        }
        
        Purchases.shared.delegate = self
    }
    
    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateSubscriptionStatus(from: customerInfo)
        } catch {
            print("Error checking subscription status: \(error)")
            subscriptionStatus = .inactive
        }
    }
    
    private func updateSubscriptionStatus(from customerInfo: CustomerInfo) {
        let activeSubscriptions = customerInfo.activeSubscriptions
        
        var activeTier: SubscriptionTier?
        var expirationDate: Date?
        var willRenew = false
        var isInTrialPeriod = false
        var isInIntroOfferPeriod = false
        
        for productId in activeSubscriptions {
            if productId.contains("base") {
                activeTier = .base
            } else if productId.contains("pro") {
                activeTier = .pro
            }
        }
        
        if let tier = activeTier,
           let entitlement = customerInfo.entitlements[tier.rawValue] {
            expirationDate = entitlement.expirationDate
            willRenew = entitlement.willRenew
            isInTrialPeriod = entitlement.isActiveInCurrentEnvironment && entitlement.periodType == .trial
            isInIntroOfferPeriod = entitlement.isActiveInCurrentEnvironment && entitlement.periodType == .intro
        }
        
        subscriptionStatus = SubscriptionStatus(
            isActive: activeTier != nil,
            tier: activeTier,
            expirationDate: expirationDate,
            willRenew: willRenew,
            isInTrialPeriod: isInTrialPeriod,
            isInIntroOfferPeriod: isInIntroOfferPeriod
        )
    }
    
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let currentOffering = offerings.current else {
                print("No current offering found")
                return
            }
            
            var products: [SubscriptionProduct] = []
            
            for tier in SubscriptionTier.allCases {
                if let monthlyPackage = currentOffering.package(identifier: tier.monthlyProductId) {
                    products.append(SubscriptionProduct(
                        tier: tier,
                        package: monthlyPackage,
                        isMonthly: true
                    ))
                }
                
                if let annualPackage = currentOffering.package(identifier: tier.annualProductId) {
                    products.append(SubscriptionProduct(
                        tier: tier,
                        package: annualPackage,
                        isMonthly: false
                    ))
                }
            }
            
            availableProducts = products
        } catch {
            print("Error loading products: \(error)")
            purchaseError = error
        }
    }
    
    func purchase(_ product: SubscriptionProduct) async throws {
        purchaseError = nil
        
        do {
            let result = try await Purchases.shared.purchase(package: product.package)
            
            if !result.userCancelled {
                updateSubscriptionStatus(from: result.customerInfo)
            }
        } catch {
            purchaseError = error
            throw error
        }
    }
    
    func restorePurchases() async throws {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updateSubscriptionStatus(from: customerInfo)
        } catch {
            purchaseError = error
            throw error
        }
    }
    
    var hasActiveSubscription: Bool {
        subscriptionStatus.isActive
    }
    
    var hasProSubscription: Bool {
        subscriptionStatus.tier == .pro
    }
    
    var canAccessFinancialMind: Bool {
        hasProSubscription
    }
}

extension SubscriptionManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            updateSubscriptionStatus(from: customerInfo)
        }
    }
}