//
//  FinancialItemCardView.swift
//  Collector
//
//  Created by Claude on 5/9/25.
//

import SwiftUI
import Foundation

// Financial categories
enum FinancialCategory: String {
    case income = "Income"
    case expense = "Expense"
    case transfer = "Transfer"
    case saving = "Saving"
}

struct FinancialItemCardView: View {
    // Properties
    let name: String
    let date: Date
    let amount: Double
    let category: FinancialCategory
    let description: String
    
    var body: some View {
        HStack {
            // Icon and Item Name Section
            HStack(spacing: 12) {
                // Icon with background
                categoryIconView
                
                // Name and Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                    
                    // Date and description
                    dateAndDescriptionView
                }
            }
            
            Spacer()
            
            // Amount Section
            amountView
        }
        .padding()
        .background(Color(.secondarySystemFill).opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Supporting Views
    
    private var categoryIconView: some View {
        Image(systemName: iconName)
            .font(.system(size: 24))
            .foregroundColor(categoryColor)
            .frame(width: 40, height: 40)
            .background(categoryColor.opacity(0.2))
            .clipShape(Circle())
    }
    
    private var dateAndDescriptionView: some View {
        HStack(spacing: 8) {
            Text(date, format: .dateTime.month().day())
            
            if !description.isEmpty {
                Text("•")
                Text(description)
                    .lineLimit(1)
            }
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
    
    private var amountView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Amount with prefix
            Text(formattedAmount)
                .font(.headline)
                .foregroundColor(amountColor)
            
            // Category label
            Text(category.rawValue)
                .font(.caption)
                .foregroundColor(categoryColor)
        }
    }
    
    // MARK: - Helper Properties
    
    private var iconName: String {
        switch category {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        case .saving: return "banknote.fill"
        }
    }
    
    private var categoryColor: Color {
        switch category {
        case .income: return .green
        case .expense: return .red
        case .transfer: return .blue
        case .saving: return .purple
        }
    }
    
    private var amountColor: Color {
        switch category {
        case .income: return .green
        case .expense: return .red
        default: return .primary
        }
    }
    
    private var formattedAmount: String {
        let prefix: String
        
        switch category {
        case .income: prefix = "+"
        case .expense: prefix = "-"
        default: prefix = ""
        }
        
        return "\(prefix)$\(String(format: "%.2f", amount))"
    }
}

#Preview {
    VStack(spacing: 20) {
        FinancialItemCardView(
            name: "Salary",
            date: Date(),
            amount: 4200.00,
            category: .income,
            description: "Monthly"
        )
        
        FinancialItemCardView(
            name: "Rent Payment",
            date: Date(),
            amount: 1200.00,
            category: .expense,
            description: "Housing"
        )
        
        FinancialItemCardView(
            name: "Bank Transfer",
            date: Date(),
            amount: 500.00,
            category: .transfer,
            description: "To Savings"
        )
        
        FinancialItemCardView(
            name: "Investment Deposit",
            date: Date(),
            amount: 300.00,
            category: .saving,
            description: "Retirement"
        )
    }
    .padding()
    .preferredColorScheme(.dark)
}
