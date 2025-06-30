//
//  SupabaseService+Profile.swift
//  Norma
//
//  Created by Claude on 6/29/25.
//

import Foundation
import Supabase

extension SupabaseService {
    
    // MARK: - Profile Methods
    
    /// Fetch user profile by user ID
    func fetchProfile(userId: String) async throws -> Profile? {
        let response: [Profile] = try await from("profiles")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return response.first
    }
    
    /// Create a new user profile
    func createProfile(_ profile: Profile) async throws -> Profile {
        let response: Profile = try await from("profiles")
            .insert(profile)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    /// Update existing user profile
    func updateProfile(_ profile: Profile) async throws -> Profile {
        let response: Profile = try await from("profiles")
            .update(profile)
            .eq("user_id", value: profile.userId)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    /// Delete user profile
    func deleteProfile(userId: String) async throws {
        try await from("profiles")
            .delete()
            .eq("user_id", value: userId)
            .execute()
    }
}