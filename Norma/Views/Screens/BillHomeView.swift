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
    @State private var showBillVerificationPopup = false
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Bills")
                        .font(.normaTitle(20))
                }
            }
            .sheet(isPresented: $showCreateBill) {
                CreateBillView()
            }
            .fullScreenCover(isPresented: $showBillVerificationPopup) {
                BillPeriodVerificationView(verificationService: billViewModel.verificationService)
            }
            .onAppear {
                Task {
                    await loadInitialData()
                }
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
