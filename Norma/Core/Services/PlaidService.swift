//
//  PlaidService.swift
//  Norma
//
//  Created by Claude on 3/17/26.
//

import Foundation

class PlaidService: ObservableObject {
    static let shared = PlaidService()

    private let baseURL = "https://cortex-production-4bcf.up.railway.app"

    @Published var connectedAccounts: [PlaidAccount] = []
    @Published var isConnected: Bool = false
    @Published var institutionName: String?
    @Published var itemId: String?
    @Published var recurringOutflows: [RecurringStream] = []

    private init() {}

    // MARK: - Models

    struct PlaidAccount: Codable, Identifiable {
        let accountId: String
        let name: String
        let officialName: String?
        let mask: String?
        let type: String
        let subtype: String?
        let balances: PlaidBalances

        var id: String { accountId }

        enum CodingKeys: String, CodingKey {
            case accountId = "account_id"
            case name
            case officialName = "official_name"
            case mask
            case type
            case subtype
            case balances
        }
    }

    struct PlaidBalances: Codable {
        let available: Double?
        let current: Double?
        let isoCurrencyCode: String?

        enum CodingKeys: String, CodingKey {
            case available
            case current
            case isoCurrencyCode = "iso_currency_code"
        }
    }

    struct PlaidTransaction: Codable, Identifiable {
        let transactionId: String
        let accountId: String
        let merchantName: String?
        let name: String
        let amount: Double
        let date: String
        let authorizedDate: String?
        let pending: Bool
        let pendingTransactionId: String?
        let isoCurrencyCode: String?
        let logoUrl: String?
        let website: String?
        let personalFinanceCategory: PersonalFinanceCategory?

        var id: String { transactionId }

        enum CodingKeys: String, CodingKey {
            case transactionId = "transaction_id"
            case accountId = "account_id"
            case merchantName = "merchant_name"
            case name
            case amount
            case date
            case authorizedDate = "authorized_date"
            case pending
            case pendingTransactionId = "pending_transaction_id"
            case isoCurrencyCode = "iso_currency_code"
            case logoUrl = "logo_url"
            case website
            case personalFinanceCategory = "personal_finance_category"
        }
    }

    struct PersonalFinanceCategory: Codable {
        let primary: String?
        let detailed: String?
    }

    struct RecurringStream: Codable, Identifiable {
        let streamId: String
        let merchantName: String?
        let averageAmount: Double
        let frequency: String
        let lastDate: String?
        let predictedNextDate: String?
        let isActive: Bool
        let category: [String]?
        let description: String?
        let accountId: String?

        var id: String { streamId }

        enum CodingKeys: String, CodingKey {
            case streamId = "stream_id"
            case merchantName = "merchant_name"
            case averageAmount = "average_amount"
            case frequency
            case lastDate = "last_date"
            case predictedNextDate = "predicted_next_date"
            case isActive = "is_active"
            case category
            case description
            case accountId = "account_id"
        }
    }

    // MARK: - Request/Response Types

    private struct CreateLinkTokenRequest: Encodable {
        let userId: String

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
        }
    }

    private struct CreateLinkTokenResponse: Decodable {
        let linkToken: String

        enum CodingKeys: String, CodingKey {
            case linkToken = "link_token"
        }
    }

    private struct ExchangeTokenRequest: Encodable {
        let userId: String
        let publicToken: String
        let institutionName: String?

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case publicToken = "public_token"
            case institutionName = "institution_name"
        }
    }

    private struct ExchangeTokenResponse: Decodable {
        let success: Bool?
        let itemId: String?
        let error: String?

        enum CodingKeys: String, CodingKey {
            case success
            case itemId = "item_id"
            case error
        }
    }

    private struct BalanceRequest: Encodable {
        let userId: String

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
        }
    }

    private struct BalanceResponse: Decodable {
        let accounts: [PlaidAccount]
    }

    private struct TransactionsRequest: Encodable {
        let userId: String
        let startDate: String
        let endDate: String

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case startDate = "start_date"
            case endDate = "end_date"
        }
    }

    private struct TransactionsResponse: Decodable {
        let accounts: [PlaidAccount]?
        let transactions: [PlaidTransaction]
        let totalTransactions: Int?

        enum CodingKeys: String, CodingKey {
            case accounts
            case transactions
            case totalTransactions = "total_transactions"
        }
    }

    // MARK: - API

    func createLinkToken(userId: String) async throws -> String {
        let body = CreateLinkTokenRequest(userId: userId)
        let response: CreateLinkTokenResponse = try await post(path: "/api/create-link-token", body: body)
        return response.linkToken
    }

    func exchangeToken(userId: String, publicToken: String, institutionName: String? = nil) async throws -> String {
        let body = ExchangeTokenRequest(userId: userId, publicToken: publicToken, institutionName: institutionName)
        let response: ExchangeTokenResponse = try await post(path: "/api/exchange-token", body: body)

        if let error = response.error {
            throw PlaidError.serverMessage(error)
        }

        guard response.success == true, let itemId = response.itemId else {
            throw PlaidError.exchangeFailed
        }

        return itemId
    }

    func fetchRecurringTransactions(userId: String) async throws -> (outflows: [RecurringStream], inflows: [RecurringStream]) {
        struct RecurringResponse: Decodable {
            let outflowStreams: [RecurringStream]
            let inflowStreams: [RecurringStream]

            enum CodingKeys: String, CodingKey {
                case outflowStreams = "outflow_streams"
                case inflowStreams = "inflow_streams"
            }
        }

        let body = CreateLinkTokenRequest(userId: userId)
        let response: RecurringResponse = try await post(path: "/api/recurring-transactions", body: body)
        return (outflows: response.outflowStreams, inflows: response.inflowStreams)
    }

    func fetchBalances(userId: String) async throws -> [PlaidAccount] {
        let body = BalanceRequest(userId: userId)
        let response: BalanceResponse = try await post(path: "/api/balance", body: body)
        return response.accounts
    }

    func fetchTransactions(userId: String, startDate: String, endDate: String) async throws -> [PlaidTransaction] {
        let body = TransactionsRequest(userId: userId, startDate: startDate, endDate: endDate)
        let response: TransactionsResponse = try await post(path: "/api/transactions", body: body)
        return response.transactions
    }

    func disconnect(userId: String, itemId: String) async throws {
        struct DisconnectRequest: Encodable {
            let userId: String
            let itemId: String

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case itemId = "item_id"
            }
        }

        struct DisconnectResponse: Decodable {
            let success: Bool?
            let error: String?
        }

        let body = DisconnectRequest(userId: userId, itemId: itemId)
        let response: DisconnectResponse = try await post(path: "/api/disconnect", body: body)

        if let error = response.error {
            throw PlaidError.serverMessage(error)
        }

        // Clear local state
        await MainActor.run {
            connectedAccounts = []
            isConnected = false
            institutionName = nil
            self.itemId = nil
        }
    }

    // MARK: - Private

    private func post<T: Encodable, R: Decodable>(path: String, body: T) async throws -> R {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw PlaidError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlaidError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw PlaidError.serverError(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(R.self, from: data)
    }
}

// MARK: - Errors

enum PlaidError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case serverMessage(String)
    case exchangeFailed
    case linkTokenMissing

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Plaid API URL"
        case .invalidResponse:
            return "Invalid response from Plaid API"
        case .serverError(let statusCode):
            return "Plaid API error (status: \(statusCode))"
        case .serverMessage(let message):
            return message
        case .exchangeFailed:
            return "Failed to exchange token"
        case .linkTokenMissing:
            return "Link token missing from response"
        }
    }
}
