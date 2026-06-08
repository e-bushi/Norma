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

    func fetchBalances(userId: String) async throws -> [PlaidAccount] {
        let body = BalanceRequest(userId: userId)
        let response: BalanceResponse = try await post(path: "/api/balance", body: body)
        return response.accounts
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

        // Cortex authenticates every request with the Supabase JWT and derives
        // the user id from it server-side. getSession() returns a valid
        // (auto-refreshed) session, or throws if the user is signed out.
        let session = try await SupabaseService.shared.getSession()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
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
