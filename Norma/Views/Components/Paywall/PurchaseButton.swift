//
//  PurchaseButton.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import SwiftUI

struct PurchaseButton: View {
    let selectedProduct: SubscriptionProduct?
    let selectedTier: SubscriptionTier
    let isPurchasing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    VStack(spacing: 2) {
                        Text("Start 7-Day Free Trial")
                            .font(.system(size: 16, weight: .semibold))
                        
                        if let product = selectedProduct {
                            Text("Then \(product.priceString)\(product.isMonthly ? "/month" : "/year")")
                                .font(.system(size: 12))
                                .opacity(0.9)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(selectedProduct != nil ? selectedTier.color : Color.gray.opacity(0.5))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(selectedProduct == nil || isPurchasing)
    }
}