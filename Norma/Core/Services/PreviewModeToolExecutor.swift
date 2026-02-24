//
//  PreviewModeToolExecutor.swift
//  Norma
//
//  Created by Claude on 10/25/25.
//

import Foundation

@MainActor
class PreviewModeToolExecutor {
    private let previewModeViewModel: PreviewModeViewModel

    init(previewModeViewModel: PreviewModeViewModel) {
        self.previewModeViewModel = previewModeViewModel
    }

    func executeToolAndGetResult(toolId: String, name: String, input: [String: Any]) async -> (String, UIComponent?) {
        print("🔧 [PreviewMode] Executing tool: \(name)")
        print("📥 [PreviewMode] Input: \(input)")

        switch name {
        case "save_user_name":
            return handleSaveUserName(input: input)
        case "save_user_currency":
            return handleSaveUserCurrency(input: input)
        case "save_user_income":
            return handleSaveUserIncome(input: input)
        case "save_user_freedom_fund":
            return handleSaveUserFreedomFund(input: input)

        case "create_bill":
            return handleCreateBill(input: input)
        case "create_expense":
            return await handleCreateExpense(input: input)
        case "show_bills_tool":
            return handleShowBills(input: input)
        case "show_expenses_tool":
            return handleShowExpenses(input: input)
        case "show_save_progress_modal":
            return handleShowSaveProgressModal(input: input)
        case "show_days":
            return handleShowDays(input: input)
        case "show_arc_count":
            return handleShowArcCount(input: input)
        case "show_flow_state":
            return handleShowFlowState(input: input)
        case "show_arc_simulator":
            return handleShowArcSimulator(input: input)
        default:
            return ("Tool not supported in preview mode", nil)
        }
    }

    // MARK: - Onboarding Tools

    private func handleSaveUserName(input: [String: Any]) -> (String, UIComponent?) {
        guard let name = input["name"] as? String else {
            return ("Missing name parameter", nil)
        }

        previewModeViewModel.userName = name
        let uiComponent = UIComponent.actionConfirmation(
            icon: "person.fill",
            message: "Norma saved your name: \(name)",
            color: "NormaPastelTeal"
        )
        return ("User name saved as '\(name)'", uiComponent)
    }

    private func handleSaveUserCurrency(input: [String: Any]) -> (String, UIComponent?) {
        guard let currency = input["currency"] as? String else {
            return ("Missing currency parameter", nil)
        }

        previewModeViewModel.userCurrency = currency.uppercased()

        let uiComponent = UIComponent.actionConfirmation(
            icon: "dollarsign.circle.fill",
            message: "Norma saved your currency: \(currency.uppercased())",
            color: "NormaPastelPurple"
        )

        return ("User currency saved as '\(currency.uppercased())'.", uiComponent)
    }

    private func handleSaveUserIncome(input: [String: Any]) -> (String, UIComponent?) {
        // Handle income as either Int or Double
        let income: Double
        if let incomeDouble = input["income"] as? Double {
            income = incomeDouble
        } else if let incomeInt = input["income"] as? Int {
            income = Double(incomeInt)
        } else {
            return ("Missing or invalid income parameter", nil)
        }

        previewModeViewModel.userIncome = income

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = previewModeViewModel.userCurrency ?? "USD"
        formatter.maximumFractionDigits = 0
        let formattedIncome = formatter.string(from: NSNumber(value: income)) ?? "\(income)"

        let uiComponent = UIComponent.actionConfirmation(
            icon: "banknote.fill",
            message: "Norma saved your income: \(formattedIncome)",
            color: "NormaPastelTeal"
        )
        return ("Monthly income after taxes saved as \(income)", uiComponent)
    }

    private func handleSaveUserFreedomFund(input: [String: Any]) -> (String, UIComponent?) {
        // Handle freedom_fund as either Int or Double
        let freedomFund: Double
        if let fundDouble = input["freedom_fund"] as? Double {
            freedomFund = fundDouble
        } else if let fundInt = input["freedom_fund"] as? Int {
            freedomFund = Double(fundInt)
        } else {
            return ("Missing or invalid freedom_fund parameter", nil)
        }

        previewModeViewModel.userFreedomFund = freedomFund

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = previewModeViewModel.userCurrency ?? "USD"
        formatter.maximumFractionDigits = 0
        let formattedFund = formatter.string(from: NSNumber(value: freedomFund)) ?? "\(freedomFund)"

        let uiComponent = UIComponent.actionConfirmation(
            icon: "sparkles",
            message: "Norma saved your freedom fund: \(formattedFund)",
            color: "NormaPastelCoral"
        )
        return ("Freedom fund saved as \(freedomFund)", uiComponent)
    }

    // MARK: - Create Tools

