//
//  BudgetDisclosureView.swift
//  Norma
//
//  Created by Claude on 5/19/25.
//

import SwiftUI

struct BudgetDisclosureView: View {
    @State private var showingAllCategories = false
    @State private var selectedBudgetForDetail: Budget?
    let isOnboardingMode: Bool
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    
    let expenses: [Expense]
    let month: String
    let onCategorySelected: ((Category) -> Void)?
    
    init(expenses: [Expense], month: String, isOnboardingMode: Bool = false, onCategorySelected: ((Category) -> Void)? = nil) {
        self.expenses = expenses
        self.month = month
        self.isOnboardingMode = isOnboardingMode
        self.onCategorySelected = onCategorySelected
    }
    
    private let maxCategoriesToShow = 3
    
    private var activeBudgets: [Budget] {
        budgetViewModel.activeBudgets
    }
    
    private var budgetsWithSpending: [(budget: Budget, spent: Double, category: Category?)] {
        activeBudgets.compactMap { budget -> (budget: Budget, spent: Double, category: Category?)? in
            guard let categoryId = budget.categoryId,
                  let category = dataManager.categories.first(where: { $0.id == categoryId }) else {
                return nil
            }
            
            // Calculate actual spent amount from linked expenses
            let spent = expenses.filter { $0.budgetId == budget.id }
                .reduce(0) { $0 + $1.amount }
            return (budget, spent, category)
        }.sorted { item1, item2 in
            let percentage1 = item1.budget.amount > 0 ? item1.spent / item1.budget.amount : 0
            let percentage2 = item2.budget.amount > 0 ? item2.spent / item2.budget.amount : 0
            return percentage1 > percentage2
        }
    }
    
    private var displayedBudgets: [(budget: Budget, spent: Double, category: Category?)] {
        Array(budgetsWithSpending.prefix(maxCategoriesToShow))
    }
    
    private var totalBudget: Double {
        activeBudgets.reduce(0) { $0 + $1.amount }
    }
    
    private var totalSpent: Double {
        budgetsWithSpending.reduce(0) { $0 + $1.spent }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Budget Summary Header
            BudgetSummaryHeader(
                month: month,
                totalBudget: totalBudget,
                totalSpent: totalSpent
            )
            
            // Budget categories container
            budgetContainer
        }
        .sheet(item: $selectedBudgetForDetail) { budget in
            BudgetDetailView(budget: budget)
                .environmentObject(dataManager)
                .environmentObject(budgetViewModel)
                .environmentObject(expenseViewModel)
                .environmentObject(profileViewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    @ViewBuilder
    private var budgetContainer: some View {
        ZStack {
            containerBackground
            
            VStack(spacing: 0) {
                if activeBudgets.isEmpty {
                    EmptyBudgetState(onCategorySelected: onCategorySelected)
                } else {
                    budgetList
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private var containerBackground: some View {
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
    }
    
    @ViewBuilder
    private var budgetList: some View {
        // Budget category items
        ForEach(displayedBudgets, id: \.budget.id) { item in
            if let category = item.category {
                Button(action: {
                    print("🔍 [DEBUG] Budget tapped: \(item.budget.name), ID: \(item.budget.id ?? "nil")")
                    selectedBudgetForDetail = item.budget
                }) {
                    BudgetRow(
                        budget: item.budget,
                        category: category,
                        spentAmount: item.spent
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        
        // See all button
        if activeBudgets.count > maxCategoriesToShow {
            seeAllButton
        }
    }
    
    @ViewBuilder
    private var seeAllButton: some View {
        Divider()
            .padding(.horizontal, 20)
        
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showingAllCategories.toggle()
            }
        }) {
            HStack {
                Text("See All Categories")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("\(activeBudgets.count - maxCategoriesToShow) more")
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
        .sheet(isPresented: $showingAllCategories) {
            allBudgetsSheet
        }
    }
    
    @ViewBuilder
    private var allBudgetsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(budgetsWithSpending, id: \.budget.id) { item in
                        if let category = item.category {
                            Button(action: {
                                print("🔍 [DEBUG] Budget tapped in sheet: \(item.budget.name), ID: \(item.budget.id ?? "nil")")
                                selectedBudgetForDetail = item.budget
                            }) {
                                BudgetRow(
                                    budget: item.budget,
                                    category: category,
                                    spentAmount: item.spent
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if item.budget.id != budgetsWithSpending.last?.budget.id {
                                Divider()
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 10)
                )
                .padding()
            }
            .navigationTitle("All Budget Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingAllCategories = false
                    }
                }
            }
        }
    }
}

#Preview {
    let dateFormatter = ISO8601DateFormatter()
    let sampleExpenses: [Expense] = [
        Expense(userId: "preview-user", name: "Groceries", amount: 350, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 1)), paymentMethod: .creditCard),
        Expense(userId: "preview-user", name: "Restaurant", amount: 200, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 2)), paymentMethod: .creditCard),
        Expense(userId: "preview-user", name: "Gas", amount: 150, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 3)), paymentMethod: .debitCard),
        Expense(userId: "preview-user", name: "Uber", amount: 80, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 4)), paymentMethod: .digitalWallet),
        Expense(userId: "preview-user", name: "Movie", amount: 50, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 5)), paymentMethod: .creditCard),
    ]
    
    return ScrollView {
        VStack(spacing: 30) {
            // Onboarding mode (empty state)
            BudgetDisclosureView(expenses: [], month: "December", isOnboardingMode: true)
            
            // Regular mode with data
            BudgetDisclosureView(expenses: sampleExpenses, month: "December")
        }
        .padding()
    }
    .preferredColorScheme(.light)
}