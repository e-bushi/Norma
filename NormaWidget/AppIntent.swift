//
//  AppIntent.swift
//  NormaWidget
//
//  Created by Chris Mauldin on 8/19/25.
//

import WidgetKit
import AppIntents
import Foundation

// MARK: - Widget Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Norma Widget Configuration" }
    static var description: IntentDescription { "Configure your Norma financial widget display." }

    @Parameter(title: "Show AI Insights", default: true)
    var showAIInsights: Bool
    
    @Parameter(title: "Number of Bills to Show", default: 3, inclusiveRange: (1, 5))
    var numberOfBills: Int
}

// MARK: - Bill Management Intents

struct PayBillIntent: AppIntent {
    static var title: LocalizedStringResource { "Pay Bill in Norma" }
    static var description: IntentDescription { "Mark a bill as paid in Norma" }
    
    @Parameter(title: "Bill Name")
    var billName: String
    
    @Parameter(title: "Amount", default: 0.0)
    var amount: Double?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Pay \(\.$billName) bill") {
            \.$amount
        }
    }
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        do {
            let (expenseId, paymentAmount) = try await SharedDataService.shared.payBillFromIntent(
                billName: billName,
                amount: amount
            )
            
            let widgetManager = WidgetDataManager.shared
            let formattedAmount = widgetManager.formatCurrency(paymentAmount)
            
            return .result(
                value: "Paid",
                dialog: "Marked \(billName) as paid for \(formattedAmount) in ${applicationName}. The payment has been recorded and your bill status updated."
            )
        } catch {
            return .result(
                value: "Error",
                dialog: "Sorry, I couldn't pay \(billName) in ${applicationName}. \(error.localizedDescription)"
            )
        }
    }
}

struct MarkBillPaidIntent: AppIntent {
    static var title: LocalizedStringResource { "Tell ${applicationName} to Mark Bill as Paid" }
    static var description: IntentDescription { "Mark a specific bill as paid in ${applicationName}" }
    
    @Parameter(title: "Bill Name")
    var billName: String
    
    @Parameter(title: "Amount Paid", default: 0.0)
    var amountPaid: Double?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Tell ${applicationName} to mark \(\.$billName) as paid") {
            \.$amountPaid
        }
    }
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        do {
            let (expenseId, paymentAmount) = try await SharedDataService.shared.payBillFromIntent(
                billName: billName,
                amount: amountPaid
            )
            
            let widgetManager = WidgetDataManager.shared
            let formattedAmount = widgetManager.formatCurrency(paymentAmount)
            
            return .result(
                value: "Marked as Paid",
                dialog: "Marked \(billName) as paid for \(formattedAmount) in ${applicationName}."
            )
        } catch {
            return .result(
                value: "Error",
                dialog: "Sorry, I couldn't mark \(billName) as paid in ${applicationName}. \(error.localizedDescription)"
            )
        }
    }
}

struct ShowBillsIntent: AppIntent {
    static var title: LocalizedStringResource { "Ask ${applicationName} to Show Bills" }
    static var description: IntentDescription { "Show upcoming bills in ${applicationName}" }
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let widgetManager = WidgetDataManager.shared
        let bills = widgetManager.getUpcomingBills()
        
        guard !bills.isEmpty else {
            return .result(
                value: "No bills",
                dialog: "You don't have any upcoming bills in ${applicationName}."
            )
        }
        
        let billList = bills.prefix(5).map { bill in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            let dueDate = dateFormatter.string(from: bill.dueDate)
            return "\(bill.name): \(widgetManager.formatCurrency(bill.amount)) due \(dueDate)"
        }.joined(separator: ", ")
        
        let totalAmount = bills.prefix(5).reduce(0) { $0 + $1.amount }
        
        return .result(
            value: billList,
            dialog: "Your upcoming bills in ${applicationName}: \(billList). Total: \(widgetManager.formatCurrency(totalAmount))"
        )
    }
}

struct CheckBillDueDateIntent: AppIntent {
    static var title: LocalizedStringResource { "Ask ${applicationName} When Bill is Due" }
    static var description: IntentDescription { "Check when a specific bill is due in ${applicationName}" }
    
