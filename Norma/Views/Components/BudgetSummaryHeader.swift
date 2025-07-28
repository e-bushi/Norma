//
//  BudgetSummaryHeader.swift
//  Norma
//
//  Created by Claude on 7/24/25.
//

import SwiftUI

struct BudgetSummaryHeader: View {
    let month: String
    let totalBudget: Double
    let totalSpent: Double
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    private var remaining: Double {
        max(0, totalBudget - totalSpent)
    }
    
    private var isOverBudget: Bool {
        totalSpent > totalBudget
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("\(month.uppercased()) BUDGET")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
            
            // Summary stats
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Total Budget")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(profileViewModel.formatCurrency(totalBudget))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text("Spent")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(profileViewModel.formatCurrency(totalSpent))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isOverBudget ? .red : .primary)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text("Remaining")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(profileViewModel.formatCurrency(remaining))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isOverBudget ? .red : .green)
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
        }
    }
}