    private func handleCreateBill(input: [String: Any]) -> (String, UIComponent?) {
        print("🔍 [CreateBill] Input received: \(input)")
        print("🔍 [CreateBill] name: \(input["name"] as? String ?? "nil")")
        print("🔍 [CreateBill] amount: \(input["amount"] ?? "nil") (type: \(type(of: input["amount"])))")
        print("🔍 [CreateBill] due_date: \(input["due_date"] as? String ?? "nil")")

        guard let name = input["name"] as? String,
              let dueDateString = input["due_date"] as? String else {
            print("🔍 [CreateBill] Guard failed - Missing name or due_date")
            return ("Missing required fields for bill creation", nil)
        }

        // Handle amount as either Int or Double
        let amount: Double
        if let amountDouble = input["amount"] as? Double {
            amount = amountDouble
        } else if let amountInt = input["amount"] as? Int {
            amount = Double(amountInt)
        } else {
            print("🔍 [CreateBill] Guard failed - Invalid amount type")
            return ("Missing or invalid amount parameter", nil)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let dueDate = dateFormatter.date(from: dueDateString) else {
            return ("Invalid date format", nil)
        }

        let frequency: BillFrequency = .monthly
        let status: BillStatus = .scheduled

        print("🔍 [CreateBill] ========== CREATING BILL ==========")
        print("🔍 [CreateBill] Name: \(name)")
        print("🔍 [CreateBill] Amount extracted: \(amount)")
        print("🔍 [CreateBill] Due date: \(dueDate)")

        let bill = Bill(
            id: UUID().uuidString,
            userId: "preview-mode-user",
            name: name,
            dueDate: dueDate,
            nextDueDate: Calendar.current.date(byAdding: .month, value: 1, to: dueDate),
            amount: amount,
            status: status,
            frequency: frequency,
            categoryId: input["category_id"] as? String,
            merchant: input["merchant"] as? String,
            isReminderOn: input["is_reminder_on"] as? Bool ?? false,
            reminderDays: input["reminder_days"] as? Int,
            notes: input["notes"] as? String
        )

        print("🔍 [CreateBill] Bill object created with amount: \(bill.amount)")
        print("🔍 [CreateBill] About to call addBill...")
        previewModeViewModel.addBill(bill)
        print("🔍 [CreateBill] addBill completed")
        print("🔍 [CreateBill] ======================================")

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = previewModeViewModel.userCurrency ?? "USD"
        formatter.maximumFractionDigits = 0
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"

        let uiComponent = UIComponent.actionConfirmation(
            icon: "doc.text.fill",
            message: "Norma created a bill: \(name) - \(formattedAmount)",
            color: "NormaPastelTeal"
        )
        return ("Bill '\(name)' created successfully for \(amount)", uiComponent)
    }

    private func handleCreateExpense(input: [String: Any]) async -> (String, UIComponent?) {
        guard let name = input["name"] as? String,
              let amount = input["amount"] as? Double,
              let expenseDate = input["expense_date"] as? String,
              let paymentMethodString = input["payment_method"] as? String else {
            return ("Missing required fields for expense creation", nil)
        }

        guard let paymentMethod = PaymentMethod(rawValue: paymentMethodString) else {
            return ("Invalid payment method", nil)
        }

        let expense = Expense(
            id: UUID().uuidString,
            userId: "preview-mode-user",
            name: name,
            amount: amount,
            expenseDate: expenseDate,
            budgetId: input["budget_id"] as? String,
            billId: input["bill_id"] as? String,
            paymentMethod: paymentMethod,
            isRecurring: input["is_recurring"] as? Bool ?? false,
            recurringFrequency: nil,
            merchant: input["merchant"] as? String,
            location: input["location"] as? String,
            tags: input["tags"] as? [String] ?? [],
            notes: input["notes"] as? String
        )

        previewModeViewModel.addExpense(expense)

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = previewModeViewModel.userCurrency ?? "USD"
        formatter.maximumFractionDigits = 0
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"

        let uiComponent = UIComponent.actionConfirmation(
            icon: "creditcard.fill",
            message: "Norma created an expense: \(name) - \(formattedAmount)",
            color: "NormaPastelCoral"
        )
        return ("Expense '\(name)' created successfully for \(amount)", uiComponent)
    }

    // MARK: - Show Tools

    private func handleShowBills(input: [String: Any]) -> (String, UIComponent?) {
        let billIdsString = input["bill_ids"] as? String ?? ""

        // If bill_ids is empty, show all bills
        let bills: [Bill]
        if billIdsString.trimmingCharacters(in: .whitespaces).isEmpty {
            bills = previewModeViewModel.bills
        } else {
            let billIds = billIdsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            bills = previewModeViewModel.bills.filter { bill in
                guard let billId = bill.id else { return false }
                return billIds.contains(billId)
            }
        }

        if bills.isEmpty {
            return ("No bills found", nil)
        }

        let currency = previewModeViewModel.userCurrency ?? "USD"
        let uiComponent = UIComponent.billCards(bills, currency: currency)
        return ("Showing \(bills.count) bill(s)", uiComponent)
    }

    private func handleShowExpenses(input: [String: Any]) -> (String, UIComponent?) {
        let expenseIdsString = input["expense_ids"] as? String ?? ""

        // If expense_ids is empty, show all expenses
        let expenses: [Expense]
        if expenseIdsString.trimmingCharacters(in: .whitespaces).isEmpty {
            expenses = previewModeViewModel.expenses
        } else {
            let expenseIds = expenseIdsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            expenses = previewModeViewModel.expenses.filter { expense in
                guard let expenseId = expense.id else { return false }
                return expenseIds.contains(expenseId)
            }
        }

        if expenses.isEmpty {
            return ("No expenses found", nil)
        }

        let currency = previewModeViewModel.userCurrency ?? "USD"
        let uiComponent = UIComponent.expenseCards(expenses, currency: currency)
        return ("Showing \(expenses.count) expense(s)", uiComponent)
    }

    // MARK: - Modal Tools

    private func handleShowSaveProgressModal(input: [String: Any]) -> (String, UIComponent?) {
        // Trigger the save progress modal to show
        previewModeViewModel.showSaveProgressModal = true
        return ("Save progress modal will be displayed", nil)
    }

    // MARK: - Arc Display Tools

    private func handleShowDays(input: [String: Any]) -> (String, UIComponent?) {
        // Get user's financial data
        guard let freedomFund = previewModeViewModel.userFreedomFund else {
            return ("Freedom fund not yet collected", nil)
        }

        let bills = previewModeViewModel.bills

        // Calculate daily burn
        let totalMonthlyBills = ArcCalculationService.calculateMonthlyBillsTotal(bills: bills)
        let dailyBurn = totalMonthlyBills / 30.0

        // Calculate days
        let days = dailyBurn > 0 ? Int(floor(freedomFund / dailyBurn)) : 0

        // Convert to human-scale time
        let humanScale = ArcCalculationService.convertDaysToHumanScale(days: days)

        // Return days count with human-scale description (no UI component, just text)
        return ("You have \(days) days - that's \(humanScale)", nil)
    }

    private func handleShowArcCount(input: [String: Any]) -> (String, UIComponent?) {
        // Check if arc_count parameter was provided (for showing example arcs)
        let displayArcCount: Double

        if let providedCount = input["arc_count"] as? Double {
            // Use the provided arc count directly
            displayArcCount = providedCount
        } else if let providedCountInt = input["arc_count"] as? Int {
            // Convert Int to Double
            displayArcCount = Double(providedCountInt)
        } else {
            // Calculate actual arc count from user's data
            guard let freedomFund = previewModeViewModel.userFreedomFund else {
                return ("Freedom fund not yet collected", nil)
            }

            let bills = previewModeViewModel.bills

            // Calculate arcs as decimal to show fractional progress
            displayArcCount = ArcCalculationService.calculateArcsDecimal(
                freedomFund: freedomFund,
                bills: bills
            )
        }

        // Create UI component with the arc count (either calculated or provided)
        let uiComponent = UIComponent.arcDisplay(displayArcCount)

        // Format the response - show decimal for fractional, whole number for >= 1
        let arcText: String
        if displayArcCount < 1 && displayArcCount > 0 {
            arcText = String(format: "%.1f arcs (%.0f%% to first arc)", displayArcCount, displayArcCount * 100)
        } else {
            let wholeArcs = Int(displayArcCount)
            arcText = "\(wholeArcs) arc\(wholeArcs == 1 ? "" : "s")"
        }
        return ("Displaying \(arcText)", uiComponent)
    }

    private func handleShowFlowState(input: [String: Any]) -> (String, UIComponent?) {
        guard let flowState = input["flow_state"] as? String else {
            return ("Missing flow_state parameter", nil)
        }

        // Validate the flow state value
        let validStates = ["In flow", "Stagnant", "Drifting"]
        guard validStates.contains(flowState) else {
            return ("Invalid flow_state. Must be 'In flow', 'Stagnant', or 'Drifting'", nil)
        }

        // Create UI component with the flow state
        let uiComponent = UIComponent.flowStateCapsule(flowState)

        // Format the response
        return ("Displaying flow state: \(flowState)", uiComponent)
    }

    // MARK: - Arc Simulator

    private func handleShowArcSimulator(input: [String: Any]) -> (String, UIComponent?) {
        guard let freedomFund = previewModeViewModel.userFreedomFund else {
            return ("Freedom fund not yet collected", nil)
        }

        let bills = previewModeViewModel.bills
        let totalMonthlyBills = ArcCalculationService.calculateMonthlyBillsTotal(bills: bills)
        let currentArcs = ArcCalculationService.calculateArcs(freedomFund: freedomFund, bills: bills)
        let currency = previewModeViewModel.userCurrency ?? "USD"

        let uiComponent = UIComponent.arcSimulatorCard(
            currentArcs: currentArcs,
            totalMonthlyBills: totalMonthlyBills,
            freedomFund: freedomFund,
            currency: currency
        )

        return ("Displaying arc simulator card. User has \(currentArcs) arcs with \(currency) \(String(format: "%.0f", freedomFund)) freedom fund and \(currency) \(String(format: "%.0f", totalMonthlyBills)) monthly bills.", uiComponent)
    }
}
