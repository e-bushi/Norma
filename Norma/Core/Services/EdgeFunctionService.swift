//
//  EdgeFunctionService.swift
//  Norma
//
//  Created by Claude on 2/6/26.
//
//  Service for calling Supabase Edge Functions
//  Handles encrypted data operations (create, update, migrate)
//

import Foundation
import Supabase
import CryptoKit

/// Service for interacting with Supabase Edge Functions
/// Handles all write operations that require server-side encryption
class EdgeFunctionService {
    private let client: SupabaseClient

    // Edge Function name - matches the deployed Supabase function
    private let encryptionFunctionName = "secure-data"

    init(client: SupabaseClient) {
        self.client = client
    }

    // MARK: - Request/Response Types

    /// Request payload for Edge Function
    struct EdgeFunctionRequest: Encodable {
        let action: String
        let table: String
        let data: [String: AnyCodable]
        let encryptionKey: String
        let userId: String
        let recordId: String?

        enum CodingKeys: String, CodingKey {
            case action
            case table
            case data
            case encryptionKey = "encryption_key"
            case userId = "user_id"
            case recordId = "record_id"
        }
    }

    /// Response from Edge Function
    struct EdgeFunctionResponse: Decodable {
        let success: Bool
        let id: String?
        let error: String?
    }

    /// Migration response from Edge Function
    struct MigrationResponse: Decodable {
        let success: Bool
        let migrated: MigratedCounts?
        let error: String?

        struct MigratedCounts: Decodable {
            let bills: Int
            let income: Int
            let budgets: Int
            let chatConversations: Int
            let profiles: Int

            enum CodingKeys: String, CodingKey {
                case bills
                case income
                case budgets
                case chatConversations = "chat_conversations"
                case profiles
            }
        }
    }

    /// Semantic search response from Edge Function
    struct SemanticSearchResponse: Decodable {
        let success: Bool
        let results: SearchResults?
        let error: String?

        struct SearchResults: Decodable {
            let bills: [String]
            let income: [String]
            let budgets: [String]
            let chatConversations: [String]
            let profiles: [String]

            enum CodingKeys: String, CodingKey {
                case bills
                case income
                case budgets
                case chatConversations = "chat_conversations"
                case profiles
            }
        }
    }

    // MARK: - Bill Operations

    /// Create a new bill via Edge Function (encrypts server-side)
    func createBill(_ bill: Bill, encryptionKey: SymmetricKey) async throws -> String {
        let keyData = bill.toEdgeFunctionData()

        let request = EdgeFunctionRequest(
            action: "create",
            table: "bills",
            data: keyData,
            encryptionKey: encryptionKey.base64Encoded,
            userId: bill.userId,
            recordId: nil
        )

        let response: EdgeFunctionResponse = try await invokeFunction(request)

        guard response.success, let id = response.id else {
            throw EdgeFunctionError.operationFailed(response.error ?? "Unknown error")
        }

        return id
    }

    /// Update an existing bill via Edge Function (encrypts server-side)
    func updateBill(_ bill: Bill, encryptionKey: SymmetricKey) async throws {
        guard let billId = bill.id else {
            throw EdgeFunctionError.missingId
        }

        let keyData = bill.toEdgeFunctionData()

        let request = EdgeFunctionRequest(
            action: "update",
            table: "bills",
            data: keyData,
            encryptionKey: encryptionKey.base64Encoded,
            userId: bill.userId,
            recordId: billId
        )

        let response: EdgeFunctionResponse = try await invokeFunction(request)

        guard response.success else {
            throw EdgeFunctionError.operationFailed(response.error ?? "Unknown error")
        }
    }

    // MARK: - Income Operations

    /// Create a new income via Edge Function (encrypts server-side)
    func createIncome(_ income: Income, encryptionKey: SymmetricKey) async throws -> String {
        let keyData = income.toEdgeFunctionData()

        let request = EdgeFunctionRequest(
            action: "create",
            table: "income",
            data: keyData,
            encryptionKey: encryptionKey.base64Encoded,
            userId: income.userId,
            recordId: nil
        )

        let response: EdgeFunctionResponse = try await invokeFunction(request)

        guard response.success, let id = response.id else {
            throw EdgeFunctionError.operationFailed(response.error ?? "Unknown error")
        }

        return id
    }

    /// Update an existing income via Edge Function (encrypts server-side)
    func updateIncome(_ income: Income, encryptionKey: SymmetricKey) async throws {
        guard let incomeId = income.id else {
            throw EdgeFunctionError.missingId
        }

        let keyData = income.toEdgeFunctionData()

        let request = EdgeFunctionRequest(
            action: "update",
            table: "income",
            data: keyData,
            encryptionKey: encryptionKey.base64Encoded,
            userId: income.userId,
            recordId: incomeId
        )

        let response: EdgeFunctionResponse = try await invokeFunction(request)

        guard response.success else {
            throw EdgeFunctionError.operationFailed(response.error ?? "Unknown error")
        }
    }

