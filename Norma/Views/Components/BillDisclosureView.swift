//
//  BillDisclosureView.swift
//  Collector
//
//  Created by Claude on 5/8/25.
//

import SwiftUI
import Foundation

struct BillDisclosureView: View {
    // Array of all bills
    let bills: [Bill]
    
    // Maximum number of bills to display in preview
    let maxBillsToShow = 3
    
    // State to track when the sheet is presented
    @State private var showingAllBills = false
    
    // Computed property to get sorted upcoming bills
    private var upcomingBills: [Bill] {
        // Filter for only scheduled bills and sort by date (earliest first)
        return bills
            .filter { $0.status == .scheduled }
            .sorted { $0.date < $1.date }
    }
    
    // Bills to display in the preview
    private var previewBills: [Bill] {
        return Array(upcomingBills.prefix(maxBillsToShow))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Upcoming Bills")
                    .font(.headline)
                
                Spacer()
                
                // See All Button
                if upcomingBills.count > maxBillsToShow {
                    Button(action: {
                        showingAllBills = true
                    }) {
                        HStack(spacing: 4) {
                            Text("See All")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            
                            Image(systemName: "chevron.up")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $showingAllBills) {
                        // This will be replaced with a full screen view of all bills
                        // For now, using a placeholder
                        MyBillsView()
                    }
                }
            }
            
            // Bills List
            VStack(spacing: 12) {
                if previewBills.isEmpty {
                    // Empty state
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.largeTitle)
                                .foregroundColor(.blue.opacity(0.7))
                            
                            Text("No upcoming bills")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    // List of upcoming bills
                    ForEach(previewBills) { bill in
                        BillCardView(
                            name: bill.name,
                            date: bill.date,
                            amount: bill.amount,
                            status: bill.status,
                            frequency: bill.frequency
                        )
                    }
                }
            }
            
            // Footer with total count
            if upcomingBills.count > maxBillsToShow {
                HStack {
                    Spacer()
                    Text("+ \(upcomingBills.count - maxBillsToShow) more upcoming bills")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
    // Sample data for preview
    let sampleBills = [
        Bill(name: "Rent", date: Date().addingTimeInterval(86400 * 2), amount: 1200.00, status: .scheduled, frequency: .monthly),
        Bill(name: "Electricity", date: Date().addingTimeInterval(86400 * 5), amount: 85.50, status: .scheduled, frequency: .monthly),
        Bill(name: "Internet", date: Date().addingTimeInterval(86400 * 7), amount: 59.99, status: .scheduled, frequency: .monthly),
        Bill(name: "Phone Bill", date: Date().addingTimeInterval(86400 * 10), amount: 45.00, status: .scheduled, frequency: .monthly),
        Bill(name: "Water Bill", date: Date().addingTimeInterval(86400 * 12), amount: 32.75, status: .scheduled, frequency: .quarterly),
        Bill(name: "Streaming Service", date: Date().addingTimeInterval(86400 * 15), amount: 14.99, status: .scheduled, frequency: .monthly),
        Bill(name: "Credit Card", date: Date().addingTimeInterval(-86400 * 2), amount: 220.30, status: .paid, frequency: .monthly),
        Bill(name: "Car Insurance", date: Date().addingTimeInterval(-86400 * 5), amount: 110.50, status: .overdue, frequency: .quarterly)
    ]
    
    return ScrollView {
        VStack {
            Text("With Multiple Bills")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            BillDisclosureView(bills: sampleBills)
                .padding(.horizontal)
            
            Divider().padding()
            
            Text("With Few Bills")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            // Scenario with just 2 bills
            BillDisclosureView(bills: Array(sampleBills.prefix(2)))
                .padding(.horizontal)
            
            Divider().padding()
            
            Text("With No Bills")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            // Empty scenario
            BillDisclosureView(bills: [])
                .padding(.horizontal)
        }
    }
}
