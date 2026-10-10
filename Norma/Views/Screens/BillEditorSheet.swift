//
//  BillEditorSheet.swift
//  Norma
//
//  Adds a new bill or edits an existing one. Edits stay in local state until
//  save, and the yearly projection updates live as the amount or frequency
//  changes.
//

import SwiftData
import SwiftUI
import UIKit

struct BillEditorSheet: View {
    /// nil adds a new bill.
    let bill: Bill?
    var initialDueDate: Date? = nil
    let currency: String

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var amountText = ""
    @State private var dueDate = Date()
    /// The occurrence the date picker showed when the sheet opened. Saving
    /// keeps the original anchor unless the user picks a different day.
    @State private var displayedDueDate = Date()
    @State private var frequency: BillFrequency = .monthly
    @State private var notes = ""
    @State private var isReminderOn = true
    @State private var showDeleteConfirm = false
    @State private var showReminderSettings = false
    @State private var dismissAfterReminderAlert = false
    @State private var saveError: String?
    @State private var isSaving = false
    /// Set once a new bill has been inserted, so a second save edits it.
    @State private var createdBill: Bill?
    @FocusState private var nameFocused: Bool

    private var amount: Double? { Money.parse(amountText, currency: currency) }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty && amount != nil }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    HeroTitle(text: bill == nil ? "new bill" : "edit bill", size: 44)

                    field("name") {
                        TextField("", text: $name, prompt: Text("rent, phone, netflix…").foregroundStyle(NormaPalette.inkMuted))
                            .font(.custom(FontFamily.Rubik.semiBold, size: 24))
                            .foregroundStyle(NormaPalette.ink)
                            .tint(NormaPalette.lavender)
                            .textInputAutocapitalization(.never)
                            .submitLabel(.next)
                            .focused($nameFocused)
                    }

                    field("amount") {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(Money.symbol(for: currency))
                                .font(.custom(FontFamily.Rubik.semiBold, size: 20))
                                .foregroundStyle(NormaPalette.inkSubtle)
                            TextField("0", text: $amountText)
                                .font(.custom(FontFamily.Rubik.semiBold, size: 24))
                                .foregroundStyle(NormaPalette.ink)
                                .tint(NormaPalette.lavender)
                                .keyboardType(.decimalPad)
                        }
                    }

                    field("how often") {
                        FlowLayout {
                            ForEach(BillFrequency.allCases) { option in
                                ChoicePill(label: option.label, isActive: frequency == option) { frequency = option }
                            }
                        }
                    }

                    field(frequency == .oneTime ? "due on" : "next due") {
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                            .labelsHidden()
                            .tint(NormaPalette.lavender)
                    }

                    if let amount {
                        projection(amount: amount)
                    }

                    Toggle(isOn: $isReminderOn) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("reminders")
                                .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                                .foregroundStyle(NormaPalette.ink)
                            Text("a nudge the day before and the morning it's due")
                                .font(.custom(FontFamily.Rubik.medium, size: 13))
                                .foregroundStyle(NormaPalette.inkSubtle)
                        }
                    }
                    .tint(NormaPalette.lavender)
                    .onChange(of: isReminderOn) { _, isOn in
                        guard isOn else { return }
                        Task { await requestReminderPermission(dismissOnDenial: false) }
                    }

                    field("notes") {
                        TextField("", text: $notes, prompt: Text("account number, autopay, anything").foregroundStyle(NormaPalette.inkMuted), axis: .vertical)
                            .font(.custom(FontFamily.Rubik.medium, size: 16))
                            .foregroundStyle(NormaPalette.ink)
                            .tint(NormaPalette.lavender)
                            .lineLimit(1...4)
                    }

                    if bill != nil {
                        deleteButton
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 48)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(NormaPalette.sheet.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                        .foregroundStyle(NormaPalette.ink.opacity(0.85))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(bill == nil ? "add" : "save", action: save)
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? NormaPalette.lavender : NormaPalette.inkMuted)
                        .disabled(!canSave || isSaving)
                }
            }
            .alert("delete \(trimmedName.lowercased())?", isPresented: $showDeleteConfirm) {
                Button("cancel", role: .cancel) {}
                Button("delete", role: .destructive, action: delete)
            } message: {
                Text("it'll be removed from every month.")
            }
            .alert("reminders are off", isPresented: $showReminderSettings) {
                Button("open settings") {
                    openNotificationSettings()
                    if dismissAfterReminderAlert { dismiss() }
                }
                Button("ok", role: .cancel) {
                    if dismissAfterReminderAlert { dismiss() }
                }
            } message: {
                Text("turn on notifications in settings to get a nudge the day before a bill is due.")
            }
            .alert(
                "couldn't save",
                isPresented: Binding(
                    get: { saveError != nil },
                    set: { if !$0 { saveError = nil } }
                )
            ) {
                Button("ok", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
        .onAppear(perform: hydrate)
    }

    // MARK: - Projection

    /// What this bill really costs: the payments left through December and,
    /// for recurring bills, the yearly total.
    private func projection(amount: Double) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let year = calendar.component(.year, from: today)
        let endOfYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) ?? today
        let anchor =
            bill.map {
                Bill.anchorToSave(existingAnchor: $0.dueDate, displayedDay: displayedDueDate, pickedDay: dueDate, calendar: calendar)
            } ?? dueDate
        let remaining = frequency.occurrences(anchor: anchor, from: today, through: endOfYear, calendar: calendar).count
        let perYear = 12 / (frequency.monthsBetweenOccurrences ?? 12)
        let minor = Money.minorUnits(fromMajor: amount, currency: currency)

        return VStack(spacing: 0) {
            projectionRow(
                label: "rest of \(String(year))",
                caption: "\(remaining) \(remaining == 1 ? "payment" : "payments") left",
                value: Money.format(minorUnits: minor * remaining, currency: currency)
            )
            if frequency != .oneTime {
                Divider().overlay(NormaPalette.ink.opacity(0.08))
                projectionRow(label: "per year", caption: nil, value: Money.format(minorUnits: minor * perYear, currency: currency))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(NormaPalette.ink.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(NormaPalette.ink.opacity(0.08)))
        .contentTransition(.numericText())
        .animation(.snappy, value: frequency)
    }

    private func projectionRow(label: String, caption: String?, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 13))
                    .foregroundStyle(NormaPalette.ink.opacity(0.85))
                if let caption {
                    Text(caption)
                        .font(.custom(FontFamily.Rubik.medium, size: 11))
                        .foregroundStyle(NormaPalette.inkSubtle)
                }
            }
            Spacer(minLength: 12)
            Text(value)
                .font(.custom(FontFamily.Rubik.bold, size: 20))
                .foregroundStyle(NormaPalette.lavender)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Building blocks

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            FieldLabel(label)
            content()
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            Haptics.firm()
            showDeleteConfirm = true
        } label: {
            Text("delete bill")
                .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                .foregroundStyle(NormaPalette.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay(
                    Capsule().strokeBorder(NormaPalette.danger.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    // MARK: - State

    private func hydrate() {
        guard let bill else {
            dueDate = initialDueDate ?? Date()
            nameFocused = true
            return
        }
        name = bill.name
        amountText = Money.editableText(bill.amount, currency: currency)
        // Editing shows the next upcoming occurrence rather than the original
        // anchor, which may be months in the past. `displayedDueDate` is what
        // save compares against so a frequency change doesn't rewrite the anchor.
        let shown = bill.nextOccurrence(onOrAfter: Date()) ?? bill.dueDate
        displayedDueDate = shown
        dueDate = shown
        frequency = bill.frequency
        notes = bill.notes ?? ""
        isReminderOn = bill.isReminderOn
    }

    private func save() {
        guard !isSaving, canSave, let amount else { return }
        isSaving = true
        Task {
            await commit(amount: amount)
            isSaving = false
        }
    }

    private func commit(amount: Double) async {
        if isReminderOn {
            let allowed = await requestReminderPermission(dismissOnDenial: true)
            guard allowed else { return }
        }
        guard write(amount: amount, reminders: isReminderOn) else { return }
        dismiss()
    }

    /// Returns true when reminders may stay on. A denial turns the toggle off,
    /// saves the bill that way, and offers Settings.
    private func requestReminderPermission(dismissOnDenial: Bool) async -> Bool {
        let decision = await NotificationService.permissionDecision()
        guard decision == .turnOffAndOpenSettings else { return true }
        isReminderOn = false
        dismissAfterReminderAlert = dismissOnDenial
        if dismissOnDenial, let amount {
            guard write(amount: amount, reminders: false) else { return false }
        }
        showReminderSettings = true
        return false
    }

    @discardableResult
    private func write(amount: Double, reminders: Bool) -> Bool {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let target: Bill
        let insertedNew: Bool
        if let bill {
            target = bill
            insertedNew = false
            target.dueDate = Bill.anchorToSave(
                existingAnchor: bill.dueDate,
                displayedDay: displayedDueDate,
                pickedDay: dueDate
            )
            target.name = trimmedName
            target.amount = amount
            target.frequency = frequency
        } else if let createdBill {
            target = createdBill
            insertedNew = false
            target.dueDate = dueDate
            target.name = trimmedName
            target.amount = amount
            target.frequency = frequency
        } else {
            target = Bill(name: trimmedName, amount: amount, dueDate: dueDate, frequency: frequency)
            createdBill = target
            insertedNew = true
            modelContext.insert(target)
        }
        target.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        target.isReminderOn = reminders
        guard Persistence.save(modelContext) else {
            if insertedNew { createdBill = nil }
            saveError = Persistence.saveFailure
            return false
        }
        Haptics.success()
        if reminders {
            Task { await NotificationService.scheduleReminders(for: target, currency: currency) }
        } else {
            NotificationService.cancelReminders(for: target)
        }
        return true
    }

    private func delete() {
        guard let bill else { return }
        let billID = bill.id
        modelContext.delete(bill)
        guard Persistence.save(modelContext) else {
            saveError = Persistence.saveFailure
            return
        }
        NotificationService.cancelReminders(forBillID: billID)
        dismiss()
    }

    private func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
