//
//  ExpenseTrackerRegularView.swift
//  Norma
//
//  Created by Claude on 7/6/25.
//

import SwiftUI

struct ExpenseTrackerRegularView: View {
    let billAmount: Double
    let currentExpenseAmount: Double
    let incomeAmount: Double
    let month: String
    let isScrolling: Bool
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var billViewModel: BillViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @EnvironmentObject var incomeViewModel: IncomeViewModel
    @State private var showingIncomeDetail = false
    
    // Animation states
    let chartAppeared: Bool
    let dotsAppeared: Bool
    let insightsAppeared: Bool
    
    @State private var showDescription = false
    @State private var headerAppeared = false
    @State private var explanationButtonAppeared = false
    @State private var incomeLabelAppeared = false
    @State private var billsLabelAppeared = false
    @State private var currentLabelAppeared = false
    
    @State private var showVoiceMode = false
    @State private var voiceAgentViewModel: VoiceAgentViewModel?
    @State private var lastTapTime: Date = Date()
    @State private var isPressed = false
    @State private var showPaywall = false
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // Segmented control state
    @State private var selectedView = 0 // 0 for Money Chart, 1 for Money Score
    
    // Chart constants (used for layout consistency)
    private let lineHeight: CGFloat = 400
    private let chartWidth: CGFloat = 320
    
    var body: some View {
        ZStack {
            VStack(spacing: 24) {
            // Enhanced header with status
            ExpenseInsightsHeader(
                month: month,
                incomeAmount: incomeAmount,
                currentExpenseAmount: currentExpenseAmount,
                billAmount: billAmount,
                headerAppeared: headerAppeared,
                insightsAppeared: insightsAppeared
            )
            
            // Voice mode instruction - Temporarily commented out
            /*
            VoiceModeInstruction(
                explanationButtonAppeared: explanationButtonAppeared,
                onActivate: {
                    // Check if user has active subscription or is in trial
                    if subscriptionManager.isInFreeTrial || subscriptionManager.hasActiveSubscription {
                        print("ExpenseTracker: User has access (trial or subscription) - activating voice mode from button...")
                        
                        // Activate voice mode
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showVoiceMode = true
                        }
                        
                        // Strong haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                        impactFeedback.impactOccurred()
                        
                        // Start voice recording or resume paused conversation
                        Task {
                            // Initialize voiceAgentViewModel if needed
                            if voiceAgentViewModel == nil {
                                if let userId = sessionViewModel.currentUser?.userId {
                                    voiceAgentViewModel = VoiceAgentViewModel(
                                        userId: userId,
                                        billViewModel: billViewModel,
                                        expenseViewModel: nil,  // ExpenseViewModel not available in this view
                                        incomeViewModel: incomeViewModel,
                                        sessionViewModel: sessionViewModel
                                    )
                                }
                            }
                            
                            // Start or resume conversation
                            if let voiceAgent = voiceAgentViewModel {
                                if voiceAgent.conversationPaused {
                                    await voiceAgent.resumeConversation()
                                } else {
                                    let userName = sessionViewModel.currentUser?.name
                                    await voiceAgent.startVoiceInteraction(userName: userName)
                                }
                            }
                        }
                    } else {
                        print("ExpenseTracker: No access to voice mode - show paywall")
                        showPaywall = true
                    }
                }
            )
            */

            // Custom Segmented Control
            MoneyViewPicker(selectedView: $selectedView, chartAppeared: chartAppeared)
                    .padding(.horizontal)

            // Content based on selection
            if selectedView == 0 {
                // Money Chart
                MoneyRemainingChartView(
                    incomeAmount: incomeAmount,
                    billAmount: billAmount,
                    currentExpenseAmount: currentExpenseAmount,
                    chartAppeared: chartAppeared,
                    incomeLabelAppeared: $incomeLabelAppeared,
                    billsLabelAppeared: $billsLabelAppeared,
                    currentLabelAppeared: $currentLabelAppeared,
                    showDescription: $showDescription,
                    explanationButtonAppeared: explanationButtonAppeared,
                    showVoiceMode: $showVoiceMode,
                    voiceAgentViewModel: $voiceAgentViewModel,
                    lastTapTime: $lastTapTime,
                    isPressed: $isPressed,
                    showPaywall: $showPaywall,
                    showingIncomeDetail: $showingIncomeDetail
                )
                
                // Chart explanation section (only for Money Chart view)
                ChartExplanation(
                    showDescription: $showDescription,
                    incomeAmount: incomeAmount,
                    billAmount: billAmount,
                    currentExpenseAmount: currentExpenseAmount,
                    explanationButtonAppeared: explanationButtonAppeared
                )
            } else {
                // Money Score View - matching chart container structure exactly
                ZStack {
                    // Content layer matching chart structure
                    ZStack {
                        // Invisible placeholder to match chart dimensions exactly
                        Color.clear
                            .frame(width: chartWidth, height: lineHeight)
                            .padding(.vertical, 60)
                            .padding(.horizontal, 20)
                        
                        // Money Score content overlaid
                        MoneyScoreView(
                            score: calculateOverallScore(),
                            trend: determineScoreTrend(),
                            billManagementScore: calculateBillManagementScore(),
                            budgetManagementScore: calculateBudgetManagementScore(),
                            savingsRateScore: calculateSavingsRateScore(),
                            // expenseControlScore: calculateExpenseControlScore(),  // Commented out - needs categorization
                            stabilityScore: calculateStabilityScore()
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.horizontal)
                .scaleEffect(chartAppeared ? 1 : 0.9)
                .opacity(chartAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedView)
            }
        }
            .onAppear {
                animateElements()
                // Initialize voice agent with user ID and BillViewModel
                if voiceAgentViewModel == nil, let userId = sessionViewModel.currentUser?.userId {
                    voiceAgentViewModel = VoiceAgentViewModel(
                        userId: userId, 
                        billViewModel: billViewModel,
                        incomeViewModel: incomeViewModel,
                        sessionViewModel: sessionViewModel
                    )
                }
                
                // IMPORTANT: Check if dotsAppeared is already true on appear
                // This handles the race condition where dotsAppeared is true before the view appears
                if dotsAppeared && !incomeLabelAppeared {
                    print("📊 ExpenseTrackerRegularView: dotsAppeared is already true on appear, triggering labels immediately")
                    // Small delay to ensure view is properly laid out
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        triggerLabelAnimations()
                    }
                }
            }
            .onChange(of: voiceAgentViewModel?.currentState) { _, newState in
                // Hide voice mode overlay when session completes or errors, but keep it visible when paused
                switch newState {
                case .idle, .error:
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showVoiceMode = false
                    }
                case .paused, .waitingForResume:
                    // Keep overlay visible for paused states
                    break
                default:
                    break
                }
            }
            .sheet(isPresented: $showingIncomeDetail) {
                IncomeDetailView()
                    .environmentObject(profileViewModel)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onChange(of: dotsAppeared) { _, newValue in
                print("📊 ExpenseTrackerRegularView: dotsAppeared changed to \(newValue)")
                if newValue {
                    triggerLabelAnimations()
                } else {
                    // Reset when dotsAppeared becomes false
                    print("   🔄 Resetting label states")
                    incomeLabelAppeared = false
                    billsLabelAppeared = false
                    currentLabelAppeared = false
                }
            }
        }
    }
    
    private func animateElements() {
        withAnimation(.easeOut(duration: 0.4)) {
            headerAppeared = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                explanationButtonAppeared = true
            }
        }
    }
    
