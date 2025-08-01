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
    @Binding var showNormaChat: Bool
    @State private var showingAllBills = false
    
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    private let maxBillsToShow = 5
    
    private var upcomingBills: [Bill] {
        // Show all bills, sorted by status priority: overdue → scheduled → paid
        bills.sorted { bill1, bill2 in
            let status1Priority = statusPriority(for: bill1.status)
            let status2Priority = statusPriority(for: bill2.status)
            
            // First sort by status priority
            if status1Priority != status2Priority {
                return status1Priority < status2Priority
            }
            
            // If same status, sort by due date
            return bill1.dueDate < bill2.dueDate
        }
    }
    
    private func statusPriority(for status: BillStatus) -> Int {
        switch status {
        case .overdue: return 0    // Highest priority (show first)
        case .scheduled: return 1  // Medium priority
        case .paid: return 2       // Lowest priority (show last)
        }
    }
    
    private var displayedBills: [Bill] {
        Array(upcomingBills.prefix(maxBillsToShow))
    }
    
    private var totalUpcomingAmount: Double {
        upcomingBills.reduce(0) { $0 + $1.amount }
    }
    
    private var totalPaidAmount: Double {
        upcomingBills.filter { bill in
            bill.calculateStatus(from: expenseViewModel.expenses) == .paid
        }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header section matching ExpenseTrackerChartView style
            VStack(spacing: 12) {
                Text("BILLS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                
                // Summary stats
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("Bill Count")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(upcomingBills.count)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Total Due")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(profileViewModel.formatCurrency(totalUpcomingAmount))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Paid So Far")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(profileViewModel.formatCurrency(totalPaidAmount))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.green)
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

#Preview {
    // Sample data for preview
    let sampleUserId = "preview-user-123"
    let sampleBills = [
        Bill(id: "1", userId: sampleUserId, name: "Rent", dueDate: Date().addingTimeInterval(86400 * 2), amount: 1200.00, status: .scheduled, frequency: .monthly),
        Bill(id: "2", userId: sampleUserId, name: "Electricity", dueDate: Date().addingTimeInterval(86400 * 5), amount: 85.50, status: .scheduled, frequency: .monthly),
        Bill(id: "3", userId: sampleUserId, name: "Internet", dueDate: Date().addingTimeInterval(86400 * 7), amount: 59.99, status: .scheduled, frequency: .monthly),
        Bill(id: "4", userId: sampleUserId, name: "Phone Bill", dueDate: Date().addingTimeInterval(86400 * 10), amount: 45.00, status: .scheduled, frequency: .monthly),
        Bill(id: "5", userId: sampleUserId, name: "Water Bill", dueDate: Date().addingTimeInterval(86400 * 12), amount: 32.75, status: .scheduled, frequency: .quarterly),
        Bill(id: "6", userId: sampleUserId, name: "Streaming Service", dueDate: Date().addingTimeInterval(86400 * 15), amount: 14.99, status: .scheduled, frequency: .monthly),
        Bill(id: "7", userId: sampleUserId, name: "Credit Card", dueDate: Date().addingTimeInterval(-86400 * 2), amount: 220.30, status: .paid, frequency: .monthly),
        Bill(id: "8", userId: sampleUserId, name: "Car Insurance", dueDate: Date().addingTimeInterval(-86400 * 5), amount: 110.50, status: .overdue, frequency: .quarterly)
    ]
    
    // Create preview view models
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let expenseViewModel = ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    
    return ScrollView {
        VStack {
            Text("With Multiple Bills")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            BillDisclosureView(bills: sampleBills, showNormaChat: .constant(false))
                .padding(.horizontal)
            
            Divider().padding()
            
            Text("With Few Bills")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            // Scenario with just 2 bills
            BillDisclosureView(bills: Array(sampleBills.prefix(2)), showNormaChat: .constant(false))
                .padding(.horizontal)
            
            Divider().padding()
            
            Text("With No Bills")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            // Empty scenario
            BillDisclosureView(bills: [], showNormaChat: .constant(false))
                .padding(.horizontal)
        }
    }
    .environmentObject(expenseViewModel)
    .environmentObject(profileViewModel)
}
