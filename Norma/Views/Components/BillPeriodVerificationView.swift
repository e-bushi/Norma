//
//  BillPeriodVerificationView.swift
//  Norma
//
//  Created by Claude on 7/29/25.
//

import SwiftUI

struct BillPeriodVerificationView: View {
    @StateObject private var verificationService: BillPeriodVerificationService
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showReviewView = false
    @State private var isProcessing = false
    
    init(verificationService: BillPeriodVerificationService) {
        self._verificationService = StateObject(wrappedValue: verificationService)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("New Billing Period")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("A new billing period has started. Will the bills you have carry over to this month?")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                .padding(.horizontal, 20)
                
                // Bills preview
                if !verificationService.billsToVerify.isEmpty {
                    VStack(spacing: 8) {
                        Text("Bills to verify (\(verificationService.billsToVerify.count))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 8) {
                            ForEach(Array(verificationService.billsToVerify.prefix(3)), id: \.id) { bill in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(bill.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Text(bill.frequency.rawValue)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(profileViewModel.formatCurrency(bill.amount))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.05))
                                )
                            }
                            
                            if verificationService.billsToVerify.count > 3 {
                                Text("and \(verificationService.billsToVerify.count - 3) more...")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            isProcessing = true
                            await verificationService.confirmAllBills()
                            isProcessing = false
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                            }
                            
                            Text(isProcessing ? "Processing..." : "Yes")
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
                        .opacity(isProcessing ? 0.8 : 1.0)
                    }
                    .disabled(isProcessing)
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showReviewView = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                            
                            Text("Review Bills")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showReviewView) {
            BillReviewSelectionView(verificationService: verificationService) {
                dismiss()
            }
        }
    }
}

struct BillReviewSelectionView: View {
    @StateObject private var verificationService: BillPeriodVerificationService
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    @State private var selectedBillIds: Set<String> = []
    @State private var isProcessing = false
    
    let onComplete: () -> Void
    
    init(verificationService: BillPeriodVerificationService, onComplete: @escaping () -> Void) {
        self._verificationService = StateObject(wrappedValue: verificationService)
        self.onComplete = onComplete
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Review Your Bills")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Select the bills you want to keep for this period. Unselected bills will be removed.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Bills list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(verificationService.billsToVerify, id: \.id) { bill in
                            BillToggleRow(
                                bill: bill,
                                isSelected: selectedBillIds.contains(bill.id ?? ""),
                                onToggle: { isSelected in
                                    if let billId = bill.id {
                                        if isSelected {
                                            selectedBillIds.insert(billId)
                                        } else {
                                            selectedBillIds.remove(billId)
                                        }
                                    }
                                }
                            )
                            .environmentObject(profileViewModel)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Action button
                VStack(spacing: 16) {
                    Text("\(selectedBillIds.count) bills selected")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        Task {
                            isProcessing = true
                            await verificationService.reviewBills(selectedBillIds: selectedBillIds)
                            isProcessing = false
                            onComplete()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                            }
                            
                            Text(isProcessing ? "Processing..." : "Confirm Selection")
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
                        .opacity(isProcessing ? 0.8 : 1.0)
                    }
                    .disabled(isProcessing)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
                .background(
                    Rectangle()
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Pre-select all bills by default
                selectedBillIds = Set(verificationService.billsToVerify.compactMap { $0.id })
            }
        }
    }
}

struct BillToggleRow: View {
    let bill: Bill
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Bill info
                VStack(alignment: .leading, spacing: 4) {
                    Text(bill.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text(bill.frequency.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("Due: \(formatDueDate(bill.dueDate))")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Amount
                Text(profileViewModel.formatCurrency(bill.amount))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.05) : Color.gray.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    let dataManager = DataManager()
    let verificationService = BillPeriodVerificationService(dataManager: dataManager)
    
    // Add some sample bills for preview
    verificationService.billsToVerify = [
        Bill(
            id: "1",
            userId: "user1",
            name: "Rent",
            dueDate: Date(),
            amount: 1200.0,
            status: .paid,
            frequency: .monthly
        ),
        Bill(
            id: "2",
            userId: "user1",
            name: "Internet",
            dueDate: Date(),
            amount: 89.99,
            status: .paid,
            frequency: .monthly
        )
    ]
    
    return BillPeriodVerificationView(verificationService: verificationService)
        .environmentObject({
            let sessionViewModel = SessionViewModel(dataManager: dataManager)
            return ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
        }())
}