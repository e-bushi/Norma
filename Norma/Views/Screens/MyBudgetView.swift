//
//  MyBudgetView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct MyBudgetView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var budgetViewModel: BudgetViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var incomeViewModel: IncomeViewModel
    @EnvironmentObject private var billViewModel: BillViewModel

    @State private var showCreateBudget = false
    @State private var selectedBudget: Budget?

    private var activeBudgets: [Budget] {
        budgetViewModel.activeBudgets
    }

    private var monthlyIncome: Double {
        // Use income from profile settings if available, otherwise fall back to IncomeViewModel
        return sessionViewModel.currentUser?.settings.monthlyIncome ?? incomeViewModel.totalMonthlyIncome
    }

    private var currencySymbol: String {
        let currencyCode = sessionViewModel.currentUser?.settings.currency ?? "USD"
        return CurrencyData.getCurrency(for: currencyCode).symbol
    }

    // Group budgets by month
    private var budgetsByMonth: [(month: Date, budgets: [(budget: Budget, spent: Double, category: Category?)])] {
        let calendar = Calendar.current
        var grouped: [Date: [(budget: Budget, spent: Double, category: Category?)]] = [:]

        for budget in activeBudgets {
            let monthStart = calendar.startOfMonth(for: budget.startDate) ?? budget.startDate
            let category = budget.categoryId != nil ? dataManager.categories.first(where: { $0.id == budget.categoryId }) : nil
            // Use the currentSpent from the budget model (maintained in database)
            let spent = budget.currentSpent

            if grouped[monthStart] != nil {
                grouped[monthStart]?.append((budget, spent, category))
            } else {
                grouped[monthStart] = [(budget, spent, category)]
            }
        }

        // Sort by month (most recent first) and sort budgets within each month by % used
        return grouped.map { (month: $0.key, budgets: $0.value.sorted { $0.spent / $0.budget.amount > $1.spent / $1.budget.amount }) }
            .sorted { $0.month > $1.month }
    }

    private func getAvailableToBudget(for month: Date) -> Double {
        // Total available = Income - Bills
        let totalAvailable = monthlyIncome - billViewModel.totalMonthlyBills

        // Get total already budgeted for this month (using monthly allocation for multi-month budgets)
        let calendar = Calendar.current
        let budgetedThisMonth = activeBudgets.filter { budget in
            let monthStart = calendar.startOfMonth(for: budget.startDate) ?? budget.startDate
            return calendar.isDate(monthStart, equalTo: month, toGranularity: .month)
        }.reduce(0.0) { total, budget in
            total + monthlyAllocation(for: budget)
        }

        // Available to budget = Total Available - Already Budgeted
        return totalAvailable - budgetedThisMonth
    }

    // Calculate monthly allocation for a budget
    private func monthlyAllocation(for budget: Budget) -> Double {
        guard let endDate = budget.endDate else {
            // If no end date, treat as single-month budget
            return budget.amount
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: budget.startDate, to: endDate)
        let months = max(1, (components.month ?? 0) + 1) // +1 to include both start and end months

        return budget.amount / Double(months)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    if activeBudgets.isEmpty {
                        // Show current month with empty state
                        monthSection(month: Date(), budgets: [], isFirstMonth: true, isLastMonth: true)
                    } else {
                        ForEach(Array(budgetsByMonth.enumerated()), id: \.element.month) { index, monthData in
                            monthSection(month: monthData.month, budgets: monthData.budgets, isFirstMonth: index == 0, isLastMonth: index == budgetsByMonth.count - 1)
                        }
                    }
                }
                .padding()
            }
            .background(Color("NormaBackground"))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Budgets")
                        .font(.normaTitle(20))
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateBudget = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showCreateBudget) {
                CreateBudgetView()
                    .environmentObject(dataManager)
                    .environmentObject(sessionViewModel)
                    .environmentObject(budgetViewModel)
                    .environmentObject(profileViewModel)
            }
            .sheet(item: $selectedBudget) { budget in
                BudgetDetailView(budget: budget)
                    .environmentObject(dataManager)
                    .environmentObject(budgetViewModel)
                    .environmentObject(expenseViewModel)
                    .environmentObject(profileViewModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(.clear)
                    .glassEffect(in: Circle())
                    .frame(width: 80, height: 80)

                Image(systemName: "target")
                    .font(.system(size: 36))
                    .foregroundColor(Color(red: 0.50, green: 0.45, blue: 0.65))
            }

            // Title and description
            VStack(spacing: 8) {
                Text("Ready to set budgets?")
                    .font(.normaFinancial(20))
                    .foregroundColor(.primary)

                Text("Tap the + button above to create spending limits for different categories")
                    .font(.normaInput(14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 250)
            }

            Spacer()
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func monthSection(month: Date, budgets: [(budget: Budget, spent: Double, category: Category?)], isFirstMonth: Bool, isLastMonth: Bool) -> some View {
        let calendar = Calendar.current
        let isCurrentMonth = calendar.isDate(month, equalTo: Date(), toGranularity: .month)

        // Separate single-month vs multi-month budgets
        let singleMonthBudgets = budgets.filter { item in
            guard let endDate = item.budget.endDate else {
                return true // If no end date, treat as single month
            }
            let startMonth = calendar.startOfMonth(for: item.budget.startDate) ?? item.budget.startDate
            let endMonth = calendar.startOfMonth(for: endDate) ?? endDate
            return calendar.isDate(startMonth, equalTo: endMonth, toGranularity: .month)
        }

        let multiMonthBudgets = budgets.filter { item in
            guard let endDate = item.budget.endDate else {
                return false
            }
            let startMonth = calendar.startOfMonth(for: item.budget.startDate) ?? item.budget.startDate
            let endMonth = calendar.startOfMonth(for: endDate) ?? endDate
            return !calendar.isDate(startMonth, equalTo: endMonth, toGranularity: .month)
        }

        VStack(alignment: .leading, spacing: 16) {
            // Month header with timeline indicator
            HStack(spacing: 12) {
                // Timeline dot
                ZStack {
                    Circle()
                        .fill(isCurrentMonth ? Color(red: 0.50, green: 0.45, blue: 0.65) : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)

                    if isCurrentMonth {
                        Circle()
                            .fill(Color(red: 0.50, green: 0.45, blue: 0.65).opacity(0.3))
                            .frame(width: 24, height: 24)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(month, format: .dateTime.month().year())
                            .font(.normaFinancial(22))
                            .foregroundColor(.primary)

                        if isCurrentMonth {
                            Text("Current")
                                .font(.normaInput(14))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 0.50, green: 0.45, blue: 0.65))
                                )
                        }
                    }
                }

                Spacer()
            }

            // Budget list or empty state
            if budgets.isEmpty && isCurrentMonth {
                // Empty state for current month with no budgets
                VStack(spacing: 16) {
                    Image(systemName: "target")
                        .font(.system(size: 32))
                        .foregroundColor(Color(red: 0.50, green: 0.45, blue: 0.65).opacity(0.6))

                    Text("No budgets set for this month")
                        .font(.normaFinancial(15))
                        .foregroundColor(.primary)

                    Text("Tap the + button above to create your first budget, or you can tell AI to do it in the chat")
                        .font(.normaInput(13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 220)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.clear)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )
            } else if !budgets.isEmpty {
                // Budget summary stats - expandable helper box
                BudgetSummaryBox(
                    totalAvailable: monthlyIncome - billViewModel.totalMonthlyBills,
                    budgeted: budgets.reduce(0) { total, item in
                        total + monthlyAllocation(for: item.budget)
                    },
                    remaining: getAvailableToBudget(for: month)
                )

                // Single-month budgets
                if !singleMonthBudgets.isEmpty {
                    budgetContainer(singleMonthBudgets)
                }

                // Multi-month budgets section with divider
                if !multiMonthBudgets.isEmpty {
                    VStack(spacing: 16) {
                        // Divider with label
                        HStack(spacing: 12) {
                            Text("Multi-Month Budgets")
                                .font(.normaInput(11))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.gray.opacity(0.6))
                                )

                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .frame(maxWidth: 285)

                        budgetContainer(multiMonthBudgets)
                    }
                }
            }


            // Timeline connector line or end message
            if !isLastMonth {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 2, height: 32)
                    .offset(x: 5)
                    .padding(.vertical, 8)
            } else {
                // "No history" message for the last (oldest) month
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)

                    Text("No budget history prior to this month.")
                        .font(.normaInput(13))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
            }
        }
        .padding(.bottom, isLastMonth ? 0 : 16)
    }

    // Helper function for budget container (MiniBudgetDisclosureView style)
    @ViewBuilder
    private func budgetContainer(_ budgets: [(budget: Budget, spent: Double, category: Category?)]) -> some View {
        ZStack {
            // Container background
            RoundedRectangle(cornerRadius: 20)
                .fill(.clear)
                .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )

            // Budget items (MiniBudgetDisclosureView style)
            VStack(spacing: 12) {
                ForEach(budgets, id: \.budget.id) { item in
                    Button(action: {
                        selectedBudget = item.budget
                    }) {
                        HStack {
                            // Category icon (or default icon if no category)
                            if let category = item.category {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Image(systemName: category.icon)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    )
                            } else {
                                Circle()
                                    .fill(Color(red: 0.50, green: 0.45, blue: 0.65))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Image(systemName: "dollarsign.circle")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    )
                            }

                            // Budget info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.budget.name)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("\(currencySymbol)\(item.spent, specifier: "%.2f") of \(currencySymbol)\(item.budget.amount, specifier: "%.2f")")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            // Remaining amount
                            let remaining = item.budget.amount - item.spent
                            Text(remaining >= 0 ? "\(currencySymbol)\(remaining, specifier: "%.2f") left" : "-\(currencySymbol)\(abs(remaining), specifier: "%.2f") over")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(remaining >= 0 ? (remaining < item.budget.amount * 0.2 ? Color(red: 0.70, green: 0.50, blue: 0.45) : Color(red: 0.40, green: 0.60, blue: 0.58)) : .red)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
        }
    }
}

