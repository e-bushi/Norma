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
    var initialMonth: Date? = nil
    @State private var showMiniChat = false
    @State private var longPressedDate: Date? = nil
    @State private var pressingDate: Date? = nil
    @State private var currentCardIndex: Int = 0
    @State private var visibleCellCount: Int = 0
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var billViewModel: BillViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel

    private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    // Haptic feedback
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    // Dictionary to track bills per day
    var billsPerDay: [Date: [Double]] = [:]

    private var billsForSelectedDate: [Bill] {
        let calendar = Calendar.current
        return billViewModel.activeBills.filter { bill in
            calendar.isDate(bill.dueDate, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Calendar
            VStack(spacing: 16) {
                // Day labels
                HStack(spacing: 0) {
                    ForEach(days, id: \.self) { day in
                        Text(day)
                            .font(.normaInput(11))
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }

                // Calendar grid
                let dates = extractDates()
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                        if let date = date {
                            BillDayCell(
                                date: date,
                                isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                isToday: Calendar.current.isDateInToday(date),
                                isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month),
                                hasBills: (billsPerDay[date.startOfDay]?.count ?? 0) > 0,
                                billTotal: billsPerDay[date.startOfDay]?.reduce(0, +) ?? 0
                            )
                            .scaleEffect(pressingDate == date ? 0.88 : 1.0)
                            .opacity(pressingDate == date ? 0.7 : (visibleCellCount > index ? 1 : 0))
                            .offset(y: visibleCellCount > index ? 0 : 8)
                            .animation(
                                .spring(response: 0.35, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.02),
                                value: visibleCellCount
                            )
                            .animation(.easeInOut(duration: 0.25), value: pressingDate)
                            .onTapGesture {
                                impactGenerator.impactOccurred()

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
                                .frame(height: 48)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                    )
            )

            // Selected day bills — stacked deck
            if !billsForSelectedDate.isEmpty {
                BillCardDeckView(
                    bills: billsForSelectedDate,
                    currentIndex: $currentCardIndex,
                    onDelete: { bill in
                        Task {
                            await billViewModel.deleteBill(bill)
                            if currentCardIndex >= billsForSelectedDate.count {
                                currentCardIndex = max(0, billsForSelectedDate.count - 1)
                            }
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .offset(y: 10)),
                    removal: .opacity
                ))
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 14, weight: .medium))
                    Text("Hold a day to add a bill")
                        .font(.normaInput(14))
                }
                .foregroundColor(.secondary.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .transition(.opacity)
            }
        }
        .onAppear {
            if let initialMonth = initialMonth {
                currentMonth = initialMonth
                selectedDate = initialMonth
            }
            let totalCells = extractDates().count
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                visibleCellCount = totalCells
            }
        }
        .onChange(of: selectedDate) { _, _ in
            currentCardIndex = 0
        }
        .sheet(isPresented: $showMiniChat) {
            if let date = longPressedDate {
                MiniChatView(selectedDate: date)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
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
}

// Bill day cell component
struct BillDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let hasBills: Bool
    let billTotal: Double
    @EnvironmentObject var profileViewModel: ProfileViewModel

    private var showNumber: Bool {
        isSelected || isToday || hasBills
    }

    private var formattedBillAmount: String {
        profileViewModel.formatCurrencyTruncated(billTotal)
    }

    var body: some View {
        VStack(spacing: 3) {
            if showNumber {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 14, weight: hasBills ? .semibold : .medium, design: .rounded))
                    .foregroundColor(textColor)
            } else {
                Circle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 4, height: 4)
            }

            // Bill amount
            if hasBills {
                Text(formattedBillAmount)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(billAmountColor)
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
                        .fill(Color("NormaPastelTeal"))
                } else if isToday {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("NormaPastelTeal").opacity(0.08))
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("NormaPastelTeal").opacity(0.25), lineWidth: 1)
                } else if hasBills {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.04))
                }
            }
        )
        .opacity(isCurrentMonth ? 1 : 0.3)
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Color("NormaPastelTeal")
        } else if hasBills {
            return .primary
        } else {
            return .secondary
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

// MARK: - Bill Card Deck (Swipeable Stack)

struct BillCardDeckView: View {
    let bills: [Bill]
    @Binding var currentIndex: Int
    var onDelete: ((Bill) -> Void)? = nil
    @State private var dragOffset: CGFloat = 0
    @EnvironmentObject var profileViewModel: ProfileViewModel

    private let cardHeight: CGFloat = 160
    private let peekOffset: CGFloat = 8
    private let peekScale: CGFloat = 0.04

    var body: some View {
        ZStack {
            // Show up to 3 cards in the stack (back to front)
            ForEach(Array(visibleCards.enumerated().reversed()), id: \.element.id) { stackIndex, bill in
                let isTop = stackIndex == 0

                BillDeckCardView(bill: bill, onDelete: onDelete)
                    .frame(height: cardHeight)
                    .scaleEffect(1 - CGFloat(stackIndex) * peekScale)
                    .offset(y: CGFloat(stackIndex) * peekOffset)
                    .offset(x: isTop ? dragOffset : 0)
                    .rotationEffect(isTop ? .degrees(Double(dragOffset) / 20) : .zero)
                    .opacity(stackIndex == 2 ? 0.5 : 1)
                    .zIndex(Double(3 - stackIndex))
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentIndex)
            }
        }
        .frame(height: cardHeight + CGFloat(min(bills.count - 1, 2)) * peekOffset)
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture(minimumDistance: 15)
                .onChanged { value in
                    // Only track horizontal swipes
                    if abs(value.translation.width) > abs(value.translation.height) {
                        dragOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        if value.translation.width < -threshold && currentIndex < bills.count - 1 {
                            currentIndex += 1
                        } else if value.translation.width > threshold && currentIndex > 0 {
                            currentIndex -= 1
                        }
                        dragOffset = 0
                    }
                }
        )

        // Page indicator
        if bills.count > 1 {
            HStack(spacing: 6) {
                ForEach(0..<bills.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color("NormaPastelTeal") : Color.secondary.opacity(0.2))
                        .frame(width: 6, height: 6)
                        .animation(.easeInOut(duration: 0.2), value: currentIndex)
                }
            }
            .padding(.top, 8)
        }
    }

    private var visibleCards: [Bill] {
        let start = currentIndex
        let end = min(currentIndex + 3, bills.count)
        return Array(bills[start..<end])
    }
}