    // MARK: - Chat Conversation Operations

    /// Create a new chat conversation via Edge Function (encrypts server-side)
    func createChatConversation(_ conversation: ChatConversation, encryptionKey: SymmetricKey) async throws -> String {
        let keyData = conversation.toEdgeFunctionData()

        let request = EdgeFunctionRequest(
            action: "create",
            table: "chat_conversations",
            data: keyData,
            encryptionKey: encryptionKey.base64Encoded,
            userId: conversation.userId,
            recordId: nil
        )

        let response: EdgeFunctionResponse = try await invokeFunction(request)

        guard response.success, let id = response.id else {
            throw EdgeFunctionError.operationFailed(response.error ?? "Unknown error")
        }

        return id
    }

    /// Update an existing chat conversation via Edge Function (encrypts server-side)
    func updateChatConversation(_ conversation: ChatConversation, encryptionKey: SymmetricKey) async throws {
        guard let conversationId = conversation.id else {
            throw EdgeFunctionError.missingId
        }

        let keyData = conversation.toEdgeFunctionData()

        let request = EdgeFunctionRequest(
            action: "update",
            table: "chat_conversations",
            data: keyData,
            encryptionKey: encryptionKey.base64Encoded,
            userId: conversation.userId,
            recordId: conversationId
        )

        let response: EdgeFunctionResponse = try await invokeFunction(request)

        guard response.success else {
            throw EdgeFunctionError.operationFailed(response.error ?? "Unknown error")
        }
    }

    // MARK: - Profile Operations

    /// Create a new profile via Edge Function (encrypts server-side)
    func createProfile(_ profile: Profile, encryptionKey: SymmetricKey) async throws -> String {
        let keyData = profile.toEdgeFunctionData()

        let request = EdgeFunctionRequest(
            action: "create",
            table: "profiles",
            data: keyData,
            encryptionKey: encryptionKey.base64Encoded,
            userId: profile.userId,
            recordId: nil
        )

        let response: EdgeFunctionResponse = try await invokeFunction(request)

        guard response.success, let id = response.id else {
            throw EdgeFunctionError.operationFailed(response.error ?? "Unknown error")
        }

        return id
    }

    /// Update an existing profile via Edge Function (encrypts server-side)
    func updateProfile(_ profile: Profile, encryptionKey: SymmetricKey) async throws {
        guard let profileId = profile.id else {
            throw EdgeFunctionError.missingId
        }

        let keyData = profile.toEdgeFunctionData()

        let request = EdgeFunctionRequest(
            action: "update",
            table: "profiles",
            data: keyData,
            encryptionKey: encryptionKey.base64Encoded,
            userId: profile.userId,
            recordId: profileId
        )

        let response: EdgeFunctionResponse = try await invokeFunction(request)

        guard response.success else {
            throw EdgeFunctionError.operationFailed(response.error ?? "Unknown error")
        }
    }

    // MARK: - Migration

    /// Migrate all existing plaintext data to encrypted format
    func migrateAllData(userId: String, encryptionKey: SymmetricKey) async throws -> MigrationResponse.MigratedCounts {
        struct MigrationRequest: Encodable {
            let action: String
            let encryptionKey: String
            let userId: String

            enum CodingKeys: String, CodingKey {
                case action
                case encryptionKey = "encryption_key"
                case userId = "user_id"
            }
        }

        let request = MigrationRequest(
            action: "migrate",
            encryptionKey: encryptionKey.base64Encoded,
            userId: userId
        )

        let response: MigrationResponse = try await invokeFunction(request)

        guard response.success, let migrated = response.migrated else {
            throw EdgeFunctionError.operationFailed(response.error ?? "Migration failed")
        }

        return migrated
    }

    // MARK: - Semantic Search

    /// Perform semantic search across all user data
    /// Returns record IDs that match the query - caller will fetch and decrypt
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - query: The search query
    ///   - limit: Maximum number of results per table (default: 10000 = effectively unlimited)
    ///   - startDate: Optional start date filter (ISO format YYYY-MM-DD)
    ///   - endDate: Optional end date filter (ISO format YYYY-MM-DD)
    func semanticSearch(userId: String, query: String, limit: Int = 10000, startDate: String? = nil, endDate: String? = nil) async throws -> SemanticSearchResponse.SearchResults {
        struct SearchRequest: Encodable {
            let action: String
            let userId: String
            let query: String
            let limit: Int
            let startDate: String?
            let endDate: String?

            enum CodingKeys: String, CodingKey {
                case action
                case userId = "user_id"
                case query
                case limit
                case startDate = "start_date"
                case endDate = "end_date"
            }
        }

        let request = SearchRequest(
            action: "semantic_search",
            userId: userId,
            query: query,
            limit: limit,
            startDate: startDate,
            endDate: endDate
        )

        let response: SemanticSearchResponse = try await invokeFunction(request)

        guard response.success, let results = response.results else {
            throw EdgeFunctionError.operationFailed(response.error ?? "Semantic search failed")
        }

        return results
    }

