//
//  BillDetailSheet.swift
//  Norma
//
//  Bill detail + edit sheet, presented when a bill row is tapped in the
//  ForecastSheet. Lets the user edit the bill's fields, toggle notifications
//  (a day-before + day-of reminder), or delete it. Styling matches the
//  ForecastSheet's dark + lavender palette so the two read as one surface.
//

import SwiftUI

struct BillDetailSheet: View {
    /// The bill being edited. Captured into local state on appear; the original
    /// is only touched when the user saves.
    let bill: Bill

    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    // Editable form state, hydrated from `bill` on appear.
    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var dueDate: Date = Date()
    @State private var frequency: BillFrequency = .monthly
    @State private var merchant: String = ""
    @State private var notes: String = ""
    @State private var isReminderOn: Bool = true

    @State private var isSaving = false
    @State private var showDeleteConfirm = false

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private let onAccentText = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255)
    private var accentPurple: Color { NormaPalette.lavender }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    nameField
                    amountField
                    dueDateField
                    frequencyField
                    reminderField
                    merchantField
                    notesField
                    deleteButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 48)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(bg.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(cream.opacity(0.85))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: save) {
                        Text(isSaving ? "saving…" : "save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(canSave ? accentPurple : cream.opacity(0.4))
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .alert("delete bill?", isPresented: $showDeleteConfirm) {
                Button("cancel", role: .cancel) {}
                Button("delete", role: .destructive) { performDelete() }
            } message: {
                Text("this will remove \(bill.name) permanently.")
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: hydrate)
    }

    // MARK: - Fields

    private var nameField: some View {
        fieldGroup("name") {
            TextField("", text: $name)
                .font(.custom(FontFamily.Rubik.semiBold, size: 24))
                .foregroundStyle(cream)
                .tint(accentPurple)
                .textFieldStyle(.plain)
        }
    }

    private var amountField: some View {
        fieldGroup("amount") {
            HStack(spacing: 6) {
                Text(currency)
                    .font(.custom(FontFamily.Rubik.medium, size: 16))
                    .foregroundStyle(mutedText)
                TextField("0", text: $amountText)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 24))
                    .foregroundStyle(cream)
                    .tint(accentPurple)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
            }
        }
    }

    private var dueDateField: some View {
        fieldGroup("due date") {
            DatePicker("", selection: $dueDate, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(accentPurple)
        }
    }

    private var frequencyField: some View {
        fieldGroup("frequency") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BillFrequency.allCases, id: \.self) { freq in
                        pill(freq.displayLabel, active: frequency == freq) {
                            frequency = freq
                        }
                    }
                }
            }
        }
    }

    private var reminderField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: $isReminderOn) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("reminders")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                        .foregroundStyle(cream)
                    Text("a nudge the day before and on the due date")
                        .font(.custom(FontFamily.Rubik.medium, size: 13))
                        .foregroundStyle(mutedText)
                }
            }
            .tint(accentPurple)
            .onChange(of: isReminderOn) { _, newValue in
                // Prompt for permission the moment the user opts in, if we
                // haven't asked yet — so the toggle actually has teeth.
                if newValue {
                    Task { await NotificationService.shared.ensurePermission() }
                }
            }
        }
    }

    private var merchantField: some View {
        fieldGroup("merchant (optional)") {
            TextField("", text: $merchant, prompt: Text("who's it to?").foregroundStyle(dimText))
                .font(.custom(FontFamily.Rubik.medium, size: 16))
                .foregroundStyle(cream)
                .tint(accentPurple)
                .textFieldStyle(.plain)
        }
    }

    private var notesField: some View {
        fieldGroup("notes (optional)") {
            TextField("", text: $notes, prompt: Text("anything to remember").foregroundStyle(dimText), axis: .vertical)
                .font(.custom(FontFamily.Rubik.medium, size: 16))
                .foregroundStyle(cream)
                .tint(accentPurple)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            showDeleteConfirm = true
        } label: {
            Text("delete bill")
                .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                .foregroundStyle(Color(red: 0xE0/255, green: 0x6C/255, blue: 0x6C/255))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay(
                    Capsule().stroke(
                        Color(red: 0xE0/255, green: 0x6C/255, blue: 0x6C/255).opacity(0.4),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    // MARK: - Building blocks

    @ViewBuilder
    private func fieldGroup<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                .tracking(0.88)
                .textCase(.uppercase)
                .foregroundStyle(mutedText)
            content()
        }
    }

    /// Capsule selector following the app's core pattern: active = solid accent
    /// fill, inactive = dashed border.
    @ViewBuilder
    private func pill(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                action()
            }
        } label: {
            Text(label.lowercased())
                .font(.custom(active ? FontFamily.Rubik.semiBold : FontFamily.Rubik.medium, size: 13))
                .foregroundStyle(active ? onAccentText : cream)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background {
                    if active { Capsule().fill(accentPurple) }
                }
                .overlay(
                    Capsule().stroke(
                        active ? accentPurple : cream.opacity(0.32),
                        style: active ? StrokeStyle(lineWidth: 1) : StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - State

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (Double(amountText) ?? 0) > 0
    }

    private func hydrate() {
        name = bill.name
        amountText = bill.amount == 0 ? "" : String(format: "%g", bill.amount)
        dueDate = bill.dueDate
        frequency = bill.frequency
        merchant = bill.merchant ?? ""
        notes = bill.notes ?? ""
        isReminderOn = bill.isReminderOn
    }

    private func save() {
        guard canSave else { return }
        isSaving = true
        var updated = bill
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.amount = Double(amountText) ?? bill.amount
        updated.dueDate = dueDate
        updated.frequency = frequency
        updated.merchant = merchant.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil : merchant.trimmingCharacters(in: .whitespaces)
        updated.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil : notes.trimmingCharacters(in: .whitespaces)
        updated.isReminderOn = isReminderOn

        Task {
            // updateBill persists and (re)schedules or cancels notifications
            // based on isReminderOn.
            await billViewModel.updateBill(updated)
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }

    private func performDelete() {
        Task {
            await billViewModel.deleteBill(bill)
            await MainActor.run { dismiss() }
        }
    }
}

// MARK: - Frequency display label

private extension BillFrequency {
    var displayLabel: String {
        switch self {
        case .oneTime: return "one-time"
        case .monthly: return "monthly"
        case .quarterly: return "quarterly"
        case .yearly: return "yearly"
        }
    }
}
