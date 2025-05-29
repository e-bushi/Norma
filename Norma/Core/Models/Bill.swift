//
//  Bill.swift
//  Collector
//
//  Created by Claude on 5/9/25.
//

import Foundation

// Bill model with all the necessary properties
struct Bill: Identifiable, Codable {
    let id: String
    let name: String
    let date: Date
    let amount: Double
    var status: BillStatus
    let frequency: BillFrequency
    
    // Initializer with generated ID
    init(id: String = UUID().uuidString, name: String, date: Date, amount: Double, status: BillStatus, frequency: BillFrequency) {
        self.id = id
        self.name = name
        self.date = date
        self.amount = amount
        self.status = status
        self.frequency = frequency
    }
}

// Bill status enum
enum BillStatus: String, Codable {
    case paid = "Paid"
    case overdue = "Overdue"
    case scheduled = "Scheduled"
}

// Bill frequency enum
enum BillFrequency: String, Codable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
}