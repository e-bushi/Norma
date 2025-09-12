//
//  VoiceAgent+Bills.swift
//  Norma
//
//  Created by Assistant on 12/6/25.
//

import Foundation

// MARK: - Bill Tools and Methods
extension VoiceAgentViewModel {
    
    // MARK: - Bill Tools Collection
    
    func getBillsTools() -> [AnthropicTool] {
        return [
            getBillCreationTool(), 
            getEditBillTool(),
            getDeleteBillTool(),
            getMarkBillPaidTool(),
            getEditIncomeTool(),
            getFinancialAnalysisTool(), 
            getEndConversationTool()
        ]
    }
    
    // MARK: - Bill Tool Definitions
    
    func getBillCreationTool() -> AnthropicTool {
        return AnthropicTool(
            name: "create_bill",
            description: "Create a new recurring bill for the user",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "name": AnthropicToolProperty(
                        type: "string",
                        description: "Name of the bill (e.g. 'Rent', 'Electric Bill')"
                    ),
                    "amount": AnthropicToolProperty(
                        type: "number",
                        description: "Monthly amount of the bill as a decimal number (e.g., 14.00, 99.99)"
                    ),
                    "due_date": AnthropicToolProperty(
                        type: "string",
                        description: "Due date in YYYY-MM-DD format"
                    ),
                    "frequency": AnthropicToolProperty(
                        type: "string",
                        description: "How often the bill occurs"
                    ),
                    "status": AnthropicToolProperty(
                        type: "string",
                        description: "Bill status: 'Paid', 'Overdue', or 'Scheduled'"
                    )
                ],
                required: ["name", "amount", "due_date", "frequency", "status"]
            )
        )
    }
    
    func getEditBillTool() -> AnthropicTool {
        return AnthropicTool(
            name: "edit_bill",
            description: "Modify an existing bill's properties (amount, due date, name, frequency)",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "bill_identifier": AnthropicToolProperty(
                        type: "string",
                        description: "Name or identifier of the bill to modify (e.g., 'rent', 'electric bill', 'Netflix')"
                    ),
                    "new_amount": AnthropicToolProperty(
                        type: "number",
                        description: "New amount for the bill (optional - only if user wants to change amount)"
                    ),
                    "new_name": AnthropicToolProperty(
                        type: "string",
                        description: "New name for the bill (optional - only if user wants to change name)"
                    ),
                    "new_due_date": AnthropicToolProperty(
                        type: "string",
                        description: "New due date in YYYY-MM-DD format (optional - only if user wants to change due date)"
                    ),
                    "new_frequency": AnthropicToolProperty(
                        type: "string",
                        description: "New frequency: 'Monthly', 'Quarterly', or 'Yearly' (optional - only if user wants to change frequency)"
                    )
                ],
                required: ["bill_identifier"]
            )
        )
    }
    
    func getDeleteBillTool() -> AnthropicTool {
        return AnthropicTool(
            name: "delete_bill",
            description: "Delete/remove an existing bill permanently",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "bill_identifier": AnthropicToolProperty(
                        type: "string",
                        description: "Name or identifier of the bill to delete (e.g., 'rent', 'electric bill', 'Netflix')"
                    ),
                    "confirmation": AnthropicToolProperty(
                        type: "boolean",
                        description: "User confirmation that they want to delete the bill"
                    )
                ],
                required: ["bill_identifier", "confirmation"]
            )
        )
    }
    
    func getMarkBillPaidTool() -> AnthropicTool {
        return AnthropicTool(
            name: "mark_bill_paid",
            description: "Mark a bill as paid or change its payment status",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "bill_identifier": AnthropicToolProperty(
                        type: "string",
                        description: "Name or identifier of the bill (e.g., 'rent', 'electric bill', 'Netflix')"
                    ),
                    "status": AnthropicToolProperty(
                        type: "string",
                        description: "New status: 'Paid', 'Overdue', or 'Scheduled'"
                    )
                ],
                required: ["bill_identifier", "status"]
            )
        )
    }
    
    // MARK: - Bill Execution Methods
    
    func executeBillCreation(input: [String: Any]) async -> String {
        print("VoiceAgent: Executing bill creation with input: \(input)")
        
        guard let billViewModel = billViewModel else {
            print("VoiceAgent: No BillViewModel available")
            return "Error: Unable to save bill - no bill manager available"
        }
        
        guard let name = input["name"] as? String,
              let dueDateString = input["due_date"] as? String,
              let frequencyString = input["frequency"] as? String,
              let statusString = input["status"] as? String else {
            return "Error: Missing required information (name, amount, due_date, frequency, or status)"
        }
        
        // Handle amount as either Int or Double
        let amount: Double
        if let doubleAmount = input["amount"] as? Double {
            amount = doubleAmount
        } else if let intAmount = input["amount"] as? Int {
            amount = Double(intAmount)
        } else {
            return "Error: Invalid amount format"
        }
        
        print("VoiceAgent: All required parameters found - name: \(name), amount: \(amount), due_date: \(dueDateString), frequency: \(frequencyString), status: \(statusString)")
        
        // Parse date with multiple formats
        let dueDate: Date
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate]
        
        if let parsedDate = isoFormatter.date(from: dueDateString) {
            dueDate = parsedDate
        } else {
            // Try alternative formats or provide a fallback
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            if let parsedDate = dateFormatter.date(from: dueDateString) {
                dueDate = parsedDate
            } else {
                print("VoiceAgent: Failed to parse date: \(dueDateString)")
                return "Error: Invalid date format. Expected YYYY-MM-DD"
            }
        }
        
        // Parse frequency
        let frequency: BillFrequency
        switch frequencyString.lowercased() {
        case "monthly":
            frequency = .monthly
        case "quarterly":
            frequency = .quarterly
        case "yearly", "annually":
            frequency = .yearly
        default:
            frequency = .monthly // Default to monthly
        }
        
        // Parse status
        let status: BillStatus
        switch statusString.lowercased() {
        case "paid":
            status = .paid
        case "overdue":
            status = .overdue
        case "scheduled":
            status = .scheduled
        default:
            status = .scheduled // Default to scheduled
        }
        
        print("VoiceAgent: Creating bill with parsed values - frequency: \(frequency), status: \(status)")
        
        // Create the bill
        let bill = Bill(
            id: UUID().uuidString,
            userId: userId,
            name: name,
            dueDate: dueDate,
            amount: amount,
            status: status,
            frequency: frequency
        )
        
        print("VoiceAgent: Bill object created, calling saveBill on BillViewModel...")
        
        // Save the bill
        _ = await billViewModel.addBill(
            name: bill.name,
            amount: bill.amount,
            dueDate: bill.dueDate,
            frequency: bill.frequency,
            status: bill.status
        )
        
        print("VoiceAgent: saveBill completed, error message: '\(billViewModel.errorMessage)'")
        
        // Check if there was an error during saving
        if billViewModel.errorMessage.isEmpty {
            let confirmationMessage = "Successfully created '\(name)' bill for \(String(format: "%.2f", amount)) due on \(formatDateForDisplay(dueDate))."
            
            // If the bill is overdue, add payment creation
            if status == .overdue {
                // Create an expense for the overdue bill payment
                if let expenseViewModel = expenseViewModel {
                    let expense = Expense(
                        id: UUID().uuidString,
                        userId: userId,
                        name: "\(name) payment",
                        amount: amount,
                        expenseDate: ISO8601DateFormatter().string(from: Date()),
                        billId: bill.id,
                        paymentMethod: .debitCard,
                        isRecurring: false
                    )
                    
                    _ = await expenseViewModel.addExpense(
                        name: expense.name,
                        amount: expense.amount,
                        expenseDate: expense.expenseDate,
                        billId: expense.billId,
                        paymentMethod: expense.paymentMethod,
                        isRecurring: expense.isRecurring
                    )
                    
                    if expenseViewModel.errorMessage.isEmpty {
                        return confirmationMessage + " The payment has also been recorded."
                    }
                }
            }
            
            return confirmationMessage
        } else {
            return "Error: Failed to save the bill. \(billViewModel.errorMessage)"
        }
    }
    
    func executeEditBill(input: [String: Any]) async -> String {
        print("VoiceAgent: Executing bill edit with input: \(input)")
        
        guard let billViewModel = billViewModel else {
            return "Error: Unable to edit bill - no bill manager available"
        }
        
        guard let billIdentifier = input["bill_identifier"] as? String else {
            return "Error: Missing bill identifier"
        }
        
        // Find the bill by name (case-insensitive)
        let bills = billViewModel.activeBills
        guard let existingBill = bills.first(where: { 
            $0.name.lowercased().contains(billIdentifier.lowercased()) 
        }) else {
            return "Error: Could not find a bill matching '\(billIdentifier)'. Please check the bill name."
        }
        
        // Get the changes to apply
        var updatedBill = existingBill
        var changes: [String] = []
        
        if let newAmount = input["new_amount"] as? Double {
            updatedBill.amount = newAmount
            changes.append("amount to \(String(format: "%.2f", newAmount))")
        }
        
        if let newName = input["new_name"] as? String {
            updatedBill.name = newName
            changes.append("name to '\(newName)'")
        }
        
        if let newDueDateString = input["new_due_date"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let newDueDate = formatter.date(from: newDueDateString) {
                updatedBill.dueDate = newDueDate
                changes.append("due date to \(formatDateForDisplay(newDueDate))")
            }
        }
        
        if let newFrequencyString = input["new_frequency"] as? String {
            let newFrequency: BillFrequency
            switch newFrequencyString.lowercased() {
            case "monthly":
                newFrequency = .monthly
            case "quarterly":
                newFrequency = .quarterly
            case "yearly", "annually":
                newFrequency = .yearly
            default:
                return "Error: Invalid frequency '\(newFrequencyString)'. Use 'Monthly', 'Quarterly', or 'Yearly'."
            }
            updatedBill.frequency = newFrequency
            changes.append("frequency to \(newFrequencyString)")
        }
        
        // Apply the changes
        if changes.isEmpty {
            return "No changes were specified for the bill."
        }
        
        await billViewModel.updateBill(updatedBill)
        
        // Check if there was an error during the update
        if billViewModel.errorMessage.isEmpty {
            let changesText = changes.joined(separator: ", ")
            return "Successfully updated '\(existingBill.name)' bill: changed \(changesText)."
        } else {
            return "Error: Failed to update the bill. \(billViewModel.errorMessage)"
        }
    }
    
    func executeDeleteBill(input: [String: Any]) async -> String {
        print("VoiceAgent: Executing bill deletion with input: \(input)")
        
        guard let billViewModel = billViewModel else {
            return "Error: Unable to delete bill - no bill manager available"
        }
        
        guard let billIdentifier = input["bill_identifier"] as? String,
              let confirmation = input["confirmation"] as? Bool else {
            return "Error: Missing bill identifier or confirmation"
        }
        
        guard confirmation else {
            return "Bill deletion cancelled - confirmation required to delete bills."
        }
        
        // Find the bill by name (case-insensitive)
        let bills = billViewModel.activeBills
        guard let existingBill = bills.first(where: { 
            $0.name.lowercased().contains(billIdentifier.lowercased()) 
        }) else {
            return "Error: Could not find a bill matching '\(billIdentifier)'. Please check the bill name."
        }
        
        // Delete the bill
        await billViewModel.deleteBill(existingBill)
        
        // Check if there was an error during deletion
        if billViewModel.errorMessage.isEmpty {
            return "Successfully deleted '\(existingBill.name)' bill."
        } else {
            return "Error: Failed to delete the bill. \(billViewModel.errorMessage)"
        }
    }
    
    func executeMarkBillPaid(input: [String: Any]) async -> String {
        print("VoiceAgent: Executing mark bill paid with input: \(input)")
        
        guard let billViewModel = billViewModel else {
            return "Error: Unable to update bill status - no bill manager available"
        }
        
        guard let billIdentifier = input["bill_identifier"] as? String,
              let statusString = input["status"] as? String else {
            return "Error: Missing bill identifier or status"
        }
        
        // Find the bill by name (case-insensitive)
        let bills = billViewModel.activeBills
        guard let existingBill = bills.first(where: { 
            $0.name.lowercased().contains(billIdentifier.lowercased()) 
        }) else {
            return "Error: Could not find a bill matching '\(billIdentifier)'. Please check the bill name."
        }
        
        // Parse the new status
        let newStatus: BillStatus
        switch statusString.lowercased() {
        case "paid":
            newStatus = .paid
        case "overdue":
            newStatus = .overdue
        case "scheduled":
            newStatus = .scheduled
        default:
            return "Error: Invalid status '\(statusString)'. Use 'Paid', 'Overdue', or 'Scheduled'."
        }
        
        // Update the bill status
        var updatedBill = existingBill
        updatedBill.status = newStatus
        
        await billViewModel.updateBill(updatedBill)
        
        // Check if there was an error during the update
        if billViewModel.errorMessage.isEmpty {
            let statusText = statusString.lowercased() == "paid" ? "paid" : statusString.lowercased()
            
            // If marking as paid, also create an expense record
            if newStatus == .paid {
                if let expenseViewModel = expenseViewModel {
                    let expense = Expense(
                        id: UUID().uuidString,
                        userId: userId,
                        name: "\(existingBill.name) payment",
                        amount: existingBill.amount,
                        expenseDate: ISO8601DateFormatter().string(from: Date()),
                        billId: existingBill.id,
                        paymentMethod: .debitCard,
                        isRecurring: false
                    )
                    
                    _ = await expenseViewModel.addExpense(
                        name: expense.name,
                        amount: expense.amount,
                        expenseDate: expense.expenseDate,
                        billId: expense.billId,
                        paymentMethod: expense.paymentMethod,
                        isRecurring: expense.isRecurring
                    )
                    
                    if expenseViewModel.errorMessage.isEmpty {
                        return "Successfully marked '\(existingBill.name)' as \(statusText). The payment has been recorded."
                    } else {
                        return "Marked '\(existingBill.name)' as \(statusText), but couldn't record the payment."
                    }
                }
            }
            
            return "Successfully marked '\(existingBill.name)' as \(statusText)."
        } else {
            return "Error: Failed to update the bill status. \(billViewModel.errorMessage)"
        }
    }
    
    // MARK: - Bill Helper Methods
    
    func generateBillsGreeting(userName: String?) -> String {
        let greeting = userName != nil ? "Hi \(userName!), " : "Hi there, "
        return greeting + "I'm here to help you manage your bills. What would you like to do?"
    }
    
    private func determineBillCategory(name: String) -> String {
        let lowercasedName = name.lowercased()
        
        if lowercasedName.contains("rent") || lowercasedName.contains("mortgage") {
            return "Housing"
        } else if lowercasedName.contains("electric") || lowercasedName.contains("gas") || 
                  lowercasedName.contains("water") || lowercasedName.contains("utility") {
            return "Utilities"
        } else if lowercasedName.contains("internet") || lowercasedName.contains("cable") || 
                  lowercasedName.contains("phone") || lowercasedName.contains("mobile") {
            return "Communications"
        } else if lowercasedName.contains("insurance") {
            return "Insurance"
        } else if lowercasedName.contains("netflix") || lowercasedName.contains("spotify") || 
                  lowercasedName.contains("hulu") || lowercasedName.contains("subscription") {
            return "Entertainment"
        } else if lowercasedName.contains("car") || lowercasedName.contains("auto") {
            return "Transportation"
        } else {
            return "Other"
        }
    }
    
    private func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}