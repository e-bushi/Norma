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
    @State private var status: BillStatus = .scheduled
    @State private var notes = ""
    @State private var reminderDays = 3
    
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
    
    private var statusColor: Color {
        switch status {
        case .paid:
            return .green
        case .overdue:
            return .red
        case .scheduled:
            return .blue
        }
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
                    // Main bill card
                    mainBillCard
                    
                    // Bill details section
                    billDetailsSection
                    
                    // Reminder settings section
                    reminderSettingsSection
                    
                    // Notes section
                    if !notes.isEmpty {
                        notesSection
                    }
                    
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
    private var mainBillCard: some View {
        VStack(spacing: 16) {
            // Header with name input
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Bill Name", text: $billName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: frequencyIcon)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(frequency.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(status.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(statusColor)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("$")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        TextField("0.00", text: $billAmount)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .focused($isAmountFieldFocused)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        isAmountFieldFocused = false
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
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
    }
    
    @ViewBuilder
    private var billDetailsSection: some View {
        VStack(spacing: 16) {
            Text("BILL DETAILS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                frequencyRow
                dueDateRow
                statusRow
                notesInput
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
    private var frequencyRow: some View {
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
                    Text(frequency.rawValue)
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .font(.system(size: 14))
            }
        }
    }
    
    @ViewBuilder
    private var dueDateRow: some View {
        DetailRow(label: "Due Date", value: "") {
            DatePicker("", selection: $dueDate, displayedComponents: .date)
                .labelsHidden()
        }
    }
    
    @ViewBuilder
    private var statusRow: some View {
        DetailRow(label: "Status", value: "") {
            Menu {
                ForEach(BillStatus.allCases, id: \.self) { billStatus in
                    Button {
                        status = billStatus
                    } label: {
                        HStack {
                            Circle()
                                .fill(getStatusColor(billStatus))
                                .frame(width: 8, height: 8)
                            Text(billStatus.rawValue)
                            if status == billStatus {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(status.rawValue)
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .font(.system(size: 14))
            }
        }
    }
    
    @ViewBuilder
    private var notesInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField("Add notes (optional)", text: $notes, axis: .vertical)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .lineLimit(3...6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func getStatusColor(_ billStatus: BillStatus) -> Color {
        switch billStatus {
        case .paid:
            return .green
        case .overdue:
            return .red
        case .scheduled:
            return .blue
        }
    }
    
    @ViewBuilder
    private var reminderSettingsSection: some View {
        VStack(spacing: 16) {
            Text("REMINDER SETTINGS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Remind me")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Menu {
                            ForEach([1, 2, 3, 5, 7], id: \.self) { days in
                                Button {
                                    reminderDays = days
                                } label: {
                                    Text("\(days) \(days == 1 ? "day" : "days") before")
                                }
                            }
                        } label: {
                            HStack {
                                Text("\(reminderDays) \(reminderDays == 1 ? "day" : "days") before")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    Text("Get notified before your bill is due")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
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
    private var notesSection: some View {
        VStack(spacing: 16) {
            Text("NOTES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(notes)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(nil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFormValid ? Color.blue : Color.gray)
            )
        }
        .disabled(!isFormValid || isLoading)
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
                status: status
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