//
//  Subscription.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import Foundation
import RevenueCat

enum SubscriptionTier: String, CaseIterable {
    case base = "norma_base"
    case pro = "norma_pro"
    
    var displayName: String {
        switch self {
        case .base:
            return "Basic"
        case .pro:
            return "Pro"
        }
    }
    
    var monthlyProductId: String {
        switch self {
        case .base:
            return "subscription_monthly_1"  // Match RevenueCat/App Store Connect
        case .pro:
            return "pro_monthly_1"  // Match App Store Connect
        }
    }
    
    var annualProductId: String {
        switch self {
        case .base:
            return "subscription_yearly_1"  // Match RevenueCat/App Store Connect
        case .pro:
            return "pro_yearly_1"  // Match App Store Connect
        }
    }
    
    var features: [String] {
        switch self {
        case .base:
            return [
                "Unlimited AI-powered bill and expense logging",
                "Bill period verification system",
                "Expense-to-bill linking",
                "Basic budgeting features",
                "Push notifications",
                "Data encryption",
                "Multi-currency support"
            ]
        case .pro:
            return [
                "Everything in Base Tier",
                "Financial Mind: AI-powered personal finance analyst",
                "Deep financial data analysis",
                "Personalized spending insights and recommendations",
                "Cash flow predictions",
                "Advanced budgeting optimization",
                "Priority customer support"
            ]
        }
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
    let tier: SubscriptionTier
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
        return "Save 17%"
    }
}