    // MARK: - Money Score Calculations
    
    private func calculateOverallScore() -> Int {
        // Average of 4 metric scores (Expense Control commented out pending implementation)
        let total = calculateBillManagementScore() +
                   calculateBudgetManagementScore() +
                   calculateSavingsRateScore() +
                   // calculateExpenseControlScore() + // Commented out - needs expense categorization
                   calculateStabilityScore()
        return total / 4
    }
    
    private func calculateBillManagementScore() -> Int {
        // Score based on bill payment status for current month
        // Get current month bills only
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        // Filter for active bills in current month
        let currentMonthBills = billViewModel.bills.filter { bill in
            // Skip inactive bills
            if bill.isActive == false { return false }
            
            // Check if bill's due date is in current month
            let billMonth = calendar.component(.month, from: bill.dueDate)
            let billYear = calendar.component(.year, from: bill.dueDate)
            
            return billMonth == currentMonth && billYear == currentYear
        }
        
        // If no bills this month, return minimal score (not penalizing)
        guard !currentMonthBills.isEmpty else { return 2 }
        
        // Calculate score based on payment status
        let paidBills = currentMonthBills.filter { $0.status == .paid }.count
        let overdueBills = currentMonthBills.filter { $0.status == .overdue }.count
        let totalBills = currentMonthBills.count
        
        // Start with percentage of paid bills
        let paidPercentage = (Double(paidBills) / Double(totalBills)) * 100
        
        // Deduct points for overdue bills (10 points per overdue bill)
        let overdueDeduction = Double(overdueBills) * 10
        
        // Calculate final score (minimum 0)
        let finalScore = max(0, paidPercentage - overdueDeduction)
        
        return Int(finalScore)
    }
    
    private func calculateBudgetManagementScore() -> Int {
        // Use actual budgets if available, otherwise return minimal score
        let activeBudgets = budgetViewModel.activeBudgets
        
        if activeBudgets.isEmpty {
            // Return 1% to indicate budgets aren't set up without tanking overall score
            return 1
        } else {
            return calculateRealBudgetScore(for: activeBudgets)
        }
    }
    
    // MARK: - Budget Score Helper Methods
    
