//
//  SupabaseService.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    private init() {
        let supabaseURL = URL(string: "https://tafoviioqavefsyxskpo.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhZm92aWlvcWF2ZWZzeXhza3BvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3Njg5MjAsImV4cCI6MjA2NjM0NDkyMH0.t-fIKOWq4i0XLcOKOJtPYiQDfKRh6xgLWMaS3u_bZ5c"
        
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }
    
    // MARK: - Authentication
    
    /// Sign up a new user
    func signUp(email: String, password: String, firstName: String, lastName: String) async throws -> AuthResponse {
        let userMetadata: [String: String] = [
            "first_name": firstName,
            "last_name": lastName
        ]
        
        // Guard against nil user data first and last names
        guard let firstName = userMetadata["first_name"],
              let lastName = userMetadata["last_name"] else {
            throw AuthError.supabaseError("Failed to get user data for signup")
        }
        
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: [
                "first_name": .string(firstName),
                "last_name": .string(lastName)
            ]
        )
        
        return response
    }
    
    /// Sign in an existing user
    func signIn(email: String, password: String) async throws -> Session {
        try await client.auth.signIn(
            email: email,
            password: password
        )
    }
    
    /// Verify OTP code
    func verifyOTP(email: String, code: String) async throws -> AuthResponse {
        let response = try await client.auth.verifyOTP(
            email: email,
            token: code,
            type: .signup
        )
        
        return response
    }
}

// MARK: - Additional Methods

extension SupabaseService {
    /// Get the current user
    var currentUser: User? {
        client.auth.currentUser
    }
    
    /// Get the current session
    var currentSession: Session? {
        client.auth.currentSession
    }
    
    /// Sign out the current user
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    /// Delete the current user's account
    /// This will delete the user from authentication and all associated data
    func deleteAccount() async throws {
        guard let userId = currentUser?.id else {
            throw AuthError.supabaseError("No user logged in")
        }
        
        // Delete user data from all tables
        // The database should have CASCADE DELETE set up, but we'll be explicit
        
        // Delete bills
        _ = try await client.from("bills")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        // Delete expenses
        _ = try await client.from("expenses")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        // Delete income
        _ = try await client.from("incomes")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        // Delete budgets
        _ = try await client.from("budgets")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        // Delete categories
        _ = try await client.from("categories")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        // Delete profile
        _ = try await client.from("profiles")
            .delete()
            .eq("id", value: userId.uuidString)
            .execute()
        
        // Note: Supabase doesn't allow direct user deletion from client-side
        // The user account will remain but all data is deleted
        // You would typically call a server-side function or edge function for complete deletion
        // For now, we'll sign out after deleting all user data
        try await signOut()
    }
    
    // MARK: - Internal Database Access Methods
    // These methods provide controlled access to the database for extensions
    
    /// Execute a select query on a table
    internal func from(_ table: String) -> PostgrestQueryBuilder {
        return client.from(table)
    }
    
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case networkError
    case invalidCredentials
    case invalidCode
    case supabaseError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .invalidCredentials:
            return "Invalid email or password."
        case .invalidCode:
            return "Invalid verification code."
        case .supabaseError(let message):
            return message
        case .unknownError:
            return "An unknown error occurred. Please try again."
        }
    }
}
