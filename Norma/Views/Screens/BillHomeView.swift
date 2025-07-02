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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
                ExpenseTrackerChartView(
                    billAmount: billViewModel.totalMonthlyBills,
                    currentExpenseAmount: expenseViewModel.totalExpenses,
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
            .navigationTitle(Text("Home"))
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await refreshData()
            }
            .onAppear {
                Task {
                    await loadInitialData()
                }
            }
            .sheet(isPresented: $showNormaChat) {
                NormaChatView(context: .bills)
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() async {
        await billViewModel.refreshBills()
        await expenseViewModel.refreshExpenses()
        await incomeViewModel.refreshIncomes()
    }
    
    private func refreshData() async {
        await billViewModel.refreshBills()
        await expenseViewModel.refreshExpenses()
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
    
    return BillHomeView()
        .environmentObject(sessionViewModel)
        .environmentObject(billViewModel)
        .environmentObject(expenseViewModel)
        .environmentObject(incomeViewModel)
        .preferredColorScheme(.light)
}