    private func calculateRealBudgetScore(for budgets: [Budget]) -> Int {
        // Calculate base score from budgets within limit
        let budgetsWithinLimit = budgets.filter { $0.currentSpent <= $0.amount }
        let basePercentage = (Double(budgetsWithinLimit.count) / Double(budgets.count)) * 100
        
        // Calculate deductions for over-budget items
        let totalDeductions = budgets
            .filter { $0.currentSpent > $0.amount }
            .reduce(0) { total, budget in
                total + calculateBudgetOverageDeduction(budget: budget)
            }
        
        // Return final score (minimum 0)
        return max(0, Int(basePercentage) - totalDeductions)
    }
    
    private func calculateBudgetOverageDeduction(budget: Budget) -> Int {
        let overagePercentage = ((budget.currentSpent - budget.amount) / budget.amount) * 100
        
        switch overagePercentage {
        case 0...10:
            return 5
        case 10...25:
            return 10
        case 25...50:
            return 15
        default:
            return 20
        }
    }
    
    private func calculateSavingsRateScore() -> Int {
        // Score based on remaining amount vs 20% savings target
        guard incomeAmount > 0 else { return 0 }
        
        // Calculate remaining amount (expenses already include paid bills)
        // So we use: income - totalExpenses (which includes both paid bills and other expenses)
        let remainingAmount = incomeAmount - currentExpenseAmount
        
        // Target savings is 20% of income
        let targetSavings = incomeAmount * 0.20
        
        // If no target savings (edge case), return 0
        guard targetSavings > 0 else { return 0 }
        
        // Calculate ratio of actual remaining to target savings
        let savingsRatio = remainingAmount / targetSavings
        
        // Score based on how well they meet the 20% target
        if savingsRatio >= 1.0 {
            // Meeting or exceeding target = excellent (cap at 100)
            return min(100, Int(savingsRatio * 100))
        } else if savingsRatio >= 0.75 {
            // 75-100% of target = good
            return 80
        } else if savingsRatio >= 0.5 {
            // 50-75% of target = fair
            return 60
        } else if savingsRatio >= 0.25 {
            // 25-50% of target = needs improvement
            return 40
        } else if savingsRatio > 0 {
            // Some savings but less than 25% of target
            return 20
        } else {
            // No remaining money or negative
            return 0
        }
    }
    
    // Commented out pending expense categorization implementation
    /*
    private func calculateExpenseControlScore() -> Int {
        // Score based on expense patterns
        guard incomeAmount > 0 else { return 0 }
        let expenseRatio = currentExpenseAmount / incomeAmount
        
        if expenseRatio <= 0.6 { return 95 }
        else if expenseRatio <= 0.8 { return 75 }
        else if expenseRatio <= 1.0 { return 55 }
        else { return 35 }
    }
    */
    
    private func calculateStabilityScore() -> Int {
        // Score based on income to expense ratio for current month
        guard incomeAmount > 0 else { return 0 }
        
        // Calculate ratio: how many times income covers expenses
        let stabilityRatio = incomeAmount / max(currentExpenseAmount, 1)
        
        // Scoring thresholds:
        if stabilityRatio >= 1.5 {
            // Saving 33%+ of income (very stable)
            return 90
        } else if stabilityRatio >= 1.2 {
            // Saving 17-33% of income (good stability)
            return 70
        } else if stabilityRatio >= 1.0 {
            // Breaking even to 17% savings (okay)
            return 50
        } else {
            // Expenses exceed income (unstable)
            return 30
        }
    }
    
    private func determineScoreTrend() -> MoneyScoreView.TrendDirection {
        // Determine trend based on financial health
        guard incomeAmount > 0 else { return .stable }
        let savingsRate = (incomeAmount - currentExpenseAmount) / incomeAmount
        
        if savingsRate >= 0.15 {
            return .improving
        } else if savingsRate < 0 {
            return .declining
        } else {
            return .stable
        }
    }
    
    private func triggerLabelAnimations() {
        print("   🎯 Triggering label animations!")
        
        // Stagger the chart label animations with reliable timing
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            incomeLabelAppeared = true
            print("   💰 incomeLabelAppeared = true")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                billsLabelAppeared = true
                print("   📄 billsLabelAppeared = true")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                currentLabelAppeared = true
                print("   💳 currentLabelAppeared = true")
            }
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let billViewModel = BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let budgetViewModel = BudgetViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let incomeViewModel = IncomeViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    
    ExpenseTrackerRegularView(
        billAmount: 1500,
        currentExpenseAmount: 2800,
        incomeAmount: 3000,
        month: "December",
        isScrolling: false, chartAppeared: true,
        dotsAppeared: true,
        insightsAppeared: true
    )
    .environmentObject(profileViewModel)
    .environmentObject(sessionViewModel)
    .environmentObject(billViewModel)
    .environmentObject(budgetViewModel)
    .environmentObject(incomeViewModel)
    .preferredColorScheme(.light)
}
