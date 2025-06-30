//
//  DataManager+Psychology.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

extension DataManager {
    
    // MARK: - Psychology Data Methods
    
    func fetchPsychologyData(userId: String) async throws {
        // let personality = try await supabaseService.fetchMoneyPersonality(userId: userId)
        // let healthInsight = try await supabaseService.fetchFinancialHealthInsight(userId: userId)
        
        // moneyPersonality = personality
        // financialHealthInsight = healthInsight
        
        print("Fetching psychology data for user: \(userId)")
    }
    
    func saveMoneyPersonality(_ personality: MoneyPersonality) async throws {
        moneyPersonality = personality
        hasUnsyncedChanges = true
        
        // try await supabaseService.saveMoneyPersonality(personality)
        
        print("Saved money personality: \(personality.category)")
    }
    
    func saveFinancialHealthInsight(_ insight: FinancialHealthInsight) async throws {
        financialHealthInsight = insight
        hasUnsyncedChanges = true
        
        // try await supabaseService.saveFinancialHealthInsight(insight)
        
        print("Saved financial health insight with score: \(insight.score)")
    }
    
    func updatePsychologicalHealth(score: Int, trend: FinancialHealthInsight.Trend) async throws {
        guard var insight = financialHealthInsight else {
            // Create new insight if none exists
            let newInsight = FinancialHealthInsight(
                userId: currentProfile?.userId ?? "",
                score: score,
                trend: trend,
                psychologicalBarriers: [],
                assessmentData: nil
            )
            try await saveFinancialHealthInsight(newInsight)
            return
        }
        
        // Update existing insight
        insight.score = score
        insight.trend = trend
        try await saveFinancialHealthInsight(insight)
    }
    
    // MARK: - Psychology Queries
    
    func hasCompletedPsychologicalAssessment() -> Bool {
        return moneyPersonality != nil
    }
    
    func getPsychologicalHealthScore() -> Int? {
        return financialHealthInsight?.score
    }
    
    func getPsychologicalHealthTrend() -> FinancialHealthInsight.Trend? {
        return financialHealthInsight?.trend
    }
    
    func shouldPromptForPsychologicalUpdate() -> Bool {
        guard let assessmentData = financialHealthInsight?.assessmentData,
              let lastAssessmentDateString = assessmentData.lastAssessmentDate,
              let lastAssessmentDate = ISO8601DateFormatter().date(from: lastAssessmentDateString) else {
            return true // No assessment data, should prompt
        }
        
        // Check if it's been more than 30 days since last assessment
        let daysSinceAssessment = Calendar.current.dateComponents([.day], 
                                                                 from: lastAssessmentDate, 
                                                                 to: Date()).day ?? 0
        
        return daysSinceAssessment >= 30
    }
    
    func getFinancialBehaviorInsights() -> [String] {
        var insights: [String] = []
        
        // Analyze spending patterns
        let monthlyExpenses = totalMonthlyExpenses
        let monthlyIncome = totalMonthlyIncome
        let savingsRate = monthlyIncome > 0 ? (monthlyIncome - monthlyExpenses) / monthlyIncome : 0
        
        if savingsRate < 0.1 {
            insights.append("Your savings rate is below 10%, which may indicate living paycheck to paycheck")
        } else if savingsRate > 0.3 {
            insights.append("Excellent savings rate of over 30% - you're building wealth effectively")
        }
        
        // Analyze budget adherence
        let overBudgetCategories = getOverBudgetCategories()
        if overBudgetCategories.count > 2 {
            insights.append("Multiple categories are over budget - consider reviewing your spending habits")
        }
        
        // Analyze bill payment patterns
        let overdueBills = getOverdueBills()
        if !overdueBills.isEmpty {
            insights.append("You have overdue bills - this might indicate cash flow challenges")
        }
        
        return insights
    }
    
    func generatePsychologicalSummary() -> String {
        guard let personality = moneyPersonality,
              let healthInsight = financialHealthInsight else {
            return "Complete your psychological assessment to receive personalized insights."
        }
        
        let trendEmoji = healthInsight.trend == .improving ? "📈" : 
                        healthInsight.trend == .declining ? "📉" : "➡️"
        
        return """
        You are \(personality.category) with a psychological health score of \(healthInsight.score)/100 \(trendEmoji).
        
        Your core belief: "\(personality.subconscious)"
        
        This shapes how you interact with money daily, influencing your spending and saving decisions.
        """
    }
}