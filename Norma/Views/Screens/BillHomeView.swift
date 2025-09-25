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
    @State private var showNormaChat: Bool = false
    @State private var refreshTask: Task<Void, Never>?
    @State private var showBillVerificationPopup = false
    @State private var showBillReviewSheet = false
    @State private var isScrolling = false
    @State private var scrollTimer: Timer?
    @State private var showAddOptions = false
    @State private var showCreateBill = false
    
    private var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
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
    
    private var currentSpentAmount: Double {
        // Calculate total spent: all active bill amounts + non-bill expenses for current month
        // This prevents double counting - we count bill amounts, not the bill payment expenses
        
        // Get current month and year
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        // Filter expenses for current month only
        let currentMonthExpenses = expenseViewModel.expenses.filter { expense in
            // Parse the expense date string (assuming ISO format)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            // Try with fractional seconds first, then without
            if let date = formatter.date(from: expense.expenseDate) {
                let expenseMonth = calendar.component(.month, from: date)
                let expenseYear = calendar.component(.year, from: date)
                return expenseMonth == currentMonth && expenseYear == currentYear
            } else {
                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: expense.expenseDate) {
                    let expenseMonth = calendar.component(.month, from: date)
                    let expenseYear = calendar.component(.year, from: date)
                    return expenseMonth == currentMonth && expenseYear == currentYear
                }
            }
            return false
        }
        
        // Get the bill amounts for all active bills (regardless of payment status)
        let activeBillsAmount = billViewModel.activeBills
            .filter { $0.isActive ?? true } // Include bills where isActive is true or nil (default to active)
            .reduce(0) { $0 + $1.amount }
        
        // Get expenses that are NOT linked to bills (billId is nil) for current month
        let nonBillExpenses = currentMonthExpenses.filter { $0.billId == nil }
        let nonBillExpensesAmount = nonBillExpenses.reduce(0) { $0 + $1.amount }
        
        return activeBillsAmount + nonBillExpensesAmount
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    // Hidden view to detect scrolling
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                    }
                    .frame(height: 0)
                    
                    // Trial status banner
                    TrialStatusBanner()
                    
                    ExpenseTrackerChartView(
                    billAmount: billViewModel.totalMonthlyBills,
                    currentExpenseAmount: currentSpentAmount,
                    incomeAmount: profileIncomeAmount,
                    month: currentMonth,
                    isOnboardingMode: shouldShowOnboardingMode,
                    showNormaChat: $showNormaChat
                    )
    
                
                    BillDisclosureView(bills: billViewModel.activeBills, showNormaChat: $showNormaChat)
                    .padding(.vertical)
                    .padding(.horizontal)
                    .padding(.horizontal)
                }
            }
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
            .navigationTitle(Text("Home"))
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await performRefresh()
            }
            .task {
                // Only load if bills are empty (not already loaded by RootView)
                if billViewModel.bills.isEmpty {
                    await loadInitialData()
                }
            }
            .sheet(isPresented: $showNormaChat) {
                NormaChatView(context: .bills)
            }
            .sheet(isPresented: $showCreateBill) {
                CreateBillView()
            }
            .sheet(isPresented: $showBillReviewSheet) {
                BillReviewSelectionView(verificationService: billViewModel.verificationService) {
                    showBillReviewSheet = false
                }
            }
            .overlay {
                if showBillVerificationPopup {
                    InformationalPopup(
                        isPresented: $showBillVerificationPopup,
                        config: .billPeriodVerification(
                            billCount: billViewModel.verificationService.billsToVerify.count,
                            onConfirmAll: {},
                            onReviewBills: {}
                        ),
                        onPrimaryAction: {
                            Task {
                                await billViewModel.verificationService.confirmAllBills()
                                showBillVerificationPopup = false
                            }
                        },
                        onSecondaryAction: {
                            showBillVerificationPopup = false
                            showBillReviewSheet = true
                        },
                        onDismiss: {
                            showBillVerificationPopup = false
                        }
                    )
                }
            }
            .onDisappear {
                refreshTask?.cancel()
            }
            .onReceive(billViewModel.verificationService.$showVerificationPrompt) { showPrompt in
                showBillVerificationPopup = showPrompt
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() async {
        await expenseViewModel.refreshExpenses()
        await billViewModel.refreshBills()
        await incomeViewModel.refreshIncomes()
    }
    
    private func performRefresh() async {
        // Cancel any existing refresh task
        refreshTask?.cancel()
        
        // Create new refresh task
        refreshTask = Task {
            await refreshData()
        }
        
        await refreshTask?.value
    }
    
    private func refreshData() async {
        await expenseViewModel.refreshExpenses()
        await billViewModel.refreshBills()
        await incomeViewModel.refreshIncomes()
    }
    
    func getDaysInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let date = Date()
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }
    
    func generateChartData() -> [ExpenseChartDataPoint] {
        // Simulate days with expense activity
        let activeDays = [2, 5, 7, 10, 12, 15, 17, 20, 22, 25, 27]
        let billAmount: Double = 1545.49
        
        var runningTotal = billAmount
        
        return activeDays.map { day in
            // Daily expense amount varies
            let dailyExpense = Double.random(in: 40...180)
            
            let lowAmount = runningTotal
            let highAmount = runningTotal + dailyExpense
            
            runningTotal = highAmount
            
            return ExpenseChartDataPoint(
                day: day,
                highAmount: highAmount,
                lowAmount: lowAmount,
                dailyExpense: dailyExpense
            )
        }
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let billViewModel = BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let expenseViewModel = ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let incomeViewModel = IncomeViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let budgetViewModel = BudgetViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    
    return BillHomeView()
        .environmentObject(sessionViewModel)
        .environmentObject(billViewModel)
        .environmentObject(expenseViewModel)
        .environmentObject(incomeViewModel)
        .environmentObject(budgetViewModel)
        .environmentObject(profileViewModel)
        .preferredColorScheme(.light)
}
