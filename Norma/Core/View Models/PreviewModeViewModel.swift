//
//  PreviewModeViewModel.swift
//  Norma
//
//  Created by Claude on 10/25/25.
//

import Foundation
import SwiftUI

@MainActor
class PreviewModeViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var bills: [Bill] = []
    @Published var budgets: [Budget] = []
    @Published var expenses: [Expense] = []

    // Onboarding data
    @Published var userName: String?
    @Published var userCurrency: String?
    @Published var userIncome: Double?
    @Published var userSavings: Double?
    @Published var userChallenge: String?

    // Preview mode completion tracking
    @Published var hasAddedBill = false
    @Published var hasAddedBudget = false
    @Published var hasAddedExpense = false
    @Published var showCompletionModal = false

    // Real onboarding tracking
    @Published var showSaveProgressModal = false
    @Published var shouldShowCapsules = false
    @Published var isRealOnboarding = false

    // MARK: - Computed Properties

    var isPreviewModeComplete: Bool {
        hasAddedBill && hasAddedBudget && hasAddedExpense
    }

    var totalBills: Double {
        bills.reduce(0) { $0 + $1.amount }
    }

    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var budgetCount: Int {
        budgets.count
    }

    // Constants for tracking initial mock data
    private let initialBillsCount = 3
    private let initialBudgetsCount = 2
    private let initialExpensesCount = 3

    // Flag to track if mock data has been generated
    private var hasMockData = false

    // MARK: - Initialization

    init() {
        // Don't generate mock data until currency is set
    }

    // MARK: - Mock Data Generation

    private func generateMockData(exchangeRate: Double) {
        let mockUserId = "preview-mode-user"
        let calendar = Calendar.current
        let today = Date() 
        let dateFormatter = ISO8601DateFormatter()

        // Helper to convert USD amounts
        func convert(_ usdAmount: Double) -> Double {
            return round(usdAmount * exchangeRate * 100) / 100
        }

        // Helper to randomize amount within range
        func randomAmount(_ base: Double, variance: Double = 0.1) -> Double {
            let variation = base * variance
            let random = Double.random(in: -variation...variation)
            return convert(base + random)
        }

        // Get month boundaries
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        // MARK: - Generate 8-10 Bills with Date-Aware Status

        var mockBills: [Bill] = []

        // Helper to create bill with auto-status
        func createBill(name: String, dayOfMonth: Int, amount: Double, merchant: String, notes: String) -> Bill {
            let dueDate = calendar.date(bySetting: .day, value: dayOfMonth, of: startOfMonth)!
            let isPast = dueDate < today

            // Randomize if past bills are paid or overdue (70% paid, 30% overdue)
            let status: BillStatus = isPast ? (Double.random(in: 0...1) < 0.7 ? .paid : .overdue) : .scheduled

            let nextDueDate = calendar.date(byAdding: .month, value: 1, to: dueDate)!

            return Bill(
                id: UUID().uuidString,
                userId: mockUserId,
                name: name,
                dueDate: dueDate,
                nextDueDate: nextDueDate,
                amount: randomAmount(amount),
                status: status,
                frequency: .monthly,
                categoryId: nil,
                merchant: merchant,
                isReminderOn: true,
                reminderDays: 3,
                isActive: true,
                notes: notes
            )
        }

        // Essential bills (5)
        mockBills.append(createBill(name: "Rent", dayOfMonth: 1, amount: 1500, merchant: "Property Management LLC", notes: "Monthly rent payment"))
        mockBills.append(createBill(name: "Internet", dayOfMonth: 5, amount: 60, merchant: "Comcast", notes: "High-speed internet"))
        mockBills.append(createBill(name: "Electric Bill", dayOfMonth: 10, amount: 120, merchant: "City Power Company", notes: "Monthly electricity"))
        mockBills.append(createBill(name: "Phone", dayOfMonth: 15, amount: 50, merchant: "T-Mobile", notes: "Mobile phone plan"))
        mockBills.append(createBill(name: "Credit Card", dayOfMonth: 20, amount: 350, merchant: "Chase Bank", notes: "Minimum payment"))

        // Subscriptions (5 random from pool)
        let subscriptions = [
            ("Netflix", 14.99, "Netflix Inc.", "Streaming subscription"),
            ("Spotify", 10.99, "Spotify AB", "Music streaming"),
            ("Gym Membership", 45, "Planet Fitness", "Monthly gym access"),
            ("Cloud Storage", 9.99, "Google", "100GB storage"),
            ("Amazon Prime", 14.99, "Amazon", "Prime membership")
        ]

        let selectedSubscriptions = subscriptions.shuffled().prefix(Int.random(in: 3...5))
        for (index, (name, amount, merchant, notes)) in selectedSubscriptions.enumerated() {
            let day = [8, 12, 18, 22, 25][index]
            mockBills.append(createBill(name: name, dayOfMonth: day, amount: amount, merchant: merchant, notes: notes))
        }

        // MARK: - Generate 3-4 Budgets with Varying Progress

        var mockBudgets: [Budget] = []

        let allBudgets: [(String, Double, Double)] = [ // (name, amount, percentUsed)
            ("Food & Groceries", 500, Double.random(in: 0.75...0.95)), // Nearly maxed
            ("Entertainment", 200, Double.random(in: 0.40...0.60)),     // Medium
            ("Transportation", 300, Double.random(in: 0.20...0.35)),    // Low
            ("Shopping", 250, Double.random(in: 0.50...0.70))           // Medium-high
        ]
        let budgetConfigs = Array(allBudgets.shuffled().prefix(Int.random(in: 3...4)))

        for (name, baseAmount, percentUsed) in budgetConfigs {
            let amount = convert(baseAmount)
            let currentSpent = round(amount * percentUsed * 100) / 100

            mockBudgets.append(Budget(
                id: UUID().uuidString,
                userId: mockUserId,
                name: name,
                amount: amount,
                categoryId: nil,
                startDate: startOfMonth,
                endDate: endOfMonth,
                isActive: true,
                currentSpent: currentSpent,
                alertThreshold: 0.8,
                notes: "Monthly \(name.lowercased()) budget"
            ))
        }

        // MARK: - Generate Smart Expenses (Current Month Only, Up to Today)

        var mockExpenses: [Expense] = []

        // Calculate days from start of month to today
        let daysIntoMonth = calendar.dateComponents([.day], from: startOfMonth, to: today).day ?? 1

        // Generate 15-25 expenses spread across available days
        let expenseCount = Int.random(in: 15...25)
        let foodBudgetId = mockBudgets.first(where: { $0.name.contains("Food") })?.id
        let transportBudgetId = mockBudgets.first(where: { $0.name.contains("Transportation") })?.id
        let entertainmentBudgetId = mockBudgets.first(where: { $0.name.contains("Entertainment") })?.id

        let expenseTemplates: [(String, Double, Double, PaymentMethod, String?, [String])] = [
            // (name, minAmount, maxAmount, paymentMethod, budgetType, tags)
            ("Coffee", 3.5, 6.5, .creditCard, "Food", ["coffee", "food"]),
            ("Lunch", 10, 18, .creditCard, "Food", ["lunch", "food"]),
            ("Groceries", 40, 120, .creditCard, "Food", ["groceries", "food"]),
            ("Gas", 35, 55, .debitCard, "Transportation", ["gas", "transportation"]),
            ("Uber", 12, 25, .digitalWallet, "Transportation", ["rideshare", "transportation"]),
            ("Movie Tickets", 15, 30, .creditCard, "Entertainment", ["movies", "entertainment"]),
            ("Dinner Out", 40, 85, .creditCard, "Food", ["dining", "food"]),
            ("Snacks", 5, 12, .cash, nil, ["snacks", "food"]),
            ("Coffee Shop", 8, 15, .creditCard, "Food", ["coffee", "food"]),
            ("Fast Food", 8, 15, .creditCard, "Food", ["fast food", "food"])
        ]

        for _ in 0..<expenseCount {
            // Random day within current month up to today
            let daysAgo = Int.random(in: 0...max(0, daysIntoMonth - 1))
            let expenseDate = calendar.date(byAdding: .day, value: -daysAgo, to: today)!

            let template = expenseTemplates.randomElement()!
            let amount = randomAmount(Double.random(in: template.1...template.2), variance: 0.05)

            // Link to budget if applicable
            var budgetId: String? = nil
            if let budgetType = template.4 {
                if budgetType == "Food" {
                    budgetId = foodBudgetId
                } else if budgetType == "Transportation" {
                    budgetId = transportBudgetId
                } else if budgetType == "Entertainment" {
                    budgetId = entertainmentBudgetId
                }
            }

            mockExpenses.append(Expense(
                id: UUID().uuidString,
                userId: mockUserId,
                name: template.0,
                amount: amount,
                expenseDate: dateFormatter.string(from: expenseDate),
                budgetId: budgetId,
                billId: nil,
                paymentMethod: template.3,
                isRecurring: false,
                recurringFrequency: nil,
                merchant: nil,
                location: nil,
                tags: template.5,
                notes: nil
            ))
        }

        // Sort expenses by date (newest first)
        mockExpenses.sort { expense1, expense2 in
            guard let date1 = dateFormatter.date(from: expense1.expenseDate),
                  let date2 = dateFormatter.date(from: expense2.expenseDate) else {
                return false
            }
            return date1 > date2
        }

        // Set the mock data
        bills = mockBills
        budgets = mockBudgets
        expenses = mockExpenses
    }

    // Generate mock data only if not already generated
    func generateMockDataIfNeeded(exchangeRate: Double = 1.0) {
        guard !hasMockData else { return }
        hasMockData = true
        generateMockData(exchangeRate: exchangeRate)
    }

    // MARK: - Data Management

    func addBill(_ bill: Bill) {
        print("🔍 [ViewModel] ========== addBill CALLED ==========")
        print("🔍 [ViewModel] Bill ID: \(bill.id ?? "nil")")
        print("🔍 [ViewModel] Bill Name: \(bill.name)")
        print("🔍 [ViewModel] Bill Amount: \(bill.amount)")
        print("🔍 [ViewModel] Bills before: \(bills.count), Total: \(totalBills)")
        print("🔍 [ViewModel] Existing bills: \(bills.map { "\($0.name): \($0.amount)" }.joined(separator: ", "))")
        bills.append(bill)
        print("🔍 [ViewModel] Bills after: \(bills.count), Total: \(totalBills)")
        print("🔍 [ViewModel] All bills now: \(bills.map { "\($0.name): \($0.amount)" }.joined(separator: ", "))")
        print("🔍 [ViewModel] ==========================================")

        // Trigger capsules to show when first bill is added (on main thread)
        if bills.count == 1 && !shouldShowCapsules {
            Task { @MainActor in
                shouldShowCapsules = true
                print("🔍 [ViewModel] First bill added, triggering capsules to appear on main thread")
            }
        }

        checkForCompletion()
    }

    func addBudget(_ budget: Budget) {
        budgets.append(budget)
        checkForCompletion()
    }

    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        checkForCompletion()
    }

    func removeBill(_ bill: Bill) {
        bills.removeAll { $0.id == bill.id }
    }

    func removeBudget(_ budget: Budget) {
        budgets.removeAll { $0.id == budget.id }
    }

    func removeExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
    }

    // MARK: - Completion Tracking

    private func checkForCompletion() {
        // Check if user has added their own items (beyond the initial mock data)
        let userBillsCount = bills.count - initialBillsCount
        let userBudgetsCount = budgets.count - initialBudgetsCount
        let userExpensesCount = expenses.count - initialExpensesCount

        print("🔍 [Completion] Bills: \(bills.count) total, \(userBillsCount) user-added (initial: \(initialBillsCount))")
        print("🔍 [Completion] Budgets: \(budgets.count) total, \(userBudgetsCount) user-added (initial: \(initialBudgetsCount))")
        print("🔍 [Completion] Expenses: \(expenses.count) total, \(userExpensesCount) user-added (initial: \(initialExpensesCount))")

        if userBillsCount > 0 && !hasAddedBill {
            hasAddedBill = true
            print("🔍 [Completion] Marked hasAddedBill = true")
        }

        if userBudgetsCount > 0 && !hasAddedBudget {
            hasAddedBudget = true
            print("🔍 [Completion] Marked hasAddedBudget = true")
        }

        if userExpensesCount > 0 && !hasAddedExpense {
            hasAddedExpense = true
        }

        // Show completion modal when all requirements are met
        if isPreviewModeComplete && !showCompletionModal {
            showCompletionModal = true
        }
    }

    // MARK: - Reset

    func reset() {
        bills.removeAll()
        budgets.removeAll()
        expenses.removeAll()
        hasAddedBill = false
        hasAddedBudget = false
        hasAddedExpense = false
        showCompletionModal = false
        hasMockData = false
        isRealOnboarding = false  // Reset to preview mode
        generateMockDataIfNeeded()
    }

    // Clear mock data but keep name and currency for real onboarding
    func clearMockData() {
        bills.removeAll()
        budgets.removeAll()
        expenses.removeAll()
        hasAddedBill = false
        hasAddedBudget = false
        hasAddedExpense = false
        showCompletionModal = false
        hasMockData = false
        shouldShowCapsules = false
        isRealOnboarding = true  // Mark that we're in real onboarding mode
        // Don't regenerate mock data - user will add their own
    }
}
