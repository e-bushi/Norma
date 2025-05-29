//
//  BillOverviewCardView.swift
//  Collector
//
//  Created by Claude on 5/8/25.
//

import SwiftUI

struct BillOverviewCardView: View {
    let totalBillAmount: Double
    let totalBillCount: Int
    let totalIncome: Double
    
    private var remainingIncome: Double {
        totalIncome - totalBillAmount
    }
    
    private var remainingStatus: BalanceStatus {
        remainingIncome >= 0 ? .positive : .negative
    }
    
    // Icon based on remaining balance status
    private var statusIcon: String {
        switch remainingStatus {
        case .positive: return "checkmark.circle.fill"
        case .negative: return "exclamationmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch remainingStatus {
        case .positive: return .green
        case .negative: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Top stats row
            HStack(spacing: 20) {
                // Income
                StatItem(
                    title: "Income",
                    value: "$\(String(format: "%.2f", totalIncome))",
                    icon: "arrow.down.circle.fill",
                    color: .green
                )
                
                Divider()
                
                // Bills Total Amount
                StatItem(
                    title: "Total Bills",
                    value: "$\(String(format: "%.2f", totalBillAmount))",
                    icon: "dollarsign.circle.fill",
                    color: .red
                )
            }
            
            Divider()
            
            // Remaining balance card (styled like BillCardView)
            HStack {
                // Icon and Name Section
                HStack(spacing: 12) {
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "banknote.fill")
                                .foregroundColor(.green)
                            
                            Text("Remaining")
                                .font(.subheadline)
                                .bold()
                        }
                        Text("\(totalBillCount) bills total")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Amount Section
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(String(format: "%.2f", remainingIncome))")
                        .font(.headline)
                        .foregroundColor(remainingStatus == .negative ? .red : .primary)
                    Text(remainingStatus.rawValue)
                        .font(.caption)
                        .foregroundColor(statusColor)
                }
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.secondarySystemFill).opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// Helper view for each statistic
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum BalanceStatus: String {
    case positive = "In Budget"
    case negative = "Over Budget"
}

#Preview {
    VStack {
        BillOverviewCardView(
            totalBillAmount: 1545.49,
            totalBillCount: 12,
            totalIncome: 3000.00
        )
    }
    .padding()
}