struct BudgetSummaryBox: View {
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @Environment(\.colorScheme) var colorScheme

    let totalAvailable: Double
    let budgeted: Double
    let remaining: Double
    @State private var showDetails = false

    private var currencySymbol: String {
        let currencyCode = sessionViewModel.currentUser?.settings.currency ?? "USD"
        return CurrencyData.getCurrency(for: currencyCode).symbol
    }

    private var textColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.50, green: 0.45, blue: 0.65)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toggle button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showDetails.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: showDetails ? "chart.bar.fill" : "chart.bar")
                        .font(.system(size: 14))
                        .foregroundColor(textColor)

                    Text(showDetails ? "Hide details" : "View budget breakdown")
                        .font(.normaInput(13))
                        .foregroundColor(textColor)

                    Spacer()

                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.85, green: 0.82, blue: 0.92).opacity(0.4),
                                    Color(red: 0.88, green: 0.85, blue: 0.94).opacity(0.4)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.75, green: 0.70, blue: 0.85).opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Animated details content
            if showDetails {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your income minus bills is \(currencySymbol)\(totalAvailable, specifier: "%.0f")")
                        .font(.normaInput(14))
                        .foregroundColor(.primary.opacity(0.8))
                        .lineSpacing(2)

                    Text("You've budgeted \(currencySymbol)\(budgeted, specifier: "%.0f") so far.")
                        .font(.normaInput(14))
                        .foregroundColor(.primary.opacity(0.8))
                        .lineSpacing(2)

                    HStack(spacing: 4) {
                        Text("You have")
                            .font(.normaInput(14))
                            .foregroundColor(.primary)

                        Text("\(currencySymbol)\(abs(remaining), specifier: "%.0f")")
                            .font(.normaFinancial(14))
                            .foregroundColor(remaining >= 0 ? Color(red: 0.40, green: 0.60, blue: 0.58) : .red)

                        Text(remaining >= 0 ? "left to budget" : "over budget")
                            .font(.normaInput(14))
                            .foregroundColor(.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.clear)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )
                .padding(.top, 8)
                .transition(.asymmetric(
                    insertion: .push(from: .top).combined(with: .opacity),
                    removal: .push(from: .bottom).combined(with: .opacity)
                ))
            }
        }
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let budgetViewModel = BudgetViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let expenseViewModel = ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let incomeViewModel = IncomeViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let billViewModel = BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)

    // Create mock categories with explicit IDs
    let groceryCategory = Category(
        id: "cat-grocery",
        name: "Groceries",
        type: .expense,
        icon: "cart.fill",
        colorHex: "#4CAF50"
    )

    let diningCategory = Category(
        id: "cat-dining",
        name: "Dining",
        type: .expense,
        icon: "fork.knife",
        colorHex: "#FF9800"
    )

    let transportCategory = Category(
        id: "cat-transport",
        name: "Transport",
        type: .expense,
        icon: "car.fill",
        colorHex: "#2196F3"
    )

    let entertainmentCategory = Category(
        id: "cat-entertainment",
        name: "Entertainment",
        type: .expense,
        icon: "tv.fill",
        colorHex: "#9C27B0"
    )

    // Create mock budgets
    let calendar = Calendar.current
    let now = Date()
    let endOfMonth = calendar.date(byAdding: .month, value: 1, to: now)!

    let groceryBudget = Budget(
        id: "budget-1",
        userId: "preview-user",
        name: "Groceries",
        amount: 500,
        categoryId: groceryCategory.id,
        startDate: calendar.startOfMonth(for: now) ?? now,
        endDate: endOfMonth,
        isActive: true,
        alertThreshold: 0.8,
        notes: nil
    )

    let diningBudget = Budget(
        id: "budget-2",
        userId: "preview-user",
        name: "Dining Out",
        amount: 300,
        categoryId: diningCategory.id,
        startDate: calendar.startOfMonth(for: now) ?? now,
        endDate: endOfMonth,
        isActive: true,
        alertThreshold: 0.8,
        notes: nil
    )

    let transportBudget = Budget(
        id: "budget-3",
        userId: "preview-user",
        name: "Transportation",
        amount: 200,
        categoryId: transportCategory.id,
        startDate: calendar.startOfMonth(for: now) ?? now,
        endDate: endOfMonth,
        isActive: true,
        alertThreshold: 0.8,
        notes: nil
    )

    let entertainmentBudget = Budget(
        id: "budget-4",
        userId: "preview-user",
        name: "Entertainment",
        amount: 150,
        categoryId: entertainmentCategory.id,
        startDate: calendar.startOfMonth(for: now) ?? now,
        endDate: endOfMonth,
        isActive: true,
        alertThreshold: 0.8,
        notes: nil
    )

    // Create mock expenses for current month
    let dateFormatter = ISO8601DateFormatter()

    let expense1 = Expense(
        id: "exp-1",
        userId: "preview-user",
        name: "Whole Foods",
        amount: 450,
        expenseDate: dateFormatter.string(from: now),
        budgetId: groceryBudget.id,
        paymentMethod: .creditCard,
        createdAt: dateFormatter.string(from: now)
    )

    let expense2 = Expense(
        id: "exp-2",
        userId: "preview-user",
        name: "Restaurant",
        amount: 85,
        expenseDate: dateFormatter.string(from: now),
        budgetId: diningBudget.id,
        paymentMethod: .debitCard,
        createdAt: dateFormatter.string(from: now)
    )

    let expense3 = Expense(
        id: "exp-3",
        userId: "preview-user",
        name: "Gas Station",
        amount: 60,
        expenseDate: dateFormatter.string(from: now),
        budgetId: transportBudget.id,
        paymentMethod: .creditCard,
        createdAt: dateFormatter.string(from: now)
    )

    let expense4 = Expense(
        id: "exp-4",
        userId: "preview-user",
        name: "Movie Tickets",
        amount: 45,
        expenseDate: dateFormatter.string(from: now),
        budgetId: entertainmentBudget.id,
        paymentMethod: .digitalWallet,
        createdAt: dateFormatter.string(from: now)
    )

    // Create previous month budgets
    let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: calendar.startOfMonth(for: now) ?? now)!
    let previousMonthEnd = calendar.date(byAdding: .day, value: -1, to: calendar.startOfMonth(for: now) ?? now)!

    let prevGroceryBudget = Budget(
        id: "budget-5",
        userId: "preview-user",
        name: "Groceries",
        amount: 450,
        categoryId: groceryCategory.id,
        startDate: previousMonthStart,
        endDate: previousMonthEnd,
        isActive: true,
        alertThreshold: 0.8,
        notes: nil
    )

    let prevDiningBudget = Budget(
        id: "budget-6",
        userId: "preview-user",
        name: "Dining Out",
        amount: 250,
        categoryId: diningCategory.id,
        startDate: previousMonthStart,
        endDate: previousMonthEnd,
        isActive: true,
        alertThreshold: 0.8,
        notes: nil
    )

    let prevTransportBudget = Budget(
        id: "budget-7",
        userId: "preview-user",
        name: "Transportation",
        amount: 180,
        categoryId: transportCategory.id,
        startDate: previousMonthStart,
        endDate: previousMonthEnd,
        isActive: true,
        alertThreshold: 0.8,
        notes: nil
    )

    // Create previous month expenses
    let prevExpense1 = Expense(
        id: "exp-5",
        userId: "preview-user",
        name: "Safeway",
        amount: 420,
        expenseDate: dateFormatter.string(from: previousMonthStart),
        budgetId: prevGroceryBudget.id,
        paymentMethod: .creditCard,
        createdAt: dateFormatter.string(from: previousMonthStart)
    )

    let prevExpense2 = Expense(
        id: "exp-6",
        userId: "preview-user",
        name: "Dinner",
        amount: 210,
        expenseDate: dateFormatter.string(from: previousMonthStart),
        budgetId: prevDiningBudget.id,
        paymentMethod: .debitCard,
        createdAt: dateFormatter.string(from: previousMonthStart)
    )

    let prevExpense3 = Expense(
        id: "exp-7",
        userId: "preview-user",
        name: "Uber",
        amount: 175,
        expenseDate: dateFormatter.string(from: previousMonthStart),
        budgetId: prevTransportBudget.id,
        paymentMethod: .digitalWallet,
        createdAt: dateFormatter.string(from: previousMonthStart)
    )

    // Populate mock data in DataManager (which BudgetViewModel observes)
    // IMPORTANT: Set categories FIRST before budgets so the lookup works
    dataManager.categories = [groceryCategory, diningCategory, transportCategory, entertainmentCategory]

    dataManager.budgets = [groceryBudget, diningBudget, transportBudget, entertainmentBudget, prevGroceryBudget, prevDiningBudget, prevTransportBudget]
    dataManager.expenses = [expense1, expense2, expense3, expense4, prevExpense1, prevExpense2, prevExpense3]

    // Manually trigger load to populate view models from DataManager
    budgetViewModel.loadBudgets()
    expenseViewModel.expenses = [expense1, expense2, expense3, expense4, prevExpense1, prevExpense2, prevExpense3]

    // Set mock income and bills for calculations
    incomeViewModel.totalMonthlyIncome = 5000
    billViewModel.totalMonthlyBills = 2000

    return MyBudgetView()
        .environmentObject(dataManager)
        .environmentObject(sessionViewModel)
        .environmentObject(budgetViewModel)
        .environmentObject(expenseViewModel)
        .environmentObject(profileViewModel)
        .environmentObject(incomeViewModel)
        .environmentObject(billViewModel)
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date? {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)
    }
}
