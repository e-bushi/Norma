//
//  MediumWidgetLightView.swift
//  NormaWidget
//
//  Created by Claude on 8/21/25.
//

import SwiftUI

struct MediumWidgetLightView: View {
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
            // Header with remaining amount
            HStack {
                Text("Remaining")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black.opacity(0.6))
                
                Text("$\(remainingBudget, specifier: "%.2f")")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.green)
                    .background(
                        Circle()
                            .fill(.green.opacity(0.15))
                            .frame(width: 20, height: 20)
                    )
            }
            
            // Horizontal progress chart section
            VStack(spacing: 12) {
                ZStack {
                    // Light mode background with subtle gradient
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.08),
                                    Color.gray.opacity(0.04)
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
                                            Color.gray.opacity(0.2),
                                            Color.gray.opacity(0.1)
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
                                            Color.gray.opacity(0.25),
                                            Color.gray.opacity(0.15)
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
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                .position(x: leftPosition, y: geometry.size.height / 2)
                            
                            // Income dot (right side)
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 1.5)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                .position(x: rightPosition, y: geometry.size.height / 2)
                            
                            // Current position dot
                            Circle()
                                .fill(.purple)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 2)
                                )
                                .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
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
                                .foregroundColor(.black.opacity(0.5))
                            Text("$\(entry.monthlyBills, specifier: "%.0f")")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.black)
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
                                .foregroundColor(.black.opacity(0.5))
                            Text("$\(entry.monthlySpending, specifier: "%.2f")")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.black)
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
                                .foregroundColor(.black.opacity(0.5))
                            Text("$\(entry.monthlyIncome, specifier: "%.0f")")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
}
