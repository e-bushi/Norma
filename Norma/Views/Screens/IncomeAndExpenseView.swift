//
//  IncomeAndExpenseView.swift
//  Collector
//
//  Created by Claude on 5/9/25.
//

import SwiftUI
import Charts

struct IncomeAndExpenseView: View {
    // Sample income and expense data
    @State private var incomeSources: [FinancialItem] = [
        FinancialItem(name: "Salary", amount: 4500.00, category: .income, date: Date()),
        FinancialItem(name: "Freelance Work", amount: 850.00, category: .income, date: Date()),
        FinancialItem(name: "Investments", amount: 320.00, category: .income, date: Date())
    ]
    
    @State private var expenses: [FinancialItem] = [
        FinancialItem(name: "Rent", amount: 1200.00, category: .expense, date: Date(), expenseCategory: .utilities),
        FinancialItem(name: "Utilities", amount: 180.00, category: .expense, date: Date(), expenseCategory: .utilities),
        FinancialItem(name: "Groceries", amount: 450.00, category: .expense, date: Date(), expenseCategory: .food),
        FinancialItem(name: "Uber", amount: 200.00, category: .expense, date: Date(), expenseCategory: .transportation),
        FinancialItem(name: "Netflix", amount: 80.00, category: .expense, date: Date(), expenseCategory: .entertainment),
        FinancialItem(name: "Dining Out", amount: 350.00, category: .expense, date: Date(), expenseCategory: .food),
        FinancialItem(name: "New Headphones", amount: 149.99, category: .expense, date: Date().addingTimeInterval(-86400 * 7), expenseCategory: .shopping),
        FinancialItem(name: "Doctor Visit", amount: 75.00, category: .expense, date: Date().addingTimeInterval(-86400 * 10), expenseCategory: .health)
    ]
    
    // Animation states
    @State private var chartAppearAnimation = false
    @State private var listAppearAnimation = false
    
    // Computed properties for totals
    private var totalIncome: Double {
        incomeSources.reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var netIncome: Double {
        totalIncome - totalExpenses
    }
    
    // Track selected date for calendar integration
    @State private var selectedDate: Date = Date()
    
    // Custom picker selection
    @State private var selectedView: BudgetExpensePicker.ViewType = .expenses
    
    private var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }
    
    // Computed property to create expense map for calendar
    private var expensesPerDay: [Date: [Double]] {
        var expenseMap: [Date: [Double]] = [:]
        
        for expense in expenses {
            let startOfDay = Calendar.current.startOfDay(for: expense.date)
            if expenseMap[startOfDay] != nil {
                expenseMap[startOfDay]?.append(expense.amount)
            } else {
                expenseMap[startOfDay] = [expense.amount]
            }
        }
        
        return expenseMap
    }
    
    // Filtered expenses for the selected date
    private var filteredExpenses: [FinancialItem] {
        expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    ExpenseCalendarView(expensesPerDay: expensesPerDay)
                    .padding(.horizontal)
                    
                    // Custom Picker
                    BudgetExpensePicker(selection: $selectedView)
                        .padding(.horizontal)
                        .padding(.horizontal)
                    
                    // Conditional view display with animation
                    Group {
                        switch selectedView {
                        case .budget:
                            BudgetDisclosureView(expenses: expenses, month: currentMonth)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        case .expenses:
                            ExpenseDisclosureView(expenses: expenses, category: nil)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedView)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Add income/expense action
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

// Financial item model representing income or expense
struct FinancialItem: Identifiable {
    let id = UUID().uuidString
    let name: String
    let amount: Double
    let category: FinancialCategory
    let date: Date
    var expenseCategory: ExpenseCategory?
    
    // Returns the expense category if this is an expense, nil otherwise
    var asExpenseCategory: ExpenseCategory? {
        if category == .expense {
            return expenseCategory ?? .other
        }
        return nil
    }
}

// Preview
#Preview {
    IncomeAndExpenseView()
}
