//
//  ExpenseCalendarView.swift
//  Collector
//
//  Created by Claude on 5/13/25.
//

import SwiftUI
import Foundation

struct ExpenseCalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth: Date = Date()
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var billViewModel: BillViewModel
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var incomeViewModel: IncomeViewModel
    @Environment(\.colorScheme) var colorScheme

    // Wave animation state
    @State private var waveAnimationStart: Date? = nil
    @State private var waveOriginCol: Int = 0
    @State private var waveOriginRow: Int = 0

    // Wave parameters
    private let waveWidth: CGFloat = 2.5
    private let waveSpeed: CGFloat = 12.0
    private let waveDuration: TimeInterval = 1.2

    // Haptic feedback
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    // Numeric animation state
    @State private var hasAppeared = false
    @State private var summaryItem1Appeared = false
    @State private var summaryItem2Appeared = false
    @State private var summaryItem3Appeared = false

    private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    // Dictionary to track expenses per day (for the dots)
    var expensesPerDay: [Date: [Double]] = [:]
    
    private var totalExpensesThisMonth: Double {
        let calendar = Calendar.current
        let expenses = expensesPerDay.filter { date, _ in
            calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        }
        return expenses.values.flatMap { $0 }.reduce(0, +)
    }

    private var displayedTotal: Double {
        hasAppeared ? totalExpensesThisMonth : 0
    }

    // Current month non-bill expenses
    private var currentMonthNonBillExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        let currentMonthNum = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        return expenseViewModel.expenses.filter { expense in
            // Exclude bill payments
            guard expense.billId == nil else { return false }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            if let date = formatter.date(from: expense.expenseDate) {
                let expenseMonth = calendar.component(.month, from: date)
                let expenseYear = calendar.component(.year, from: date)
                return expenseMonth == currentMonthNum && expenseYear == currentYear
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: expense.expenseDate) {
                    let expenseMonth = calendar.component(.month, from: date)
                    let expenseYear = calendar.component(.year, from: date)
                    return expenseMonth == currentMonthNum && expenseYear == currentYear
                }
            }
            return false
        }
    }

    // Total non-bill expenses for current month
    private var totalNonBillExpensesThisMonth: Double {
        currentMonthNonBillExpenses.reduce(0) { $0 + $1.amount }
    }

    // Available budget after bills (using user's set monthly income from settings)
    private var availableAfterBills: Double {
        let monthlyIncome = sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
        return monthlyIncome - billViewModel.totalBillsThisMonth
    }

    // Remaining discretionary budget
    private var remainingDiscretionary: Double {
        availableAfterBills - totalNonBillExpensesThisMonth
    }

    // Displayed values for numeric animation (staggered)
    private var displayedAvailableAfterBills: Double {
        summaryItem1Appeared ? availableAfterBills : 0
    }

    private var displayedSpent: Double {
        summaryItem2Appeared ? totalNonBillExpensesThisMonth : 0
    }

    private var displayedRemaining: Double {
        summaryItem3Appeared ? remainingDiscretionary : 0
    }

    private var daysWithExpenses: Int {
        let calendar = Calendar.current
        return expensesPerDay.filter { date, _ in
            calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        }.count
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header section matching ExpenseTrackerChartView style
            VStack(spacing: 12) {
                Text(monthYearFormatter.string(from: currentMonth).uppercased())
                    .font(.normaFinancial(18))
                    .foregroundColor(.secondary)
                    .tracking(1.2)

                // Summary stats - redesigned with larger numbers and glow
                VStack(spacing: 8) {
                    Text(profileViewModel.formatCurrency(displayedTotal))
                        .font(.normaHeadline(72))
                        .foregroundColor(.primary)
                        .shadow(color: Color("NormaPastelCoral").opacity(0.25), radius: 20, y: 4)
                        .contentTransition(.numericText())
                    Text("Total spent this month")
                        .font(.normaInput(13))
                        .foregroundColor(.secondary)
                }
                .onAppear {
                    // Big number animates first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            hasAppeared = true
                        }
                    }
                    // Staggered budget summary items
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            summaryItem1Appeared = true
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            summaryItem2Appeared = true
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            summaryItem3Appeared = true
                        }
                    }
                }

                // Budget Summary
                VStack(spacing: 16) {
                    // Available after bills
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "banknote")
                                .font(.system(size: 16))
                                .foregroundColor(Color("NormaPastelTeal"))
                            Text("Available after bills")
                                .font(.normaInput(15))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(profileViewModel.formatCurrency(displayedAvailableAfterBills))
                            .font(.normaFinancial(16))
                            .foregroundColor(availableAfterBills >= 0 ? Color("NormaPastelTeal") : Color("NormaPastelCoral"))
                            .contentTransition(.numericText())
                    }

                    // Amount spent (non-bill)
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "cart")
                                .font(.system(size: 16))
                                .foregroundColor(Color("NormaPastelCoral"))
                            Text("Spent (excl. bills)")
                                .font(.normaInput(15))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(profileViewModel.formatCurrency(displayedSpent))
                            .font(.normaFinancial(16))
                            .foregroundColor(.primary)
                            .contentTransition(.numericText())
                    }

                    // Remaining
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "wallet.pass")
                                .font(.system(size: 16))
                                .foregroundColor(remainingDiscretionary >= 0 ? Color("NormaPastelBeige") : Color("NormaPastelCoral"))
                            Text("Remaining")
                                .font(.normaInput(15))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(profileViewModel.formatCurrency(displayedRemaining))
                            .font(.normaFinancial(16))
                            .fontWeight(.semibold)
                            .foregroundColor(remainingDiscretionary >= 0 ? .primary : Color("NormaPastelCoral"))
                            .contentTransition(.numericText())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                )
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }

            // Calendar container
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                    )

                TimelineView(.animation(minimumInterval: 1.0/60.0, paused: waveAnimationStart == nil)) { timeline in
                    let waveRadius = currentWaveRadius(at: timeline.date)

                    VStack(spacing: 20) {
                        // Day labels
                        HStack(spacing: 0) {
                            ForEach(days, id: \.self) { day in
                                Text(day)
                                    .font(.normaInput(12))
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)

                        // Calendar grid
                        let dates = extractDates()
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                                let row = index / 7
                                let col = index % 7
                                let distance = calculateDistance(
                                    fromCol: waveOriginCol,
                                    fromRow: waveOriginRow,
                                    toCol: col,
                                    toRow: row
                                )

                                if let date = date {
                                    DayCell(
                                        date: date,
                                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                        isToday: Calendar.current.isDateInToday(date),
                                        isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month),
                                        expenseCount: expensesPerDay[date.startOfDay]?.count ?? 0,
                                        expenseTotal: expensesPerDay[date.startOfDay]?.reduce(0, +) ?? 0,
                                        waveRadius: waveRadius,
                                        waveWidth: waveWidth,
                                        distanceFromOrigin: distance
                                    )
                                    .onTapGesture {
                                        // Haptic feedback
                                        impactGenerator.impactOccurred()

                                        // Trigger wave animation
                                        triggerWaveAnimation(fromCol: col, fromRow: row)

                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedDate = date
                                        }
                                    }
                                } else {
                                    // Empty cell for placeholders
                                    Rectangle()
                                        .foregroundColor(.clear)
                                        .frame(height: 45)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
    }
    
    // Extract all the dates for the current month's calendar view (including leading/trailing days)
    private func extractDates() -> [Date?] {
        let calendar = Calendar.current
        
        // Get the first day of the month
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        
        // Get the weekday of the first day (0 = Sunday, 1 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        
        // Calculate the number of leading empty cells (days from previous month)
        let leadingEmptyCells = firstWeekday - 1
        
        // Get the number of days in the month
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        
        // Calculate total cells needed (always a multiple of 7 for complete rows)
        let totalCellsNeeded = leadingEmptyCells + daysInMonth
        let rows = (totalCellsNeeded + 6) / 7  // Round up to complete weeks
        let totalCells = rows * 7
        
        // Calculate the number of trailing empty cells
        let trailingEmptyCells = totalCells - daysInMonth - leadingEmptyCells
        
        var dates: [Date?] = []
        
        // Add leading empty cells
        for _ in 0..<leadingEmptyCells {
            dates.append(nil)
        }
        
        // Add current month days
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                dates.append(date)
            }
        }
        
        // Add trailing empty cells
        for _ in 0..<trailingEmptyCells {
            dates.append(nil)
        }
        
        return dates
    }

    // MARK: - Wave Animation Helpers

    private func calculateDistance(fromCol: Int, fromRow: Int, toCol: Int, toRow: Int) -> Double {
        let dx = Double(toCol - fromCol)
        let dy = Double(toRow - fromRow)
        return hypot(dx, dy)
    }

    private func currentWaveRadius(at date: Date) -> CGFloat {
        guard let start = waveAnimationStart else { return -100 }
        let elapsed = date.timeIntervalSince(start)
        return CGFloat(elapsed) * waveSpeed
    }

    private func triggerWaveAnimation(fromCol: Int, fromRow: Int) {
        guard waveAnimationStart == nil else { return }

        waveOriginCol = fromCol
        waveOriginRow = fromRow
        waveAnimationStart = Date()

        DispatchQueue.main.asyncAfter(deadline: .now() + waveDuration) {
            self.waveAnimationStart = nil
        }
    }

    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}

