//
//  EncryptableExpense.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//  Updated: 2/6/26 - Simplified for Edge Function encryption architecture
//

import Foundation
import CryptoKit

/// Represents expense data as stored in the database (encrypted)
/// - `name`, `amount`, `merchant`, `location`, `notes` contain encrypted ciphertext
/// - Use `toExpense(using:)` to decrypt for display
struct EncryptableExpense: Identifiable, Codable {
    var id: String?
    let userId: String

    // Encrypted fields (ciphertext strings)
    let name: String           // encrypted
    let amount: String         // encrypted (was numeric, now text for encryption)
    let merchant: String?      // encrypted
    let location: String?      // encrypted
    var notes: String?         // encrypted

    // Unencrypted fields (for server-side queries)
    let expenseDate: String
    let budgetId: String?
    let billId: String?
    let paymentMethod: PaymentMethod
    let isRecurring: Bool
    var recurringFrequency: ExpenseFrequency?
    let tags: [String]
    var createdAt: String?
    var updatedAt: String?
    var attachmentUrls: [String]
    var bankDetail: BankDetail?
    var source: String
    var pending: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case amount
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
        case bankDetail = "bank_detail"
        case source
        case pending
    }

    /// Decrypt and convert to Expense for display
    /// - Parameter masterKey: The user's master encryption key
    /// - Returns: Decrypted Expense, or nil if decryption fails
    func toExpense(using masterKey: SymmetricKey) -> Expense? {
        // Decrypt sensitive fields
        guard let decryptedName = EncryptionService.shared.decrypt(name, with: masterKey),
              let decryptedAmount = EncryptionService.shared.decryptAmount(amount, with: masterKey) else {
            return nil
        }

        // Decrypt optional fields
        let decryptedMerchant = merchant.flatMap { EncryptionService.shared.decrypt($0, with: masterKey) }
        let decryptedLocation = location.flatMap { EncryptionService.shared.decrypt($0, with: masterKey) }
        let decryptedNotes = notes.flatMap { EncryptionService.shared.decrypt($0, with: masterKey) }

        return Expense(
            id: id,
            userId: userId,
            name: decryptedName,
            amount: decryptedAmount,
            expenseDate: expenseDate,
            budgetId: budgetId,
            billId: billId,
            paymentMethod: paymentMethod,
            isRecurring: isRecurring,
            recurringFrequency: recurringFrequency,
            merchant: decryptedMerchant,
            location: decryptedLocation,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt,
            notes: decryptedNotes,
            attachmentUrls: attachmentUrls,
            bankDetail: bankDetail,
            source: source,
            pending: pending
        )
    }
}

extension EncryptableExpense {
    // Initializer for creating instances directly
    init(
        id: String? = nil,
        userId: String,
        name: String,
        amount: String,
        expenseDate: String,
        budgetId: String? = nil,
        billId: String? = nil,
        paymentMethod: PaymentMethod = .other,
        isRecurring: Bool = false,
        recurringFrequency: ExpenseFrequency? = nil,
        merchant: String? = nil,
        location: String? = nil,
        tags: [String] = [],
        createdAt: String? = nil,
        updatedAt: String? = nil,
        notes: String? = nil,
        attachmentUrls: [String] = [],
        bankDetail: BankDetail? = nil,
        source: String = "manual",
        pending: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.amount = amount
        self.expenseDate = expenseDate
        self.budgetId = budgetId
        self.billId = billId
        self.paymentMethod = paymentMethod
        self.isRecurring = isRecurring
        self.recurringFrequency = recurringFrequency
        self.merchant = merchant
        self.location = location
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
        self.attachmentUrls = attachmentUrls
        self.bankDetail = bankDetail
        self.source = source
        self.pending = pending
    }
}
