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
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var billViewModel: BillViewModel
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var incomeViewModel: IncomeViewModel
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    // Voice mode states
    @State private var showVoiceMode = false
    @State private var voiceAgentViewModel: VoiceAgentViewModel?
    @State private var lastTapTime: Date = Date()
    @State private var isPressed = false
    @State private var showPaywall = false
    
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
                    .font(.normaFinancial(18))
                    .foregroundColor(.secondary)
                    .tracking(1.2)

                // Summary stats - redesigned with larger numbers
                VStack(spacing: 8) {
                    Text(profileViewModel.formatCurrency(totalExpensesThisMonth))
                        .font(.normaHeadline(48))
                        .foregroundColor(.primary)
                    Text("Total spent this month")
                        .font(.normaInput(13))
                        .foregroundColor(.secondary)
                }
            }
            
            // Voice mode instruction - Temporarily commented out
            /*
            CalendarVoiceModeInstruction(
                onActivate: {
                    // Check if user has active subscription or is in trial
                    if subscriptionManager.isInFreeTrial || subscriptionManager.hasActiveSubscription {
                        print("ExpenseCalendar: User has access (trial or subscription) - activating voice mode from button...")
                        
                        // Activate voice mode
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showVoiceMode = true
                        }
                        
                        // Strong haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                        impactFeedback.impactOccurred()
                        
                        // Start voice recording
                        Task {
                            await startVoiceInteraction()
                        }
                    } else {
                        print("ExpenseCalendar: No access to voice mode - show paywall")
                        showPaywall = true
                    }
                }
            )
            */
            
            // Calendar container
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: colorScheme == .dark ? [
                                Color(red: 0.160, green: 0.128, blue: 0.102),
                                Color(red: 0.180, green: 0.145, blue: 0.118)
                            ] : [
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
                    .animatedBorder(
                        cornerRadius: 20,
                        lineWidth: 2,
                        useRainbow: true,
                        isVoiceModeActive: showVoiceMode
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
            .expenseCalendarVoiceMode(
                showVoiceMode: $showVoiceMode,
                voiceAgentViewModel: $voiceAgentViewModel,
                lastTapTime: $lastTapTime,
                isPressed: $isPressed,
                cornerRadius: 20
            )
        }
        .overlay(
            VoiceModeOverlay(
                isVisible: $showVoiceMode,
                cornerRadius: 20,
                voiceAgentViewModel: voiceAgentViewModel ?? VoiceAgentViewModel(
                    userId: sessionViewModel.currentUser?.userId ?? "",
                    billViewModel: billViewModel,
                    expenseViewModel: expenseViewModel,
                    incomeViewModel: incomeViewModel,
                    sessionViewModel: sessionViewModel
                )
            )
        )
        .sheet(isPresented: $showPaywall) {
            PaywallView()
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
    
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    private func startVoiceInteraction() async {
        let userName = sessionViewModel.currentUser?.name
        
        if let voiceAgent = voiceAgentViewModel {
            // Check if there's a paused conversation to resume
            if voiceAgent.conversationPaused {
                print("Resuming paused voice conversation...")
                await voiceAgent.resumeConversation()
            } else {
                print("Starting new voice interaction for expenses...")
                // Request permissions if needed
                if !voiceAgent.hasPermissions {
                    print("Requesting permissions...")
                    let granted = await voiceAgent.requestPermissions()
                    if !granted {
                        print("Permissions not granted")
                        return
                    }
                }
                await voiceAgent.startExpenseVoiceInteraction(userName: userName)
            }
        } else {
            print("VoiceAgentViewModel is nil - initializing now")
            if let userId = sessionViewModel.currentUser?.userId {
                voiceAgentViewModel = VoiceAgentViewModel(
                    userId: userId,
                    billViewModel: billViewModel,
                    expenseViewModel: expenseViewModel,
                    incomeViewModel: incomeViewModel,
                    sessionViewModel: sessionViewModel
                )
                // Request permissions if needed
                if let voiceAgent = voiceAgentViewModel {
                    if !voiceAgent.hasPermissions {
                        print("Requesting permissions...")
                        let granted = await voiceAgent.requestPermissions()
                        if !granted {
                            print("Permissions not granted")
                            return
                        }
                    }
                    await voiceAgent.startExpenseVoiceInteraction(userName: userName)
                }
            }
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
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
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
        ExpenseCalendarView(expensesPerDay: expensesPerDay)
    }
    .padding()
}