// Day cell component
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let expenseCount: Int
    let expenseTotal: Double
    let waveRadius: CGFloat
    let waveWidth: CGFloat
    let distanceFromOrigin: Double
    @EnvironmentObject var profileViewModel: ProfileViewModel

    // Wave intensity based on how close the wave front is to this cell
    private var waveIntensity: CGFloat {
        let distanceFromWaveFront = abs(CGFloat(distanceFromOrigin) - waveRadius)

        if distanceFromWaveFront > waveWidth {
            return 0
        }

        let normalizedDistance = distanceFromWaveFront / waveWidth
        return (1 + cos(normalizedDistance * .pi)) / 2
    }

    // Scale based on wave intensity
    private var scale: CGFloat {
        1.0 + (0.3 * waveIntensity)
    }

    // Brightness boost as wave passes
    private var brightness: Double {
        0.25 * Double(waveIntensity)
    }

    // Shadow radius for depth effect
    private var shadowRadius: CGFloat {
        3 * waveIntensity
    }

    // Format expense amount based on digit count
    private var formattedExpenseAmount: String {
        return profileViewModel.formatCurrencyTruncated(expenseTotal)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(cellTextColor)

            // Expense indicator
            if expenseCount > 0 {
                Text(formattedExpenseAmount)
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundColor(expenseAmountColor)
            } else {
                Text(" ")
                    .font(.system(size: 9, weight: .regular, design: .rounded))
            }
        }
        .frame(height: 45)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.85, green: 0.82, blue: 0.92).opacity(0.5),
                                    Color(red: 0.88, green: 0.85, blue: 0.94).opacity(0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.75, green: 0.70, blue: 0.85).opacity(0.4), lineWidth: 1.5)
                } else if isToday {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("NormaPastelCoral").opacity(0.08))

                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("NormaPastelCoral").opacity(0.25), lineWidth: 1)
                } else if expenseCount > 0 {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("NormaPastelCoral").opacity(0.05))
                }
            }
        )
        .scaleEffect(scale)
        .brightness(brightness)
        .shadow(color: Color("NormaPastelCoral").opacity(0.4 * Double(waveIntensity)), radius: shadowRadius, y: 2)
        .opacity(isCurrentMonth ? 1 : 0.3)
    }

    private var cellTextColor: Color {
        if isSelected {
            return .primary
        } else if isToday {
            return Color("NormaPastelCoral")
        } else if !isCurrentMonth {
            return .secondary.opacity(0.5)
        } else {
            return .primary
        }
    }

    private var expenseAmountColor: Color {
        if isSelected {
            return .primary.opacity(0.8)
        } else {
            return Color("NormaPastelCoral").opacity(0.9)
        }
    }
}

// Extension to get start of day for date comparison
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

#Preview {
    let currentDate = Date()
    let calendar = Calendar.current
    
    // Create sample expense data for preview with various amount ranges
    var expensesPerDay: [Date: [Double]] = [:]
    
    // Add expenses for today - two digits
    expensesPerDay[currentDate.startOfDay] = [25.50, 10.75]
    
    // Add expenses for tomorrow - three digits
    if let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate) {
        expensesPerDay[tomorrow.startOfDay] = [245.99, 100.00]
    }
    
    // Add expenses for a week ago - four digits
    if let lastWeek = calendar.date(byAdding: .day, value: -7, to: currentDate) {
        expensesPerDay[lastWeek.startOfDay] = [2500.00, 750.50]
    }
    
    // Add expense for two weeks ago - five digits
    if let twoWeeks = calendar.date(byAdding: .day, value: -14, to: currentDate) {
        expensesPerDay[twoWeeks.startOfDay] = [15000.00, 5000.00]
    }
    
    return VStack {
        ExpenseCalendarView(selectedDate: .constant(Date()), expensesPerDay: expensesPerDay)
    }
    .padding()
}
