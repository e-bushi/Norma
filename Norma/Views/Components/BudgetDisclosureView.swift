//
//  BudgetDisclosureView.swift
//  Norma
//
//  Created by Claude on 5/19/25.
//

import SwiftUI

struct BudgetDisclosureView: View {
    @State private var categoryBudgets: [ExpenseCategory: Double] = [:]
    @State private var showingAllCategories = false
    let isOnboardingMode: Bool
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    let expenses: [Expense]
    let month: String
    
    init(expenses: [Expense], month: String, isOnboardingMode: Bool = false) {
        self.expenses = expenses
        self.month = month
        self.isOnboardingMode = isOnboardingMode
        
        // Initialize with empty budgets - users should set their own
        _categoryBudgets = State(initialValue: [:])
    }
    
    private let maxCategoriesToShow = 3
    
    private var expensesByCategory: [ExpenseCategory: Double] {
        var totals: [ExpenseCategory: Double] = [:]
        
        for expense in expenses {
            // TODO: Map expense.categoryId to ExpenseCategory
            // For now, default all to .other since we don't have the mapping implemented
            let category = ExpenseCategory.other
            totals[category, default: 0] += expense.amount
        }
        
        return totals
    }
    
    private var categoriesWithBudgets: [ExpenseCategory] {
        return categoryBudgets.compactMap { category, budget in
            budget > 0 ? category : nil
        }.sorted { category1, category2 in
            let spent1 = expensesByCategory[category1] ?? 0
            let spent2 = expensesByCategory[category2] ?? 0
            let budget1 = categoryBudgets[category1] ?? 0
            let budget2 = categoryBudgets[category2] ?? 0
            let percentage1 = budget1 > 0 ? spent1 / budget1 : 0
            let percentage2 = budget2 > 0 ? spent2 / budget2 : 0
            return percentage1 > percentage2
        }
    }
    
    private var displayedCategories: [ExpenseCategory] {
        Array(categoriesWithBudgets.prefix(maxCategoriesToShow))
    }
    
    private var totalBudget: Double {
        categoryBudgets.values.reduce(0, +)
    }
    
