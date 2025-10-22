//
//  MyExpensesView.swift
//  Norma
//
//  Created by Claude on 7/12/25.
//

import SwiftUI

struct MyExpensesView: View {
    // Environment objects
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var dataManager: DataManager
    
    // Filter options for the list
    @State private var selectedFilter: ExpenseFilter = .all
    
    // Selected date for the day picker
    @State private var selectedDate: Date = Date()
    @State private var showAllDates: Bool = true
    
    // Animation state
    @State private var headerAppeared = false
    
    // Sheet presentation
    @State private var showNormaChatView = false
    
    // Task Management
    @State private var refreshTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Day picker view
                    DayPickerView(selectedDate: $selectedDate, showAllDates: $showAllDates)
                        .padding(.vertical)
                        .animation(.spring(response: 0.4), value: selectedDate)
                        .animation(.spring(response: 0.4), value: showAllDates)
                    
                    // Expense list view component
                    ExpenseListView(
                        expenses: expenseViewModel.expenses,
                        selectedFilter: $selectedFilter,
                        selectedDate: $selectedDate,
                        showAllDates: $showAllDates
                    )
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Expenses")
                        .font(.normaTitle(20))
                }
            }
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
                
                // Load expenses if not already loaded
                Task {
                    await expenseViewModel.refreshExpenses()
                }
            }
            .sheet(isPresented: $showNormaChatView) {
                NormaChatView(context: .expenses)
            }
        }
    }
}



#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let expenseViewModel = ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    
    return MyExpensesView()
        .environmentObject(dataManager)
        .environmentObject(sessionViewModel)
        .environmentObject(expenseViewModel)
}