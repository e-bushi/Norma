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
    @State private var selectedCategoryForBudget: Category?
    
    private var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }
    
    // Computed property to filter expenses for current month
    private var currentMonthExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        return expenseViewModel.expenses.filter { expense in
            // Parse the expense date string
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            // Try with fractional seconds first, then without
            if let date = formatter.date(from: expense.expenseDate) {
                let expenseMonth = calendar.component(.month, from: date)
                let expenseYear = calendar.component(.year, from: date)
                return expenseMonth == currentMonth && expenseYear == currentYear
            } else {
                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: expense.expenseDate) {
                    let expenseMonth = calendar.component(.month, from: date)
                    let expenseYear = calendar.component(.year, from: date)
                    return expenseMonth == currentMonth && expenseYear == currentYear
                }
            }
            return false
        }
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
                            BudgetDisclosureView(expenses: currentMonthExpenses, month: currentMonth) { category in
                                selectedCategoryForBudget = category
                            }
                            .environmentObject(BudgetViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        case .expenses:
                            ExpenseDisclosureView(expenses: currentMonthExpenses, category: nil)
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
            .scrollIndicators(.hidden)
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Create a placeholder category to trigger the sheet
                        selectedCategoryForBudget = Category(
                            userId: "placeholder",
                            name: "Select Category",
                            type: .expense,
                            icon: "questionmark.circle",
                            colorHex: "#808080",
                            parentCategoryId: nil,
                            isSystem: false,
                            isActive: true,
                            sortOrder: 0
                        )
                    }) {
                        Image(systemName: "target")
                    }
                }
                
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
                    // Fetch budgets
                    if let userId = sessionViewModel.currentUser?.userId {
                        try? await dataManager.fetchBudgets(userId: userId)
                    }
                }
            }
            .sheet(isPresented: $showNormaChatView) {
                NormaChatView(context: .expenses)
            }
            .sheet(item: $selectedCategoryForBudget) { category in
                CreateBudgetView(preselectedCategory: category)
                    .environmentObject(dataManager)
                    .environmentObject(sessionViewModel)
                    .environmentObject(BudgetViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
                    .environmentObject(ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
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
        .environmentObject(ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
}
