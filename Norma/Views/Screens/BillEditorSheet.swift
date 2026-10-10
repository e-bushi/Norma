//
//  BillEditorSheet.swift
//  Norma
//
//  Adds a new bill or edits an existing one. Edits stay in local state until
//  save, and the yearly projection updates live as the amount or frequency
//  changes.
//

import SwiftUI
import SwiftData

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
    @State private var frequency: BillFrequency = .monthly
    @State private var notes = ""
    @State private var isReminderOn = true
    @State private var showDeleteConfirm = false
    @FocusState private var nameFocused: Bool

    private var amount: Double? { Money.parse(amountText) }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty && amount != nil }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    HeroTitle(text: bill == nil ? "new bill" : "edit bill", size: 44)

                    field("name") {
                        TextField("", text: $name, prompt: Text("rent, phone, netflix…").foregroundStyle(NormaPalette.inkMuted))
                            .rubik(FontFamily.Rubik.semiBold, size: 24, relativeTo: .title2)
                            .foregroundStyle(NormaPalette.ink)
                            .tint(NormaPalette.lavender)
                            .textInputAutocapitalization(.never)
                            .submitLabel(.next)
                            .focused($nameFocused)
                    }

                    field("amount") {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(Money.symbol(for: currency))
                                .rubik(FontFamily.Rubik.semiBold, size: 20, relativeTo: .title3)
                                .foregroundStyle(NormaPalette.inkSubtle)
                            TextField("0", text: $amountText)
                                .rubik(FontFamily.Rubik.semiBold, size: 24, relativeTo: .title2)
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
                                .rubik(FontFamily.Rubik.semiBold, size: 16, relativeTo: .body)
                                .foregroundStyle(NormaPalette.ink)
                            Text("a nudge the day before and the morning it's due")
                                .rubik(FontFamily.Rubik.medium, size: 13, relativeTo: .footnote)
                                .foregroundStyle(NormaPalette.inkSubtle)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(NormaPalette.lavender)
                    .onChange(of: isReminderOn) { _, isOn in
                        if isOn { Task { await NotificationService.ensurePermission() } }
                    }

                    field("notes") {
                        TextField("", text: $notes, prompt: Text("account number, autopay, anything").foregroundStyle(NormaPalette.inkMuted), axis: .vertical)
                            .rubik(FontFamily.Rubik.medium, size: 16, relativeTo: .body)
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
                        .disabled(!canSave)
                }
            }
            .alert("delete \(trimmedName.lowercased())?", isPresented: $showDeleteConfirm) {
                Button("cancel", role: .cancel) {}
                Button("delete", role: .destructive, action: delete)
            } message: {
                Text("it'll be removed from every month.")
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
        let remaining = frequency.occurrences(anchor: dueDate, from: today, through: endOfYear, calendar: calendar).count
        let perYear = 12 / (frequency.monthsBetweenOccurrences ?? 12)

        return VStack(spacing: 0) {
            projectionRow(
                label: "rest of \(String(year))",
                caption: "\(remaining) \(remaining == 1 ? "payment" : "payments") left",
                value: Money.format(Double(remaining) * amount, currency: currency)
            )
            if frequency != .oneTime {
                Divider().overlay(NormaPalette.ink.opacity(0.08))
                projectionRow(label: "per year", caption: nil, value: Money.format(Double(perYear) * amount, currency: currency))
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
                    .rubik(FontFamily.Rubik.semiBold, size: 13, relativeTo: .footnote)
                    .foregroundStyle(NormaPalette.ink.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                if let caption {
                    Text(caption)
                        .rubik(FontFamily.Rubik.medium, size: 11, relativeTo: .caption2)
                        .foregroundStyle(NormaPalette.inkSubtle)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 12)
            Text(value)
                .rubik(FontFamily.Rubik.bold, size: 20, relativeTo: .title3)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
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
                .rubik(FontFamily.Rubik.semiBold, size: 15, relativeTo: .body)
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
        amountText = Money.editableText(bill.amount)
        // Editing shows the next upcoming occurrence rather than the original
        // anchor, which may be months in the past.
        dueDate = bill.nextOccurrence(onOrAfter: Date()) ?? bill.dueDate
        frequency = bill.frequency
        notes = bill.notes ?? ""
        isReminderOn = bill.isReminderOn
    }

    private func save() {
        guard canSave, let amount else { return }
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let target: Bill
        if let bill {
            target = bill
            if !Calendar.current.isDate(bill.nextOccurrence(onOrAfter: Date()) ?? bill.dueDate, inSameDayAs: dueDate)
                || bill.frequency != frequency {
                target.dueDate = dueDate
            }
            target.name = trimmedName
            target.amount = amount
            target.frequency = frequency
        } else {
            target = Bill(name: trimmedName, amount: amount, dueDate: dueDate, frequency: frequency)
            modelContext.insert(target)
        }
        target.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        target.isReminderOn = isReminderOn
        try? modelContext.save()

        Haptics.success()
        Task { await NotificationService.scheduleReminders(for: target, currency: currency) }
        dismiss()
    }

    private func delete() {
        guard let bill else { return }
        NotificationService.cancelReminders(for: bill)
        modelContext.delete(bill)
        try? modelContext.save()
        dismiss()
    }
}
