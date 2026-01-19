//
//  BillDueDateCalendarView.swift
//  Norma
//
//  Created by Claude on 10/9/25.
//

import SwiftUI
import Foundation

struct BillDueDateCalendarView: View {
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var billItemStates: [Bool] = []
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var billViewModel: BillViewModel
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @Environment(\.colorScheme) var colorScheme

    private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    // Haptic feedback
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    // Dictionary to track bills per day
    var billsPerDay: [Date: [Double]] = [:]

    private var daysWithBills: Int {
        let calendar = Calendar.current
        return billsPerDay.filter { date, _ in
            calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        }.count
    }
    
    private var billAmountTotal: Double {
        billViewModel.activeBills.reduce(0) { $0 + $1.amount }
    }

    // Numeric animation state
    @State private var hasAppeared = false

    private var displayedTotal: Double {
        hasAppeared ? billAmountTotal : 0
    }

    private var billsForSelectedDate: [Bill] {
        let calendar = Calendar.current
        return billViewModel.activeBills.filter { bill in
            calendar.isDate(bill.dueDate, inSameDayAs: selectedDate)
        }
    }

    private func animateBillsStaggered() {
        billItemStates = Array(repeating: false, count: billsForSelectedDate.count)
        for i in 0..<billsForSelectedDate.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    if i < billItemStates.count {
                        billItemStates[i] = true
                    }
                }
            }
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header section matching ExpenseCalendarView style
            VStack(spacing: 12) {
                Text(monthYearFormatter.string(from: currentMonth).uppercased())
                    .font(.normaFinancial(18))
                    .foregroundColor(.secondary)
                    .tracking(1.2)

                // Summary stats - redesigned with larger number and glow
                VStack(spacing: 8) {
                    Text(profileViewModel.formatCurrency(displayedTotal))
                        .font(.normaHeadline(72))
                        .foregroundColor(.primary)
                        .shadow(color: Color("NormaPastelCoral").opacity(0.25), radius: 20, y: 4)
                        .contentTransition(.numericText())
                    Text("Total of all bills combined")
                        .font(.normaInput(13))
                        .foregroundColor(.secondary)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            hasAppeared = true
                        }
                    }
                }
            }

            // Calendar container
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                    )

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
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(extractDates(), id: \.self) { date in
                            if let date = date {
                                BillDayCell(
                                    date: date,
                                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                    isToday: Calendar.current.isDateInToday(date),
                                    isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month),
                                    billCount: billsPerDay[date.startOfDay]?.count ?? 0,
                                    billTotal: billsPerDay[date.startOfDay]?.reduce(0, +) ?? 0
                                )
                                .onTapGesture {
                                    impactGenerator.impactOccurred()

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

            // Selected day bills section
            if !billsForSelectedDate.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Bills Due")
                        .font(.normaInput(14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 8) {
                        ForEach(Array(billsForSelectedDate.enumerated()), id: \.element.id) { index, bill in
                            BillRowView(bill: bill)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.clear)
                                        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                                )
                                .opacity(index < billItemStates.count && billItemStates[index] ? 1 : 0)
                                .offset(x: index < billItemStates.count && billItemStates[index] ? 0 : -20)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .onAppear {
                    animateBillsStaggered()
                }
            } else {
                VStack(spacing: 8) {
                    Text("No bills due")
                        .font(.normaInput(14))
                        .foregroundColor(.secondary)
                    Text(selectedDateFormatted)
                        .font(.normaInput(12))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .transition(.opacity)
            }
        }
        .onChange(of: selectedDate) { _, _ in
            animateBillsStaggered()
        }
    }

    private var selectedDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: selectedDate)
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


    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}

// Bill day cell component
struct BillDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let billCount: Int
    let billTotal: Double
    @EnvironmentObject var profileViewModel: ProfileViewModel

    // Format bill amount based on digit count
    private var formattedBillAmount: String {
        return profileViewModel.formatCurrencyTruncated(billTotal)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(cellTextColor)

            // Bill indicator
            if billCount > 0 {
                Text(formattedBillAmount)
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundColor(billAmountColor)
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
                        .fill(Color("NormaPastelTeal"))

                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("NormaPastelTeal").opacity(0.6), lineWidth: 1.5)
                } else if isToday {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("NormaPastelTeal").opacity(0.08))

                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("NormaPastelTeal").opacity(0.25), lineWidth: 1)
                } else if billCount > 0 {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("NormaPastelTeal").opacity(0.05))

                    // Pastel pink outline for days with bills due
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("NormaPastelPink").opacity(0.6), lineWidth: 1.5)
                }
            }
        )
        .opacity(isCurrentMonth ? 1 : 0.3)
    }

    private var cellTextColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Color("NormaPastelTeal")
        } else if !isCurrentMonth {
            return .secondary.opacity(0.5)
        } else {
            return .primary
        }
    }

    private var billAmountColor: Color {
        if isSelected {
            return .white.opacity(0.9)
        } else {
            return Color("NormaPastelTeal").opacity(0.9)
        }
    }
}

#Preview {
    let currentDate = Date()
    let calendar = Calendar.current

    // Create sample bill data for preview
    var billsPerDay: [Date: [Double]] = [:]

    // Add bills for today
    billsPerDay[currentDate.startOfDay] = [125.50, 60.75]

    // Add bills for tomorrow
    if let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate) {
        billsPerDay[tomorrow.startOfDay] = [1200.00]
    }

    // Add bills for a week ago
    if let lastWeek = calendar.date(byAdding: .day, value: -7, to: currentDate) {
        billsPerDay[lastWeek.startOfDay] = [85.50, 59.99]
    }

    // Add bill for two weeks ago
    if let twoWeeks = calendar.date(byAdding: .day, value: -14, to: currentDate) {
        billsPerDay[twoWeeks.startOfDay] = [220.30]
    }

    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let billViewModel = BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let expenseViewModel = ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)

    return VStack {
        BillDueDateCalendarView(billsPerDay: billsPerDay)
            .environmentObject(profileViewModel)
            .environmentObject(sessionViewModel)
            .environmentObject(billViewModel)
            .environmentObject(expenseViewModel)
    }
    .padding()
}
