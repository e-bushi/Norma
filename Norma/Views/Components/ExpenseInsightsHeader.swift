//
//  ExpenseInsightsHeader.swift
//  Norma
//
//  Created by Claude on 8/6/25.
//

import SwiftUI

struct ExpenseInsightsHeader: View {
    let month: String
    let incomeAmount: Double
    let currentExpenseAmount: Double
    let billAmount: Double
    let headerAppeared: Bool
    let insightsAppeared: Bool
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress badge
            Text("\(month.uppercased())'S PROGRESS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : -10)
            
            // Smart insights
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Remaining")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(profileViewModel.formatCurrency(max(0, incomeAmount - currentExpenseAmount)))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text("Daily Budget")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(profileViewModel.formatCurrency((incomeAmount - billAmount) / 30))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(insightsAppeared ? 1 : 0.7)
            .opacity(insightsAppeared ? 1 : 0)
            .offset(y: insightsAppeared ? 0 : 20)
        }
    }
}