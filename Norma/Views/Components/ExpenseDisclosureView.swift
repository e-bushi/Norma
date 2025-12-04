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
    @Binding var showNormaChat: Bool
    @State private var showingAllExpenses = false
    @State private var selectedExpense: Expense? = nil
    @State private var showCreateExpense = false
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.colorScheme) var colorScheme
    
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
            // Add expense button
            Button(action: {
                showCreateExpense = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15))

                    Text("Add Expense")
                        .font(.normaInput(14))
                }
                .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.50, green: 0.45, blue: 0.65))
                .frame(maxWidth: .infinity)
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
            
            // Expenses list container
            if displayedExpenses.isEmpty {
                // Enhanced empty state
                VStack(spacing: 24) {
                    // Icon with gradient background
                    ZStack {
                        Circle()
                            .fill(.clear)
                            .glassEffect(in: Circle())
                            .frame(width: 80, height: 80)

                        Image(systemName: "creditcard.and.123")
                            .font(.system(size: 36))
                            .foregroundColor(Color("NormaPastelCoral"))
                    }

                    VStack(spacing: 12) {
                        Text("No expenses yet")
                            .font(.normaFinancial(20))
                            .foregroundColor(.primary)

                        Text("Start tracking your daily expenses\nto better manage your budget")
                            .font(.normaInput(14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }

                    // Quick tips
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color("NormaPastelBeige"))

                            Text("Track groceries, dining, and shopping")
                                .font(.normaInput(13))
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "chart.pie.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color("NormaPastelCoral"))

                            Text("Categorize spending automatically")
                                .font(.normaInput(13))
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 16))
                                .foregroundColor(Color("NormaPastelTeal"))

                            Text("Visualize your spending habits")
                                .font(.normaInput(13))
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
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                .background(
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
                )
            } else {
                VStack(spacing: 0) {
                    // Expense items
                    VStack(spacing: 16) {
                        ForEach(displayedExpenses) { expense in
                            Button(action: {
                                selectedExpense = expense
                            }) {
                                ExpenseRowView(expense: expense)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                    )

                    // See all button
                    if filteredExpenses.count > maxExpensesToShow {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showingAllExpenses.toggle()
                            }
                        }) {
                            HStack {
                                Text("See All Expenses")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color("NormaPastelCoral"))

                                Spacer()

                                Text("\(filteredExpenses.count - maxExpensesToShow) more")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color("NormaPastelCoral"))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 12)
                        .sheet(isPresented: $showingAllExpenses) {
                            MyExpensesView()
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedExpense) { expense in
            ExpenseDetailView(expense: expense)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCreateExpense) {
            CreateExpenseView()
        }
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var budgetViewModel: BudgetViewModel

    private var category: Category? {
        // Get category through the budget
        guard let budgetId = expense.budgetId,
              let budget = budgetViewModel.budgets.first(where: { $0.id == budgetId }),
              let categoryId = budget.categoryId else {
            return nil
        }
        return dataManager.categories.first { $0.id == categoryId }
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
        HStack(spacing: 12) {
            // Category icon
            Circle()
                .fill((category?.color ?? Color("NormaPastelCoral")).opacity(0.15))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: category?.icon ?? "dollarsign.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(category?.color ?? Color("NormaPastelCoral"))
                )

            // Expense info
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.name)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)

                Text(timeAgoText)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Amount
            Text(profileViewModel.formatCurrency(expense.amount))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    // Sample data for preview
    let dateFormatter = ISO8601DateFormatter()
    let sampleExpenses: [Expense] = [
        Expense(userId: "preview-user", name: "Groceries", amount: 120.50, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 1)), paymentMethod: .creditCard),
//        Expense(userId: "preview-user", name: "Gas", amount: 45.00, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 2)), paymentMethod: .debitCard),
//        Expense(userId: "preview-user", name: "Movie Tickets", amount: 32.99, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 3)), paymentMethod: .creditCard),
//        Expense(userId: "preview-user", name: "Restaurant", amount: 85.75, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 4)), paymentMethod: .creditCard),
//        Expense(userId: "preview-user", name: "Uber Ride", amount: 18.50, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 5)), paymentMethod: .digitalWallet),
//        Expense(userId: "preview-user", name: "Clothing", amount: 99.99, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 6)), paymentMethod: .creditCard),
//        Expense(userId: "preview-user", name: "Doctor Visit", amount: 75.00, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 7)), paymentMethod: .creditCard),
//        Expense(userId: "preview-user", name: "Electricity Bill", amount: 135.62, expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 8)), paymentMethod: .bankTransfer)
    ]
    
    // Create preview view models
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    @State var showNormaChat = false
    
    return ScrollView {
        VStack {
            Text("All Expenses")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            ExpenseDisclosureView(expenses: sampleExpenses, category: nil, showNormaChat: $showNormaChat)
                .padding(.horizontal)
            
            Divider().padding()
            
            Text("Food Expenses Only")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            ExpenseDisclosureView(expenses: sampleExpenses, category: nil, showNormaChat: $showNormaChat)
                .padding(.horizontal)
            
            Divider().padding()
            
            Text("Empty State")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            ExpenseDisclosureView(expenses: [], category: nil, showNormaChat: $showNormaChat)
                .padding(.horizontal)
        }
    }
    .environmentObject(profileViewModel)
}
