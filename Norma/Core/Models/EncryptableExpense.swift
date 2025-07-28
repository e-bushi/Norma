//
//  EncryptableExpense.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import Foundation
import CryptoKit

// This model represents the raw data from the database that may or may not be encrypted
struct EncryptableExpense: Identifiable, Codable {
    var id: String?
    let userId: String
    
    // Original fields (for backward compatibility)
    let name: String
    let amount: Double
    
    // Encrypted fields (new)
    let encryptedName: String?
    let encryptedAmount: String?
    let isEncrypted: Bool
    
    // Other fields (remain unencrypted)
    let expenseDate: String
    let budgetId: String?
    let billId: String?
    let paymentMethod: PaymentMethod
    let isRecurring: Bool
    var recurringFrequency: ExpenseFrequency?
    let merchant: String?
    let location: String?
    let tags: [String]
    var createdAt: String?
    var updatedAt: String?
    var notes: String?
    var attachmentUrls: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case amount
        case encryptedName = "encrypted_name"
        case encryptedAmount = "encrypted_amount"
        case isEncrypted = "is_encrypted"
        case expenseDate = "expense_date"
        case budgetId = "budget_id"
        case billId = "bill_id"
        case paymentMethod = "payment_method"
        case isRecurring = "is_recurring"
        case recurringFrequency = "recurring_frequency"
        case merchant
        case location
        case tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case notes
        case attachmentUrls = "attachment_urls"
    }
    
    // Convert to regular Expense for display (decrypting if necessary)
    func toExpense(using masterKey: SymmetricKey?) -> Expense? {
        let displayName: String
        let displayAmount: Double
        
        if isEncrypted {
            // Decrypt the data
            guard let key = masterKey,
                  let encryptedName = encryptedName,
                  let encryptedAmount = encryptedAmount,
                  let decryptedName = EncryptionService.shared.decrypt(encryptedName, with: key),
                  let decryptedAmount = EncryptionService.shared.decryptAmount(encryptedAmount, with: key) else {
                return nil
            }
            displayName = decryptedName
            displayAmount = decryptedAmount
        } else {
            // Use plain data
            displayName = name
            displayAmount = amount
        }
        
        return Expense(
            id: id,
            userId: userId,
            name: displayName,
            amount: displayAmount,
            expenseDate: expenseDate,
            budgetId: budgetId,
            billId: billId,
            paymentMethod: paymentMethod,
            isRecurring: isRecurring,
            recurringFrequency: recurringFrequency,
            merchant: merchant,
            location: location,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt,
            notes: notes,
            attachmentUrls: attachmentUrls
        )
    }
}

// Extension to create EncryptableExpense from regular Expense
extension Expense {
    func toEncryptable(encrypt: Bool = false, using masterKey: SymmetricKey? = nil) -> EncryptableExpense? {
        if encrypt {
            guard let key = masterKey,
                  let encryptedName = EncryptionService.shared.encrypt(name, with: key),
                  let encryptedAmount = EncryptionService.shared.encryptAmount(amount, with: key) else {
                return nil
            }
            
            return EncryptableExpense(
                id: id,
                userId: userId,
                name: name, // Keep original for migration purposes
                amount: amount, // Keep original for migration purposes
                encryptedName: encryptedName,
                encryptedAmount: encryptedAmount,
                isEncrypted: true,
                expenseDate: expenseDate,
                budgetId: budgetId,
                billId: billId,
                paymentMethod: paymentMethod,
                isRecurring: isRecurring,
                recurringFrequency: recurringFrequency,
                merchant: merchant,
                location: location,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
                notes: notes,
                attachmentUrls: attachmentUrls
            )
        } else {
            // Create unencrypted version
            return EncryptableExpense(
                id: id,
                userId: userId,
                name: name,
                amount: amount,
                encryptedName: nil,
                encryptedAmount: nil,
                isEncrypted: false,
                expenseDate: expenseDate,
                budgetId: budgetId,
                billId: billId,
                paymentMethod: paymentMethod,
                isRecurring: isRecurring,
                recurringFrequency: recurringFrequency,
                merchant: merchant,
                location: location,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
                notes: notes,
                attachmentUrls: attachmentUrls
            )
        }
    }
}
