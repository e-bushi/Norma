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
            print("📱 RevenueCat CustomerInfo - Active Subscriptions: \(customerInfo.activeSubscriptions)")
            print("📱 RevenueCat CustomerInfo - Entitlements: \(customerInfo.entitlements.all.keys)")
            updateSubscriptionStatus(from: customerInfo)
        } catch {
            print("Error checking subscription status: \(error)")
            subscriptionStatus = .inactive
        }
    }
    
    private func updateSubscriptionStatus(from customerInfo: CustomerInfo) {
        let activeSubscriptions = customerInfo.activeSubscriptions
        print("📱 Active subscriptions: \(activeSubscriptions)")
        print("📱 All entitlements: \(customerInfo.entitlements.all.keys)")
        
        var activeTier: SubscriptionTier?
        var expirationDate: Date?
        var willRenew = false
        var isInTrialPeriod = false
        var isInIntroOfferPeriod = false
        
        // First, check if there are any active entitlements at all
        if let firstActiveEntitlement = customerInfo.entitlements.active.values.first {
            print("✅ Found active entitlement: \(firstActiveEntitlement.identifier)")
            
            // Determine tier from either the product ID or entitlement ID
            for productId in activeSubscriptions {
                print("🔍 Checking productId: \(productId)")
                if productId.contains("base") {
                    activeTier = .base
                } else if productId.contains("pro") {
                    activeTier = .pro
                } else {
                    // Default to pro if we have any active subscription
                    activeTier = .pro
                }
            }
            
            // If we still don't have a tier, default to pro for any active entitlement
            if activeTier == nil && !activeSubscriptions.isEmpty {
                activeTier = .pro
            }
            
            // Use the active entitlement details
            expirationDate = firstActiveEntitlement.expirationDate
            willRenew = firstActiveEntitlement.willRenew
            isInTrialPeriod = firstActiveEntitlement.periodType == .trial
            isInIntroOfferPeriod = firstActiveEntitlement.periodType == .intro
            
            print("✅ Subscription status - tier: \(activeTier?.rawValue ?? "nil"), isActive: true, periodType: \(firstActiveEntitlement.periodType)")
        } else {
            print("❌ No active entitlements found")
            
            // Still check for active subscriptions without entitlements (edge case)
            if !activeSubscriptions.isEmpty {
                print("⚠️ Active subscriptions found without entitlements: \(activeSubscriptions)")
                activeTier = .pro // Default to pro if there are active subscriptions
            }
        }
        
        subscriptionStatus = SubscriptionStatus(
            isActive: activeTier != nil || !customerInfo.entitlements.active.isEmpty,
            tier: activeTier,
            expirationDate: expirationDate,
            willRenew: willRenew,
            isInTrialPeriod: isInTrialPeriod,
            isInIntroOfferPeriod: isInIntroOfferPeriod
        )
        
        // Mark trial as used if user is in trial or has had a trial
        if isInTrialPeriod || (expirationDate != nil && activeTier != nil) {
            markTrialAsUsed()
        }
    }
    
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        
        do {
            print("🚀 Loading offerings from RevenueCat...")
            let offerings = try await Purchases.shared.offerings()
            
            print("📦 Offerings: \(offerings.all.keys)")
            print("📦 Current offering: \(offerings.current?.identifier ?? "nil")")
            
            guard let currentOffering = offerings.current else {
                print("❌ No current offering found")
                // Try to use default offering
                if let defaultOffering = offerings.offering(identifier: "default") {
                    print("📦 Using default offering instead")
                }
                return
            }
            
            print("📦 Available packages: \(currentOffering.availablePackages.map { $0.identifier })")
            
            var products: [SubscriptionProduct] = []
            
            // Load both Base and Pro tier products using RevenueCat package identifiers
            for tier in SubscriptionTier.allCases {
                // Map to RevenueCat package identifiers (simplified naming)
                let monthlyPackageId = tier == .base ? "base_monthly" : "pro_monthly"
                let annualPackageId = tier == .base ? "base_yearly" : "pro_yearly"
                
                print("🔍 Looking for monthly package: \(monthlyPackageId)")
                if let monthlyPackage = currentOffering.package(identifier: monthlyPackageId) {
                    products.append(SubscriptionProduct(
                        tier: tier,
                        package: monthlyPackage,
                        isMonthly: true
                    ))
                    print("✅ Found monthly package for \(tier.rawValue)")
                } else {
                    print("❌ Monthly package not found: \(monthlyPackageId)")
                    // Fallback: try using product ID
                    if let monthlyPackage = currentOffering.package(identifier: tier.monthlyProductId) {
                        products.append(SubscriptionProduct(
                            tier: tier,
                            package: monthlyPackage,
                            isMonthly: true
                        ))
                        print("✅ Found monthly package using product ID: \(tier.monthlyProductId)")
                    }
                }
                
                print("🔍 Looking for annual package: \(annualPackageId)")
                if let annualPackage = currentOffering.package(identifier: annualPackageId) {
                    products.append(SubscriptionProduct(
                        tier: tier,
                        package: annualPackage,
                        isMonthly: false
                    ))
                    print("✅ Found annual package for \(tier.rawValue)")
                } else {
                    print("❌ Annual package not found: \(annualPackageId)")
                    // Fallback: try using product ID
                    if let annualPackage = currentOffering.package(identifier: tier.annualProductId) {
                        products.append(SubscriptionProduct(
                            tier: tier,
                            package: annualPackage,
                            isMonthly: false
                        ))
                        print("✅ Found annual package using product ID: \(tier.annualProductId)")
                    }
                }
            }
            
            // If no products found with custom IDs, try standard RevenueCat templates
            if products.isEmpty {
                print("⚠️ No products found with custom IDs, trying standard templates...")
                
                if let monthlyPackage = currentOffering.monthly {
                    products.append(SubscriptionProduct(
                        tier: .pro,
                        package: monthlyPackage,
                        isMonthly: true
                    ))
                    print("✅ Added $rc_monthly package")
                }
                
                if let annualPackage = currentOffering.annual {
                    products.append(SubscriptionProduct(
                        tier: .pro,
                        package: annualPackage,
                        isMonthly: false
                    ))
                    print("✅ Added $rc_annual package")
                }
            }
            
            print("📱 Total products loaded: \(products.count)")
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
                
                // Log purchase verification info
                // RevenueCat handles verification internally, but you can access the info
                if let transaction = result.transaction {
                    print("🔐 Purchase verified - Transaction ID: \(transaction.transactionIdentifier)")
                    print("🔐 Product ID: \(transaction.productIdentifier)")
                    print("🔐 Purchase Date: \(transaction.purchaseDate)")
                    
                    // RevenueCat automatically validates receipts with Apple/Google
                    // The JWT token you see is RevenueCat's internal verification
                    // You can trust result.customerInfo as the source of truth
                    
                    // Optional: Send purchase event to your backend via Supabase
                    // This would be for analytics or additional business logic
                    // await recordPurchaseInBackend(transaction: transaction)
                }
            }
        } catch {
            purchaseError = error
            throw error
        }
    }
    
    // Optional: Record purchase in your Supabase backend for analytics
    /*
    private func recordPurchaseInBackend(transaction: StoreTransaction) async {
        // This would send purchase data to your Supabase backend
        // for analytics, user history, or business intelligence
        // The actual subscription validation is handled by RevenueCat
    }
    */
    
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
    
    var isInFreeTrial: Bool {
        subscriptionStatus.isInTrialPeriod
    }
    
    var trialDaysRemaining: Int? {
        guard isInFreeTrial,
              let expirationDate = subscriptionStatus.expirationDate else {
            return nil
        }
        
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
        return max(0, days ?? 0)
    }
    
    var hasUsedFreeTrial: Bool {
        // Check if user has ever had a trial (this would need to be tracked in UserDefaults or backend)
        // For now, we'll check if they have an expiration date but no active subscription
        if subscriptionStatus.expirationDate != nil && !hasActiveSubscription {
            return true
        }
        // Also check UserDefaults for trial history
        return UserDefaults.standard.bool(forKey: "com.norma.hasUsedFreeTrial")
    }
    
    func markTrialAsUsed() {
        UserDefaults.standard.set(true, forKey: "com.norma.hasUsedFreeTrial")
    }
}

extension SubscriptionManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            updateSubscriptionStatus(from: customerInfo)
        }
    }
}
