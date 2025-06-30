//
//  MyBillsView.swift
//  Collector
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct MyBillsView: View {
    // Sample data for testing
    private let sampleUserId = "sample-user-123"
    @State private var bills: [Bill] = []
    
    init() {
        let userId = sampleUserId
        _bills = State(initialValue: [
            Bill(
                userId: userId,
                name: "Electricity Bill",
                dueDate: Date(),
                amount: 87.50,
                status: .paid,
                frequency: .monthly
            ),
            Bill(
                userId: userId,
                name: "Internet Service",
                dueDate: Date().addingTimeInterval(-86400 * 5),
                amount: 65.99,
                status: .overdue,
                frequency: .monthly
            ),
            Bill(
                userId: userId,
                name: "Rent Payment",
                dueDate: Date().addingTimeInterval(86400 * 3),
                amount: 1200.00,
                status: .scheduled,
                frequency: .monthly
            ),
            Bill(
                userId: userId,
                name: "Car Insurance",
                dueDate: Date().addingTimeInterval(86400 * 30),
                amount: 420.00,
                status: .scheduled,
                frequency: .quarterly
            ),
            Bill(
                userId: userId,
                name: "Property Tax",
                dueDate: Date().addingTimeInterval(86400 * 60),
                amount: 2500.00,
                status: .scheduled,
                frequency: .yearly
            )
        ])
    }
    
    // Filter options for the list
    @State private var selectedFilter: BillFilter = .all
    
    // Selected date for the day picker
    @State private var selectedDate: Date = Date()
    @State private var showAllDates: Bool = true
    
    // Animation state
    @State private var headerAppeared = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Day picker view
                    DayPickerView(selectedDate: $selectedDate, showAllDates: $showAllDates)
                        .padding(.vertical)
                        .animation(.spring(response: 0.4), value: selectedDate)
                        .animation(.spring(response: 0.4), value: showAllDates)
                    
                    // Bill list view component
                    BillListView(
                        bills: bills,
                        selectedFilter: $selectedFilter,
                        selectedDate: $selectedDate,
                        showAllDates: $showAllDates
                    )
                }
            }
            .navigationTitle("My Bills")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Add new bill action
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                // Animate header when the view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        headerAppeared = true
                    }
                }
            }
        }
    }
}



#Preview {
    MyBillsView()
}
