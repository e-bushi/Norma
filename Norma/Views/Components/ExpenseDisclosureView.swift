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
    let selectedDate: Date?
    let monthHasExpenses: Bool
    @Binding var showNormaChat: Bool
    var animationDelay: Double = 0
    @State private var showingAllExpenses = false
    @State private var selectedExpense: Expense? = nil
    @State private var itemStates: [Bool] = []
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @Environment(\.colorScheme) var colorScheme

    // Multi-select state
    @State private var isEditMode = false
    @State private var selectedExpenseIds: Set<String> = []
    @State private var isDeleting = false

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

    // Selection computed properties
    private var selectedExpenses: [Expense] {
        filteredExpenses.filter { expense in
            guard let id = expense.id else { return false }
            return selectedExpenseIds.contains(id)
        }
    }

    private var selectedAmount: Double {
        selectedExpenses.reduce(0) { $0 + $1.amount }
    }

    private var allDisplayedSelected: Bool {
        !displayedExpenses.isEmpty &&
        displayedExpenses.allSatisfy { expense in
            guard let id = expense.id else { return false }
            return selectedExpenseIds.contains(id)
        }
    }

    private var selectedDateText: String {
        guard let date = selectedDate else { return "this day" }
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "yesterday"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    private func animateItemsStaggered() {
        itemStates = Array(repeating: false, count: displayedExpenses.count)
        for i in 0..<displayedExpenses.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay + Double(i) * 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                    if i < itemStates.count {
                        itemStates[i] = true
                    }
                }
            }
        }
    }

    // MARK: - Selection Methods

    private func isExpenseSelected(_ expense: Expense) -> Bool {
        guard let id = expense.id else { return false }
        return selectedExpenseIds.contains(id)
    }

    private func toggleSelection(_ expense: Expense) {
        guard let id = expense.id else { return }

        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        if selectedExpenseIds.contains(id) {
            selectedExpenseIds.remove(id)
        } else {
            selectedExpenseIds.insert(id)
        }
    }

    private func toggleSelectAll() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        if allDisplayedSelected {
            selectedExpenseIds.removeAll()
        } else {
            selectedExpenseIds = Set(displayedExpenses.compactMap { $0.id })
        }
    }

    private func deleteSelectedExpenses() {
        guard !selectedExpenses.isEmpty else { return }

        isDeleting = true

        Task {
            for expense in selectedExpenses {
                await expenseViewModel.deleteExpense(expense)
            }

            await MainActor.run {
                isDeleting = false
                selectedExpenseIds.removeAll()
                isEditMode = false

                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }

    private func exitEditMode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isEditMode = false
            selectedExpenseIds.removeAll()
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Expenses list container
            if displayedExpenses.isEmpty {
                if monthHasExpenses {
                    // Simple empty state for selected day (month has other expenses)
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.clear)
                                .glassEffect(in: Circle())
                                .frame(width: 60, height: 60)

                            Image(systemName: "calendar.badge.minus")
                                .font(.system(size: 28))
                                .foregroundColor(Color("NormaPastelCoral").opacity(0.8))
                        }

                        VStack(spacing: 6) {
                            Text("No expenses \(selectedDateText)")
                                .font(.normaFinancial(18))
                                .foregroundColor(.primary)

                            Text("Select another day or add an expense")
                                .font(.normaInput(13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                            )
                    )
                } else {
                    // Full empty state for no expenses this month
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
                }
            } else {
                VStack(spacing: 0) {
                    // Header with Edit button
                    HStack {
                        Spacer()

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if isEditMode {
                                    exitEditMode()
                                } else {
                                    isEditMode = true
                                }
                            }
                        } label: {
                            Text(isEditMode ? "Done" : "Edit")
                                .font(.custom(FontFamily.Rubik.medium, size: 14))
                                .foregroundColor(Color("NormaPastelCoral"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color("NormaPastelCoral").opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 12)

                    // Expense items
                    VStack(spacing: 16) {
                        ForEach(Array(displayedExpenses.enumerated()), id: \.element.id) { index, expense in
                            if isEditMode {
                                SelectableExpenseRow(
                                    expense: expense,
                                    isSelected: isExpenseSelected(expense),
                                    onToggle: { toggleSelection(expense) }
                                )
                                .opacity(index < itemStates.count && itemStates[index] ? 1 : 0)
                                .offset(x: index < itemStates.count && itemStates[index] ? 0 : -20)
                            } else {
                                Button(action: {
                                    selectedExpense = expense
                                }) {
                                    ExpenseRowView(expense: expense)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .opacity(index < itemStates.count && itemStates[index] ? 1 : 0)
                                .offset(x: index < itemStates.count && itemStates[index] ? 0 : -20)
                            }
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

                    // Floating action bar when in edit mode
                    if isEditMode {
                        expenseEditActionBar
                            .padding(.top, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // See all button (hidden in edit mode)
                    if !isEditMode && filteredExpenses.count > maxExpensesToShow {
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
                            MyExpensesView(presetDate: selectedDate)
                        }
                    }
                }
                .onAppear {
                    animateItemsStaggered()
                }
                .onChange(of: expenses) { _, _ in
                    animateItemsStaggered()
                }
            }
        }
        .sheet(item: $selectedExpense) { expense in
            ExpenseDetailView(expense: expense)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Floating Action Bar

    private var expenseEditActionBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                // Select All / Deselect All
                Button {
                    toggleSelectAll()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: allDisplayedSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 13, weight: .medium))
                        Text(allDisplayedSelected ? "Deselect" : "Select All")
                            .font(.custom(FontFamily.Rubik.medium, size: 13))
                    }
                    .foregroundColor(Color("NormaPastelCoral"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color("NormaPastelCoral").opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color("NormaPastelCoral").opacity(0.25), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                // Selected count
                if !selectedExpenseIds.isEmpty {
                    Text("\(selectedExpenseIds.count) selected")
                        .font(.custom(FontFamily.Rubik.regular, size: 13))
                        .foregroundColor(.secondary)
                }
            }

            // Delete button - full width
            Button {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                deleteSelectedExpenses()
            } label: {
                HStack(spacing: 8) {
                    if isDeleting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .bold))
                    }

                    if selectedExpenseIds.isEmpty {
                        Text("Select expenses to delete")
                            .font(.custom(FontFamily.Rubik.medium, size: 15))
                    } else {
                        Text("Delete \(selectedExpenseIds.count)")
                            .font(.custom(FontFamily.Rubik.medium, size: 15))

                        Text("•")
                            .font(.system(size: 10))
                            .opacity(0.6)

                        Text(profileViewModel.formatCurrency(selectedAmount))
                            .font(.custom(FontFamily.Rubik.regular, size: 14))
                            .opacity(0.9)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(selectedExpenseIds.isEmpty ?
                              Color.gray.opacity(0.4) :
                              Color.red.opacity(0.85))
                )
            }
            .buttonStyle(.plain)
            .disabled(selectedExpenseIds.isEmpty || isDeleting)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.clear)
                .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.gray.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
    }
}