    @Parameter(title: "Bill Name")
    var billName: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Ask ${applicationName} when \(\.$billName) is due")
    }
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let widgetManager = WidgetDataManager.shared
        let bills = widgetManager.getUpcomingBills()
        
        guard let matchingBill = bills.first(where: { 
            $0.name.lowercased().contains(billName.lowercased()) 
        }) else {
            return .result(
                value: "Not found",
                dialog: "I couldn't find a bill named \(billName) in ${applicationName}."
            )
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dueDate = dateFormatter.string(from: matchingBill.dueDate)
        
        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: matchingBill.dueDate).day ?? 0
        
        let urgency: String
        if daysUntil < 0 {
            urgency = "overdue by \(abs(daysUntil)) days"
        } else if daysUntil == 0 {
            urgency = "due today"
        } else if daysUntil == 1 {
            urgency = "due tomorrow"
        } else {
            urgency = "due in \(daysUntil) days"
        }
        
        return .result(
            value: dueDate,
            dialog: "In Norma, \(matchingBill.name) is \(urgency) on \(dueDate) for $\(matchingBill.amount)."
        )
    }
}

struct ShowOverdueBillsIntent: AppIntent {
    static var title: LocalizedStringResource { "Ask ${applicationName} What Bills are Overdue" }
    static var description: IntentDescription { "Show overdue bills in ${applicationName}" }
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let widgetManager = WidgetDataManager.shared
        let bills = widgetManager.getUpcomingBills()
        
        let overdueBills = bills.filter { $0.status == .overdue }
        
        guard !overdueBills.isEmpty else {
            return .result(
                value: "None",
                dialog: "Great news! You don't have any overdue bills in Norma."
            )
        }
        
        let total = overdueBills.reduce(0) { $0 + $1.amount }
        let billNames = overdueBills.map { $0.name }.joined(separator: ", ")
        let formattedTotal = widgetManager.formatCurrency(total)
        
        return .result(
            value: billNames,
            dialog: "You have \(overdueBills.count) overdue bills in Norma totaling \(formattedTotal): \(billNames)"
        )
    }
}

// MARK: - Expense Tracking Intents

struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource { "Tell ${applicationName} to Add Expense" }
    static var description: IntentDescription { "Add a new expense to ${applicationName}" }
    
    @Parameter(title: "Amount")
    var amount: Double
    
    @Parameter(title: "Description")
    var expenseDescription: String
    
    @Parameter(title: "Category", default: "Other")
    var category: String?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Tell ${applicationName} to add expense \(\.$amount) for \(\.$expenseDescription)") {
            \.$category
        }
    }
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        do {
            let expenseId = try await SharedDataService.shared.createExpenseFromIntent(
                amount: amount,
                description: expenseDescription,
                category: category ?? "Other"
            )
            
            let widgetManager = WidgetDataManager.shared
            let formattedAmount = widgetManager.formatCurrency(amount)
            
            return .result(
                value: "Added",
                dialog: "Added \(formattedAmount) expense for \(expenseDescription) to ${applicationName}."
            )
        } catch {
            return .result(
                value: "Error",
                dialog: "Sorry, I couldn't add the expense to ${applicationName}. \(error.localizedDescription)"
            )
        }
    }
}

struct LogExpenseIntent: AppIntent {
    static var title: LocalizedStringResource { "Tell ${applicationName} I Paid" }
    static var description: IntentDescription { "Log a payment or expense in ${applicationName}" }
    
    @Parameter(title: "Amount")
    var amount: Double
    
    @Parameter(title: "Description")
    var expenseDescription: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Tell ${applicationName} I paid \(\.$amount) for \(\.$expenseDescription)")
    }
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        do {
            let expenseId = try await SharedDataService.shared.createExpenseFromIntent(
                amount: amount,
                description: expenseDescription,
                category: "Other"
            )
            
            return .result(
                value: "Logged",
                dialog: "Logged your $\(amount) payment for \(expenseDescription) in ${applicationName}."
            )
        } catch {
            return .result(
                value: "Error",
                dialog: "Sorry, I couldn't log your payment in ${applicationName}. \(error.localizedDescription)"
            )
        }
    }
}

struct CheckTodaysSpendingIntent: AppIntent {
    static var title: LocalizedStringResource { "Ask ${applicationName} How Much Spent Today" }
    static var description: IntentDescription { "Check today's spending in ${applicationName}" }
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let widgetManager = WidgetDataManager.shared
        let todaysSpending = widgetManager.getTodaysSpending()
        let formattedAmount = widgetManager.formatCurrency(todaysSpending)
        
        if todaysSpending == 0 {
            return .result(
                value: formattedAmount,
                dialog: "You haven't spent anything in ${applicationName} today. Great job staying on budget!"
            )
        } else if todaysSpending < 50 {
            return .result(
                value: formattedAmount,
                dialog: "You've spent \(formattedAmount) today in Norma. Looking good!"
            )
        } else {
            return .result(
                value: formattedAmount,
                dialog: "You've spent \(formattedAmount) today in Norma."
            )
        }
    }
}