    // MARK: - Private Helpers

    private func invokeFunction<T: Encodable, R: Decodable>(_ request: T) async throws -> R {
        do {
            let response: R = try await client.functions.invoke(
                encryptionFunctionName,
                options: .init(body: request)
            )
            return response
        } catch {
            throw EdgeFunctionError.invocationFailed(error.localizedDescription)
        }
    }
}

// MARK: - Errors

enum EdgeFunctionError: LocalizedError {
    case invocationFailed(String)
    case operationFailed(String)
    case missingId
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .invocationFailed(let message):
            return "Failed to invoke Edge Function: \(message)"
        case .operationFailed(let message):
            return "Edge Function operation failed: \(message)"
        case .missingId:
            return "Record ID is required for update operations"
        case .encodingFailed:
            return "Failed to encode data for Edge Function"
        }
    }
}

// MARK: - SymmetricKey Extension

extension SymmetricKey {
    /// Convert SymmetricKey to base64 string for sending to Edge Function
    var base64Encoded: String {
        withUnsafeBytes { Data($0).base64EncodedString() }
    }
}

// MARK: - Model Extensions for Edge Function Data
// Note: Uses AnyCodable from AnthropicModels.swift

extension Bill {
    /// Convert Bill to dictionary for Edge Function
    func toEdgeFunctionData() -> [String: AnyCodable] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var data: [String: AnyCodable] = [
            "name": AnyCodable(name),
            "amount": AnyCodable(amount),
            "due_date": AnyCodable(dateFormatter.string(from: dueDate)),
            "status": AnyCodable(status.rawValue),
            "frequency": AnyCodable(frequency.rawValue),
            "is_reminder_on": AnyCodable(isReminderOn)
        ]

        if let nextDueDate = nextDueDate {
            data["next_due_date"] = AnyCodable(dateFormatter.string(from: nextDueDate))
        }
        if let categoryId = categoryId {
            data["category_id"] = AnyCodable(categoryId)
        }
        if let merchant = merchant {
            data["merchant"] = AnyCodable(merchant)
        }
        if let reminderDays = reminderDays {
            data["reminder_days"] = AnyCodable(reminderDays)
        }
        if let notes = notes {
            data["notes"] = AnyCodable(notes)
        }
        if let isActive = isActive {
            data["is_active"] = AnyCodable(isActive)
        }

        return data
    }
}

extension Income {
    /// Convert Income to dictionary for Edge Function
    func toEdgeFunctionData() -> [String: AnyCodable] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var data: [String: AnyCodable] = [
            "name": AnyCodable(name),
            "amount": AnyCodable(amount),
            "frequency": AnyCodable(frequency.rawValue),
            "source": AnyCodable(source.rawValue),
            "next_date": AnyCodable(dateFormatter.string(from: nextDate)),
            "is_active": AnyCodable(isActive),
            "taxable": AnyCodable(taxable)
        ]

        if let endDate = endDate {
            data["end_date"] = AnyCodable(dateFormatter.string(from: endDate))
        }
        if let lastReceivedDate = lastReceivedDate {
            data["last_received_date"] = AnyCodable(dateFormatter.string(from: lastReceivedDate))
        }
        if let notes = notes {
            data["notes"] = AnyCodable(notes)
        }

        return data
    }
}

extension ChatConversation {
    /// Convert ChatConversation to dictionary for Edge Function
    func toEdgeFunctionData() -> [String: AnyCodable] {
        var data: [String: AnyCodable] = [:]

        if let title = title {
            data["title"] = AnyCodable(title)
        }

        // Encode messages as JSON string
        if let jsonData = try? JSONEncoder().encode(messages),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            data["messages"] = AnyCodable(jsonString)
        } else {
            data["messages"] = AnyCodable("[]")
        }

        return data
    }
}

extension Profile {
    /// Convert Profile to dictionary for Edge Function
    func toEdgeFunctionData() -> [String: AnyCodable] {
        var data: [String: AnyCodable] = [
            "email": AnyCodable(email),
            "name": AnyCodable(name)
        ]

        if let profileImageUrl = profileImageUrl {
            data["profile_image_url"] = AnyCodable(profileImageUrl)
        }
        if let monthlyIncome = monthlyIncome {
            data["monthly_income"] = AnyCodable(monthlyIncome)
        }
        if let freedomFund = freedomFund {
            data["freedom_fund"] = AnyCodable(freedomFund)
        }
        if let painPoint = painPoint {
            data["pain_point"] = AnyCodable(painPoint)
        }

        // Encode settings as JSON string
        if let jsonData = try? JSONEncoder().encode(settings),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            data["settings"] = AnyCodable(jsonString)
        }

        // Encode onboarding insights as JSON string
        if let insights = onboardingInsights,
           let jsonData = try? JSONEncoder().encode(insights),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            data["onboarding_insights"] = AnyCodable(jsonString)
        }

        return data
    }
}
