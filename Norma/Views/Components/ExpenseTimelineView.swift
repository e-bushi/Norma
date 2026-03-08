//
//  ExpenseTimelineView.swift
//  Norma
//
//  Created by Claude on 3/7/26.
//

import SwiftUI

// MARK: - Hour Group Model

private struct HourGroup: Identifiable {
    let id: Int // hour value (0-23)
    let label: String
    let expenses: [Expense]
}

struct ExpenseTimelineView: View {
    let expenses: [Expense]
    let selectedDate: Date?
    let monthHasExpenses: Bool
    @Binding var showNormaChat: Bool

    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @State private var selectedExpense: Expense? = nil
    @State private var groupAppeared: [Bool] = []
    @State private var deckIndices: [Int: Int] = [:]

    // MARK: - Grouping by Hour

    private var hourGroups: [HourGroup] {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoFallback = ISO8601DateFormatter()
        isoFallback.formatOptions = [.withInternetDateTime]

        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h a"

        // Parse dates and pair with expenses
        var parsed: [(expense: Expense, date: Date)] = []
        for expense in expenses {
            if let d = isoFormatter.date(from: expense.expenseDate) ?? isoFallback.date(from: expense.expenseDate) {
                parsed.append((expense, d))
            }
        }

        // Sort newest first
        parsed.sort { $0.date > $1.date }

        // Group by hour
        var grouped: [Int: [Expense]] = [:]
        var hourDates: [Int: Date] = [:]
        for item in parsed {
            let hour = calendar.component(.hour, from: item.date)
            grouped[hour, default: []].append(item.expense)
            if hourDates[hour] == nil { hourDates[hour] = item.date }
        }

        // Build sorted groups (newest hour first)
        return grouped.keys.sorted(by: >).map { hour in
            let raw = timeFormatter.string(from: hourDates[hour]!)
            let label = raw.replacingOccurrences(of: " ", with: ":00 ", options: [], range: raw.range(of: " "))
            return HourGroup(id: hour, label: label, expenses: grouped[hour]!)
        }
    }

    private var selectedDateText: String {
        guard let date = selectedDate else { return "this day" }
        if Calendar.current.isDateInToday(date) { return "today" }
        if Calendar.current.isDateInYesterday(date) { return "yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func animateGroups() {
        let count = hourGroups.count
        groupAppeared = Array(repeating: false, count: count)
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    if i < groupAppeared.count {
                        groupAppeared[i] = true
                    }
                }
            }
        }
    }

    private func deleteExpense(_ expense: Expense) {
        Task {
            await expenseViewModel.deleteExpense(expense)
        }
    }

    var body: some View {
        if hourGroups.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(hourGroups.enumerated()), id: \.element.id) { groupIndex, group in
                    let isLast = groupIndex == hourGroups.count - 1

                    HStack(alignment: .top, spacing: 0) {
                        // Timeline column
                        VStack(spacing: 0) {
                            Circle()
                                .fill(Color("NormaPastelCoral").opacity(0.6))
                                .frame(width: 8, height: 8)
                                .padding(.top, 8)

                            if !isLast {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.18))
                                    .frame(width: 1.5)
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(width: 20)

                        // Hour label + card(s)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.label)
                                .font(.normaFinancial(16))
                                .fontWeight(.bold)
                                .foregroundColor(.secondary.opacity(0.5))

                            if group.expenses.count == 1 {
                                // Single card
                                ExpenseTimelineCardView(
                                    expense: group.expenses[0],
                                    onTap: { selectedExpense = group.expenses[0] },
                                    onDelete: { deleteExpense(group.expenses[0]) }
                                )
                            } else {
                                // Card deck
                                ExpenseCardDeckView(
                                    expenses: group.expenses,
                                    currentIndex: Binding(
                                        get: { deckIndices[group.id] ?? 0 },
                                        set: { deckIndices[group.id] = $0 }
                                    ),
                                    onTap: { expense in selectedExpense = expense },
                                    onDelete: { expense in deleteExpense(expense) }
                                )
                            }
                        }
                        .padding(.leading, 12)
                        .padding(.bottom, isLast ? 0 : 24)
                    }
                    .opacity(groupIndex < groupAppeared.count && groupAppeared[groupIndex] ? 1 : 0)
                    .offset(y: groupIndex < groupAppeared.count && groupAppeared[groupIndex] ? 0 : 12)
                }
            }
            .onAppear { animateGroups() }
            .onChange(of: expenses) { _, _ in
                deckIndices = [:]
                animateGroups()
            }
            .sheet(item: $selectedExpense) { expense in
                ExpenseDetailView(expense: expense)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        Group {
            if monthHasExpenses {
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
                VStack(spacing: 24) {
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
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.02))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }
}

