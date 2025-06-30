//
//  ProfileViewModel.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var profile: Profile?
    @Published var financialHealthInsights: [FinancialHealthInsight] = []
    @Published var moneyPersonality: MoneyPersonality?
    
    // UI State
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isEditingProfile = false
    @Published var hasUnsavedChanges = false
    
    // Profile Form Data
    @Published var editableProfile: Profile?
    @Published var profileImageData: Data?
    
    // Financial Health
    @Published var overallHealthScore: Double = 0
    @Published var healthTrends: [HealthTrend] = []
    @Published var recommendations: [HealthRecommendation] = []
    
    // MARK: - Dependencies
    
    private let dataManager: DataManager
    private let sessionViewModel: SessionViewModel
    private let billViewModel: BillViewModel?
    private let expenseViewModel: ExpenseViewModel?
    private let budgetViewModel: BudgetViewModel?
    private let incomeViewModel: IncomeViewModel?
    
    // MARK: - Initialization
    
    init(
        dataManager: DataManager,
        sessionViewModel: SessionViewModel,
        billViewModel: BillViewModel? = nil,
        expenseViewModel: ExpenseViewModel? = nil,
        budgetViewModel: BudgetViewModel? = nil,
        incomeViewModel: IncomeViewModel? = nil
    ) {
        self.dataManager = dataManager
        self.sessionViewModel = sessionViewModel
        self.billViewModel = billViewModel
        self.expenseViewModel = expenseViewModel
        self.budgetViewModel = budgetViewModel
        self.incomeViewModel = incomeViewModel
        
        setupObservers()
        loadProfile()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe session user changes
        sessionViewModel.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                if user != nil {
                    self?.loadProfile()
                }
            }
            .store(in: &cancellables)
        
        // Observe profile changes in data manager
        dataManager.$profiles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] profiles in
                if let userId = self?.sessionViewModel.currentUser?.userId,
                   let userProfile = profiles.first(where: { $0.userId == userId }) {
                    self?.profile = userProfile
                    self?.editableProfile = userProfile
                }
            }
            .store(in: &cancellables)
        
        // Monitor changes to detect unsaved edits
        $editableProfile
            .combineLatest($profile)
            .sink { [weak self] editable, original in
                self?.hasUnsavedChanges = editable != original
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Data Loading
    
    func loadProfile() {
        guard let userId = sessionViewModel.currentUser?.userId else { return }
        
        isLoading = true
        clearError()
        
        Task {
            do {
                // For now, create a default profile if none exists
                if let existingProfile = dataManager.profiles.first(where: { $0.userId == userId }) {
                    profile = existingProfile
                    editableProfile = existingProfile
                } else {
                    // Create a default profile
                    let defaultProfile = Profile(
                        userId: userId,
                        email: sessionViewModel.currentUser?.email ?? "",
                        name: sessionViewModel.currentUser?.name ?? "User"
                    )
                    profile = defaultProfile
                    editableProfile = defaultProfile
                }
                await loadFinancialHealthData()
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func loadFinancialHealthData() async {
        await calculateFinancialHealth()
        await generateRecommendations()
    }
    
    // MARK: - Profile Management
    
    func updateProfile(_ updatedProfile: Profile) async {
        isLoading = true
        clearError()
        
        do {
            // For now, just update locally until DataManager methods are implemented
            if let index = dataManager.profiles.firstIndex(where: { $0.userId == updatedProfile.userId }) {
                dataManager.profiles[index] = updatedProfile
            } else {
                dataManager.profiles.append(updatedProfile)
            }
            profile = updatedProfile
            editableProfile = updatedProfile
            hasUnsavedChanges = false
            isEditingProfile = false
        } catch {
            showError("Failed to update profile: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func saveProfileChanges() async {
        guard let updatedProfile = editableProfile else { return }
        await updateProfile(updatedProfile)
    }
    
    func discardProfileChanges() {
        editableProfile = profile
        hasUnsavedChanges = false
        isEditingProfile = false
    }
    
    func updateProfileImage(_ imageData: Data) async {
        guard var currentProfile = profile else { return }
        
        isLoading = true
        clearError()
        
        do {
            // For now, store image data locally (would upload to storage in production)
            let imageUrl = "local://profile_image_\(currentProfile.userId)"
            currentProfile.profileImageUrl = imageUrl
            
            // Update profile locally
            await updateProfile(currentProfile)
        } catch {
            showError("Failed to update profile image: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Financial Health Analysis
    
    private func calculateFinancialHealth() async {
        guard let profile = profile else { return }
        
        var insights: [(insight: FinancialHealthInsight, category: HealthCategory)] = []
        var totalScore: Double = 0
        var scoreCount = 0
        
        // Income Stability (25% weight)
        if let incomeVM = incomeViewModel {
            let incomeStability = analyzeIncomeStability(incomeVM)
            insights.append((incomeStability, .incomeStability))
            totalScore += Double(incomeStability.score) * 0.25
            scoreCount += 1
        }
        
        // Expense Management (20% weight)
        if let expenseVM = expenseViewModel {
            let expenseManagement = analyzeExpenseManagement(expenseVM)
            insights.append((expenseManagement, .expenseManagement))
            totalScore += Double(expenseManagement.score) * 0.20
            scoreCount += 1
        }
        
        // Budget Adherence (20% weight)
        if let budgetVM = budgetViewModel {
            let budgetAdherence = analyzeBudgetAdherence(budgetVM)
            insights.append((budgetAdherence, .budgetAdherence))
            totalScore += Double(budgetAdherence.score) * 0.20
            scoreCount += 1
        }
        
        // Bill Payment Health (20% weight)
        if let billVM = billViewModel {
            let billPaymentHealth = analyzeBillPaymentHealth(billVM)
            insights.append((billPaymentHealth, .billPayment))
            totalScore += Double(billPaymentHealth.score) * 0.20
            scoreCount += 1
        }
        
        // Savings Rate (15% weight)
        let savingsRate = analyzeSavingsRate()
        insights.append((savingsRate, .savings))
        totalScore += Double(savingsRate.score) * 0.15
        scoreCount += 1
        
        await MainActor.run {
            financialHealthInsights = insights.map { $0.insight }
            overallHealthScore = scoreCount > 0 ? totalScore : 0
        }
    }
    
    private func analyzeIncomeStability(_ incomeVM: IncomeViewModel) -> FinancialHealthInsight {
        let recurringIncome = incomeVM.recurringIncomes.reduce(0) { $0 + $1.amount }
        let totalIncome = incomeVM.totalMonthlyIncome
        let stabilityRatio = totalIncome > 0 ? recurringIncome / totalIncome : 0
        
        let score = min(stabilityRatio * 100, 100)
        let status: HealthStatus = score >= 80 ? .excellent : score >= 60 ? .good : score >= 40 ? .fair : .poor
        
        return FinancialHealthInsight(
            userId: sessionViewModel.currentUser?.userId ?? "",
            score: Int(score),
            trend: score >= 70 ? .improving : .stable,
            psychologicalBarriers: score < 70 ? ["Income variability anxiety", "Financial instability fear"] : [],
            assessmentData: nil
        )
    }
    
    private func analyzeExpenseManagement(_ expenseVM: ExpenseViewModel) -> FinancialHealthInsight {
        let monthlyExpenses = expenseVM.totalExpenses
        let monthlyIncome = incomeViewModel?.totalMonthlyIncome ?? 0
        let expenseRatio = monthlyIncome > 0 ? (monthlyExpenses / monthlyIncome) * 100 : 100
        
        let score = max(100 - expenseRatio, 0)
        let status: HealthStatus = score >= 80 ? .excellent : score >= 60 ? .good : score >= 40 ? .fair : .poor
        
        return FinancialHealthInsight(
            userId: sessionViewModel.currentUser?.userId ?? "",
            score: Int(score),
            trend: score >= 70 ? .improving : .declining,
            psychologicalBarriers: score < 70 ? ["Overspending tendency", "Budget resistance"] : [],
            assessmentData: nil
        )
    }
    
    private func analyzeBudgetAdherence(_ budgetVM: BudgetViewModel) -> FinancialHealthInsight {
        let overBudgetCount = budgetVM.overBudgetItems.count
        let totalBudgets = budgetVM.activeBudgets.count
        let adherenceRate = totalBudgets > 0 ? Double(totalBudgets - overBudgetCount) / Double(totalBudgets) : 1.0
        
        let score = adherenceRate * 100
        let status: HealthStatus = score >= 90 ? .excellent : score >= 70 ? .good : score >= 50 ? .fair : .poor
        
        return FinancialHealthInsight(
            userId: sessionViewModel.currentUser?.userId ?? "",
            score: Int(score),
            trend: score >= 80 ? .improving : .stable,
            psychologicalBarriers: score < 80 ? ["Budget perfectionism", "Financial discipline struggles"] : [],
            assessmentData: nil
        )
    }
    
    private func analyzeBillPaymentHealth(_ billVM: BillViewModel) -> FinancialHealthInsight {
        let overdueBills = billVM.overdueBills.count
        let totalBills = billVM.activeBills.count
        let paymentHealth = totalBills > 0 ? Double(totalBills - overdueBills) / Double(totalBills) : 1.0
        
        let score = paymentHealth * 100
        let status: HealthStatus = score >= 95 ? .excellent : score >= 85 ? .good : score >= 70 ? .fair : .poor
        
        return FinancialHealthInsight(
            userId: sessionViewModel.currentUser?.userId ?? "",
            score: Int(score),
            trend: score >= 90 ? .improving : .declining,
            psychologicalBarriers: score < 90 ? ["Payment procrastination", "Organizational challenges"] : [],
            assessmentData: nil
        )
    }
    
    private func analyzeSavingsRate() -> FinancialHealthInsight {
        let monthlyIncome = incomeViewModel?.totalMonthlyIncome ?? 0
        let monthlyExpenses = expenseViewModel?.totalExpenses ?? 0
        let monthlySavings = monthlyIncome - monthlyExpenses
        let savingsRate = monthlyIncome > 0 ? (monthlySavings / monthlyIncome) * 100 : 0
        
        let score = min(max(savingsRate, 0), 100)
        let status: HealthStatus = score >= 20 ? .excellent : score >= 15 ? .good : score >= 10 ? .fair : .poor
        
        return FinancialHealthInsight(
            userId: sessionViewModel.currentUser?.userId ?? "",
            score: Int(score),
            trend: score >= 15 ? .improving : .stable,
            psychologicalBarriers: score < 15 ? ["Instant gratification tendency", "Savings resistance"] : [],
            assessmentData: nil
        )
    }
    
    // MARK: - Recommendations
    
    private func generateRecommendations() async {
        var recs: [HealthRecommendation] = []
        
        // Analyze each insight for recommendations
        for (index, insight) in financialHealthInsights.enumerated() {
            let status = getHealthStatus(from: insight.score)
            switch status {
            case .poor, .fair:
                // Determine category based on index
                let categories: [HealthCategory] = [.incomeStability, .expenseManagement, .budgetAdherence, .billPayment, .savings]
                let category = index < categories.count ? categories[index] : .incomeStability
                let recommendation = generateRecommendation(for: category)
                recs.append(recommendation)
            default:
                break
            }
        }
        
        // Add general recommendations based on overall score
        if overallHealthScore < 60 {
            recs.append(HealthRecommendation(
                title: "Financial Health Checkup",
                description: "Your overall financial health could use improvement. Consider reviewing all areas.",
                priority: .high,
                category: .general
            ))
        }
        
        await MainActor.run {
            recommendations = recs
        }
    }
    
    private func generateRecommendation(for category: HealthCategory) -> HealthRecommendation {
        switch category {
        case .incomeStability:
            return HealthRecommendation(
                title: "Improve Income Stability",
                description: "Consider creating multiple income streams or focusing on recurring income sources.",
                priority: .medium,
                category: .income
            )
        case .expenseManagement:
            return HealthRecommendation(
                title: "Reduce Monthly Expenses",
                description: "Review your spending patterns and identify areas where you can cut costs.",
                priority: .high,
                category: .expenses
            )
        case .budgetAdherence:
            return HealthRecommendation(
                title: "Improve Budget Discipline",
                description: "Set more realistic budgets and track spending more carefully.",
                priority: .medium,
                category: .budgets
            )
        case .billPayment:
            return HealthRecommendation(
                title: "Automate Bill Payments",
                description: "Set up automatic payments or calendar reminders to avoid late fees.",
                priority: .high,
                category: .bills
            )
        case .savings:
            return HealthRecommendation(
                title: "Increase Savings Rate",
                description: "Try to save at least 15-20% of your income for financial security.",
                priority: .high,
                category: .savings
            )
        }
    }
    
    // MARK: - Money Personality Analysis
    
    func analyzeMoneyPersonality() async {
        guard let expenseVM = expenseViewModel,
              let budgetVM = budgetViewModel else { return }
        
        // Analyze spending patterns, budget behavior, etc.
        let spendingPattern = analyzeSpendingPattern(expenseVM)
        let budgetingStyle = analyzeBudgetingStyle(budgetVM)
        let riskTolerance = analyzeRiskTolerance()
        
        let personalityType = determinePrimaryType(spendingPattern, budgetingStyle, riskTolerance)
        let personality = MoneyPersonality(
            userId: sessionViewModel.currentUser?.userId ?? "",
            category: personalityType.rawValue,
            primaryTrait: spendingPattern.rawValue,
            subconscious: riskTolerance.rawValue,
            patterns: [budgetingStyle.rawValue],
            strengths: getStrengthsFor(personalityType),
            growthAreas: getChallengesFor(personalityType),
            psychologicalBarriers: getBarriersFor(personalityType)
        )
        
        await MainActor.run {
            moneyPersonality = personality
        }
    }
    
    private func analyzeSpendingPattern(_ expenseVM: ExpenseViewModel) -> SpendingStyle {
        // Analyze expense patterns to determine spending style
        // This is a simplified version - in reality, you'd analyze more data
        let monthlyExpenses = expenseVM.totalExpenses
        let monthlyIncome = incomeViewModel?.totalMonthlyIncome ?? 0
        let spendingRatio = monthlyIncome > 0 ? monthlyExpenses / monthlyIncome : 0
        
        if spendingRatio > 0.8 {
            return .spender
        } else if spendingRatio < 0.5 {
            return .saver
        } else {
            return .balanced
        }
    }
    
    private func analyzeBudgetingStyle(_ budgetVM: BudgetViewModel) -> BudgetingStyle {
        let activeBudgetCount = budgetVM.activeBudgets.count
        let budgetAdherence = budgetVM.budgetPerformance.reduce(0) { $0 + $1.percentageUsed } / Double(max(budgetVM.budgetPerformance.count, 1))
        
        if activeBudgetCount > 5 && budgetAdherence < 90 {
            return .detailed
        } else if activeBudgetCount <= 2 {
            return .minimal
        } else {
            return .moderate
        }
    }
    
    private func analyzeRiskTolerance() -> RiskTolerance {
        // This would typically analyze investment patterns, emergency fund size, etc.
        // For now, we'll use a simplified heuristic
        // Get savings rate from the last insight (savings is always added last)
        let savingsRate = financialHealthInsights.last?.score ?? 0
        
        if savingsRate > 20 {
            return .conservative
        } else if savingsRate > 10 {
            return .moderate
        } else {
            return .aggressive
        }
    }
    
    private func determinePrimaryType(_ spending: SpendingStyle, _ budgeting: BudgetingStyle, _ risk: RiskTolerance) -> MoneyPersonalityType {
        // Simplified logic to determine personality type
        switch (spending, budgeting, risk) {
        case (.saver, _, .conservative):
            return .saver
        case (.spender, .minimal, _):
            return .spender
        case (_, .detailed, .conservative):
            return .planner
        case (.balanced, .moderate, .moderate):
            return .balanced
        default:
            return .balanced
        }
    }
    
    private func getStrengthsFor(_ type: MoneyPersonalityType) -> [String] {
        switch type {
        case .saver: return ["Disciplined saving", "Long-term thinking"]
        case .spender: return ["Enjoys life", "Takes opportunities"]
        case .planner: return ["Organized finances", "Goal-oriented"]
        case .balanced: return ["Flexible approach", "Balanced priorities"]
        }
    }
    
    private func getChallengesFor(_ type: MoneyPersonalityType) -> [String] {
        switch type {
        case .saver: return ["May be too restrictive", "Could miss opportunities"]
        case .spender: return ["Impulse control", "Long-term planning"]
        case .planner: return ["May be inflexible", "Over-planning tendency"]
        case .balanced: return ["Decision consistency", "Focus prioritization"]
        }
    }
    
    private func getBarriersFor(_ type: MoneyPersonalityType) -> [String] {
        switch type {
        case .saver: return ["Scarcity mindset", "Fear of spending"]
        case .spender: return ["Instant gratification", "Future discounting"]
        case .planner: return ["Perfectionism", "Analysis paralysis"]
        case .balanced: return ["Inconsistent habits", "Priority confusion"]
        }
    }
    
    private func getHealthStatus(from score: Int) -> HealthStatus {
        switch score {
        case 80...100: return .excellent
        case 60...79: return .good
        case 40...59: return .fair
        default: return .poor
        }
    }
    
    // MARK: - Error Handling
    
    private func clearError() {
        showError = false
        errorMessage = ""
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
        
        // Auto-hide error after 5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await MainActor.run {
                clearError()
            }
        }
    }
}

// MARK: - Supporting Types

struct HealthTrend: Identifiable {
    let id = UUID()
    let category: HealthCategory
    let scores: [Double]
    let dates: [Date]
    let trend: TrendDirection
}

enum TrendDirection {
    case improving
    case stable
    case declining
}

struct HealthRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: RecommendationPriority
    let category: RecommendationCategory
}

enum RecommendationPriority {
    case low
    case medium
    case high
}

enum RecommendationCategory {
    case general
    case income
    case expenses
    case budgets
    case bills
    case savings
}

// Additional enums needed by ProfileViewModel
enum HealthStatus {
    case excellent
    case good
    case fair
    case poor
}

enum HealthCategory {
    case incomeStability
    case expenseManagement
    case budgetAdherence
    case billPayment
    case savings
}

enum SpendingStyle: String {
    case saver = "Saver"
    case spender = "Spender"
    case balanced = "Balanced"
}

enum BudgetingStyle: String {
    case detailed = "Detailed"
    case moderate = "Moderate"
    case minimal = "Minimal"
}

enum RiskTolerance: String {
    case conservative = "Conservative"
    case moderate = "Moderate"
    case aggressive = "Aggressive"
}

enum MoneyPersonalityType: String {
    case saver = "Saver"
    case spender = "Spender"
    case planner = "Planner"
    case balanced = "Balanced"
}