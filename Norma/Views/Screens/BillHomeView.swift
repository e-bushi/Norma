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
    
    private var billsPerDayDict: [Date: [Double]] {
        let calendar = Calendar.current
        var dict: [Date: [Double]] = [:]

        for bill in billViewModel.activeBills {
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
                VStack(spacing: 24) {
                    // Bill Due Date Calendar
                    BillDueDateCalendarView(billsPerDay: billsPerDayDict)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Bill Disclosure
                    BillDisclosureView(bills: billViewModel.activeBills, showNormaChat: $showNormaChat)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
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
            .navigationTitle(Text("My Bills"))
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await performRefresh()
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
