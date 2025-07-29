//
//  IncomeDetailView.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import SwiftUI

struct IncomeDetailView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var newIncomeAmount: String = ""
    @State private var showingAlert = false
    @State private var isUpdating = false
    
    
    private var isUpdateDisabled: Bool {
        isUpdating || newIncomeAmount.isEmpty
    }
    
    private var buttonText: String {
        isUpdating ? "Updating..." : "Update Income"
    }
    
    private var buttonContent: some View {
        HStack {
            if isUpdating {
                ProgressView()
                    .scaleEffect(0.8)
                    .foregroundColor(.white)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
            }
            
            Text(buttonText)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
    
    private var buttonBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var currentIncomeText: some View {
        let currentIncome = profileViewModel.profile?.settings.monthlyIncome ?? 0
        let formattedIncome = profileViewModel.formatCurrency(currentIncome)
        
        return Text(formattedIncome)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.green)
    }
    
    @ViewBuilder
    private var currentIncomeDetailsView: some View {
        VStack(spacing: 16) {
            // Header with income amount
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Monthly Income")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        
                        Text("Active")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    currentIncomeText
                    
                    Text("Monthly")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(cardBackground)
        }
    }
    
    @ViewBuilder
    private var updateIncomeView: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("UPDATE INCOME")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                Spacer()
            }
            
            // Update form
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Monthly Income")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    TextField("Enter amount", text: $newIncomeAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 16))
                        .onAppear {
                            let income = profileViewModel.profile?.settings.monthlyIncome ?? 0
                            newIncomeAmount = String(income)
                        }
                }
                
                Text("Enter your monthly income before taxes and deductions")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(cardBackground)
        }
    }
    
    @ViewBuilder
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // Update Button
            Button(action: updateIncome) {
                buttonContent
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(buttonBackground)
                    .cornerRadius(12)
            }
            .disabled(isUpdateDisabled)
            .opacity(isUpdateDisabled ? 0.6 : 1.0)
            
            // Cancel Button
            Button("Cancel") {
                dismiss()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(UIColor.systemBackground),
                        Color.gray.opacity(0.02)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.2),
                                Color.gray.opacity(0.05)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Income Display Section
                    currentIncomeDetailsView
                    
                    // Update Income Section
                    updateIncomeView
                    
                    // Action Buttons
                    actionButtonsView
                }
                .padding()
            }
            .navigationTitle("Monthly Income")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Income Updated", isPresented: $showingAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your monthly income has been successfully updated.")
            }
        }
    }
    
    private func updateIncome() {
        guard let amount = Double(newIncomeAmount), amount >= 0 else {
            return
        }
        
        isUpdating = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            profileViewModel.updateMonthlyIncome(amount)
            isUpdating = false
            showingAlert = true
        }
    }
}

#Preview {
    IncomeDetailView()
        .environmentObject({
            let dataManager = DataManager()
            let sessionViewModel = SessionViewModel(dataManager: dataManager)
            return ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
        }())
}
