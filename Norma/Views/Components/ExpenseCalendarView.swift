//
//  ExpenseCalendarView.swift
//  Collector
//
//  Created by Claude on 5/13/25.
//

import SwiftUI
import Foundation

struct ExpenseCalendarView: View {
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    
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
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                
                // Summary stats
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Month Total")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.2f", totalExpensesThisMonth))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Active Days")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(daysWithExpenses)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
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
            
            // Calendar container
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
                
                VStack(spacing: 20) {
                    // Day labels
                    HStack(spacing: 0) {
                        ForEach(days, id: \.self) { day in
                            Text(day)
                                .font(.system(size: 12, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Calendar grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(extractDates(), id: \.self) { date in
                            if let date = date {
                                DayCell(
                                    date: date,
                                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                    isToday: Calendar.current.isDateInToday(date),
                                    isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month),
                                    expenseCount: expensesPerDay[date.startOfDay]?.count ?? 0,
                                    expenseTotal: expensesPerDay[date.startOfDay]?.reduce(0, +) ?? 0
                                )
                                .onTapGesture {
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
        
        // Calculate the number of trailing empty cells (to complete the 7x5 grid = 35 cells)
        let trailingEmptyCells = 35 - daysInMonth - leadingEmptyCells
        
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
    
    // Format expense amount based on digit count
    private var formattedExpenseAmount: String {
        if expenseTotal < 100 {
            // Two digits or less: show full amount with decimals
            return "$\(String(format: "%.2f", expenseTotal))"
        } else if expenseTotal < 1000 {
            // Three digits: remove decimals, add + if there were decimals
            let hasDecimals = expenseTotal.truncatingRemainder(dividingBy: 1) > 0
            return "$\(Int(expenseTotal))" + (hasDecimals ? "+" : "")
        } else if expenseTotal < 10000 {
            // Four digits: show as K with one decimal
            return "$\(String(format: "%.1f", expenseTotal / 1000))K"
        } else if expenseTotal < 100000 {
            // Five digits: show as K with no decimals
            return "$\(Int(expenseTotal / 1000))K"
        } else if expenseTotal < 1000000 {
            // Six digits: show as K with no decimals
            return "$\(Int(expenseTotal / 1000))K"
        } else {
            // Million or more: show as M with appropriate decimals
            if expenseTotal < 10000000 {
                return "$\(String(format: "%.1f", expenseTotal / 1000000))M"
            } else {
                return "$\(Int(expenseTotal / 1000000))M"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: isToday ? .semibold : .regular))
                .foregroundColor(cellTextColor)
            
            // Expense indicator
            if expenseCount > 0 {
                Text(formattedExpenseAmount)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.purple.opacity(0.8))
            } else {
                Text(" ")
                    .font(.system(size: 9))
            }
        }
        .frame(height: 45)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.purple.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1.5)
                } else if isToday {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.05))
                    
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                } else if expenseCount > 0 {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.purple.opacity(0.05))
                }
            }
        )
        .opacity(isCurrentMonth ? 1 : 0.3)
    }
    
    private var cellTextColor: Color {
        if isSelected {
            return .purple
        } else if isToday {
            return .blue
        } else if !isCurrentMonth {
            return .secondary.opacity(0.5)
        } else {
            return .primary
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
        ExpenseCalendarView(expensesPerDay: expensesPerDay)
    }
    .padding()
}