//
//  SupabaseService+Bills.swift
//  Norma
//
//  Created by Claude on 6/29/25.
//

import Foundation
import Supabase

extension SupabaseService {
    
    // MARK: - Bills Methods (Legacy - Non-encrypted)
    
    /// Fetch all bills for a user
    func fetchBills(userId: String) async throws -> [Bill] {
        let response: [Bill] = try await from("bills")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return response
    }
    
    /// Create a new bill
    func createBill(_ bill: Bill) async throws -> Bill {
        print("🔍 [DEBUG] SupabaseService.createBill called with bill: \(bill)")
        
        // Debug: Print the JSON being sent
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(bill)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "Could not convert to string"
            print("🔍 [DEBUG] JSON being sent to Supabase: \(jsonString)")
        } catch {
            print("⚠️ [DEBUG] Could not encode bill to JSON: \(error)")
        }
        
        print("🔄 [DEBUG] SupabaseService.createBill: About to execute database insert...")
        let response: Bill = try await from("bills")
            .insert(bill)
            .select()
            .single()
            .execute()
            .value
        
        print("✅ [DEBUG] SupabaseService.createBill: Database insert completed successfully")
        print("✅ [DEBUG] SupabaseService.createBill: Response: \(response)")
        
        return response
    }
    
    /// Update existing bill
    func updateBill(_ bill: Bill) async throws -> Bill {
        let response: Bill = try await from("bills")
            .update(bill)
            .eq("id", value: bill.id ?? "")
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    /// Delete a bill
    func deleteBill(_ billId: String) async throws {
        try await from("bills")
            .delete()
            .eq("id", value: billId)
            .execute()
    }
    
    /// Fetch bills due within a date range
    func fetchBillsDue(userId: String, from startDate: Date, to endDate: Date) async throws -> [Bill] {
        let dateFormatter = ISO8601DateFormatter()
        
        let response: [Bill] = try await from("bills")
            .select()
            .eq("user_id", value: userId)
            .gte("due_date", value: dateFormatter.string(from: startDate))
            .lte("due_date", value: dateFormatter.string(from: endDate))
            .order("due_date", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Bills Methods (Encryption Support)
    
    /// Fetch bills with encryption support
    func fetchEncryptableBills(userId: String) async throws -> [EncryptableBill] {
        let response: [EncryptableBill] = try await from("bills")
            .select()
            .eq("user_id", value: userId)
            .order("due_date", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    /// Create bill with encryption support
    func createEncryptableBill(_ bill: EncryptableBill) async throws -> EncryptableBill {
        let response: EncryptableBill = try await from("bills")
            .insert(bill)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    /// Update bill with encryption support
    func updateEncryptableBill(_ bill: EncryptableBill) async throws -> EncryptableBill {
        guard let id = bill.id else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bill ID is required for update"])
        }
        
        print("🔍 [DEBUG] updateEncryptableBill - Bill to update: \(bill)")
        print("🔍 [DEBUG] updateEncryptableBill - Bill nextDueDate: \(bill.nextDueDate ?? Date())")
        
        let response: EncryptableBill = try await from("bills")
            .update(bill)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        
        print("🔍 [DEBUG] updateEncryptableBill - Response nextDueDate: \(response.nextDueDate ?? Date())")
        return response
    }
    
    /// Update bill encryption during migration
    func updateBillEncryption(billId: String, encryptedName: String, encryptedAmount: String) async throws {
        _ = try await from("bills")
            .update([
                "encrypted_name": AnyJSON.string(encryptedName),
                "encrypted_amount": AnyJSON.string(encryptedAmount),
                "is_encrypted": AnyJSON.bool(true)
            ])
            .eq("id", value: billId)
            .execute()
    }

    // MARK: - Verification Support

    /// Update only the unencrypted verification fields (bypasses Edge Function)
    func updateBillVerificationFields(billId: String, status: BillStatus, verificationDate: String, dueDate: String, nextDueDate: String?) async throws {
        var fields: [String: AnyJSON] = [
            "status": AnyJSON.string(status.rawValue),
            "verification_date": AnyJSON.string(verificationDate),
            "due_date": AnyJSON.string(dueDate)
        ]
        if let nextDueDate = nextDueDate {
            fields["next_due_date"] = AnyJSON.string(nextDueDate)
        }

        _ = try await from("bills")
            .update(fields)
            .eq("id", value: billId)
            .execute()
    }

    // MARK: - Semantic Search Support

    /// Fetch specific bills by their IDs (for semantic search results)
    func fetchBillsByIds(_ ids: [String]) async throws -> [EncryptableBill] {
        guard !ids.isEmpty else { return [] }

        let response: [EncryptableBill] = try await from("bills")
            .select()
            .in("id", values: ids)
            .execute()
            .value

        return response
    }
}
