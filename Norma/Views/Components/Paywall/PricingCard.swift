//
//  PricingCard.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import SwiftUI
import RevenueCat

struct PricingCard: View {
    let product: SubscriptionProduct
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Recommended badge
                if isRecommended {
                    Text("RECOMMENDED")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                }
                
                VStack(spacing: 12) {
                    tierNameSection
                    priceSection
                    featureHighlight
                }
                .padding(16)
            }
            .background(backgroundStyle)
            .overlay(borderStyle)
            .cornerRadius(12)
            .scaleEffect(isSelected ? 1.02 : 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var tierNameSection: some View {
        HStack {
            Text(product.tier.displayName)
                .font(.system(size: 18, weight: .semibold))
            
            if product.tier == .pro {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(.accentColor)
            }
            
            Spacer()
        }
    }
    
    private var priceSection: some View {
        HStack(alignment: .bottom, spacing: 4) {
            Text(product.priceString)
                .font(.system(size: 28, weight: .bold))
            
            Text(product.isMonthly ? "/mo" : "/yr")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            Spacer()
            
            if let monthlyEquivalent = product.monthlyEquivalentPrice, !product.isMonthly {
                Text("\(monthlyEquivalent)/mo")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var featureHighlight: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)
            
            Text(product.tier == .pro ? "Financial Mind AI included" : "Core features included")
                .font(.system(size: 13))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private var backgroundStyle: some View {
        Color(.secondarySystemFill).opacity(isSelected ? 0.5 : 0.2)
    }
    
    private var borderStyle: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                isSelected ? Color.accentColor : Color.gray.opacity(0.2),
                lineWidth: isSelected ? 2 : 1
            )
    }
}