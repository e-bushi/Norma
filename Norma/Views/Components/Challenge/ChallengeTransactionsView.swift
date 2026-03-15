//
//  ChallengeTransactionsView.swift
//  Norma
//
//  Created by Claude on 1/17/26.
//

import SwiftUI

// MARK: - Challenge Expense List (no header)

/// View showing just the expense list for a selected day (without stats header)
struct ChallengeExpenseList: View {
    let selectedDay: ChallengeDay
    let expenses: [Expense]
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var showingAllExpenses = false
    @State private var selectedExpense: Expense? = nil
    @State private var itemStates: [Bool] = []

    private let maxExpensesToShow = 5

    private var displayedExpenses: [Expense] {
        Array(expenses.prefix(maxExpensesToShow))
    }

    private func animateItemsStaggered() {
        // Reset all states
        itemStates = Array(repeating: false, count: displayedExpenses.count)

        // Animate each item with staggered delay
        for i in 0..<displayedExpenses.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    if i < itemStates.count {
                        itemStates[i] = true
                    }
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text("EXPENSES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.5)

            if displayedExpenses.isEmpty {
                // Empty state with radar rings
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("No expenses on this day")
                        .font(.normaInput(14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.03))

                        Canvas { context, size in
                            let origin = CGPoint(x: size.width, y: size.height)
                            let ringCount = 6
                            let maxRadius: CGFloat = 140
                            let ringSpacing = maxRadius / CGFloat(ringCount)

                            for i in 1...ringCount {
                                let radius = CGFloat(i) * ringSpacing
                                let opacity = 0.2 * (1.0 - CGFloat(i) / CGFloat(ringCount))
                                let rect = CGRect(
                                    x: origin.x - radius,
                                    y: origin.y - radius,
                                    width: radius * 2,
                                    height: radius * 2
                                )
                                context.stroke(
                                    Path(ellipseIn: rect),
                                    with: .color(Color.secondary.opacity(opacity)),
                                    lineWidth: 1
                                )
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .allowsHitTesting(false)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                )
            } else {
                VStack(spacing: 0) {
                    // Expense items
                    VStack(spacing: 16) {
                        ForEach(Array(displayedExpenses.enumerated()), id: \.element.id) { index, expense in
                            Button(action: {
                                selectedExpense = expense
                            }) {
                                ChallengeExpenseRow(expense: expense)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .opacity(index < itemStates.count && itemStates[index] ? 1 : 0)
                            .offset(x: index < itemStates.count && itemStates[index] ? 0 : -20)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.clear)
                            .glassEffect(in: RoundedRectangle(cornerRadius: 16))
                    )

                    // See all button
                    if expenses.count > maxExpensesToShow {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showingAllExpenses.toggle()
                            }
                        }) {
                            HStack {
                                Text("See All Expenses")
                                    .font(.normaInput(13))
                                    .foregroundColor(Color("NormaPastelCoral"))

                                Spacer()

                                Text("\(expenses.count - maxExpensesToShow) more")
                                    .font(.normaInput(12))
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
                            MyExpensesView(presetDate: selectedDay.date)
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
        .onAppear {
            animateItemsStaggered()
        }
        .onChange(of: expenses) { _, _ in
            animateItemsStaggered()
        }
    }
}

// MARK: - Challenge Transactions View (with header)

/// View showing transactions for a selected challenge day
struct ChallengeTransactionsView: View {
    let selectedDay: ChallengeDay
    let expenses: [Expense]
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var showingAllExpenses = false
    @State private var selectedExpense: Expense? = nil
    @State private var itemStates: [Bool] = []

    private let maxExpensesToShow = 5

    private var displayedExpenses: [Expense] {
        Array(expenses.prefix(maxExpensesToShow))
    }

    private func animateItemsStaggered() {
        // Reset all states
        itemStates = Array(repeating: false, count: displayedExpenses.count)

        // Animate each item with staggered delay
        for i in 0..<displayedExpenses.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    if i < itemStates.count {
                        itemStates[i] = true
                    }
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day Summary Header
            DaySummaryHeader(selectedDay: selectedDay)

            if displayedExpenses.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("No expenses on this day")
                        .font(.normaInput(14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                )
            } else {
                VStack(spacing: 0) {
                    // Expense items
                    VStack(spacing: 16) {
                        ForEach(Array(displayedExpenses.enumerated()), id: \.element.id) { index, expense in
                            Button(action: {
                                selectedExpense = expense
                            }) {
                                ChallengeExpenseRow(expense: expense)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .opacity(index < itemStates.count && itemStates[index] ? 1 : 0)
                            .offset(x: index < itemStates.count && itemStates[index] ? 0 : -20)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.clear)
                            .glassEffect(in: RoundedRectangle(cornerRadius: 16))
                    )

                    // See all button
                    if expenses.count > maxExpensesToShow {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showingAllExpenses.toggle()
                            }
                        }) {
                            HStack {
                                Text("See All Expenses")
                                    .font(.normaInput(13))
                                    .foregroundColor(Color("NormaPastelCoral"))

                                Spacer()

                                Text("\(expenses.count - maxExpensesToShow) more")
                                    .font(.normaInput(12))
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
                            MyExpensesView(presetDate: selectedDay.date)
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
        .onAppear {
            animateItemsStaggered()
        }
        .onChange(of: expenses) { _, _ in
            animateItemsStaggered()
        }
    }
}

// MARK: - Day Summary Header

struct DaySummaryHeader: View {
    let selectedDay: ChallengeDay
    @EnvironmentObject var profileViewModel: ProfileViewModel

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDay.date)
    }

    private var statusColor: Color {
        guard selectedDay.dailyCap != nil else { return .secondary }
        return selectedDay.isOverBudget ? Color("NormaPastelCoral") : Color("NormaPastelGreen")
    }

    private var statusIcon: String {
        guard selectedDay.dailyCap != nil else { return "circle.dashed" }
        return selectedDay.isOverBudget ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
    }

    private var statusText: String {
        guard let cap = selectedDay.dailyCap else { return "No cap set" }
        let difference = abs(cap - selectedDay.spending)
        let formattedDiff = profileViewModel.formatCurrency(difference)
        if selectedDay.isOverBudget {
            return "\(formattedDiff) over"
        } else {
            return "\(formattedDiff) under"
        }
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
                if selectedDay.isToday {
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
                    Text(profileViewModel.formatCurrency(selectedDay.spending))
                        .font(.normaFinancial(18))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                }

                Spacer()

                // Daily Cap
                if let cap = selectedDay.dailyCap {
                    VStack(alignment: .center, spacing: 4) {
                        Text("CAP")
                            .font(.normaInput(10))
                            .foregroundColor(.secondary)
                            .tracking(0.8)
                        Text(profileViewModel.formatCurrency(cap))
                            .font(.normaFinancial(18))
                            .foregroundColor(.secondary)
                            .contentTransition(.numericText())
                    }

                    Spacer()

                    // Status
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("STATUS")
                            .font(.normaInput(10))
                            .foregroundColor(.secondary)
                            .tracking(0.8)
                        HStack(spacing: 4) {
                            Image(systemName: statusIcon)
                                .font(.system(size: 12))
                            Text(statusText)
                                .font(.normaInput(14))
                                .contentTransition(.numericText())
                        }
                        .foregroundColor(statusColor)
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedDay.spending)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedDay.dailyCap)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Challenge Expense Row

struct ChallengeExpenseRow: View {
    let expense: Expense
    @EnvironmentObject var profileViewModel: ProfileViewModel

    private var timeText: String {
        let dateFormatter = ISO8601DateFormatter()
        guard let expenseDate = dateFormatter.date(from: expense.expenseDate) else {
            return "Unknown"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: expenseDate)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Circle()
                .fill(Color("NormaPastelCoral").opacity(0.15))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color("NormaPastelCoral"))
                )

            // Expense info
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.name)
                    .font(.normaInput(14))
                    .foregroundColor(.primary)

                Text(timeText)
                    .font(.normaInput(12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Amount
            Text(profileViewModel.formatCurrency(expense.amount))
                .font(.normaFinancial(14))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Previews

#Preview("With Expenses") {
    ChallengeTransactionsView(
        selectedDay: ChallengeDay(date: Date(), isToday: true, isPast: false, spending: 125.50, dailyCap: 100.00),
        expenses: [
            Expense(
                id: "1",
                userId: "user",
                name: "Coffee",
                amount: 5.50,
                expenseDate: ISO8601DateFormatter().string(from: Date()),
                paymentMethod: .debitCard
            ),
            Expense(
                id: "2",
                userId: "user",
                name: "Lunch",
                amount: 15.00,
                expenseDate: ISO8601DateFormatter().string(from: Date()),
                paymentMethod: .debitCard
            ),
            Expense(
                id: "3",
                userId: "user",
                name: "Groceries",
                amount: 85.00,
                expenseDate: ISO8601DateFormatter().string(from: Date()),
                paymentMethod: .debitCard
            )
        ]
    )
    .padding(20)
    .background(Color("NormaBackground"))
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}

#Preview("Empty State") {
    ChallengeTransactionsView(
        selectedDay: ChallengeDay(date: Date(), isToday: true, isPast: false, spending: 0, dailyCap: 100.00),
        expenses: []
    )
    .padding(20)
    .background(Color("NormaBackground"))
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}

#Preview("Overflow State") {
    ChallengeTransactionsView(
        selectedDay: ChallengeDay(date: Date(), isToday: true, isPast: false, spending: 250.00, dailyCap: 100.00),
        expenses: (1...8).map { i in
            Expense(
                id: "\(i)",
                userId: "user",
                name: "Expense \(i)",
                amount: Double(i) * 10.0,
                expenseDate: ISO8601DateFormatter().string(from: Date()),
                paymentMethod: .debitCard
            )
        }
    )
    .padding(20)
    .background(Color("NormaBackground"))
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}

#Preview("Day Summary - Under Budget") {
    DaySummaryHeader(
        selectedDay: ChallengeDay(date: Date(), isToday: true, isPast: false, spending: 45.00, dailyCap: 100.00)
    )
    .padding(20)
    .background(Color("NormaBackground"))
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}

#Preview("Day Summary - Over Budget") {
    DaySummaryHeader(
        selectedDay: ChallengeDay(date: Date(), isToday: false, isPast: true, spending: 125.50, dailyCap: 100.00)
    )
    .padding(20)
    .background(Color("NormaBackground"))
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}

#Preview("Expense List") {
    ChallengeExpenseList(
        selectedDay: ChallengeDay(date: Date(), isToday: true, isPast: false, spending: 125.50, dailyCap: 100.00),
        expenses: [
            Expense(
                id: "1",
                userId: "user",
                name: "Coffee",
                amount: 5.50,
                expenseDate: ISO8601DateFormatter().string(from: Date()),
                paymentMethod: .debitCard
            ),
            Expense(
                id: "2",
                userId: "user",
                name: "Lunch",
                amount: 15.00,
                expenseDate: ISO8601DateFormatter().string(from: Date()),
                paymentMethod: .debitCard
            ),
            Expense(
                id: "3",
                userId: "user",
                name: "Groceries",
                amount: 85.00,
                expenseDate: ISO8601DateFormatter().string(from: Date()),
                paymentMethod: .debitCard
            )
        ]
    )
    .padding(20)
    .background(Color("NormaBackground"))
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}

#Preview("Expense List - Empty") {
    ChallengeExpenseList(
        selectedDay: ChallengeDay(date: Date(), isToday: true, isPast: false, spending: 0, dailyCap: 100.00),
        expenses: []
    )
    .padding(20)
    .background(Color("NormaBackground"))
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}