// MARK: - Large Minimal Bill Card

struct BillDeckCardView: View {
    let bill: Bill
    var onDelete: ((Bill) -> Void)? = nil
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @State private var showDeleteConfirm = false

    private var formattedAmount: String {
        profileViewModel.formatCurrency(bill.amount)
    }

    private var status: BillStatus {
        bill.calculateStatus(from: expenseViewModel.expenses)
    }

    private var statusColor: Color {
        switch status {
        case .paid: return Color("NormaPastelGreen")
        case .overdue: return Color("NormaPastelCoral")
        case .scheduled: return Color("NormaPastelTeal")
        }
    }

    private var statusText: String {
        switch status {
        case .paid: return "Paid"
        case .overdue: return "Overdue"
        case .scheduled: return "Scheduled"
        }
    }

    private var dueDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: bill.dueDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: name + status + delete
            HStack(alignment: .center) {
                Text(bill.name)
                    .font(.normaInput(15))
                    .foregroundColor(.secondary)

                Spacer()

                Text(statusText)
                    .font(.normaInput(12))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.12))
                    )

                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.4))
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Amount
            Text(formattedAmount)
                .font(.normaHeadline(38))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            // Bottom row: due date + frequency
            HStack(spacing: 12) {
                Label(dueDateFormatted, systemImage: "calendar")
                    .font(.normaInput(12))
                    .foregroundColor(.secondary.opacity(0.6))

                Text("·")
                    .foregroundColor(.secondary.opacity(0.3))

                Text(bill.frequency.rawValue.capitalized)
                    .font(.normaInput(12))
                    .foregroundColor(.secondary.opacity(0.6))

                if bill.isReminderOn {
                    Text("·")
                        .foregroundColor(.secondary.opacity(0.3))

                    Label("Reminder", systemImage: "bell.fill")
                        .font(.normaInput(12))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.clear)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 20))

                // Radar rings from bottom-right
                Canvas { context, size in
                    let origin = CGPoint(x: size.width, y: size.height)
                    let ringCount = 6
                    let maxRadius: CGFloat = 180
                    let ringSpacing = maxRadius / CGFloat(ringCount)

                    for i in 1...ringCount {
                        let radius = CGFloat(i) * ringSpacing
                        let opacity = 0.08 * (1.0 - CGFloat(i) / CGFloat(ringCount))
                        let rect = CGRect(
                            x: origin.x - radius,
                            y: origin.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )
                        context.stroke(
                            Path(ellipseIn: rect),
                            with: .color(statusColor.opacity(opacity)),
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
                .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
        )
        .confirmationDialog("Delete \(bill.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete?(bill)
            }
        }
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let billViewModel = BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let expenseViewModel = ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)

    return BillDueDateCalendarView(billsPerDay: [:])
        .environmentObject(sessionViewModel)
        .environmentObject(billViewModel)
        .environmentObject(profileViewModel)
        .environmentObject(expenseViewModel)
        .padding()
}
