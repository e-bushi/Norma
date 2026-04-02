//
//  BillListView.swift
//  Collector
//
//  Created by Chris Mauldin on 5/8/25.
//

import SwiftUI
import Foundation

struct BillHomeView: View {
    
    @EnvironmentObject var billViewModel: BillViewModel
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var incomeViewModel: IncomeViewModel
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var coinColorViewModel: CoinColorViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showMyBills: Bool = false
    @State private var isScrolling = false
    @State private var scrollTimer: Timer?
    @State private var showAddOptions = false
    @State private var showCreateBill = false
    @State private var showAllBills = false
    @State private var showInfoPopover = false
    @State private var selectedMonthOffset: Int = 0
    @State private var showRecurringReview = false
    @State private var showAdvanceBills = false
    @ObservedObject private var plaidService = PlaidService.shared

    private var referenceDate: Date {
        Calendar.current.date(byAdding: .month, value: selectedMonthOffset, to: Date()) ?? Date()
    }

    private var displayMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: referenceDate)
    }

    private var displayYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: referenceDate)
    }

    private var nextMonthLabel: String {
        let nextDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: nextDate).uppercased()
    }

    private var currentMonthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: Date()).uppercased()
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    @State private var waveAnimating = false

    private var billsForSelectedMonth: [Bill] {
        billViewModel.bills.filter {
            Calendar.current.isDate($0.dueDate, equalTo: referenceDate, toGranularity: .month)
        }
    }

    private var selectedMonthBillTotal: Double {
        billsForSelectedMonth.reduce(0) { $0 + $1.amount }
    }

    private var formattedBillTotal: String {
        selectedMonthBillTotal.formatted(.currency(code: currency).precision(.fractionLength(0)))
    }

    private var waveWords: [(word: String, color: Color)] {
        var words: [(String, Color)] = []
        words.append(("You", .primary))
        words.append(("have", .primary))
        for part in formattedBillTotal.split(separator: " ").map(String.init) {
            words.append((part, Color("NormaPastelCoral")))
        }
        words.append(("in", .primary))
        words.append(("bills", .primary))
        let isCurrentMonth = selectedMonthOffset == 0
        words.append((isCurrentMonth ? "this" : "next", .primary))
        words.append(("month.", .primary))
        return words
    }

    private var paidBillCount: Int {
        billsForSelectedMonth
            .filter { $0.calculateStatus(from: expenseViewModel.expenses) == .paid }
            .count
    }

    private var totalBillCountThisMonth: Int {
        billsForSelectedMonth.count
    }

    private var paidBillsToAdvance: [Bill] {
        billsForSelectedMonth.filter {
            $0.calculateStatus(from: expenseViewModel.expenses) == .paid
        }
    }

    private var profileIncomeAmount: Double {
        // Use income from profile settings if available, otherwise fall back to IncomeViewModel
        return sessionViewModel.currentUser?.settings.monthlyIncome ?? incomeViewModel.totalMonthlyIncome
    }
    
    private var shouldShowOnboardingMode: Bool {
        // Show onboarding mode if:
        // 1. User has no bills yet (hasn't started tracking)
        // 2. User has income from profile (came from onboarding)
        return billViewModel.activeBills.isEmpty && profileIncomeAmount > 0
    }
    
    private var billsPerDayDict: [Date: [Double]] {
        let calendar = Calendar.current
        var dict: [Date: [Double]] = [:]

        // Active bills with dueDate in this month
        for bill in billsForSelectedMonth {
            let startOfDay = calendar.startOfDay(for: bill.dueDate)
            if dict[startOfDay] != nil {
                dict[startOfDay]?.append(bill.amount)
            } else {
                dict[startOfDay] = [bill.amount]
            }
        }

        // Bill payment expenses in this month (for advanced bills that already rolled forward)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        let activeBillIds = Set(billsForSelectedMonth.compactMap { $0.id })

        for expense in expenseViewModel.expenses {
            guard let billId = expense.billId,
                  !activeBillIds.contains(billId),
                  let expenseDate = dateFormatter.date(from: expense.expenseDate),
                  calendar.isDate(expenseDate, equalTo: referenceDate, toGranularity: .month) else { continue }

            let startOfDay = calendar.startOfDay(for: expenseDate)
            if dict[startOfDay] != nil {
                dict[startOfDay]?.append(expense.amount)
            } else {
                dict[startOfDay] = [expense.amount]
            }
        }

        return dict
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 8) {
                            monthCapsule(
                                label: currentMonthLabel,
                                isActive: selectedMonthOffset == 0
                            ) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedMonthOffset = 0
                                }
                            }

                            monthCapsule(
                                label: nextMonthLabel,
                                isActive: selectedMonthOffset == 1
                            ) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedMonthOffset = 1
                                }
                            }
                        }
                        .padding(.top, 20)

                        ColoredWaveTextView(
                            words: waveWords,
                            font: .normaHeadline(64),
                            isAnimating: waveAnimating,
                            alignment: .leading
                        )
                        .id(selectedMonthOffset)
                        .padding(.top, 16)
                        .onChange(of: selectedMonthOffset) { _, _ in
                            waveAnimating = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                waveAnimating = true
                            }
                        }

                        if totalBillCountThisMonth > 0 {
                            HStack(spacing: 8) {
                                Button {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    showAllBills = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("All Bills")
                                            .font(.normaFinancial(16))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundColor(Color("NormaPastelTeal"))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .stroke(Color("NormaPastelTeal").opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())

                                if !paidBillsToAdvance.isEmpty {
                                    Button {
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                        showAdvanceBills = true
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.right.circle")
                                                .font(.system(size: 12, weight: .semibold))
                                            Text("Advance")
                                                .font(.normaFinancial(16))
                                        }
                                        .foregroundColor(Color("NormaPastelPurple"))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .stroke(Color("NormaPastelPurple").opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.top, 12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .onAppear {
                        waveAnimating = true
                    }

                    // Recurring bills detected banner
                    if !plaidService.recurringOutflows.isEmpty {
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            showRecurringReview = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("NormaPastelTeal"))

                                Text("\(plaidService.recurringOutflows.count) bills detected")
                                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                                    .foregroundColor(.primary)

                                Spacer()

                                Text("Review")
                                    .font(.custom(FontFamily.Rubik.medium, size: 14))
                                    .foregroundColor(Color("NormaPastelTeal"))

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color("NormaPastelTeal"))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.clear)
                                    .glassEffect(in: RoundedRectangle(cornerRadius: 14))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color("NormaPastelTeal").opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 24)
                    }

                    // Bill Due Date Calendar
                    BillDueDateCalendarView(initialMonth: referenceDate, billsPerDay: billsPerDayDict)
                        .id(selectedMonthOffset)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedMonthOffset)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .scrollIndicators(.hidden)
            .background {
                CoinGradientBackground(coinColor: coinColorViewModel.coinColor, colorScheme: colorScheme)
                    .ignoresSafeArea()
            }
            .scrollContentBackground(.hidden)
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { _ in
                // Scroll detected
                isScrolling = true

                // Cancel previous timer
                scrollTimer?.invalidate()

                // Set timer to detect when scrolling stops
                scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                    isScrolling = false
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        showInfoPopover = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .popover(isPresented: $showInfoPopover, arrowEdge: .top) {
                        BillInfoPopover()
                            .presentationCompactAdaptation(.popover)
                    }
                }
            }
            .sheet(isPresented: $showCreateBill) {
                CreateBillView()
            }
            .sheet(isPresented: $showAllBills) {
                MyBillsView()
            }
            .sheet(isPresented: $showRecurringReview) {
                RecurringBillsReviewView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showAdvanceBills) {
                AdvanceBillsSheet(bills: paidBillsToAdvance)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                Task {
                    await loadInitialData()
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func monthCapsule(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        } label: {
            Text(label)
                .font(.normaFinancial(18))
                .foregroundColor(isActive ? .secondary : .secondary.opacity(0.4))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .background(
            Group {
                if isActive {
                    Capsule()
                        .fill(.clear)
                        .glassEffect(.regular.interactive(), in: .capsule)
                } else {
                    Capsule()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .foregroundColor(.secondary.opacity(0.2))
                }
            }
        )
        .buttonStyle(PlainButtonStyle())
    }

    private func loadInitialData() async {
        await expenseViewModel.refreshExpenses()
        await billViewModel.refreshBills()
        await incomeViewModel.refreshIncomes()
    }
    
}

// MARK: - Bill Info Popover

struct BillInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color("NormaPastelTeal"))

                Text("Bills")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Keep track of your recurring bills and due dates so nothing slips through the cracks.")
                    .font(.normaInput(14))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Tap a day on the calendar to see which bills are due. Press and hold a day to add a bill directly. Swipe cards to browse multiple bills on the same day.")
                    .font(.normaInput(14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color("NormaPastelTeal"))

                Text("Adding Bills")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundColor(.primary)
            }

            Text("Tell Norma in the chat — just say something like \"Electric bill, 120\" and she'll set it up for you.")
                .font(.normaInput(14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 300)
        .background(Color("NormaBackground"))
    }
}

