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
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    // Track selected date for calendar integration
    @State private var selectedDate: Date = Date()
    @State private var waveAnimating = false
    @State private var showAllExpenses = false
    @State private var showInfoPopover = false

    // MARK: - Computed Properties

    private var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    private var currentYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private var formattedExpenseTotal: String {
        expenseViewModel.currentMonthExpenses.formatted(.currency(code: currency).precision(.fractionLength(0)))
    }

    private var waveWords: [(word: String, color: Color)] {
        var words: [(String, Color)] = []
        words.append(("You", .primary))
        words.append(("spent", .primary))
        for part in formattedExpenseTotal.split(separator: " ").map(String.init) {
            words.append((part, Color("NormaPastelCoral")))
        }
        words.append(("so", .primary))
        words.append(("far", .primary))
        words.append(("this", .primary))
        words.append(("month.", .primary))
        return words
    }

    // Remaining for the month (income - bills - total expenses)
    private var remainingThisMonth: Double {
        let monthlyIncome = sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
        return monthlyIncome - billViewModel.totalBillsThisMonth - expenseViewModel.currentMonthExpenses
    }

    // Computed property to filter expenses for current month
    private var currentMonthExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        let currentMonthNum = calendar.component(.month, from: now)
        let currentYearNum = calendar.component(.year, from: now)

        return expenseViewModel.expenses.filter { expense in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            if let date = formatter.date(from: expense.expenseDate) {
                let expenseMonth = calendar.component(.month, from: date)
                let expenseYear = calendar.component(.year, from: date)
                return expenseMonth == currentMonthNum && expenseYear == currentYearNum
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: expense.expenseDate) {
                    let expenseMonth = calendar.component(.month, from: date)
                    let expenseYear = calendar.component(.year, from: date)
                    return expenseMonth == currentMonthNum && expenseYear == currentYearNum
                }
            }
            return false
        }
    }

    // Computed property to create expense map for calendar
    private var expensesPerDay: [Date: [Double]] {
        var expenseMap: [Date: [Double]] = [:]
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current

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

    // Filtered expenses for the selected date only
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
                VStack(alignment: .leading, spacing: 24) {
                    // Header — matches BillHomeView pattern
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(currentMonth) \(currentYear)".uppercased())
                            .font(.normaFinancial(20))
                            .foregroundColor(.secondary)
                            .padding(.top, 20)

                        ColoredWaveTextView(
                            words: waveWords,
                            font: .normaHeadline(64),
                            isAnimating: waveAnimating,
                            alignment: .leading
                        )
                        .padding(.top, 16)

                        // Budget capsules row
                        HStack(spacing: 8) {
                            Text(profileViewModel.formatCurrency(remainingThisMonth) + " left")
                                .font(.normaFinancial(14))
                                .foregroundColor(remainingThisMonth >= 0 ? Color("NormaPastelTeal") : Color("NormaPastelCoral"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .glassEffect(.regular.interactive(), in: .capsule)

                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                showAllExpenses = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text("All Expenses")
                                        .font(.normaFinancial(14))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundColor(Color("NormaPastelCoral"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .glassEffect(.regular.interactive(), in: .capsule)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 12)
                    }
                    .padding(.horizontal, 24)
                    .onAppear {
                        waveAnimating = true
                    }

                    // Calendar (grid only, no header)
                    ExpenseCalendarView(selectedDate: $selectedDate, expensesPerDay: expensesPerDay)
                        .padding(.horizontal)

                    // Day summary header
                    ExpenseDaySummary(
                        selectedDate: selectedDate,
                        totalSpent: filteredExpenses.reduce(0) { $0 + $1.amount },
                        transactionCount: filteredExpenses.count
                    )
                    .padding(.horizontal)

                    // Expense timeline for selected day
                    ExpenseTimelineView(
                        expenses: filteredExpenses,
                        selectedDate: selectedDate,
                        monthHasExpenses: monthHasExpenses,
                        showNormaChat: .constant(false)
                    )
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .background(Color("NormaBackground"))
            .scrollIndicators(.hidden)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showInfoPopover = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .popover(isPresented: $showInfoPopover, arrowEdge: .top) {
                        ExpenseInfoPopover()
                            .presentationCompactAdaptation(.popover)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("")
                }
            }
            .sheet(isPresented: $showAllExpenses) {
                MyExpensesView()
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

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: selectedDate)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var displayedSpent: Double {
        hasAppeared ? totalSpent : 0
    }

    private var formattedAmount: String {
        profileViewModel.formatCurrency(displayedSpent)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: today badge
            HStack {
                Spacer()
                if isToday {
                    Text("Today")
                        .font(.normaInput(12))
                        .foregroundColor(Color("NormaPastelCoral"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color("NormaPastelCoral").opacity(0.12))
                        )
                }
            }

            // Amount
            Text(formattedAmount)
                .font(.normaHeadline(46))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .contentTransition(.numericText())

            // Bottom row: date + expense count
            HStack(spacing: 12) {
                Label(dateFormatted, systemImage: "calendar")
                    .font(.normaInput(12))
                    .foregroundColor(.secondary.opacity(0.6))

                Text("·")
                    .foregroundColor(.secondary.opacity(0.3))

                Text(transactionCount == 1 ? "1 expense" : "\(transactionCount) expenses")
                    .font(.normaInput(12))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.03))

                // Radar rings from bottom-right
                Canvas { context, size in
                    let origin = CGPoint(x: size.width, y: size.height)
                    let ringCount = 6
                    let maxRadius: CGFloat = 180
                    let ringSpacing = maxRadius / CGFloat(ringCount)

                    for i in 1...ringCount {
                        let radius = CGFloat(i) * ringSpacing
                        let opacity = 0.14 * (1.0 - CGFloat(i) / CGFloat(ringCount))
                        let rect = CGRect(
                            x: origin.x - radius,
                            y: origin.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )
                        context.stroke(
                            Path(ellipseIn: rect),
                            with: .color(Color("NormaPastelCoral").opacity(opacity)),
                            lineWidth: 1
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .allowsHitTesting(false)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
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

// MARK: - Expense Info Popover

struct ExpenseInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color("NormaPastelCoral"))

                Text("Expenses")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Track your daily spending and see how it compares to your income and bills.")
                    .font(.normaInput(14))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Tap any day on the calendar to see what you spent. Expenses are grouped by the hour they were logged.")
                    .font(.normaInput(14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color("NormaPastelTeal"))

                Text("Adding Expenses")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundColor(.primary)
            }

            Text("Tell Norma about your purchases in the chat — just say something like \"I spent $40 on groceries\" and she'll log it for you.")
                .font(.normaInput(14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 300)
        .background(Color("NormaBackground"))
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