struct CheckMonthlySpendingIntent: AppIntent {
    static var title: LocalizedStringResource { "Ask ${applicationName} Monthly Spending" }
    static var description: IntentDescription { "Check this month's spending in ${applicationName}" }
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let widgetManager = WidgetDataManager.shared
        let monthlySpending = widgetManager.getMonthlySpending()
        let monthlyBills = widgetManager.getMonthlyBills()
        let nonBillExpenses = monthlySpending - monthlyBills
        
        let formattedSpending = widgetManager.formatCurrency(monthlySpending)
        let formattedBills = widgetManager.formatCurrency(monthlyBills)
        let formattedNonBill = widgetManager.formatCurrency(nonBillExpenses)
        
        return .result(
            value: formattedSpending,
            dialog: "You've spent \(formattedSpending) this month in Norma: \(formattedBills) on bills and \(formattedNonBill) on other expenses."
        )
    }
}

struct CheckRemainingBudgetIntent: AppIntent {
    static var title: LocalizedStringResource { "Ask ${applicationName} Remaining Budget" }
    static var description: IntentDescription { "Check remaining budget in ${applicationName}" }
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let widgetManager = WidgetDataManager.shared
        let monthlyIncome = widgetManager.getMonthlyIncome()
        let monthlySpending = widgetManager.getMonthlySpending()
        let remaining = monthlyIncome - monthlySpending
        
        let formattedRemaining = widgetManager.formatCurrency(remaining)
        
        if remaining > 500 {
            return .result(
                value: formattedRemaining,
                dialog: "You have \(formattedRemaining) remaining in your Norma budget this month. You're doing great!"
            )
        } else if remaining > 0 {
            return .result(
                value: formattedRemaining,
                dialog: "You have \(formattedRemaining) remaining in your Norma budget this month. Be mindful of your spending."
            )
        } else if remaining == 0 {
            return .result(
                value: formattedRemaining,
                dialog: "You've exactly met your budget in ${applicationName} this month."
            )
        } else {
            let formattedOverAmount = widgetManager.formatCurrency(abs(remaining))
            return .result(
                value: formattedRemaining,
                dialog: "You're over budget by \(formattedOverAmount) in ${applicationName} this month. Consider reviewing your expenses."
            )
        }
    }
}

struct ShowTodaysExpensesIntent: AppIntent {
    static var title: LocalizedStringResource { "Ask ${applicationName} to Show Today's Expenses" }
    static var description: IntentDescription { "Show today's expenses in ${applicationName}" }
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let widgetManager = WidgetDataManager.shared
        let todaysSpending = widgetManager.getTodaysSpending()
        
        if todaysSpending == 0 {
            return .result(
                value: "No expenses",
                dialog: "You haven't recorded any expenses in ${applicationName} today."
            )
        } else {
            return .result(
                value: "$\(todaysSpending)",
                dialog: "Today's expenses in ${applicationName} total \(widgetManager.formatCurrency(todaysSpending)). Great job tracking your spending!"
            )
        }
    }
}

// MARK: - Financial Status Intents

struct FinancialSummaryIntent: AppIntent {
    static var title: LocalizedStringResource { "Ask ${applicationName} for Financial Summary" }
    static var description: IntentDescription { "Get a financial summary from Norma" }
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let widgetManager = WidgetDataManager.shared
        let income = widgetManager.getMonthlyIncome()
        let spending = widgetManager.getMonthlySpending()
        let bills = widgetManager.getMonthlyBills()
        let remaining = income - spending
        
        let percentUsed = income > 0 ? (spending / income * 100) : 0
        
        let statusEmoji = remaining > 0 ? "👍" : "⚠️"
        
        let formattedIncome = widgetManager.formatCurrency(income)
        let formattedSpending = widgetManager.formatCurrency(spending)
        let formattedRemaining = widgetManager.formatCurrency(remaining)
        let formattedPercent = String(format: "%.1f", percentUsed)
        
        return .result(
            value: "Income: \(formattedIncome), Spent: \(formattedSpending), Remaining: \(formattedRemaining)",
            dialog: "\(statusEmoji) Your Norma summary: Monthly income is \(formattedIncome). You've spent \(formattedSpending) (\(formattedPercent)%), with \(formattedRemaining) remaining."
        )
    }
}

