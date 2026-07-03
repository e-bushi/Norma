//
//  ChipView.swift
//  Norma
//
//  Created by Claude on 4/25/26.
//

import SwiftUI

struct ChipView: View {
    let token: NoteToken
    var style: Style = .inline
    /// Wired by the note canvas for reminder chips. When set, an unconfirmed
    /// reminder becomes tappable: tap opens a date/time picker, picker confirm
    /// calls this with the chosen fire time. Nil = chip is non-interactive
    /// (used in previews, sample data).
    var onConfirmReminder: ((Date) -> Void)? = nil

    @State private var showingPicker: Bool = false
    @State private var pickerDate: Date = Date()

    enum Style {
        case inline
        case card
    }

    var body: some View {
        if token.kind == .reminder {
            reminderBody
        } else {
            financialBody
        }
    }

    // MARK: - Financial chip (expense / bill / income / transfer)

    private var financialBody: some View {
        HStack(spacing: spacing) {
            Circle()
                .fill(NormaPalette.lavender)
                .frame(width: dotSize, height: dotSize)

            if let label = leadingLabel {
                Text(label)
                    .font(.system(size: labelSize, weight: .medium))
                    .tracking(1.6)
                    .foregroundStyle(NormaPalette.lavender)
            }

            if style == .card, let subject = token.subject {
                separator
                Text(subject)
                    .font(.system(size: bodySize))
                    .foregroundStyle(NormaPalette.lavenderText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            separator
            Text(formattedValue)
                .font(.system(size: bodySize, weight: style == .card ? .medium : .regular))
                .foregroundStyle(NormaPalette.lavenderText)

            if style == .inline, let counterparty = token.counterparty {
                separator
                Text(Self.truncatedChipText(counterparty).uppercased())
                    .font(.system(size: labelSize, weight: .medium))
                    .tracking(1.6)
                    .foregroundStyle(NormaPalette.lavender)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .glassEffect(in: shape)
        .overlay(shape.stroke(NormaPalette.lavender.opacity(0.7), lineWidth: 1))
        .fixedSize(horizontal: style == .inline, vertical: true)
    }

    // MARK: - Reminder chip
    //
    // Three visual states, all sharing the same capsule shape so the chip reads
    // as part of the same family as the financial chips:
    //   1. Confirmed (remindAt + confirmedAt set) — solid border, shows the
    //      scheduled fire time. Tap is a no-op.
    //   2. Has time, awaiting confirmation — dashed border, shows the proposed
    //      time. Tap opens the picker (pre-filled with the proposed time) so
    //      the user can verify or adjust before scheduling.
    //   3. Needs time — dashed border, "SET TIME" hint in place of a time.
    //      Tap opens the picker defaulted to the next 9 AM local.

    private var reminderBody: some View {
        let confirmed = token.confirmedAt != nil
        let interactive = !confirmed && onConfirmReminder != nil

        let chip = HStack(spacing: spacing) {
            Circle()
                .fill(NormaPalette.lavender)
                .frame(width: dotSize, height: dotSize)

            Text("REMINDER")
                .font(.system(size: labelSize, weight: .medium))
                .tracking(1.6)
                .foregroundStyle(NormaPalette.lavender)

            if let subject = token.subject, !subject.isEmpty {
                separator
                Text(Self.truncatedChipText(subject))
                    .font(.system(size: bodySize))
                    .foregroundStyle(NormaPalette.lavenderText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            separator

            if let remindAt = token.remindAt {
                Text(Self.formatReminderTime(remindAt))
                    .font(.system(size: labelSize, weight: .medium))
                    .tracking(1.6)
                    .foregroundStyle(NormaPalette.lavender)
            } else {
                Text("SET TIME")
                    .font(.system(size: labelSize, weight: .medium))
                    .tracking(1.6)
                    .foregroundStyle(NormaPalette.lavender)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .glassEffect(in: shape)
        .overlay(reminderBorder(confirmed: confirmed))
        .fixedSize(horizontal: style == .inline, vertical: true)

        return Group {
            if interactive {
                Button(action: openPicker) { chip }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingPicker) {
                        ReminderPickerPopover(
                            initialDate: $pickerDate,
                            onConfirm: { date in
                                showingPicker = false
                                onConfirmReminder?(date)
                            },
                            onCancel: { showingPicker = false }
                        )
                        .presentationCompactAdaptation(.popover)
                    }
            } else {
                chip
            }
        }
    }

    private func openPicker() {
        pickerDate = token.remindAt ?? Self.defaultPickerDate()
        showingPicker = true
    }

    @ViewBuilder
    private func reminderBorder(confirmed: Bool) -> some View {
        if confirmed {
            shape.stroke(NormaPalette.lavender.opacity(0.7), lineWidth: 1)
        } else {
            shape.stroke(
                NormaPalette.lavender.opacity(0.7),
                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
            )
        }
    }

    // MARK: - Shared helpers

    private var shape: AnyShape {
        switch style {
        case .inline: return AnyShape(Capsule())
        case .card: return AnyShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var separator: some View {
        Text("·")
            .font(.system(size: labelSize))
            .foregroundStyle(NormaPalette.lavender.opacity(0.55))
    }

    private var leadingLabel: String? {
        switch token.kind {
        case .income:
            return "INCOME"
        case .transfer:
            return "TRANSFER"
        case .bill:
            return token.category?.displayName.uppercased()
        case .reminder:
            return "REMINDER"
        case .intent:
            return "INTENTION"
        case .commit:
            return "COMMITMENT"
        case .billPayment:
            return token.subject.map { Self.truncatedChipText($0).uppercased() }
        }
    }

    /// Cap user-derived chip text (subject, counterparty) so the chip stays
    /// inside one row of the canvas regardless of what the LLM extracts.
    static let chipTextMaxLength = 12

    static func truncatedChipText(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > chipTextMaxLength else { return trimmed }
        let head = trimmed.prefix(chipTextMaxLength - 1)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(head)…"
    }

    static func formatReminderTime(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.minute], from: date)
        let formatter = DateFormatter()
        formatter.dateFormat = (comps.minute == 0) ? "MMM d · h a" : "MMM d · h:mm a"
        return formatter.string(from: date).uppercased()
    }

    /// Next 9 AM local — matches the LLM's fallback convention so the picker
    /// defaults to the same time the extractor would have proposed.
    static func defaultPickerDate(now: Date = Date(), calendar: Calendar = .current) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 9
        components.minute = 0
        let candidate = calendar.date(from: components) ?? now
        if candidate <= now {
            return calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }
        return candidate
    }

    private var formattedValue: String {
        let amount = token.amount
        let symbol = NormaPalette.currencySymbol(for: token.currency)
        let formatted: String
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            formatted = String(format: "%.0f", amount)
        } else {
            formatted = String(format: "%.2f", amount)
        }
        let withSeparators = NormaPalette.thousandsSeparated(formatted)
        let signPrefix = token.kind == .income ? "+" : ""
        switch token.currency.uppercased() {
        case "USD", "CAD", "AUD", "NZD":
            return "\(signPrefix)\(symbol)\(withSeparators)"
        default:
            return "\(signPrefix)\(withSeparators)\(symbol)"
        }
    }

    private var dotSize: CGFloat { style == .card ? 6 : 5 }
    private var labelSize: CGFloat { style == .card ? 11 : 10 }
    private var bodySize: CGFloat { style == .card ? 15 : 12 }
    private var spacing: CGFloat { style == .card ? 10 : 6 }
    private var horizontalPadding: CGFloat { style == .card ? 18 : 10 }
    private var verticalPadding: CGFloat { style == .card ? 18 : 5 }
}

enum NormaPalette {
    /// User-selectable accent — reads the persisted `AppTheme` choice.
    /// Every existing call site stays a plain color read, so changing the
    /// theme in Settings updates the whole app without further wiring.
    static var lavender: Color { AppTheme.current.color }
    static let lavenderText = Color(red: 0.91, green: 0.86, blue: 1.0)
    static let canvas = Color(red: 0.055, green: 0.055, blue: 0.063)
    static let cardSurface = Color(red: 0.102, green: 0.078, blue: 0.149)
    /// Warm off-white from the D5 design (#F2EDE2). Use instead of pure white.
    static let ink = Color(red: 0.949, green: 0.929, blue: 0.886)
    /// Muted dark gray for section headers, indices, /count meta (#5C5852).
    static let inkMuted = Color(red: 0.361, green: 0.345, blue: 0.322)
    /// Mid-warm gray for preview text, secondary labels (#7A7670).
    static let inkSubtle = Color(red: 0.478, green: 0.463, blue: 0.439)

    static func currencySymbol(for code: String) -> String {
        switch code.uppercased() {
        case "USD", "CAD", "AUD", "NZD", "SGD", "HKD": return "$"
        case "THB": return "฿"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY", "CNY": return "¥"
        case "INR": return "₹"
        case "KRW": return "₩"
        case "VND": return "₫"
        case "PHP": return "₱"
        case "MXN": return "$"
        case "BRL": return "R$"
        default: return code
        }
    }

    static func thousandsSeparated(_ s: String) -> String {
        let parts = s.split(separator: ".", maxSplits: 1).map(String.init)
        let intPart = parts[0]
        let decimal = parts.count > 1 ? "." + parts[1] : ""
        var result = ""
        let reversed = Array(intPart.reversed())
        for (i, c) in reversed.enumerated() {
            if i != 0 && i % 3 == 0 { result.append(",") }
            result.append(c)
        }
        return String(result.reversed()) + decimal
    }
}

/// Inline confirmation popover for reminder chips. Shows a compact date+time
/// picker pre-filled with the LLM's proposed time (or next 9 AM if missing),
/// plus confirm/cancel actions. Lives in this file alongside ChipView since
/// it's only used by the reminder-chip path.
struct ReminderPickerPopover: View {
    @Binding var initialDate: Date
    let onConfirm: (Date) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WHEN SHOULD WE REMIND YOU?")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.6)
                .foregroundStyle(NormaPalette.lavender)

            DatePicker(
                "",
                selection: $initialDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .tint(NormaPalette.lavender)

            HStack(spacing: 10) {
                Button(action: onCancel) {
                    Text("cancel")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(NormaPalette.lavender.opacity(0.7))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .overlay(
                            Capsule().stroke(
                                NormaPalette.lavender.opacity(0.5),
                                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                            )
                        )
                }
                .buttonStyle(.plain)

                Button(action: { onConfirm(initialDate) }) {
                    Text("confirm")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(NormaPalette.canvas)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Capsule().fill(NormaPalette.lavender))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(width: 280)
        .background(NormaPalette.canvas)
    }
}
