//
//  MyBillsView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct MyBillsView: View {
    // Environment objects
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var dataManager: DataManager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // Filter options for the list
    @State private var selectedFilter: BillFilter = .all
    
    // Selected date for the day picker
    @State private var selectedDate: Date = Date()
    @State private var showAllDates: Bool = true
    
    // Animation state
    @State private var headerAppeared = false
    
    // Sheet presentation
    @State private var showNormaChatView = false
    
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
                        bills: billViewModel.activeBills,
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
                        showNormaChatView = true
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
                
                // Load bills if not already loaded
                Task {
                    await billViewModel.refreshBills()
                }
            }
            .sheet(isPresented: $showNormaChatView) {
                NormaChatView(context: .bills)
            }
        }
    }
}



#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let billViewModel = BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    
    return MyBillsView()
        .environmentObject(dataManager)
        .environmentObject(sessionViewModel)
        .environmentObject(billViewModel)
}
