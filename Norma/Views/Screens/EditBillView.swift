//
//  EditBillView.swift
//  Norma
//
//  Created by Claude on 7/11/25.
//

import SwiftUI

struct EditBillView: View {
    let bill: Bill
    
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Form fields
    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var dueDate: Date = Date()
    @State private var frequency: BillFrequency = .monthly
    @State private var merchant: String = ""
    @State private var reminderDays: String = ""
    @State private var notes: String = ""
    @State private var isAutoPayEnabled: Bool = false
    
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Bill details section
                    billDetailsView
                    
                    // Additional details section
                    additionalDetailsView
                    
                    // Notes section
                    notesView
                    
                    // Save button
                    saveButton
                }
                .padding()
            }
            .navigationTitle("Edit Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                }
            }
            .onAppear {
                loadBillData()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var billDetailsView: some View {
        VStack(spacing: 16) {
            // Header with status badge
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Bill Name", text: $name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: statusIcon)
                            .font(.system(size: 12))
                            .foregroundColor(statusColor)
                        
                        Text(bill.status.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(statusColor)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack {
                        Text(profileViewModel.currencyInfo?.symbol ?? "$")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        TextField("0.00", text: $amount)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                    }
                    
                    Picker("", selection: $frequency) {
                        ForEach(BillFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .accentColor(.secondary)
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
            
            // Bill details grid
            VStack(spacing: 16) {
                Text("BILL DETAILS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    // Due Date
                    HStack {
                        Text("Due Date")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.vertical, 2)
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
    }
    
    @ViewBuilder
    private var additionalDetailsView: some View {
        VStack(spacing: 16) {
            Text("ADDITIONAL DETAILS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 0) {
                // Merchant
                DetailEditRow(
                    label: "Merchant",
                    placeholder: "Optional",
                    text: $merchant
                )
                
                Divider()
                    .padding(.horizontal, 24)
                
                // Reminder
                HStack {
                    Text("Reminder")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        TextField("0", text: $reminderDays)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 40)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("days before")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                Divider()
                    .padding(.horizontal, 24)
                
                // Auto Pay
                HStack {
                    Text("Auto Pay")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $isAutoPayEnabled)
                        .labelsHidden()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
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
    private var notesView: some View {
        VStack(spacing: 16) {
            Text("NOTES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("Add notes (optional)", text: $notes, axis: .vertical)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .lineLimit(3...6)
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
    private var saveButton: some View {
        Button(action: {
            Task {
                await updateBill()
            }
        }) {
            HStack(spacing: 12) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                }
                
                Text(isProcessing ? "Saving..." : "Save Changes")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.blue.opacity(0.8)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .opacity(isProcessing || name.isEmpty || amount.isEmpty ? 0.8 : 1.0)
        }
        .disabled(name.isEmpty || amount.isEmpty || isProcessing)
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Views
    
    private struct DetailEditRow: View {
        let label: String
        let placeholder: String
        @Binding var text: String
        
        var body: some View {
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Helper Properties
    
    private var statusIcon: String {
        switch bill.status {
        case .paid: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .scheduled: return "calendar.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch bill.status {
        case .paid: return .green
        case .overdue: return .red
        case .scheduled: return .blue
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadBillData() {
        name = bill.name
        amount = String(format: "%.2f", bill.amount)
        dueDate = bill.dueDate
        frequency = bill.frequency
        merchant = bill.merchant ?? ""
        reminderDays = bill.reminderDays != nil ? String(bill.reminderDays!) : ""
        notes = bill.notes ?? ""
        isAutoPayEnabled = bill.isAutoPayEnabled
    }
    
    private func updateBill() async {
        isProcessing = true
        
        // Validate amount
        guard let amountValue = Double(amount) else {
            errorMessage = "Please enter a valid amount"
            showError = true
            isProcessing = false
            return
        }
        
        // Parse reminder days
        let reminderDaysValue: Int? = reminderDays.isEmpty ? nil : Int(reminderDays)
        
        // Create updated bill
        var updatedBill = bill
        updatedBill.name = name
        updatedBill.amount = amountValue
        updatedBill.dueDate = dueDate
        updatedBill.frequency = frequency
        updatedBill.merchant = merchant.isEmpty ? nil : merchant
        updatedBill.reminderDays = reminderDaysValue
        updatedBill.notes = notes.isEmpty ? nil : notes
        updatedBill.isAutoPayEnabled = isAutoPayEnabled
        
        await billViewModel.updateBill(updatedBill)
        
        isProcessing = false
        
        if billViewModel.errorMessage == nil {
            dismiss()
        } else {
            errorMessage = billViewModel.errorMessage ?? "Failed to update bill"
            showError = true
        }
    }
}

#Preview {
    let sampleBill = Bill(
        id: "1",
        userId: "user1",
        name: "Electric Bill",
        dueDate: Date(),
        amount: 125.50,
        status: .scheduled,
        frequency: .monthly,
        merchant: "Power Company",
        reminderDays: 3,
        notes: "Account #12345"
    )
    
    return EditBillView(bill: sampleBill)
        .environmentObject(BillViewModel(dataManager: DataManager(), sessionViewModel: SessionViewModel(dataManager: DataManager())))
}