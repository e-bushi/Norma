//
//  LargeWidgetView.swift
//  NormaWidget
//
//  Created by Claude on 8/19/25.
//

import SwiftUI

struct LargeWidgetView: View {
    let entry: NormaEntry
    
    private var remainingBudget: Double {
        return entry.monthlyIncome - entry.monthlySpending
    }
    
    private var budgetProgress: Double {
        guard entry.monthlyIncome > 0 else { return 0 }
        return min(entry.monthlySpending / entry.monthlyIncome, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            // Header with remaining amount - same as MediumWidgetView
            HStack {
                Text("Remaining")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("$\(remainingBudget, specifier: "%.2f")")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.green)
                    .background(
                        Circle()
                            .fill(.green.opacity(0.2))
                            .frame(width: 20, height: 20)
                    )
            }
            
            // Horizontal progress chart section - same as MediumWidgetView
            VStack(spacing: 12) {
                ZStack {
                    // Dark mode background with subtle gradient
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.04)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.15),
                                            Color.white.opacity(0.05)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    // Chart content
                    GeometryReader { geometry in
                        let chartWidth = geometry.size.width - 32
                        let leftPosition: CGFloat = 16
                        let rightPosition: CGFloat = chartWidth + 16
                        let currentPosition = leftPosition + (chartWidth * budgetProgress)
                        
                        ZStack {
                            // Horizontal reference line
                            RoundedRectangle(cornerRadius: 1)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: chartWidth, height: 2)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            
                            // Bills dot (left side)
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 1.5)
                                )
                                .position(x: leftPosition, y: geometry.size.height / 2)
                            
                            // Income dot (right side)
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 1.5)
                                )
                                .position(x: rightPosition, y: geometry.size.height / 2)
                            
                            // Current position dot
                            Circle()
                                .fill(.purple)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 2)
                                )
                                .shadow(color: .purple.opacity(0.4), radius: 4, x: 0, y: 2)
                                .position(x: currentPosition, y: geometry.size.height / 2)
                        }
                    }
                }
                .frame(height: 40)
                
                // Labels below the chart
                HStack(spacing: 20) {
                    Spacer()
                    
                    // Bills label
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.red)
                            .frame(width: 2, height: 16)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Bills")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            Text("$\(entry.monthlyBills, specifier: "%.0f")")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Current label
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.purple)
                            .frame(width: 2, height: 16)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Current")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            Text("$\(entry.monthlySpending, specifier: "%.2f")")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Income label
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.green)
                            .frame(width: 2, height: 16)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Income")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            Text("$\(entry.monthlyIncome, specifier: "%.0f")")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
            
            // Upcoming Bills Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Upcoming Bills")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    ForEach(Array(entry.upcomingBills.prefix(2).enumerated()), id: \.offset) { index, bill in
                        HStack {
                            Circle()
                                .fill(bill.status == .overdue ? .red : (bill.status == .paid ? .green : .orange))
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(bill.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                Text(formatDate(bill.dueDate))
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Text("$\(bill.amount, specifier: "%.0f")")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.08))
                        )
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