    private var totalSpent: Double {
        expensesByCategory.values.reduce(0, +)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header section
            VStack(spacing: 12) {
                Text("\(month.uppercased()) BUDGET")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                
                // Summary stats
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Total Budget")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(profileViewModel.formatCurrency(totalBudget))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Spent")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(profileViewModel.formatCurrency(totalSpent))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(totalSpent > totalBudget ? .red : .primary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Remaining")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(profileViewModel.formatCurrency(max(0, totalBudget - totalSpent)))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(totalSpent > totalBudget ? .red : .green)
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
            
            // Budget categories container
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
                    if displayedCategories.isEmpty {
                        // Enhanced empty state
                        VStack(spacing: 24) {
                            if true {
                                // Enhanced empty state with category grid
                                VStack(spacing: 16) {
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
                                        
                                        Image(systemName: "target")
                                            .font(.system(size: 36))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    VStack(spacing: 8) {
                                        Text("Ready to set budgets?")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Text("Create spending limits for different categories to stay on track")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                
                                Divider()
                                    .frame(maxWidth: 200)
                                
                                // Quick budget suggestions
                                VStack(spacing: 12) {
                                    Text("Popular budget categories")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                        ForEach([ExpenseCategory.food, .transportation, .entertainment, .shopping], id: \.self) { category in
                                            Button(action: {
                                                addQuickBudget(for: category)
                                            }) {
                                                HStack(spacing: 8) {
                                                    Image(systemName: category.icon)
                                                        .font(.system(size: 14))
                                                        .foregroundColor(category.color)
                                                    
                                                    Text(category.rawValue)
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(.primary)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(category.color.opacity(0.05))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .stroke(category.color.opacity(0.2), lineWidth: 1)
                                                        )
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            } else {
                                // Regular empty state
                                VStack(spacing: 16) {
                                    Image(systemName: "chart.pie.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue.opacity(0.5))
                                    
                                    VStack(spacing: 8) {
                                        Text("No budgets set")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Text("Add budget categories to track your spending")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                
                                Button(action: {
                                    // Add budget action
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 14))
                                        
                                        Text("Add Budget Category")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 40)
                        .padding(.horizontal, 24)
                    } else {
                        // Budget category items
                        ForEach(displayedCategories, id: \.self) { category in
                            BudgetCategoryRow(
                                category: category,
                                budgetAmount: categoryBudgets[category] ?? 0,
                                spentAmount: expensesByCategory[category] ?? 0,
                                onBudgetChanged: { newBudget in
                                    categoryBudgets[category] = newBudget
                                }
                            )
                        }
                        
                        // See all button
                        if categoriesWithBudgets.count > maxCategoriesToShow {
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
                                    
                                    Text("\(categoriesWithBudgets.count - maxCategoriesToShow) more")
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
                                NavigationStack {
                                    ScrollView {
                                        VStack(spacing: 0) {
                                            ForEach(categoriesWithBudgets, id: \.self) { category in
                                                BudgetCategoryRow(
                                                    category: category,
                                                    budgetAmount: categoryBudgets[category] ?? 0,
                                                    spentAmount: expensesByCategory[category] ?? 0,
                                                    onBudgetChanged: { newBudget in
                                                        categoryBudgets[category] = newBudget
                                                    }
                                                )
                                                
                                                if category != categoriesWithBudgets.last {
                                                    Divider()
                                                        .padding(.horizontal, 20)
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
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private func addQuickBudget(for category: ExpenseCategory) {
        let suggestedBudgets: [ExpenseCategory: Double] = [
            .food: 600,
            .transportation: 300,
            .entertainment: 200,
            .shopping: 400,
            .utilities: 250,
            .health: 150,
            .other: 200
        ]
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            categoryBudgets[category] = suggestedBudgets[category] ?? 200
        }
    }
}

struct BudgetCategoryRow: View {
    let category: ExpenseCategory
    let budgetAmount: Double
    let spentAmount: Double
    let onBudgetChanged: (Double) -> Void
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @State private var isEditingBudget = false
    @State private var tempBudgetText: String = ""
    
    private var percentageUsed: Double {
        guard budgetAmount > 0 else { return 0 }
        return min(spentAmount / budgetAmount, 1.5) // Cap at 150% for visual purposes
    }
    
    private var isOverBudget: Bool {
        spentAmount > budgetAmount
    }
    
    private var statusColor: Color {
        if percentageUsed < 0.5 {
            return .green
        } else if percentageUsed < 0.8 {
            return .yellow
        } else if percentageUsed < 1.0 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 16))
                        .foregroundColor(category.color)
                }
                
                // Category info
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text(profileViewModel.formatCurrency(spentAmount))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isOverBudget ? .red : .primary)
                        
                        Text("of")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        if isEditingBudget {
                            TextField("Budget", text: $tempBudgetText)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                                .textFieldStyle(PlainTextFieldStyle())
                                .frame(width: 60)
                                .onSubmit {
                                    saveBudget()
                                }
                        } else {
                            Text(profileViewModel.formatCurrency(budgetAmount))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                                .onTapGesture {
                                    tempBudgetText = "\(Int(budgetAmount))"
                                    isEditingBudget = true
                                }
                        }
                    }
                }
                
                Spacer()
                
                // Percentage and remaining
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(percentageUsed * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(statusColor)
                    
                    if !isOverBudget {
                        Text("\(profileViewModel.formatCurrency(budgetAmount - spentAmount)) left")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(profileViewModel.formatCurrency(spentAmount - budgetAmount)) over")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Enhanced progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .frame(height: 12)
                    
                    // Progress fill - styled like quick add budget buttons
                    RoundedRectangle(cornerRadius: 6)
                        .fill(statusColor.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(statusColor.opacity(0.2), lineWidth: 1)
                        )
                        .frame(width: min(geometry.size.width * percentageUsed, geometry.size.width), height: 12)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: percentageUsed)
                }
            }
            .frame(height: 12)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .onTapGesture {
            if isEditingBudget {
                saveBudget()
            }
        }
    }
    
    private func saveBudget() {
        if let newBudget = Double(tempBudgetText), newBudget > 0 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                onBudgetChanged(newBudget)
            }
        }
        isEditingBudget = false
    }
}

extension ExpenseCategory: CaseIterable {
    static var allCases: [ExpenseCategory] {
        return [.food, .transportation, .entertainment, .shopping, .utilities, .health, .other]
    }
}

struct BudgetDisclosureView_Previews: PreviewProvider {
    static let dateFormatter = ISO8601DateFormatter()
    static let sampleExpenses: [Expense] = [
        Expense(userId: "preview-user", name: "Groceries", amount: 350, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 1)), paymentMethod: .creditCard),
        Expense(userId: "preview-user", name: "Restaurant", amount: 200, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 2)), paymentMethod: .creditCard),
        Expense(userId: "preview-user", name: "Gas", amount: 150, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 3)), paymentMethod: .debitCard),
        Expense(userId: "preview-user", name: "Uber", amount: 80, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 4)), paymentMethod: .digitalWallet),
        Expense(userId: "preview-user", name: "Movie", amount: 50, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 5)), paymentMethod: .creditCard),
        Expense(userId: "preview-user", name: "Concert", amount: 180, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 6)), paymentMethod: .creditCard),
        Expense(userId: "preview-user", name: "Clothes", amount: 300, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 7)), paymentMethod: .creditCard),
        Expense(userId: "preview-user", name: "Electric Bill", amount: 120, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 8)), paymentMethod: .bankTransfer),
        Expense(userId: "preview-user", name: "Doctor Visit", amount: 100, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 9)), paymentMethod: .creditCard)
    ]
    
    static var previews: some View {
        ScrollView {
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
}
