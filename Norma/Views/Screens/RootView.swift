//
//  RootView.swift
//  Collector
//
//  Created by Chris Mauldin on 5/8/25.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ViewModelContainer(dataManager: dataManager, sessionViewModel: sessionViewModel) {
            TabView {
                BillHomeView()
                    .tabItem {
                        Label("My Bills", systemImage: "doc.text.fill")
                    }
                    
                
                IncomeAndExpenseView()
                    .tabItem {
                        Label("Expenses", systemImage: "chart.bar.fill")
                    }
                    
                
                ProfileView(hasProfileData: dataManager.hasPsychologyData)
                    .tabItem {
                        Label("Profile", systemImage: "brain.head.profile")
                    }
                    
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .environmentObject(sessionViewModel)
                    .environmentObject(dataManager)
            }
        }
        .overlay(
            // Encryption migration popup
            Group {
                if sessionViewModel.shouldShowEncryptionMigration {
                    EncryptionMigrationPopup(
                        isPresented: $sessionViewModel.shouldShowEncryptionMigration,
                        onMigrate: { password in
                            try await sessionViewModel.startEncryptionMigration(password: password)
                        },
                        onDismiss: {
                            sessionViewModel.dismissEncryptionMigration()
                        },
                        userEmail: sessionViewModel.currentUser?.email ?? ""
                    )
                }
            }
        )
        .onAppear {
            // Set the model context on DataManager
            print("🔍 [DEBUG] RootView.onAppear: Setting model context on DataManager")
            dataManager.setModelContext(modelContext)
            print("✅ [DEBUG] RootView.onAppear: Model context set successfully")
        }
        .task {
            // Load user data when main app becomes active
            if let _ = sessionViewModel.currentUser?.userId {
                do {
                    // Refresh user profile first
                    await sessionViewModel.fetchUserProfile()
                    // Then fetch financial data
                    try await dataManager.fetchAllFinancialData()
                } catch {
                    print("Failed to load financial data: \(error)")
                }
            }
        }
    }
}

// MARK: - ViewModelContainer

struct ViewModelContainer<Content: View>: View {
    let dataManager: DataManager
    let sessionViewModel: SessionViewModel
    let content: Content
    
    @StateObject private var billViewModel: BillViewModel
    @StateObject private var expenseViewModel: ExpenseViewModel
    @StateObject private var incomeViewModel: IncomeViewModel
    @StateObject private var budgetViewModel: BudgetViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    
    init(dataManager: DataManager, sessionViewModel: SessionViewModel, @ViewBuilder content: () -> Content) {
        self.dataManager = dataManager
        self.sessionViewModel = sessionViewModel
        self.content = content()
        
        // Initialize view models with proper dependencies
        self._billViewModel = StateObject(wrappedValue: BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        self._expenseViewModel = StateObject(wrappedValue: ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        self._incomeViewModel = StateObject(wrappedValue: IncomeViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        self._budgetViewModel = StateObject(wrappedValue: BudgetViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        self._profileViewModel = StateObject(wrappedValue: ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
    }
    
    var body: some View {
        content
            .environmentObject(dataManager)
            .environmentObject(sessionViewModel)
            .environmentObject(billViewModel)
            .environmentObject(expenseViewModel)
            .environmentObject(incomeViewModel)
            .environmentObject(budgetViewModel)
            .environmentObject(profileViewModel)
            .onAppear {
                // Set up BudgetViewModel dependency after view appears
                budgetViewModel.setExpenseViewModel(expenseViewModel)
            }
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    
    return RootView()
        .environmentObject(dataManager)
        .environmentObject(sessionViewModel)
        .preferredColorScheme(.light)
}
