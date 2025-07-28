//
//  SupabaseService+Profile.swift
//  Norma
//
//  Created by Claude on 6/29/25.
//

import Foundation
import Supabase

extension SupabaseService {
    
    // MARK: - Profile Methods (Legacy - Non-encrypted)
    
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
    
    // MARK: - Profile Methods (Encryption Support)
    
    /// Fetch profile with encryption support
    func fetchEncryptableProfile(userId: String) async throws -> EncryptableProfile? {
        let response = try await from("profiles")
            .select()
            .eq("user_id", value: userId)
            .execute()
        
        let decoder = JSONDecoder()
        do {
            let profiles = try decoder.decode([EncryptableProfile].self, from: response.data)
            return profiles.first
        } catch {
            print("❌ Failed to decode EncryptableProfile. Raw response: \(String(data: response.data, encoding: .utf8) ?? "nil")")
            print("❌ Decode error: \(error)")
            throw error
        }
    }
    
    /// Create profile with encryption support
    func createEncryptableProfile(_ profile: EncryptableProfile) async throws -> EncryptableProfile {
        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)
        
        let response = try await from("profiles")
            .insert(data)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode(EncryptableProfile.self, from: response.data)
    }
    
    /// Update profile with encryption support
    func updateEncryptableProfile(_ profile: EncryptableProfile) async throws -> EncryptableProfile {
        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)
        
        let response = try await from("profiles")
            .update(data)
            .eq("user_id", value: profile.userId)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode(EncryptableProfile.self, from: response.data)
    }
    
    /// Update profile settings encryption during migration
    func updateProfileSettingsEncryption(userId: String, encryptedSettings: String) async throws {
        _ = try await from("profiles")
            .update([
                "encrypted_settings": AnyJSON.string(encryptedSettings),
                "settings_encrypted": AnyJSON.bool(true)
            ])
            .eq("user_id", value: userId)
            .execute()
    }
}