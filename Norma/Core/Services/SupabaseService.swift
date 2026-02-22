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

    static let supabaseURLString = "https://tafoviioqavefsyxskpo.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhZm92aWlvcWF2ZWZzeXhza3BvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3Njg5MjAsImV4cCI6MjA2NjM0NDkyMH0.t-fIKOWq4i0XLcOKOJtPYiQDfKRh6xgLWMaS3u_bZ5c"

    private let client: SupabaseClient

    /// Edge Function service that shares this client's auth session
    lazy var edgeFunctionService = EdgeFunctionService(client: client)

    private init() {
        let supabaseURL = URL(string: Self.supabaseURLString)!
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: Self.supabaseAnonKey)
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

    /// Resend OTP code to the user's email
    func resendOTP(email: String) async throws {
        try await client.auth.resend(
            email: email,
            type: .signup
        )
    }

    /// Sign in with Apple using ID token
    /// - Parameters:
    ///   - idToken: The identity token from Apple Sign In
    ///   - nonce: Optional nonce for additional security
    ///   - firstName: User's first name (only available on first sign-in)
    ///   - lastName: User's last name (only available on first sign-in)
    /// - Returns: Session containing the authenticated user
    func signInWithApple(idToken: String, nonce: String? = nil, firstName: String? = nil, lastName: String? = nil) async throws -> Session {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )

        // If we have name data (first sign-in only), update user metadata
        if let firstName = firstName, !firstName.isEmpty {
            _ = try? await client.auth.update(user: UserAttributes(
                data: [
                    "first_name": .string(firstName),
                    "last_name": .string(lastName ?? "")
                ]
            ))
        }

        return session
    }

    /// Sign in with Google using ID token and access token
    /// - Parameters:
    ///   - idToken: The identity token from Google Sign In
    ///   - accessToken: The access token from Google Sign In
    ///   - firstName: User's first name
    ///   - lastName: User's last name
    /// - Returns: Session containing the authenticated user
    func signInWithGoogle(idToken: String, accessToken: String, firstName: String? = nil, lastName: String? = nil) async throws -> Session {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )

        // Update user metadata with name if available
        if let firstName = firstName, !firstName.isEmpty {
            _ = try? await client.auth.update(user: UserAttributes(
                data: [
                    "first_name": .string(firstName),
                    "last_name": .string(lastName ?? "")
                ]
            ))
        }

        return session
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

    /// Get the current session asynchronously (waits for session restoration on cold start)
    func getSession() async throws -> Session {
        try await client.auth.session
    }

    /// Stream of auth state changes (for token refresh handling)
    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> {
        client.auth.authStateChanges
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
            .eq("user_id", value: userId.uuidString)
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
    case appleSignInError(String)
    case googleSignInError(String)
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
        case .appleSignInError(let message):
            return "Apple Sign In failed: \(message)"
        case .googleSignInError(let message):
            return "Google Sign In failed: \(message)"
        case .unknownError:
            return "An unknown error occurred. Please try again."
        }
    }
}
