//
//  SupabaseService+Encryption.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import Foundation
import Supabase

extension SupabaseService {
    
    // MARK: - User Encryption Keys
    
    func getUserEncryptionKeys(userId: String) async throws -> UserEncryptionKeys? {
        let response = try await from("user_encryption_keys")
            .select()
            .eq("user_id", value: userId)
            .execute()
        
        let decoder = JSONDecoder()
        do {
            let keysArray = try decoder.decode([UserEncryptionKeys].self, from: response.data)
            
            // Handle multiple rows case
            if keysArray.count > 1 {
                print("⚠️ WARNING: Multiple encryption keys found for user \(userId). Using most recent.")
                // Return the most recently updated one
                return keysArray.max { key1, key2 in
                    let date1 = key1.updatedAt ?? key1.createdAt ?? ""
                    let date2 = key2.updatedAt ?? key2.createdAt ?? ""
                    return date1 < date2
                }
            }
            
            return keysArray.first
        } catch {
            // No keys found for user or decode error
            return nil
        }
    }
    
    func storeUserEncryptionKeys(_ keys: UserEncryptionKeys) async throws -> UserEncryptionKeys {
        print("📍 [DEBUG] storeUserEncryptionKeys: Starting...")
        
        // Follow the same pattern as createExpense
        let response: UserEncryptionKeys = try await from("user_encryption_keys")
            .insert(keys)
            .select()  
            .single()
            .execute()
            .value
        
        print("✅ [DEBUG] Successfully stored encryption keys for user: \(response.userId)")
        return response
    }
    
    func updateUserEncryptionKeys(_ keys: UserEncryptionKeys) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(keys)
        
        _ = try await from("user_encryption_keys")
            .update(data)
            .eq("user_id", value: keys.userId)
            .execute()
    }
    
    // MARK: - General Migration Support
    
    /// Check if user has any encrypted data
    func hasEncryptedData(userId: String) async throws -> Bool {
        let expensesResponse = try await from("expenses")
            .select("id")
            .eq("user_id", value: userId)
            .eq("is_encrypted", value: true)
            .limit(1)
            .execute()
        
        let decoder = JSONDecoder()
        let expenses = try decoder.decode([[String: String]].self, from: expensesResponse.data)
        
        return !expenses.isEmpty
    }
    
    /// Check if user has encryption enabled
    func hasEncryptionEnabled(userId: String) async throws -> Bool {
        return try await getUserEncryptionKeys(userId: userId) != nil
    }
    
    /// Clean up duplicate encryption keys for a user (keep most recent)
    func cleanupDuplicateEncryptionKeys(userId: String) async throws {
        let response = try await from("user_encryption_keys")
            .select()
            .eq("user_id", value: userId)
            .execute()
        
        let decoder = JSONDecoder()
        let keysArray = try decoder.decode([UserEncryptionKeys].self, from: response.data)
        
        if keysArray.count > 1 {
            print("🧹 Cleaning up \(keysArray.count - 1) duplicate encryption keys for user \(userId)")
            
            // Sort by date (most recent first)
            let sortedKeys = keysArray.sorted { key1, key2 in
                let date1 = key1.updatedAt ?? key1.createdAt ?? ""
                let date2 = key2.updatedAt ?? key2.createdAt ?? ""
                return date1 > date2
            }
            
            // Delete all except the most recent
            for key in sortedKeys.dropFirst() {
                _ = try await from("user_encryption_keys")
                    .delete()
                    .eq("user_id", value: userId)
                    .eq("created_at", value: key.createdAt ?? "")
                    .execute()
            }
            
            print("✅ Cleanup complete. Kept most recent encryption key.")
        }
    }
}