// MARK: - Selectable Expense Row

struct SelectableExpenseRow: View {
    let expense: Expense
    let isSelected: Bool
    let onToggle: () -> Void
    @EnvironmentObject var profileViewModel: ProfileViewModel

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
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color("NormaPastelCoral") : Color.gray.opacity(0.4))
            }
            .buttonStyle(.plain)

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
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)

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
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var dataManager: DataManager

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
    let expenseViewModel = ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    @State var showNormaChat = false

    return ScrollView {
        VStack {
            Text("With Expenses")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ExpenseDisclosureView(expenses: sampleExpenses, category: nil, selectedDate: Date(), monthHasExpenses: true, showNormaChat: $showNormaChat)
                .padding(.horizontal)

            Divider().padding()

            Text("No Expenses on Day (Month Has Expenses)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ExpenseDisclosureView(expenses: [], category: nil, selectedDate: Date(), monthHasExpenses: true, showNormaChat: $showNormaChat)
                .padding(.horizontal)

            Divider().padding()

            Text("No Expenses This Month")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ExpenseDisclosureView(expenses: [], category: nil, selectedDate: nil, monthHasExpenses: false, showNormaChat: $showNormaChat)
                .padding(.horizontal)
        }
    }
    .environmentObject(profileViewModel)
    .environmentObject(expenseViewModel)
}
