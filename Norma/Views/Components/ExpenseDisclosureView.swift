//
//  ExpenseDisclosureView.swift
//  Collector
//
//  Created by Claude on 5/13/25.
//

import SwiftUI
import Foundation

struct ExpenseDisclosureView: View {
    let expenses: [FinancialItem]
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
    
    private var filteredExpenses: [FinancialItem] {
        let filtered = expenses.filter { expense in
            expense.category == .expense && 
            (category == nil || expense.asExpenseCategory == category)
        }
        return filtered.sorted { $0.date > $1.date }
    }
    
    private var displayedExpenses: [FinancialItem] {
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
                        Text("$\(Int(totalExpenseAmount))")
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
                        // Empty state
                        VStack(spacing: 12) {
                            Image(systemName: "creditcard.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.purple.opacity(0.5))
                            
                            Text("No recent expenses")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
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
    let expense: FinancialItem
    
    private var expenseCategory: ExpenseCategory {
        expense.asExpenseCategory ?? .other
    }
    
    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: expense.date, relativeTo: Date())
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
            Text("$\(Int(expense.amount))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview {
    // Sample data for preview
    let sampleExpenses: [FinancialItem] = [
        FinancialItem(name: "Groceries", amount: 120.50, category: .expense, date: Date().addingTimeInterval(-86400 * 1), expenseCategory: .food),
        FinancialItem(name: "Gas", amount: 45.00, category: .expense, date: Date().addingTimeInterval(-86400 * 2), expenseCategory: .transportation),
        FinancialItem(name: "Movie Tickets", amount: 32.99, category: .expense, date: Date().addingTimeInterval(-86400 * 3), expenseCategory: .entertainment),
        FinancialItem(name: "Restaurant", amount: 85.75, category: .expense, date: Date().addingTimeInterval(-86400 * 4), expenseCategory: .food),
        FinancialItem(name: "Uber Ride", amount: 18.50, category: .expense, date: Date().addingTimeInterval(-86400 * 5), expenseCategory: .transportation),
        FinancialItem(name: "Clothing", amount: 99.99, category: .expense, date: Date().addingTimeInterval(-86400 * 6), expenseCategory: .shopping),
        FinancialItem(name: "Doctor Visit", amount: 75.00, category: .expense, date: Date().addingTimeInterval(-86400 * 7), expenseCategory: .health),
        FinancialItem(name: "Electricity Bill", amount: 135.62, category: .expense, date: Date().addingTimeInterval(-86400 * 8), expenseCategory: .utilities)
    ]
    
    return ScrollView {
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
            
            ExpenseDisclosureView(expenses: sampleExpenses, category: .food)
                .padding(.horizontal)
            
            Divider().padding()
            
            Text("Health Expenses (Just One)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            ExpenseDisclosureView(expenses: sampleExpenses, category: .health)
                .padding(.horizontal)
            
            Divider().padding()
            
            Text("Shopping Expenses (Empty)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            ExpenseDisclosureView(expenses: sampleExpenses.filter { $0.asExpenseCategory != .shopping }, category: .shopping)
                .padding(.horizontal)
        }
    }
}
