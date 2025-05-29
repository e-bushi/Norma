//
//  BillListView.swift
//  Collector
//
//  Created by Chris Mauldin on 5/8/25.
//

import SwiftUI
import Foundation

struct BillHomeView: View {
    
    @State private var showMyBills: Bool = false
    
    let sampleBills = [
        Bill(name: "Rent", date: Date().addingTimeInterval(86400 * 2), amount: 1200.00, status: .scheduled, frequency: .monthly),
        Bill(name: "Electricity", date: Date().addingTimeInterval(86400 * 5), amount: 85.50, status: .scheduled, frequency: .monthly),
        Bill(name: "Internet", date: Date().addingTimeInterval(86400 * 7), amount: 59.99, status: .scheduled, frequency: .monthly),
        Bill(name: "Phone Bill", date: Date().addingTimeInterval(86400 * 10), amount: 45.00, status: .scheduled, frequency: .monthly),
        Bill(name: "Water Bill", date: Date().addingTimeInterval(86400 * 12), amount: 32.75, status: .scheduled, frequency: .quarterly),
        Bill(name: "Streaming Service", date: Date().addingTimeInterval(86400 * 15), amount: 14.99, status: .scheduled, frequency: .monthly),
        Bill(name: "Credit Card", date: Date().addingTimeInterval(-86400 * 2), amount: 220.30, status: .paid, frequency: .monthly),
        Bill(name: "Car Insurance", date: Date().addingTimeInterval(-86400 * 5), amount: 110.50, status: .overdue, frequency: .quarterly)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
                ExpenseTrackerChartView(
                    billAmount: 1500,
                    currentExpenseAmount: 2000,
                    incomeAmount: 3000
                )
                .padding(.horizontal)
    
                
                BillDisclosureView(bills: sampleBills)
                .padding(.horizontal)
                .padding(.horizontal)
            }
            .navigationTitle(Text("Home"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func getDaysInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let date = Date()
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }
    
    func generateChartData() -> [ExpenseChartDataPoint] {
        // Simulate days with expense activity
        let activeDays = [2, 5, 7, 10, 12, 15, 17, 20, 22, 25, 27]
        let billAmount: Double = 1545.49
        
        var runningTotal = billAmount
        
        return activeDays.map { day in
            // Daily expense amount varies
            let dailyExpense = Double.random(in: 40...180)
            
            let lowAmount = runningTotal
            let highAmount = runningTotal + dailyExpense
            
            runningTotal = highAmount
            
            return ExpenseChartDataPoint(
                day: day,
                highAmount: highAmount,
                lowAmount: lowAmount,
                dailyExpense: dailyExpense
            )
        }
    }
}

#Preview {
    BillHomeView()
        .preferredColorScheme(.dark)
}
