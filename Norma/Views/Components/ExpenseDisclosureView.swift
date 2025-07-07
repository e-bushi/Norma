//
//  ExpenseDisclosureView.swift
//  Collector
//
//  Created by Claude on 5/13/25.
//

import SwiftUI
import Foundation

struct ExpenseDisclosureView: View {
    let expenses: [Expense]
    let category: ExpenseCategory?
    @State private var showingAllExpenses = false
    
    private let maxExpensesToShow = 5
    
    var title: String {
        if let category = category {
            return "\(category.rawValue) Expenses"
        } else {
            return "Recent Expenses"
        }
    }
    
    private var filteredExpenses: [Expense] {
        let filtered = expenses.filter { expense in
            // For now, include all expenses since we don't have category filtering implemented
            // TODO: Implement category filtering with the Category model
            return true
        }
        let dateFormatter = ISO8601DateFormatter()
        return filtered.sorted { 
            guard let date1 = dateFormatter.date(from: $0.expenseDate),
                  let date2 = dateFormatter.date(from: $1.expenseDate) else { return false }
            return date1 > date2
        }
    }
    
    private var displayedExpenses: [Expense] {
        Array(filteredExpenses.prefix(maxExpensesToShow))
    }
    
    private var totalExpenseAmount: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header section matching ExpenseTrackerChartView style
            VStack(spacing: 12) {
                Text("RECENT EXPENSES")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                
                // Summary stats
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Total Spent")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.2f", totalExpenseAmount))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Transactions")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(filteredExpenses.count)")
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
            
            // Expenses list container
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
                    if displayedExpenses.isEmpty {
                        // Enhanced empty state
                        VStack(spacing: 24) {
                            // Icon with gradient background
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.purple.opacity(0.1),
                                                Color.purple.opacity(0.05)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "creditcard.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.purple)
                            }
                            
                            VStack(spacing: 12) {
                                Text("No expenses yet")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("Start tracking your spending to see your patterns")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                            }
                            
                            // Quick tips
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                    
                                    Text("Tap + to add an expense")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 14))
                                        .foregroundColor(.blue)
                                    
                                    Text("Watch your spending trends grow")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "target")
                                        .font(.system(size: 14))
                                        .foregroundColor(.orange)
                                    
                                    Text("Stay within your budget goals")
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
                        // Expense items
                        ForEach(displayedExpenses) { expense in
                            ExpenseRowView(expense: expense)
                            
                            
                        }
                        
                        // See all button
                        if filteredExpenses.count > maxExpensesToShow {
                            Divider()
                                .padding(.horizontal, 20)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showingAllExpenses.toggle()
                                }
                            }) {
                                HStack {
                                    Text("See All Expenses")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.purple)
                                    
                                    Spacer()
                                    
                                    Text("\(filteredExpenses.count - maxExpensesToShow) more")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.secondary)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.purple)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .sheet(isPresented: $showingAllExpenses) {
                                NavigationStack {
                                    List(filteredExpenses) { expense in
                                        ExpenseRowView(expense: expense)
                                            .listRowSeparator(.hidden)
                                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    }
                                    .listStyle(.plain)
                                    .navigationTitle(title)
                                    .toolbar {
                                        ToolbarItem(placement: .navigationBarTrailing) {
                                            Button("Done") {
                                                showingAllExpenses = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    
    private var expenseCategory: ExpenseCategory {
        // TODO: Map category from Expense.categoryId to ExpenseCategory
        // For now, default to .other since we don't have the mapping implemented
        .other
    }
    
    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let dateFormatter = ISO8601DateFormatter()
        guard let expenseDate = dateFormatter.date(from: expense.expenseDate) else {
            return "Unknown"
        }
        return formatter.localizedString(for: expenseDate, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Category icon
            ZStack {
                Circle()
                    .fill(expenseCategory.color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: expenseCategory.icon)
                    .font(.system(size: 18))
                    .foregroundColor(expenseCategory.color)
            }
            
            // Expense info
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(timeAgoText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount
            Text("$\(String(format: "%.2f", expense.amount))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview {
    // Sample data for preview
    let dateFormatter = ISO8601DateFormatter()
    let sampleExpenses: [Expense] = [
        Expense(userId: "preview-user", name: "Groceries", amount: 120.50, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 1)), paymentMethod: .creditCard),
        Expense(userId: "preview-user", name: "Gas", amount: 45.00, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 2)), paymentMethod: .debitCard),
        Expense(userId: "preview-user", name: "Movie Tickets", amount: 32.99, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 3)), paymentMethod: .creditCard),
        Expense(userId: "preview-user", name: "Restaurant", amount: 85.75, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 4)), paymentMethod: .creditCard),
        Expense(userId: "preview-user", name: "Uber Ride", amount: 18.50, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 5)), paymentMethod: .digitalWallet),
        Expense(userId: "preview-user", name: "Clothing", amount: 99.99, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 6)), paymentMethod: .creditCard),
        Expense(userId: "preview-user", name: "Doctor Visit", amount: 75.00, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 7)), paymentMethod: .creditCard),
        Expense(userId: "preview-user", name: "Electricity Bill", amount: 135.62, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 8)), paymentMethod: .bankTransfer)
    ]
    
    ScrollView {
        VStack {
            Text("All Expenses")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            ExpenseDisclosureView(expenses: sampleExpenses, category: nil)
                .padding(.horizontal)
            
            Divider().padding()
            
            Text("Food Expenses Only")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            ExpenseDisclosureView(expenses: sampleExpenses, category: nil)
                .padding(.horizontal)
            
            Divider().padding()
            
            Text("Empty State")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            ExpenseDisclosureView(expenses: [], category: nil)
                .padding(.horizontal)
        }
    }
}
