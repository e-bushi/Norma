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
    
    var body: some View {
        VStack(spacing: 20) {
            // Month selector
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(monthYearFormatter.string(from: currentMonth))
                    .font(.title2.bold())
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            
            // Day labels
            HStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(extractDates(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(date),
                            isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month),
                            expenseCount: expensesPerDay[date.startOfDay]?.count ?? 0
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                selectedDate = date
                            }
                        }
                    } else {
                        // Empty cell for placeholders
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(height: 40)
                    }
                }
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
    
    private func previousMonth() {
        withAnimation {
            currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!
        }
    }
    
    private func nextMonth() {
        withAnimation {
            currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)!
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
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16))
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(cellTextColor)
            
            // Expense indicator dots (if any)
            if expenseCount > 0 {
                HStack(spacing: 4) {
                    ForEach(0..<min(expenseCount, 3), id: \.self) { _ in
                        Circle()
                            .fill(cellColor)
                            .frame(width: 4, height: 4)
                    }
                    
                    if expenseCount > 3 {
                        Text("+\(expenseCount - 3)")
                            .font(.system(size: 8))
                            .foregroundColor(cellColor)
                    }
                }
                .padding(.top, 2)
            }
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? cellColor.opacity(0.2) : Color.clear)

                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(cellColor.opacity(0.3), lineWidth: 1)
                }
            }
        )
        .opacity(isCurrentMonth ? 1 : 0.3)
    }
    
    private var cellColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .green
        } else if expenseCount > 0 {
            return .blue
        } else {
            return .primary
        }
    }
    
    private var cellTextColor: Color {
        if isSelected {
            return cellColor
        } else if isToday {
            return .green
        } else if !isCurrentMonth {
            return .secondary
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
    
    // Create sample expense data for preview
    var expensesPerDay: [Date: [Double]] = [:]
    
    // Add expenses for today
    expensesPerDay[currentDate.startOfDay] = [25.0, 10.0]
    
    // Add expenses for tomorrow
    if let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate) {
        expensesPerDay[tomorrow.startOfDay] = [15.0]
    }
    
    // Add expenses for a week ago
    if let lastWeek = calendar.date(byAdding: .day, value: -7, to: currentDate) {
        expensesPerDay[lastWeek.startOfDay] = [55.0, 22.0, 13.0, 9.0]
    }
    
    return VStack {
        ExpenseCalendarView(expensesPerDay: expensesPerDay)
    }
    .padding()
}