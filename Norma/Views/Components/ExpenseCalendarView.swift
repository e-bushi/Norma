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

    // Wave animation state
    @State private var waveAnimationStart: Date? = nil
    @State private var waveOriginCol: Int = 0
    @State private var waveOriginRow: Int = 0

    // Long press / MiniChat state
    @State private var showMiniChat = false
    @State private var longPressedDate: Date? = nil
    @State private var pressingDate: Date? = nil

    // Wave parameters
    private let waveWidth: CGFloat = 2.5
    private let waveSpeed: CGFloat = 12.0
    private let waveDuration: TimeInterval = 1.2

    // Haptic feedback
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    // Dictionary to track expenses per day (for the dots)
    var expensesPerDay: [Date: [Double]] = [:]
    
    var body: some View {
        VStack(spacing: 24) {
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
                                    .scaleEffect(pressingDate == date ? 0.88 : 1.0)
                                    .opacity(pressingDate == date ? 0.7 : 1.0)
                                    .animation(.easeInOut(duration: 0.25), value: pressingDate)
                                    .onTapGesture {
                                        impactGenerator.impactOccurred()
                                        triggerWaveAnimation(fromCol: col, fromRow: row)

                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedDate = date
                                        }
                                    }
                                    .onLongPressGesture(minimumDuration: 0.5) {
                                        let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
                                        mediumImpact.impactOccurred()
                                        pressingDate = nil
                                        longPressedDate = date
                                        showMiniChat = true
                                    } onPressingChanged: { pressing in
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            pressingDate = pressing ? date : nil
                                        }
                                    }
                                } else {
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

            // Hold-to-add hint
            HStack(spacing: 8) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 14, weight: .medium))
                Text("Hold a day to add an expense")
                    .font(.normaInput(14))
            }
            .foregroundColor(.secondary.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .sheet(isPresented: $showMiniChat) {
            if let date = longPressedDate {
                MiniChatView(selectedDate: date, context: .expense)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
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

    private var showNumber: Bool {
        isSelected || isToday || expenseCount > 0
    }

    var body: some View {
        VStack(spacing: 3) {
            if showNumber {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 14, weight: expenseCount > 0 ? .semibold : .medium, design: .rounded))
                    .foregroundColor(cellTextColor)
            } else {
                Circle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 4, height: 4)
            }

            // Expense amount
            if expenseCount > 0 {
                Text(formattedExpenseAmount)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(expenseAmountColor)
            } else {
                Text(" ")
                    .font(.system(size: 9))
            }
        }
        .frame(height: 48)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("NormaPastelCoral"))
                } else if isToday {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("NormaPastelCoral").opacity(0.08))
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("NormaPastelCoral").opacity(0.25), lineWidth: 1)
                } else if expenseCount > 0 {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.04))
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
            return .white
        } else if isToday {
            return Color("NormaPastelCoral")
        } else if expenseCount > 0 {
            return .primary
        } else {
            return .secondary
        }
    }

    private var expenseAmountColor: Color {
        if isSelected {
            return .white.opacity(0.9)
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
    
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)

    return VStack {
        ExpenseCalendarView(selectedDate: .constant(Date()), expensesPerDay: expensesPerDay)
    }
    .padding()
    .environmentObject(ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
}
