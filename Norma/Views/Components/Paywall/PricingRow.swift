//
//  PricingRow.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import SwiftUI
import RevenueCat

struct PricingRow: View {
    let product: SubscriptionProduct
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Period icon
                ZStack {
                    Circle()
                        .fill(periodColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: periodIcon)
                        .font(.system(size: 18))
                        .foregroundColor(periodColor)
                }
                
                // Billing info
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.isMonthly ? "Monthly" : "Annual")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text(product.priceString)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        if !product.isMonthly {
                            Text("• Save 17%")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                        
                        if let monthlyEquivalent = product.monthlyEquivalentPrice, !product.isMonthly {
                            Text("(\(monthlyEquivalent)/mo)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accentColor.opacity(0.05) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var periodIcon: String {
        product.isMonthly ? "calendar" : "calendar.badge.clock"
    }
    
    private var periodColor: Color {
        product.isMonthly ? .blue : .green
    }
}