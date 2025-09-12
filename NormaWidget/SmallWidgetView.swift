//
//  SmallWidgetView.swift
//  NormaWidget
//
//  Created by Claude on 8/19/25.
//

import SwiftUI

struct SmallWidgetView: View {
    let entry: NormaEntry
    
    private var remainingBudget: Double {
        return entry.monthlyIncome - entry.monthlySpending
    }
    
    private var budgetProgress: Double {
        guard entry.monthlyIncome > 0 else { return 0 }
        return min(entry.monthlySpending / entry.monthlyIncome, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with up arrow
            HStack {
                Text("Remaining")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.up")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.green)
                    .background(
                        Circle()
                            .fill(.green.opacity(0.2))
                            .frame(width: 16, height: 16)
                    )
            }
            
            // Main amount - more compact
            Text("$\(remainingBudget, specifier: "%.0f")")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Progress bar - smaller
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background bar
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 6)
                        
                        // Progress bar
                        RoundedRectangle(cornerRadius: 3)
                            .fill(budgetProgress > 0.8 ? .red : (budgetProgress > 0.6 ? .orange : .green))
                            .frame(width: geometry.size.width * budgetProgress, height: 6)
                    }
                }
                .frame(height: 6)
                
                // Spent today - more compact
                HStack {
                    Text("Spent today")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("$\(entry.todaysSpending, specifier: "%.2f")")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Next bill - compact with vertical line
                if let nextBill = entry.upcomingBills.first {
                    HStack(spacing: 8) {
                        // Colored vertical line
                        Rectangle()
                            .fill(billStatusColor(nextBill.status))
                            .frame(width: 3, height: 28)
                        
                        // Bill info
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Next Bill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            HStack {
                                Text(nextBill.name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("$\(nextBill.amount, specifier: "%.0f")")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
    }
    
    private func billStatusColor(_ status: WidgetBillStatus) -> Color {
        switch status {
        case .paid: return .green
        case .overdue: return .red
        case .scheduled: return .blue
        }
    }
}
