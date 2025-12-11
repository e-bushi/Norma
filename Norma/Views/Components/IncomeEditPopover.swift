//
//  IncomeEditPopover.swift
//  Norma
//
//  Created by Claude on 12/5/25.
//

import SwiftUI

struct IncomeEditPopover: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var sessionViewModel: SessionViewModel

    @State private var appeared = false
    @State private var incomeText: String = ""
    @State private var freedomFundText: String = ""
    @State private var isSaving = false

    @FocusState private var focusedField: Field?

    enum Field {
        case income
        case freedomFund
    }

    private var currentIncome: Double {
        sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
    }

    private var currentFreedomFund: Double {
        sessionViewModel.currentUser?.settings.freedomFund ?? 0
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.currencySymbol ?? "$"
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Dismiss overlay
            Color.black.opacity(appeared ? 0.3 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Popover content
            VStack(alignment: .leading, spacing: 16) {
                // Income field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Monthly Income (after taxes)")
                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        Text(currencySymbol)
                            .font(.custom(FontFamily.Rubik.medium, size: 18))
                            .foregroundColor(.primary)

                        TextField("0", text: $incomeText)
                            .font(.custom(FontFamily.Rubik.regular, size: 18))
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .income)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                focusedField == .income ? Color("NormaPastelTeal") : Color.clear,
                                lineWidth: 2
                            )
                    )
                }

                // Freedom Fund field
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Freedom Fund")
                            .font(.custom(FontFamily.Rubik.medium, size: 14))
                            .foregroundColor(.secondary)

                        Text("Money set aside to pay future bills")
                            .font(.custom(FontFamily.Rubik.regular, size: 12))
                            .foregroundColor(.secondary.opacity(0.7))
                    }

                    HStack(spacing: 8) {
                        Text(currencySymbol)
                            .font(.custom(FontFamily.Rubik.medium, size: 18))
                            .foregroundColor(.primary)

                        TextField("0", text: $freedomFundText)
                            .font(.custom(FontFamily.Rubik.regular, size: 18))
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .freedomFund)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                focusedField == .freedomFund ? Color("NormaPastelPurple") : Color.clear,
                                lineWidth: 2
                            )
                    )
                }

                // Save button
                Button {
                    saveChanges()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                                .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("NormaPastelTeal"))
                    )
                    .foregroundColor(.white)
                }
                .disabled(isSaving)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.clear)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 16))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            )
            .padding(.top, 100)
            .padding(.horizontal, 16)
            .scaleEffect(appeared ? 1 : 0.8, anchor: .top)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            // Pre-populate with current values
            if currentIncome > 0 {
                incomeText = formatNumberWithoutCurrency(currentIncome)
            }
            if currentFreedomFund > 0 {
                freedomFundText = formatNumberWithoutCurrency(currentFreedomFund)
            }

            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                appeared = true
            }

            // Auto-focus income field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                focusedField = .income
            }
        }
    }

    private func formatNumberWithoutCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private func parseNumber(_ text: String) -> Double {
        let cleanedText = text.replacingOccurrences(of: ",", with: "")
        return Double(cleanedText) ?? 0
    }

    private func saveChanges() {
        guard let currentUser = sessionViewModel.currentUser else { return }

        isSaving = true

        let newIncome = parseNumber(incomeText)
        let newFreedomFund = parseNumber(freedomFundText)

        // Create updated settings
        var updatedSettings = currentUser.settings
        updatedSettings.monthlyIncome = newIncome
        updatedSettings.freedomFund = newFreedomFund

        // Create updated profile
        var updatedProfile = currentUser
        updatedProfile.settings = updatedSettings
        updatedProfile.monthlyIncome = newIncome
        updatedProfile.freedomFund = newFreedomFund

        Task {
            await sessionViewModel.updateUserProfile(updatedProfile)

            await MainActor.run {
                isSaving = false

                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

                dismiss()
            }
        }
    }

    private func dismiss() {
        focusedField = nil

        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            appeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}

#Preview {
    ZStack {
        Color("NormaBackground")
            .ignoresSafeArea()

        IncomeEditPopover(isPresented: .constant(true))
            .environmentObject(SessionViewModel(dataManager: DataManager()))
    }
}
