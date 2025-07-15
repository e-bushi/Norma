//
//  ExpenseListView.swift
//  Norma
//
//  Created by Claude on 7/12/25.
//

import SwiftUI

// Filter options enum
enum ExpenseFilter: String, CaseIterable {
    case all = "All"
    case cash = "Cash"
    case card = "Card"
    case recurring = "Recurring"
}

struct ExpenseListView: View {
    // Expenses and filters
    let expenses: [Expense]
    @Binding var selectedFilter: ExpenseFilter
    @Binding var selectedDate: Date
    @Binding var showAllDates: Bool
    
    // Animation state
    @Namespace private var animation
    @State private var appearAnimation = false
    @State private var animationTrigger = UUID()
    
    // Sheet state
    @State private var selectedExpense: Expense? = nil
    
    // Computed properties for filtered expenses
    private var filteredExpenses: [Expense] {
        switch selectedFilter {
        case .all:
            return expenses
        case .cash:
            return expenses.filter { $0.paymentMethod == .cash }
        case .card:
            return expenses.filter { 
                $0.paymentMethod == .creditCard || $0.paymentMethod == .debitCard 
            }
        case .recurring:
            return expenses.filter { $0.isRecurring }
        }
    }
    
    private var filteredAndDateFilteredExpenses: [Expense] {
        if showAllDates {
            return filteredExpenses
        } else {
            let calendar = Calendar.current
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            return filteredExpenses.filter { expense in
                if let expenseDate = dateFormatter.date(from: expense.expenseDate) {
                    return calendar.isDate(expenseDate, inSameDayAs: selectedDate)
                }
                return false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Filter selector with enhanced animation
            VStack(spacing: 4) {
                // Picker with custom transitions
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ExpenseFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue)
                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                            .matchedGeometryEffect(id: "filter_\(filter.rawValue)", in: animation, isSource: selectedFilter == filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .scaleEffect(x: appearAnimation ? 1 : 0.98, y: appearAnimation ? 1 : 0.98)
                .animation(.spring(response: 0.3), value: appearAnimation)
            }
            .onChange(of: selectedFilter) {
                triggerAnimation()
            }
            
            // Expenses content
            if filteredAndDateFilteredExpenses.isEmpty {
                emptyStateView
            } else {
                expenseListView
            }
        }
        .onAppear {
            // Trigger initial animation when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    appearAnimation = true
                }
            }
        }
        .onChange(of: selectedDate) {
            triggerAnimation()
        }
        .onChange(of: showAllDates) {
            triggerAnimation()
        }
        .sheet(item: $selectedExpense) { expense in
            ExpenseDetailView(expense: expense)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // Empty state view when no expenses match the current filter/date
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.top, 60)
                .scaleEffect(appearAnimation ? 1 : 0.8)
                .opacity(appearAnimation ? 1 : 0)
            
            Text("No expenses found")
                .font(.title3)
                .foregroundColor(.secondary)
                .scaleEffect(appearAnimation ? 1 : 0.9)
                .opacity(appearAnimation ? 1 : 0)
            
            Text(showAllDates ? "Try changing the filter" : "Try selecting a different date")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .scaleEffect(appearAnimation ? 1 : 0.9)
                .opacity(appearAnimation ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1), value: appearAnimation)
    }
    
    // Expense list view when there are expenses to show
    private var expenseListView: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(filteredAndDateFilteredExpenses.enumerated()), id: \.element.id) { index, expense in
                Button(action: {
                    selectedExpense = expense
                }) {
                    ExpenseRowCard(expense: expense)
                }
                .padding(.horizontal)
                // Apply multiple transformations for a more interesting animation
                .offset(x: appearAnimation ? 0 : -20)
                .scaleEffect(appearAnimation ? 1 : 0.95)
                .opacity(appearAnimation ? 1 : 0)
                // Add slight rotation for a more dynamic effect
                .rotation3DEffect(
                    .degrees(appearAnimation ? 0 : -5),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
                // Use a spring animation with staggered delay based on index
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0.3)
                    .delay(0.08 + Double(index) * 0.06),
                    value: appearAnimation
                )
                .buttonStyle(TapToBounceStyle())
                .id("\(expense.id ?? "")-\(animationTrigger)")
            }
        }
        .padding(.vertical)
    }
    
    // Helper method to trigger a fresh animation
    private func triggerAnimation() {
        // Reset animation state
        appearAnimation = false
        animationTrigger = UUID()
        
        // Small delay to ensure the state reset is processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appearAnimation = true
            }
        }
    }
}

