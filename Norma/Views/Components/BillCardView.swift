//
//  BillCardView.swift
//  Collector
//
//  Created by Claude on 5/8/25.
//

import SwiftUI
import Foundation

struct BillCardView: View {
    let name: String
    let date: Date
    let amount: Double
    let status: BillStatus
    let frequency: BillFrequency
    var calculatedStatus: BillStatus? = nil
    
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    // Use calculated status if provided, otherwise use the stored status
    private var displayStatus: BillStatus {
        calculatedStatus ?? status
    }
    
    // Icon based on bill status
    private var statusIcon: String {
        switch displayStatus {
        case .paid: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .scheduled: return "calendar.circle.fill"
        }
    }
    
    var body: some View {
        HStack {
            // Icon and Bill Name Section
            HStack(spacing: 12) {
                Image(systemName: statusIcon)
                    .font(.system(size: 24))
                    .foregroundColor(statusColor)
                    .frame(width: 40, height: 40)
                    .background(statusColor.opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                    HStack(spacing: 8) {
                        Text(date, format: .dateTime.month().day())
                        Text("•")
                        Text(frequency.rawValue)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Amount Section
            VStack(alignment: .trailing, spacing: 4) {
                Text(profileViewModel.formatCurrency(amount))
                    .font(.headline)
                    .foregroundColor(displayStatus == .overdue ? .red : .primary)
                Text(displayStatus.rawValue)
                    .font(.caption)
                    .foregroundColor(statusColor)
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
    
    private var statusColor: Color {
        switch displayStatus {
        case .paid:
            return .green
        case .overdue:
            return .red
        case .scheduled:
            return .blue
        }
    }
}


#Preview {
    VStack(spacing: 20) {
        BillCardView(
            name: "Electricity Bill",
            date: Date(),
            amount: 87.50,
            status: .paid,
            frequency: .monthly
        )
        
        BillCardView(
            name: "Internet Service",
            date: Date().addingTimeInterval(-86400 * 5),
            amount: 65.99,
            status: .overdue,
            frequency: .monthly
        )
        
        BillCardView(
            name: "Rent Payment",
            date: Date().addingTimeInterval(86400 * 3),
            amount: 1200.00,
            status: .scheduled,
            frequency: .monthly
        )
        
        BillCardView(
            name: "Car Insurance",
            date: Date().addingTimeInterval(86400 * 30),
            amount: 420.00,
            status: .scheduled,
            frequency: .quarterly
        )
        
        BillCardView(
            name: "Property Tax",
            date: Date().addingTimeInterval(86400 * 60),
            amount: 2500.00,
            status: .scheduled,
            frequency: .yearly
        )
    }
    .padding()
    .previewLayout(.sizeThatFits)
}
