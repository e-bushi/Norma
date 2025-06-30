//
//  SupabaseService+Bills.swift
//  Norma
//
//  Created by Claude on 6/29/25.
//

import Foundation
import Supabase

extension SupabaseService {
    
    // MARK: - Bills Methods
    
    /// Fetch all bills for a user
    func fetchBills(userId: String) async throws -> [Bill] {
        let response: [Bill] = try await from("bills")
            .select()
            .eq("user_id", value: userId)
            .order("due_date", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    /// Create a new bill
    func createBill(_ bill: Bill) async throws -> Bill {
        let response: Bill = try await from("bills")
            .insert(bill)
            .select()
            .single()
            .execute()
            .value
        
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
}