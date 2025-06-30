//
//  BillDisclosureView.swift
//  Collector
//
//  Created by Claude on 5/8/25.
//

import SwiftUI
import Foundation

struct BillDisclosureView: View {
    let bills: [Bill]
    @State private var showingAllBills = false
    
    private let maxBillsToShow = 5
    
    private var upcomingBills: [Bill] {
        bills.filter { $0.status == .scheduled || $0.status == .overdue || $0.status == .active }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    private var displayedBills: [Bill] {
        Array(upcomingBills.prefix(maxBillsToShow))
    }
    
    private var totalUpcomingAmount: Double {
        upcomingBills.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header section matching ExpenseTrackerChartView style
            VStack(spacing: 12) {
                Text("UPCOMING BILLS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                
                // Summary stats
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Total Due")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("$\(Int(totalUpcomingAmount))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Bill Count")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(upcomingBills.count)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
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
            
            // Bills list container
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(UIColor.systemBackground),
                                Color.gray.opacity(0.02)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.2),
                                        Color.gray.opacity(0.05)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                
                VStack(spacing: 0) {
                    if displayedBills.isEmpty {
                        // Enhanced empty state
                        VStack(spacing: 24) {
                            // Icon with gradient background
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.blue.opacity(0.1),
                                                Color.blue.opacity(0.05)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 36))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(spacing: 12) {
                                Text("No bills yet")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("Start tracking your monthly bills\nto never miss a payment")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                            }
                            
                            // Quick tips
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.yellow)
                                    
                                    Text("Track rent, utilities, subscriptions")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.blue)
                                    
                                    Text("Get reminders before due dates")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                    
                                    Text("See your spending patterns")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            
                            // Add bill button
                            Button(action: {
                                // Add bill action
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue)
                                    
                                    Text("Add your first bill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 40)
                        .padding(.horizontal, 20)
                    } else {
                        // Bill items
                        ForEach(displayedBills) { bill in
                            BillRowView(bill: bill)
                            
                            if bill.id != displayedBills.last?.id {
                                Divider()
                                    .padding(.horizontal, 20)
                            }
                        }
                        
                        // See all button
                        if upcomingBills.count > maxBillsToShow {
                            Divider()
                                .padding(.horizontal, 20)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showingAllBills.toggle()
                                }
                            }) {
                                HStack {
                                    Text("See All Bills")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.blue)
                                    
                                    Spacer()
                                    
                                    Text("\(upcomingBills.count - maxBillsToShow) more")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.secondary)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .sheet(isPresented: $showingAllBills) {
                                MyBillsView()
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct BillRowView: View {
    let bill: Bill
    
    private var statusIcon: String {
        switch bill.status {
        case .paid: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .scheduled: return "calendar.circle.fill"
        case .active: return "clock.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch bill.status {
        case .paid: return .green
        case .overdue: return .red
        case .scheduled: return .blue
        case .active: return .orange
        }
    }
    
    private var daysUntilDue: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: bill.dueDate).day ?? 0
        return days
    }
    
    private var dueDateText: String {
        if daysUntilDue == 0 {
            return "Due today"
        } else if daysUntilDue == 1 {
            return "Due tomorrow"
        } else if daysUntilDue < 0 {
            return "\(abs(daysUntilDue)) days overdue"
        } else {
            return "Due in \(daysUntilDue) days"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: statusIcon)
                    .font(.system(size: 18))
                    .foregroundColor(statusColor)
            }
            
            // Bill info
            VStack(alignment: .leading, spacing: 4) {
                Text(bill.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(dueDateText)
                    .font(.system(size: 12))
                    .foregroundColor(bill.status == .overdue ? .red : .secondary)
            }
            
            Spacer()
            
            // Amount
            Text("$\(Int(bill.amount))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(bill.status == .overdue ? .red : .primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}


#Preview {
    // Sample data for preview
    let sampleUserId = "preview-user-123"
    let sampleBills = [
        Bill(userId: sampleUserId, name: "Rent", dueDate: Date().addingTimeInterval(86400 * 2), amount: 1200.00, status: .scheduled, frequency: .monthly),
        Bill(userId: sampleUserId, name: "Electricity", dueDate: Date().addingTimeInterval(86400 * 5), amount: 85.50, status: .scheduled, frequency: .monthly),
        Bill(userId: sampleUserId, name: "Internet", dueDate: Date().addingTimeInterval(86400 * 7), amount: 59.99, status: .scheduled, frequency: .monthly),
        Bill(userId: sampleUserId, name: "Phone Bill", dueDate: Date().addingTimeInterval(86400 * 10), amount: 45.00, status: .scheduled, frequency: .monthly),
        Bill(userId: sampleUserId, name: "Water Bill", dueDate: Date().addingTimeInterval(86400 * 12), amount: 32.75, status: .scheduled, frequency: .quarterly),
        Bill(userId: sampleUserId, name: "Streaming Service", dueDate: Date().addingTimeInterval(86400 * 15), amount: 14.99, status: .scheduled, frequency: .monthly),
        Bill(userId: sampleUserId, name: "Credit Card", dueDate: Date().addingTimeInterval(-86400 * 2), amount: 220.30, status: .paid, frequency: .monthly),
        Bill(userId: sampleUserId, name: "Car Insurance", dueDate: Date().addingTimeInterval(-86400 * 5), amount: 110.50, status: .overdue, frequency: .quarterly)
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
