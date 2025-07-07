//
//  IncomeAndExpenseView.swift
//  Collector
//
//  Created by Claude on 5/9/25.
//

import SwiftUI
import Charts

struct IncomeAndExpenseView: View {
    // View Models from Environment
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var incomeViewModel: IncomeViewModel
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var dataManager: DataManager
    
    // Animation states
    @State private var chartAppearAnimation = false
    @State private var listAppearAnimation = false
    
    // Computed properties for totals
    private var totalIncome: Double {
        incomeViewModel.totalMonthlyIncome
    }
    
    private var totalExpenses: Double {
        expenseViewModel.totalExpenses
    }
    
    private var netIncome: Double {
        totalIncome - totalExpenses
    }
    
    // Track selected date for calendar integration
    @State private var selectedDate: Date = Date()
    
    // Custom picker selection
    @State private var selectedView: BudgetExpensePicker.ViewType = .expenses
    
    // Sheet presentation
    @State private var showNormaChatView = false
    
    private var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }
    
    // Computed property to create expense map for calendar
    private var expensesPerDay: [Date: [Double]] {
        var expenseMap: [Date: [Double]] = [:]
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current // Use local timezone
        
        for expense in expenseViewModel.expenses {
            guard let expenseDate = dateFormatter.date(from: expense.expenseDate) else { continue }
            let startOfDay = Calendar.current.startOfDay(for: expenseDate)
            if expenseMap[startOfDay] != nil {
                expenseMap[startOfDay]?.append(expense.amount)
            } else {
                expenseMap[startOfDay] = [expense.amount]
            }
        }
        
        return expenseMap
    }
    
    // Filtered expenses for the selected date
    private var filteredExpenses: [Expense] {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current // Use local timezone
        return expenseViewModel.expenses.filter { expense in
            guard let expenseDate = dateFormatter.date(from: expense.expenseDate) else { return false }
            return Calendar.current.isDate(expenseDate, inSameDayAs: selectedDate)
        }
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
                            BudgetDisclosureView(expenses: expenseViewModel.expenses, month: currentMonth)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        case .expenses:
                            ExpenseDisclosureView(expenses: expenseViewModel.expenses, category: nil)
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
                        showNormaChatView = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                Task {
                    await expenseViewModel.refreshExpenses()
                    await incomeViewModel.refreshIncomes()
                }
            }
            .sheet(isPresented: $showNormaChatView) {
                NormaChatView(context: .expenses)
            }
        }
    }
}

// MARK: - Supporting Types

// Preview
#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    
    return IncomeAndExpenseView()
        .environmentObject(dataManager)
        .environmentObject(sessionViewModel)
        .environmentObject(ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        .environmentObject(IncomeViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
}