// MARK: - Single Expense Timeline Card

struct ExpenseTimelineCardView: View {
    let expense: Expense
    var onTap: () -> Void
    var onDelete: () -> Void

    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var showDeleteConfirm = false

    private func timeString(for expense: Expense) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = isoFormatter.date(from: expense.expenseDate)
        if date == nil {
            isoFormatter.formatOptions = [.withInternetDateTime]
            date = isoFormatter.date(from: expense.expenseDate)
        }
        guard let d = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: d)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Top row: name + amount + delete
                HStack(alignment: .top) {
                    Text(expense.name)
                        .font(.normaInput(15))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Spacer()

                    Text(profileViewModel.formatCurrency(expense.amount))
                        .font(.normaFinancial(16))
                        .foregroundColor(Color("NormaPastelCoral"))

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

                // Dashed separator
                DashedDivider()
                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .frame(height: 1)

                // Bottom row: time + merchant + payment method
                HStack(spacing: 8) {
                    let time = timeString(for: expense)
                    if !time.isEmpty {
                        Label(time, systemImage: "clock")
                            .font(.normaInput(12))
                            .foregroundColor(.secondary.opacity(0.7))
                    }

                    if let merchant = expense.merchant, !merchant.isEmpty {
                        Text("·")
                            .foregroundColor(.secondary.opacity(0.3))
                        Text(merchant)
                            .font(.normaInput(12))
                            .foregroundColor(.secondary.opacity(0.7))
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(expense.paymentMethod.rawValue)
                        .font(.normaInput(11))
                        .foregroundColor(Color("NormaPastelCoral").opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color("NormaPastelCoral").opacity(0.08))
                        )
                }

                // Tags
                if !expense.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(expense.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.normaInput(11))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.gray.opacity(0.06))
                                )
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.clear)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 16))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.12), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog("Delete \(expense.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
}

// MARK: - Expense Card Deck (Swipeable Stack)

struct ExpenseCardDeckView: View {
    let expenses: [Expense]
    @Binding var currentIndex: Int
    var onTap: ((Expense) -> Void)?
    var onDelete: ((Expense) -> Void)?

    @State private var dragOffset: CGFloat = 0
    @EnvironmentObject var profileViewModel: ProfileViewModel

    private let cardHeight: CGFloat = 140
    private let peekOffset: CGFloat = 8
    private let peekScale: CGFloat = 0.04

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(Array(visibleCards.enumerated().reversed()), id: \.element.id) { stackIndex, expense in
                    let isTop = stackIndex == 0

                    ExpenseTimelineCardView(
                        expense: expense,
                        onTap: { onTap?(expense) },
                        onDelete: {
                            onDelete?(expense)
                            if currentIndex >= expenses.count - 1 {
                                currentIndex = max(0, expenses.count - 2)
                            }
                        }
                    )
                    .scaleEffect(1 - CGFloat(stackIndex) * peekScale)
                    .offset(y: -CGFloat(stackIndex) * peekOffset)
                    .offset(x: isTop ? dragOffset : 0)
                    .rotationEffect(isTop ? .degrees(Double(dragOffset) / 20) : .zero)
                    .opacity(stackIndex == 2 ? 0.5 : 1)
                    .zIndex(Double(3 - stackIndex))
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentIndex)
                }
            }
            .frame(height: cardHeight + CGFloat(min(expenses.count - 1, 2)) * peekOffset)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 15)
                    .onChanged { value in
                        if abs(value.translation.width) > abs(value.translation.height) {
                            dragOffset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            if value.translation.width < -threshold && currentIndex < expenses.count - 1 {
                                currentIndex += 1
                            } else if value.translation.width > threshold && currentIndex > 0 {
                                currentIndex -= 1
                            }
                            dragOffset = 0
                        }
                    }
            )

        }
    }

    private var visibleCards: [Expense] {
        let start = currentIndex
        let end = min(currentIndex + 3, expenses.count)
        guard start < end else { return [] }
        return Array(expenses[start..<end])
    }
}

// MARK: - Dashed Line Shape

private struct DashedDivider: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}
