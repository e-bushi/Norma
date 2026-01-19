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

    // Sheet presentation
    @State private var showNormaChatView = false
    @State private var showCreateExpense = false
    
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
    
    // Whether the current month has any expenses
    private var monthHasExpenses: Bool {
        !currentMonthExpenses.isEmpty
    }

    // Filtered expenses for the selected date only (no fallback)
    private var filteredExpenses: [Expense] {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current

        return expenseViewModel.expenses.filter { expense in
            guard let expenseDate = dateFormatter.date(from: expense.expenseDate) else { return false }
            return Calendar.current.isDate(expenseDate, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ExpenseCalendarView(selectedDate: $selectedDate, expensesPerDay: expensesPerDay)
                        .padding(.horizontal)

                    // Day summary header
                    ExpenseDaySummary(
                        selectedDate: selectedDate,
                        totalSpent: filteredExpenses.reduce(0) { $0 + $1.amount },
                        transactionCount: filteredExpenses.count
                    )
                    .padding(.horizontal)

                    // Expense list for selected day
                    ExpenseDisclosureView(
                        expenses: filteredExpenses,
                        category: nil,
                        selectedDate: selectedDate,
                        monthHasExpenses: monthHasExpenses,
                        showNormaChat: $showNormaChatView
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color("NormaBackground"))
            .scrollIndicators(.hidden)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Expenses")
                        .font(.normaTitle(20))
                }
            }
            // Removed .onAppear - data is loaded by RootView
            .sheet(isPresented: $showNormaChatView) {
                NormaChatView(context: .expenses)
            }
            .sheet(isPresented: $showCreateExpense) {
                CreateExpenseView()
            }
        }
    }
}

// MARK: - Expense Day Summary

struct ExpenseDaySummary: View {
    let selectedDate: Date
    let totalSpent: Double
    let transactionCount: Int
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var hasAppeared = false

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var displayedSpent: Double {
        hasAppeared ? totalSpent : 0
    }

    private var displayedCount: Int {
        hasAppeared ? transactionCount : 0
    }

    var body: some View {
        VStack(spacing: 16) {
            // Date header
            HStack {
                Text(dateText.uppercased())
                    .font(.normaInput(11))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                Spacer()
                if isToday {
                    Text("TODAY")
                        .font(.normaInput(10))
                        .foregroundColor(Color("NormaPastelCoral"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color("NormaPastelCoral").opacity(0.15))
                        )
                }
            }

            // Summary stats
            HStack(spacing: 0) {
                // Total Spent
                VStack(alignment: .leading, spacing: 4) {
                    Text("SPENT")
                        .font(.normaInput(10))
                        .foregroundColor(.secondary)
                        .tracking(0.8)
                    Text(profileViewModel.formatCurrency(displayedSpent))
                        .font(.normaFinancial(18))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                }

                Spacer()

                // Transaction Count
                VStack(alignment: .trailing, spacing: 4) {
                    Text("TRANSACTIONS")
                        .font(.normaInput(10))
                        .foregroundColor(.secondary)
                        .tracking(0.8)
                    Text("\(displayedCount)")
                        .font(.normaFinancial(18))
                        .foregroundColor(.secondary)
                        .contentTransition(.numericText())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    hasAppeared = true
                }
            }
        }
    }
}

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
        .environmentObject(BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
}
