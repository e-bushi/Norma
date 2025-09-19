//
//  BillingToggle.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import SwiftUI

struct BillingToggle: View {
    @Binding var isMonthlyBilling: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            monthlyButton
            annualButton
        }
        .padding(4)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var monthlyButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isMonthlyBilling = true
            }
        } label: {
            Text("Monthly")
                .font(.system(size: 14, weight: isMonthlyBilling ? .semibold : .regular))
                .foregroundColor(isMonthlyBilling ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isMonthlyBilling ? Color(.secondarySystemFill) : Color.clear)
                .cornerRadius(8)
        }
    }
    
    private var annualButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isMonthlyBilling = false
            }
        } label: {
            HStack(spacing: 6) {
                Text("Annual")
                    .font(.system(size: 14, weight: !isMonthlyBilling ? .semibold : .regular))
                    .foregroundColor(!isMonthlyBilling ? .primary : .secondary)
                
                if !isMonthlyBilling {
                    Text("Save 17%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(!isMonthlyBilling ? Color(.secondarySystemFill) : Color.clear)
            .cornerRadius(8)
        }
    }
}