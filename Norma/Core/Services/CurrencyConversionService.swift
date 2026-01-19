//
//  CurrencyConversionService.swift
//  Norma
//
//  Created by Claude on 12/14/25.
//

import Foundation

// MARK: - Response Model

struct CurrencyConversionResponse: Codable {
    let amount: Double
    let fromCurrency: String
    let toCurrency: String
    let exchangeRate: Double
    let convertedValue: Double
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case amount
        case fromCurrency = "from_currency"
        case toCurrency = "to_currency"
        case exchangeRate = "exchange_rate"
        case convertedValue = "converted_value"
        case timestamp
    }
}

// MARK: - Request Model

struct CurrencyConversionRequest: Codable {
    let amount: Double
    let fromCurrency: String
    let toCurrency: String

    enum CodingKeys: String, CodingKey {
        case amount
        case fromCurrency = "from_currency"
        case toCurrency = "to_currency"
    }
}

// MARK: - Error Types

enum CurrencyConversionError: Error, LocalizedError {
    case invalidURL
    case encodingFailed
    case networkError(Error)
    case invalidResponse
    case decodingFailed(Error)
    case serverError(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .encodingFailed:
            return "Failed to encode request"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message ?? "Unknown error")"
        }
    }
}

// MARK: - Service

class CurrencyConversionService {
    static let shared = CurrencyConversionService()

    private let baseURL = "https://tafoviioqavefsyxskpo.supabase.co/functions/v1/currency-convert"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhZm92aWlvcWF2ZWZzeXhza3BvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3Njg5MjAsImV4cCI6MjA2NjM0NDkyMH0.t-fIKOWq4i0XLcOKOJtPYiQDfKRh6xgLWMaS3u_bZ5c"

    private init() {}

    /// Converts an amount from one currency to another using real-time exchange rates
    /// - Parameters:
    ///   - amount: The amount to convert
    ///   - from: The source currency code (e.g., "USD")
    ///   - to: The target currency code (e.g., "EUR")
    /// - Returns: A `CurrencyConversionResponse` containing the converted value and exchange rate
    func convert(amount: Double, from: String, to: String) async throws -> CurrencyConversionResponse {
        guard let url = URL(string: baseURL) else {
            throw CurrencyConversionError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = CurrencyConversionRequest(
            amount: amount,
            fromCurrency: from,
            toCurrency: to
        )

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw CurrencyConversionError.encodingFailed
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw CurrencyConversionError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CurrencyConversionError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8)
            throw CurrencyConversionError.serverError(
                statusCode: httpResponse.statusCode,
                message: errorMessage
            )
        }

        do {
            let conversionResponse = try JSONDecoder().decode(CurrencyConversionResponse.self, from: data)
            return conversionResponse
        } catch {
            throw CurrencyConversionError.decodingFailed(error)
        }
    }
}
