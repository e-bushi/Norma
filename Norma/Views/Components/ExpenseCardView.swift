//
//  ExpenseCardView.swift
//  Collector
//
//  Created by Claude on 5/13/25.
//

import SwiftUI
import Foundation

enum ExpenseCategory: String, Codable {
    case food = "Food"
    case transportation = "Transportation"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case utilities = "Utilities"
    case health = "Health"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .entertainment: return "tv.fill"
        case .shopping: return "bag.fill"
        case .utilities: return "bolt.fill"
        case .health: return "heart.fill"
        case .other: return "square.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .food: return .orange
        case .transportation: return .blue
        case .entertainment: return .purple
        case .shopping: return .pink
        case .utilities: return .yellow
        case .health: return .red
        case .other: return .gray
        }
    }
}

struct ExpenseCardView: View {
    let name: String
    let date: Date
    let amount: Double
    let category: ExpenseCategory
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        HStack {
            // Icon and Expense Name Section
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(category.color)
                    .frame(width: 40, height: 40)
                    .background(category.color.opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                    HStack(spacing: 8) {
                        Text(date, format: .dateTime.month().day())
                        Text("•")
                        Text(category.rawValue)
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Amount Section
            VStack(alignment: .trailing, spacing: 4) {
                Text("-\(profileViewModel.formatCurrency(amount))")
                    .font(.headline)
                    .foregroundColor(.red)
                    
                Text("Expense")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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

#Preview {
    VStack(spacing: 20) {
        ExpenseCardView(
            name: "Grocery Shopping",
            date: Date(),
            amount: 87.50,
            category: .food
        )
        
        ExpenseCardView(
            name: "Uber Ride",
            date: Date().addingTimeInterval(-86400 * 2),
            amount: 25.99,
            category: .transportation
        )
        
        ExpenseCardView(
            name: "Movie Tickets",
            date: Date().addingTimeInterval(-86400 * 5),
            amount: 32.00,
            category: .entertainment
        )
        
        ExpenseCardView(
            name: "New Headphones",
            date: Date().addingTimeInterval(-86400 * 7),
            amount: 149.99,
            category: .shopping
        )
        
        ExpenseCardView(
            name: "Doctor Visit",
            date: Date().addingTimeInterval(-86400 * 10),
            amount: 75.00,
            category: .health
        )
    }
    .padding()
    .previewLayout(.sizeThatFits)
}