// Expense row card for list display
struct ExpenseRowCard: View {
    let expense: Expense
    
    private var expenseDate: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: expense.expenseDate) ?? Date()
    }
    
    private var paymentMethodIcon: String {
        switch expense.paymentMethod {
        case .cash:
            return "banknote.fill"
        case .creditCard:
            return "creditcard.fill"
        case .debitCard:
            return "creditcard"
        case .bankTransfer:
            return "building.columns.fill"
        case .digitalWallet:
            return "wallet.pass.fill"
        case .check:
            return "checkmark.rectangle.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
    
    private var paymentMethodColor: Color {
        switch expense.paymentMethod {
        case .cash:
            return .green
        case .creditCard, .debitCard:
            return .blue
        case .bankTransfer:
            return .purple
        case .digitalWallet:
            return .orange
        case .check:
            return .gray
        case .other:
            return .secondary
        }
    }
    
    var body: some View {
        HStack {
            // Icon and Expense Name Section
            HStack(spacing: 12) {
                Image(systemName: paymentMethodIcon)
                    .font(.system(size: 16))
                    .foregroundColor(paymentMethodColor)
                    .frame(width: 40, height: 40)
                    .background(paymentMethodColor.opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    HStack(spacing: 8) {
                        Text(expenseDate, format: .dateTime.month().day())
                        if let merchant = expense.merchant {
                            Text("•")
                            Text(merchant)
                                .lineLimit(1)
                        }
                        if expense.isRecurring {
                            Text("•")
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Amount Section
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(expense.amount, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(expense.paymentMethod.rawValue)
                    .font(.caption)
                    .foregroundColor(paymentMethodColor)
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

// Custom button style that adds a bounce animation when tapped
struct TapToBounceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// Preview
struct ExpenseListView_Previews: PreviewProvider {
    static var previews: some View {
        struct PreviewWrapper: View {
            let sampleExpenses: [Expense] = {
                let sampleUserId = "preview-user-123"
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                return [
                    Expense(
                        userId: sampleUserId,
                        name: "Groceries",
                        amount: 87.50,
                        expenseDate: dateFormatter.string(from: Date()),
                        paymentMethod: .creditCard,
                        isRecurring: false,
                        merchant: "Whole Foods",
                        tags: ["food", "groceries"]
                    ),
                    Expense(
                        userId: sampleUserId,
                        name: "Gas",
                        amount: 65.99,
                        expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 2)),
                        paymentMethod: .debitCard,
                        isRecurring: false,
                        merchant: "Shell",
                        tags: ["transportation", "gas"]
                    ),
                    Expense(
                        userId: sampleUserId,
                        name: "Netflix Subscription",
                        amount: 15.99,
                        expenseDate: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 5)),
                        paymentMethod: .creditCard,
                        isRecurring: true,
                        recurringFrequency: .monthly,
                        merchant: "Netflix",
                        tags: ["entertainment", "subscription"]
                    ),
                    Expense(
                        userId: sampleUserId,
                        name: "Coffee",
                        amount: 5.50,
                        expenseDate: dateFormatter.string(from: Date()),
                        paymentMethod: .cash,
                        isRecurring: false,
                        merchant: "Starbucks",
                        tags: ["food", "coffee"]
                    )
                ]
            }()
            
            @State private var selectedFilter: ExpenseFilter = .all
            @State private var selectedDate: Date = Date()
            @State private var showAllDates: Bool = true
            
            var body: some View {
                ExpenseListView(
                    expenses: sampleExpenses,
                    selectedFilter: $selectedFilter,
                    selectedDate: $selectedDate,
                    showAllDates: $showAllDates
                )
                .padding(.vertical)
            }
        }
        
        return NavigationStack {
            PreviewWrapper()
        }
    }
}
