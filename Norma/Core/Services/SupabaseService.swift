//
//  SupabaseService.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//
//  Backend client for the dormant server integrations only — Plaid bank
//  sync, Deepgram voice, and share-extension receipt capture, each switched
//  off in FeatureFlags. The core app never touches it: all user data lives
//  on device.
//

import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()

    static let supabaseURLString = "https://tafoviioqavefsyxskpo.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhZm92aWlvcWF2ZWZzeXhza3BvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3Njg5MjAsImV4cCI6MjA2NjM0NDkyMH0.t-fIKOWq4i0XLcOKOJtPYiQDfKRh6xgLWMaS3u_bZ5c"

    private let client: SupabaseClient

    private init() {
        let supabaseURL = URL(string: Self.supabaseURLString)!
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: Self.supabaseAnonKey)
    }

    /// The current session, waiting for restoration on cold start.
    func getSession() async throws -> Session {
        try await client.auth.session
    }

    /// Query builder for the extensions in this folder.
    internal func from(_ table: String) -> PostgrestQueryBuilder {
        client.from(table)
    }
}
