//
//  CreateBillView.swift
//  Norma
//
//  Created by Claude on 9/18/25.
//

import SwiftUI

struct CreateBillView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    // Form fields
    @State private var billName = ""
    @State private var billAmount = ""
    @State private var frequency: BillFrequency = .monthly
    @State private var dueDate = Date()
    @State private var notes = ""
    
    // UI state
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isAmountFieldFocused: Bool
    
    // Computed properties
    private var formattedAmount: Double? {
        Double(billAmount.replacingOccurrences(of: ",", with: ""))
    }
    
    private var isFormValid: Bool {
        !billName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        formattedAmount != nil &&
        formattedAmount! > 0
    }

    private var currencySymbol: String {
        let currencyCode = sessionViewModel.currentUser?.settings.currency ?? "USD"
        return CurrencyData.getCurrency(for: currencyCode).symbol
    }

    private var frequencyIcon: String {
        switch frequency {
        case .monthly:
            return "calendar"
        case .quarterly:
            return "calendar.badge.3"
        case .yearly:
            return "calendar.badge.365"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with centered icon and name
                    headerView

                    // Bill amount card
                    billAmountCard

                    // Bill details section
                    billDetailsSection

                    // Due date section
                    dueDateSection

                    // Save button
                    saveButtonView
                }
                .padding()
            }
            .navigationTitle("New Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - View Sections

    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 12) {
            // Bill icon
            Circle()
                .fill(Color("NormaPastelPurple").opacity(0.15))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color("NormaPastelPurple"))
                )

            // Bill name
            VStack(spacing: 4) {
                TextField("Bill Name", text: $billName)
                    .font(.normaTitle())
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 6) {
                    Image(systemName: frequencyIcon)
                        .font(.normaHeadline(12))
                    Text(frequency.rawValue)
                        .font(.normaHeadline(14))
                }
                .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var billAmountCard: some View {
        VStack(spacing: 8) {
            Text("Bill Amount (\(currencySymbol))")
                .font(.normaHeadline(12))
                .foregroundColor(.secondary)

            TextField("0.00", text: $billAmount)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .focused($isAmountFieldFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isAmountFieldFocused = false
                        }
                        .font(.normaHeadline(16))
                    }
                }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
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
        )
    }
    
    @ViewBuilder
    private var billDetailsSection: some View {
        VStack(spacing: 16) {
            Text("BILL DETAILS")
                .font(.normaHeadline(11))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                // Frequency selection
                DetailRow(label: "Frequency", value: "") {
                    Menu {
                        ForEach(BillFrequency.allCases, id: \.self) { freq in
                            Button {
                                frequency = freq
                            } label: {
                                HStack {
                                    Text(freq.rawValue)
                                    if frequency == freq {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: frequencyIcon)
                                    .font(.normaHeadline(14))
                                Text(frequency.rawValue)
                            }
                            .foregroundColor(.primary)

                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .font(.normaHeadline(14))
                    }
                }

                Divider()

                // Notes input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.normaHeadline(14))
                        .foregroundColor(.secondary)

                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .font(.normaHeadline(14))
                        .foregroundColor(.primary)
                        .lineLimit(3...6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    @ViewBuilder
    private var dueDateSection: some View {
        VStack(spacing: 16) {
            Text("DUE DATE")
                .font(.normaHeadline(11))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                DetailRow(label: "Due Date", value: "") {
                    DatePicker("", selection: $dueDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private var saveButtonView: some View {
        Button(action: {
            saveBill()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                }

                Text("Create Bill")
                    .font(.normaHeadline(16))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: isFormValid ? [
                                Color("NormaPastelPurple"),
                                Color("NormaPastelPurple").opacity(0.8)
                            ] : [
                                Color.gray,
                                Color.gray.opacity(0.8)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
        }
        .disabled(!isFormValid || isLoading)
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Actions
    
    private func saveBill() {
        guard let amount = formattedAmount else {
            showError(message: "Invalid bill amount")
            return
        }

        let trimmedName = billName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showError(message: "Bill name is required")
            return
        }

        isLoading = true

        Task {
            let createdBill = await billViewModel.addBill(
                name: trimmedName,
                amount: amount,
                dueDate: dueDate,
                frequency: frequency,
                status: .scheduled
            )

            await MainActor.run {
                isLoading = false
                if createdBill != nil {
                    dismiss()
                } else {
                    showError(message: "Failed to create bill")
                }
            }
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Preview

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let billViewModel = BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    
    return CreateBillView()
        .environmentObject(billViewModel)
        .environmentObject(sessionViewModel)
        .environmentObject(profileViewModel)
}