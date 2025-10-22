//
//  BudgetRow.swift
//  Norma
//
//  Created by Claude on 7/24/25.
//

import SwiftUI

struct BudgetRow: View {
    let budget: Budget
    let category: Category
    let spentAmount: Double
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    
    private var percentageUsed: Double {
        guard budget.amount > 0 else { return 0 }
        return min(spentAmount / budget.amount, 1.5) // Cap at 150% for visual purposes
    }
    
    private var isOverBudget: Bool {
        spentAmount > budget.amount
    }
    
    private var statusColor: Color {
        if percentageUsed < 0.5 {
            return .green
        } else if percentageUsed < 0.8 {
            return .yellow
        } else if percentageUsed < 1.0 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(category.color)
                        .frame(width: 36, height: 36)

                    Image(systemName: category.icon)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                
                // Budget info
                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text(profileViewModel.formatCurrency(spentAmount))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isOverBudget ? .red : .primary)
                        
                        Text("of")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(profileViewModel.formatCurrency(budget.amount))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // Percentage and remaining
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(percentageUsed * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(statusColor)
                    
                    if !isOverBudget {
                        Text("\(profileViewModel.formatCurrency(budget.amount - spentAmount)) left")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(profileViewModel.formatCurrency(spentAmount - budget.amount)) over")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Enhanced progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .frame(height: 12)
                    
                    // Progress fill - styled like quick add budget buttons
                    RoundedRectangle(cornerRadius: 6)
                        .fill(statusColor.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(statusColor.opacity(0.2), lineWidth: 1)
                        )
                        .frame(width: min(geometry.size.width * percentageUsed, geometry.size.width), height: 12)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: percentageUsed)
                }
            }
            .frame(height: 12)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}