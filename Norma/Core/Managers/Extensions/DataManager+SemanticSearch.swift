//
//  DataManager+SemanticSearch.swift
//  Norma
//
//  Created by Claude on 2/7/26.
//
//  Semantic search for finding relevant financial records based on user queries
//

import Foundation
import CryptoKit

extension DataManager {

    /// Results from semantic search - contains decrypted records relevant to the query
    struct SemanticSearchResults {
        let bills: [Bill]
        let income: [Income]

        var isEmpty: Bool {
            bills.isEmpty && income.isEmpty
        }

        var totalCount: Int {
            bills.count + income.count
        }
    }

    /// Perform semantic search to find records relevant to a user's question
    /// - Parameters:
    ///   - query: The user's question (e.g., "What's my Netflix bill?")
    ///   - limit: Maximum number of results per table (default: 10000 = effectively unlimited)
    ///   - startDate: Optional start date filter (ISO format YYYY-MM-DD)
    ///   - endDate: Optional end date filter (ISO format YYYY-MM-DD)
    /// - Returns: Decrypted records that semantically match the query
    func semanticSearch(query: String, limit: Int = 10000, startDate: String? = nil, endDate: String? = nil) async throws -> SemanticSearchResults {
        guard let userId = currentProfile?.userId else {
            throw EncryptionError.noEncryptionKeys
        }

        guard let masterKey = getCurrentMasterKey() else {
            throw EncryptionError.noEncryptionKeys
        }

        print("🔍 [SemanticSearch] Searching for: \"\(query)\" (startDate: \(startDate ?? "nil"), endDate: \(endDate ?? "nil"))")

        // Call Edge Function to get matching record IDs
        let searchResults = try await supabaseService.edgeFunctionService.semanticSearch(
            userId: userId,
            query: query,
            limit: limit,
            startDate: startDate,
            endDate: endDate
        )

        print("🔍 [SemanticSearch] Found IDs - Bills: \(searchResults.bills.count), Income: \(searchResults.income.count)")

        // Fetch and decrypt matching records
        async let matchingBills = fetchBillsByIds(searchResults.bills, masterKey: masterKey)
        async let matchingIncome = fetchIncomeByIds(searchResults.income, masterKey: masterKey)

        let bills = try await matchingBills
        let income = try await matchingIncome

        print("🔍 [SemanticSearch] Decrypted - Bills: \(bills.count), Income: \(income.count)")

        return SemanticSearchResults(
            bills: bills,
            income: income
        )
    }

    // MARK: - Private Fetch Methods

    private func fetchBillsByIds(_ ids: [String], masterKey: SymmetricKey) async throws -> [Bill] {
        guard !ids.isEmpty else { return [] }

        let encryptedBills = try await supabaseService.fetchBillsByIds(ids)
        return encryptedBills.compactMap { $0.toBill(using: masterKey) }
    }

    private func fetchIncomeByIds(_ ids: [String], masterKey: SymmetricKey) async throws -> [Income] {
        guard !ids.isEmpty else { return [] }

        // Income is not encrypted yet, so we return the fetched records directly
        return try await supabaseService.fetchIncomeByIds(ids)
    }
}
