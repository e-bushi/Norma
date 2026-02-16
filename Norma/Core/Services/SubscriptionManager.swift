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

        // Any active entitlement means premium
        if let firstActiveEntitlement = customerInfo.entitlements.active.values.first {
            print("✅ Found active entitlement: \(firstActiveEntitlement.identifier)")
            activeTier = .premium

            expirationDate = firstActiveEntitlement.expirationDate
            willRenew = firstActiveEntitlement.willRenew
            isInTrialPeriod = firstActiveEntitlement.periodType == .trial
            isInIntroOfferPeriod = firstActiveEntitlement.periodType == .intro

            print("✅ Subscription status - tier: premium, isActive: true, periodType: \(firstActiveEntitlement.periodType)")
        } else if !activeSubscriptions.isEmpty {
            // Active subscriptions without entitlements (edge case)
            print("⚠️ Active subscriptions found without entitlements: \(activeSubscriptions)")
            activeTier = .premium
        } else {
            print("❌ No active entitlements found")
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

        // Ensure RevenueCat is configured
        if !Purchases.isConfigured {
            print("⚠️ RevenueCat not configured, attempting to configure...")
            Purchases.configure(withAPIKey: "appl_yYpBhkamzaQglHiLXRoRouGgjTf")
        }

        do {
            print("🚀 Loading offerings from RevenueCat...")
            let offerings = try await Purchases.shared.offerings()

            print("📦 Offerings: \(offerings.all.keys)")
            print("📦 Current offering: \(offerings.current?.identifier ?? "nil")")

            guard let currentOffering = offerings.current else {
                print("❌ No current offering found")
                return
            }

            print("📦 Available packages: \(currentOffering.availablePackages.map { $0.identifier })")

            var products: [SubscriptionProduct] = []

            // Log all available packages
            print("📱 All packages in current offering:")
            for package in currentOffering.availablePackages {
                print("  - Package ID: \(package.identifier)")
                print("    Product ID: \(package.storeProduct.productIdentifier)")
                print("    Price: \(package.storeProduct.localizedPriceString)")
            }

            // Try custom package identifiers first
            let monthlyPackageIds = ["norma_monthly", "$rc_monthly"]
            let annualPackageIds = ["norma_annual", "$rc_annual"]

            for packageId in monthlyPackageIds {
                if let monthlyPackage = currentOffering.package(identifier: packageId) {
                    products.append(SubscriptionProduct(package: monthlyPackage, isMonthly: true))
                    print("✅ Found monthly package with ID: \(packageId)")
                    break
                }
            }

            for packageId in annualPackageIds {
                if let annualPackage = currentOffering.package(identifier: packageId) {
                    products.append(SubscriptionProduct(package: annualPackage, isMonthly: false))
                    print("✅ Found annual package with ID: \(packageId)")
                    break
                }
            }

            // Fallback to standard RevenueCat templates
            if products.isEmpty {
                print("⚠️ No products found with custom IDs, trying standard templates...")

                if let monthlyPackage = currentOffering.monthly {
                    products.append(SubscriptionProduct(package: monthlyPackage, isMonthly: true))
                    print("✅ Added $rc_monthly package")
                }

                if let annualPackage = currentOffering.annual {
                    products.append(SubscriptionProduct(package: annualPackage, isMonthly: false))
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

                if let transaction = result.transaction {
                    print("🔐 Purchase verified - Transaction ID: \(transaction.transactionIdentifier)")
                    print("🔐 Product ID: \(transaction.productIdentifier)")
                    print("🔐 Purchase Date: \(transaction.purchaseDate)")
                }
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
        if subscriptionStatus.expirationDate != nil && !hasActiveSubscription {
            return true
        }
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
