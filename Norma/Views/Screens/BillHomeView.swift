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
    @State private var showMyBills: Bool = false
    @State private var isScrolling = false
    @State private var scrollTimer: Timer?
    @State private var showAddOptions = false
    @State private var showCreateBill = false
    @State private var showAllBills = false
    @State private var showInfoPopover = false
    @State private var selectedMonthOffset: Int = 0

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

        for bill in billsForSelectedMonth {
            let startOfDay = calendar.startOfDay(for: bill.dueDate)
            if dict[startOfDay] != nil {
                dict[startOfDay]?.append(bill.amount)
            } else {
                dict[startOfDay] = [bill.amount]
            }
        }

        return dict
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header — matches FinancialOverviewView positioning
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
                                Text("\(paidBillCount) of \(totalBillCountThisMonth) paid")
                                    .font(.normaFinancial(16))
                                    .foregroundColor(paidBillCount == totalBillCountThisMonth ? Color("NormaPastelGreen") : .secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )

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
                            }
                            .padding(.top, 12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .onAppear {
                        waveAnimating = true
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
            .background(Color("NormaBackground"))
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