struct CheckBudgetStatusIntent: AppIntent {
    static var title: LocalizedStringResource { "Ask ${applicationName} if On Budget" }
    static var description: IntentDescription { "Check if you're on budget in ${applicationName}" }
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> & ProvidesDialog {
        let widgetManager = WidgetDataManager.shared
        let income = widgetManager.getMonthlyIncome()
        let spending = widgetManager.getMonthlySpending()
        let remaining = income - spending
        
        let onBudget = remaining >= 0
        let formattedRemaining = widgetManager.formatCurrency(remaining)
        
        if remaining > 500 {
            return .result(
                value: onBudget,
                dialog: "Yes! You're well within budget in ${applicationName} with \(formattedRemaining) to spare. Keep up the great work!"
            )
        } else if remaining > 100 {
            return .result(
                value: onBudget,
                dialog: "Yes! You're on budget in ${applicationName} with \(formattedRemaining) remaining."
            )
        } else if remaining > 0 {
            return .result(
                value: onBudget,
                dialog: "Yes, you're technically on budget in ${applicationName}, but only \(formattedRemaining) remaining. Be careful with spending!"
            )
        } else {
            let formattedOverAmount = widgetManager.formatCurrency(abs(remaining))
            return .result(
                value: onBudget,
                dialog: "No, you're over budget by \(formattedOverAmount) in ${applicationName}. Time to review your expenses."
            )
        }
    }
}

struct BiggestExpenseIntent: AppIntent {
    static var title: LocalizedStringResource { "Ask ${applicationName} Biggest Expense" }
    static var description: IntentDescription { "Find biggest expense this month in ${applicationName}" }
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let widgetManager = WidgetDataManager.shared
        
        // For now, check biggest bill since we have that data readily available
        let bills = widgetManager.getUpcomingBills()
        
        guard !bills.isEmpty else {
            return .result(
                value: "None",
                dialog: "You don't have any expenses tracked in ${applicationName} yet this month."
            )
        }
        
        let biggestBill = bills.max(by: { $0.amount < $1.amount })!
        
        return .result(
            value: biggestBill.name,
            dialog: "Your biggest upcoming bill in ${applicationName} is \(biggestBill.name) at $\(biggestBill.amount)."
        )
    }
}

// MARK: - App Shortcuts Provider

struct NormaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckTodaysSpendingIntent(),
            phrases: [
                "How much did I spend today in \(.applicationName)",
                "What did I spend today in \(.applicationName)",
                "Show my spending today in \(.applicationName)",
                "Check today's expenses in \(.applicationName)",
                "Ask \(.applicationName) how much I've spent today",
                "Tell \(.applicationName) to show today's spending",
                "Check \(.applicationName) today's expenses"
            ],
            shortTitle: "Today's Spending",
            systemImageName: "dollarsign.circle"
        )
        
        AppShortcut(
            intent: CheckRemainingBudgetIntent(),
            phrases: [
                "Ask \(.applicationName) what's my remaining budget",
                "Tell \(.applicationName) to show my budget",
                "Check budget in \(.applicationName)",
                "What's left in my \(.applicationName) budget"
            ],
            shortTitle: "Remaining Budget",
            systemImageName: "chart.pie"
        )
        
        AppShortcut(
            intent: ShowBillsIntent(),
            phrases: [
                "Ask \(.applicationName) to show my bills",
                "Tell \(.applicationName) to list bills",
                "What bills do I have in \(.applicationName)",
                "Show my \(.applicationName) bills"
            ],
            shortTitle: "Show Bills",
            systemImageName: "doc.text"
        )
        
        AppShortcut(
            intent: PayBillIntent(),
            phrases: [
                "Pay my rent bill in \(.applicationName)",
                "Mark Netflix as paid in \(.applicationName)",
                "Pay electricity bill in \(.applicationName)",
                "Tell \(.applicationName) I paid my rent",
                "Tell \(.applicationName) to pay my electric bill",
                "Tell \(.applicationName) to pay my rent", 
                "Tell \(.applicationName) to pay Netflix"
            ],
            shortTitle: "Pay Bill",
            systemImageName: "creditcard"
        )
        
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Tell \(.applicationName) to add an expense",
                "Add expense to \(.applicationName)",
                "Log expense in \(.applicationName)",
                "Add a \(.applicationName) expense"
            ],
            shortTitle: "Add Expense",
            systemImageName: "plus.circle"
        )
        
        AppShortcut(
            intent: FinancialSummaryIntent(),
            phrases: [
                "Ask \(.applicationName) for my financial summary",
                "Tell \(.applicationName) to show my finances",
                "Get \(.applicationName) summary",
                "Show my \(.applicationName) finances"
            ],
            shortTitle: "Financial Summary",
            systemImageName: "chart.bar"
        )
        
        AppShortcut(
            intent: CheckBudgetStatusIntent(),
            phrases: [
                "Ask \(.applicationName) if I'm on budget",
                "Am I on budget in \(.applicationName)",
                "Check budget status in \(.applicationName)",
                "Check my \(.applicationName) budget status"
            ],
            shortTitle: "Budget Status",
            systemImageName: "checkmark.circle"
        )
    }
}
