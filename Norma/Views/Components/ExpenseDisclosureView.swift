//
//  ExpenseDisclosureView.swift
//  Collector
//
//  Created by Claude on 5/13/25.
//

import SwiftUI
import Foundation

struct ExpenseDisclosureView: View {
    // Array of all expenses
    let expenses: [FinancialItem]
    
    // Category to filter by, nil means show all
    let category: ExpenseCategory?
    
    // Maximum number of expenses to display in preview
    let maxExpensesToShow = 3
    
    // State to track when the sheet is presented
    @State private var showingAllExpenses = false
    
    // Title to show in the header
    var title: String {
        if let category = category {
            return "\(category.rawValue) Expenses"
        } else {
            return "Recent Expenses"
        }
    }
    
    // Computed property to get filtered and sorted expenses
    private var filteredExpenses: [FinancialItem] {
        // Filter for matching category if provided, and ensure they're actually expenses
        let filtered = expenses.filter { expense in
            expense.category == .expense && 
            (category == nil || expense.asExpenseCategory == category)
        }
        
        // Sort by date (most recent first)
        return filtered.sorted { $0.date > $1.date }
    }
    
    // Expenses to display in the preview
    private var previewExpenses: [FinancialItem] {
        return Array(filteredExpenses.prefix(maxExpensesToShow))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .padding(.bottom, 4)
                    // Total amount for this category/all expenses
                    if !filteredExpenses.isEmpty {
                        HStack {
                            Text("Total:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("$\(filteredExpenses.reduce(0) { $0 + $1.amount }, specifier: "%.2f")")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
                
                // See All Button
                if filteredExpenses.count > maxExpensesToShow {
                    Button(action: {
                        showingAllExpenses = true
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
                    .sheet(isPresented: $showingAllExpenses) {
                        // This will be replaced with a full screen view of all expenses
                        NavigationStack {
                            List(filteredExpenses) { expense in
                                ExpenseCardView(
                                    name: expense.name,
                                    date: expense.date,
                                    amount: expense.amount,
                                    category: expense.asExpenseCategory ?? .other
                                )
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                            .listStyle(.plain)
                            .navigationTitle(title)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button(action: {
                                        showingAllExpenses = false
                                    }) {
                                        Text("Done")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Expense List
            VStack(spacing: 12) {
                if previewExpenses.isEmpty {
                    // Empty state
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "creditcard")
                                .font(.largeTitle)
                                .foregroundColor(.blue.opacity(0.7))
                            
                            Text("No expenses found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    // List of expenses
                    ForEach(previewExpenses) { expense in
                        ExpenseCardView(
                            name: expense.name,
                            date: expense.date,
                            amount: expense.amount,
                            category: expense.asExpenseCategory ?? .other
                        )
                    }
                }
            }
            
            // Footer with total count
            if filteredExpenses.count > maxExpensesToShow {
                HStack {
                    Spacer()
                    Text("+ \(filteredExpenses.count - maxExpensesToShow) more expenses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
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
