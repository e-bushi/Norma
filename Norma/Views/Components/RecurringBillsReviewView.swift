//
//  RecurringBillsReviewView.swift
//  Norma
//
//  Created by Claude on 3/27/26.
//

import SwiftUI

struct RecurringBillsReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @ObservedObject private var plaidService = PlaidService.shared

    @State private var selectedStreams: Set<String> = []
    @State private var isSaving = false

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = sessionViewModel.currentUser?.settings.currency ?? "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(String(format: "%.2f", value))"
    }

    private func mapFrequency(_ plaidFrequency: String) -> BillFrequency {
        switch plaidFrequency.uppercased() {
        case "WEEKLY", "BIWEEKLY", "SEMI_MONTHLY":
            return .monthly
        case "MONTHLY":
            return .monthly
        case "QUARTERLY":
            return .quarterly
        case "ANNUALLY":
            return .yearly
        default:
            return .monthly
        }
    }

    private func parseDueDate(_ dateString: String?) -> Date {
        guard let dateString = dateString else { return Date() }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString) ?? Date()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text("We found \(plaidService.recurringOutflows.count) recurring charges from your bank.")
                                .font(.custom(FontFamily.Rubik.medium, size: 18))
                                .foregroundColor(.primary)
                                .lineSpacing(4)

                            Text("Select the ones you'd like to track as bills.")
                                .font(.custom(FontFamily.Rubik.regular, size: 15))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 16)

                        // Select all / deselect
                        HStack {
                            Button {
                                if selectedStreams.count == plaidService.recurringOutflows.count {
                                    selectedStreams.removeAll()
                                } else {
                                    selectedStreams = Set(plaidService.recurringOutflows.map { $0.streamId })
                                }
                            } label: {
                                Text(selectedStreams.count == plaidService.recurringOutflows.count ? "Deselect All" : "Select All")
                                    .font(.custom(FontFamily.Rubik.medium, size: 14))
                                    .foregroundColor(Color("NormaPastelTeal"))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Spacer()

                            Text("\(selectedStreams.count) selected")
                                .font(.custom(FontFamily.Rubik.regular, size: 14))
                                .foregroundColor(.secondary)
                        }

                        // Stream list
                        VStack(spacing: 6) {
                            ForEach(plaidService.recurringOutflows) { stream in
                                let isSelected = selectedStreams.contains(stream.streamId)

                                Button {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    if isSelected {
                                        selectedStreams.remove(stream.streamId)
                                    } else {
                                        selectedStreams.insert(stream.streamId)
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(isSelected ? Color("NormaPastelTeal") : .secondary.opacity(0.3))

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(stream.merchantName ?? stream.description ?? "Unknown")
                                                .font(.custom(FontFamily.Rubik.medium, size: 16))
                                                .foregroundColor(.primary)

                                            HStack(spacing: 6) {
                                                Text(stream.frequency.capitalized)
                                                    .font(.custom(FontFamily.Rubik.regular, size: 13))
                                                    .foregroundColor(.secondary)

                                                if let nextDate = stream.predictedNextDate {
                                                    Text("·")
                                                        .foregroundColor(.secondary.opacity(0.4))
                                                    Text("Next: \(nextDate)")
                                                        .font(.custom(FontFamily.Rubik.regular, size: 13))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }

                                        Spacer()

                                        Text(formatCurrency(stream.averageAmount))
                                            .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(.clear)
                                            .glassEffect(in: RoundedRectangle(cornerRadius: 14))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                isSelected ? Color("NormaPastelTeal").opacity(0.4) : Color.secondary.opacity(0.1),
                                                lineWidth: isSelected ? 1.5 : 0.5
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }

                // Add button pinned at bottom
                if !selectedStreams.isEmpty {
                    Button {
                        addSelectedBills()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.primary)
                                    .scaleEffect(0.8)
                            } else {
                                Text("Add \(selectedStreams.count) \(selectedStreams.count == 1 ? "Bill" : "Bills")")
                                    .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(.clear)
                                .glassEffect(in: RoundedRectangle(cornerRadius: 28))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                    }
                    .disabled(isSaving)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedStreams.isEmpty)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Detected Bills")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom(FontFamily.Rubik.medium, size: 16))
                }
            }
        }
    }

    private func addSelectedBills() {
        guard let userId = sessionViewModel.currentUser?.userId else { return }
        isSaving = true

        let streamsToAdd = plaidService.recurringOutflows.filter { selectedStreams.contains($0.streamId) }

        Task {
            for stream in streamsToAdd {
                await billViewModel.addBill(
                    name: stream.merchantName ?? stream.description ?? "Unknown",
                    amount: stream.averageAmount,
                    dueDate: parseDueDate(stream.predictedNextDate ?? stream.lastDate),
                    frequency: mapFrequency(stream.frequency),
                    merchant: stream.merchantName,
                    isReminderOn: true,
                    reminderDays: 3
                )
            }

            // Remove added streams from the list
            await MainActor.run {
                plaidService.recurringOutflows.removeAll { selectedStreams.contains($0.streamId) }
                selectedStreams.removeAll()
                isSaving = false

                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

                dismiss()
            }
        }
    }
}
