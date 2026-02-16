//
//  Subscription.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import Foundation
import RevenueCat

enum SubscriptionTier: String, CaseIterable {
    case premium = "norma_premium"

    var displayName: String {
        "Premium"
    }

    var monthlyProductId: String {
        "norma_monthly"
    }

    var annualProductId: String {
        "norma_annual"
    }

    var features: [String] {
        [
            "Unlimited AI-powered bill and expense logging",
            "Bill period verification system",
            "Expense-to-bill linking",
            "Budgeting features",
            "Push notifications",
            "Data encryption",
            "Multi-currency support",
            "Spending challenges",
            "AI-powered personal finance analyst",
            "Personalized spending insights"
        ]
    }
}

struct SubscriptionStatus {
    let isActive: Bool
    let tier: SubscriptionTier?
    let expirationDate: Date?
    let willRenew: Bool
    let isInTrialPeriod: Bool
    let isInIntroOfferPeriod: Bool

    static let inactive = SubscriptionStatus(
        isActive: false,
        tier: nil,
        expirationDate: nil,
        willRenew: false,
        isInTrialPeriod: false,
        isInIntroOfferPeriod: false
    )
}

struct SubscriptionProduct {
    let package: Package
    let isMonthly: Bool

    var priceString: String {
        package.storeProduct.localizedPriceString
    }

    var monthlyEquivalentPrice: String? {
        guard !isMonthly else { return nil }
        let monthlyPrice = (package.storeProduct.price as NSDecimalNumber).doubleValue / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = package.storeProduct.priceFormatter?.locale ?? Locale.current
        return formatter.string(from: NSNumber(value: monthlyPrice))
    }

    var savingsPercentage: String? {
        guard !isMonthly else { return nil }
        let annualPrice = (package.storeProduct.price as NSDecimalNumber).doubleValue
        let monthlyEquiv = annualPrice / 12
        let fullMonthlyPrice = 9.99 // fallback comparison
        let savings = ((fullMonthlyPrice - monthlyEquiv) / fullMonthlyPrice) * 100
        return savings > 0 ? "Save \(Int(savings.rounded()))%" : nil
    }
}