// MARK: - Advance Bills Sheet

private struct AdvanceBillsSheet: View {
    let bills: [Bill]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var coinColorViewModel: CoinColorViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAdvancing = false
    @State private var heroAnimating = false

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private func formatCurrency(_ amount: Double) -> String {
        amount.formatted(.currency(code: currency).precision(.fractionLength(0)))
    }

    private func nextDueDateForBill(_ bill: Bill) -> Date {
        let calendar = Calendar.current
        switch bill.frequency {
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: bill.dueDate) ?? bill.dueDate
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: bill.dueDate) ?? bill.dueDate
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: bill.dueDate) ?? bill.dueDate
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private var heroWords: [(word: String, color: Color)] {
        var words: [(String, Color)] = []
        let count = "\(bills.count)"
        words.append((count, Color("NormaPastelPurple")))
        words.append(("paid", .primary))
        words.append((bills.count == 1 ? "bill" : "bills", .primary))
        words.append(("ready", .primary))
        words.append(("to", .primary))
        words.append(("advance.", .primary))
        return words
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Hero text
                ColoredWaveTextView(
                    words: heroWords,
                    font: .normaHeadline(48),
                    isAnimating: heroAnimating,
                    alignment: .leading
                )
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 8)

                // Bill list
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(bills, id: \.id) { bill in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(bill.name)
                                        .font(.custom(FontFamily.Rubik.medium, size: 16))
                                        .foregroundColor(.primary)

                                    HStack(spacing: 6) {
                                        Text(formatDate(bill.dueDate))
                                            .font(.normaFinancial(13))
                                            .foregroundColor(.secondary.opacity(0.6))

                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.secondary.opacity(0.4))

                                        Text(formatDate(nextDueDateForBill(bill)))
                                            .font(.normaFinancial(13))
                                            .foregroundColor(Color("NormaPastelTeal"))
                                    }
                                }

                                Spacer()

                                Text(formatCurrency(bill.amount))
                                    .font(.normaFinancial(15))
                                    .foregroundColor(.primary)
                            }
                            .padding(16)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.clear)
                                        .glassEffect(in: RoundedRectangle(cornerRadius: 14))

                                    Canvas { context, size in
                                        let origin = CGPoint(x: size.width, y: size.height)
                                        let ringCount = 5
                                        let maxRadius: CGFloat = 100
                                        let ringSpacing = maxRadius / CGFloat(ringCount)

                                        for i in 1...ringCount {
                                            let radius = CGFloat(i) * ringSpacing
                                            let opacity = 0.10 * (1.0 - CGFloat(i) / CGFloat(ringCount))
                                            let rect = CGRect(
                                                x: origin.x - radius,
                                                y: origin.y - radius,
                                                width: radius * 2,
                                                height: radius * 2
                                            )
                                            context.stroke(
                                                Path(ellipseIn: rect),
                                                with: .color(Color("NormaPastelPurple").opacity(opacity)),
                                                lineWidth: 1
                                            )
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .allowsHitTesting(false)
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Confirm button
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    isAdvancing = true
                    Task {
                        await billViewModel.advancePaidBills(bills)
                        isAdvancing = false
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isAdvancing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 16))
                            Text("Advance All")
                                .font(.custom(FontFamily.Rubik.medium, size: 16))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color("NormaPastelPurple"))
                    )
                }
                .disabled(isAdvancing)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .background {
                CoinGradientBackground(coinColor: coinColorViewModel.coinColor, colorScheme: colorScheme)
                    .ignoresSafeArea()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Info action
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                heroAnimating = true
            }
        }
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let billViewModel = BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let expenseViewModel = ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let incomeViewModel = IncomeViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)

    return BillHomeView()
        .environmentObject(sessionViewModel)
        .environmentObject(billViewModel)
        .environmentObject(expenseViewModel)
        .environmentObject(incomeViewModel)
        .environmentObject(profileViewModel)
        .preferredColorScheme(.light)
}
