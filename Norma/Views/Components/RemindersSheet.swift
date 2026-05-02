//
//  RemindersSheet.swift
//  Norma
//
//  Sheet listing scheduled reminders + bill notifications. Reads pending
//  requests from UNUserNotificationCenter and renders them in the D9/D10
//  dark editorial language used by CalendarSheet and BillsView.
//

import SwiftUI
import SwiftData
import UserNotifications

struct RemindersSheet: View {
    @Binding var isPresented: Bool
    @State private var reminders: [LoadedReminder] = []
    @State private var isLoading = true
    @Environment(\.modelContext) private var modelContext

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private let accentPurple = Color(red: 0x96/255, green: 0x76/255, blue: 0xD9/255)

    private var heroFont: Font { .system(size: 56, weight: .heavy) }

    private struct LoadedReminder: Identifiable {
        let id: String
        let title: String
        let date: Date
        let kindLabel: String  // "bill" or "reminder"
        let amount: String?
        let recurrence: String? // "daily" | "weekly" | "monthly" | nil
    }

    var body: some View {
        VStack(spacing: 0) {
            dragHandle

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroBlock
                        .padding(.horizontal, 24)

                    listBlock
                        .padding(.horizontal, 24)
                        .padding(.top, 22)
                        .padding(.bottom, 32)
                }
            }
        }
        .background(bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .task { await loadReminders() }
    }

    // MARK: - Drag handle

    private var dragHandle: some View {
        Capsule()
            .fill(cream.opacity(0.2))
            .frame(width: 36, height: 4)
            .padding(.top, 6)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("reminders.")
                .font(heroFont)
                .tracking(-2.24)
                .foregroundStyle(cream)

            Text(eyebrowText)
                .font(.custom(FontFamily.Rubik.medium, size: 14))
                .foregroundStyle(mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var eyebrowText: String {
        if isLoading { return "loading…" }
        if reminders.isEmpty { return "nothing scheduled." }
        let count = reminders.count
        return "\(count) \(count == 1 ? "reminder" : "reminders") scheduled."
    }

    // MARK: - List

    @ViewBuilder
    private var listBlock: some View {
        if isLoading {
            EmptyView()
        } else if reminders.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(reminders) { reminder in
                    reminderCard(reminder)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ask norma to set a reminder, or write “remind me to…” in a note. it'll land here.")
                .font(.custom(FontFamily.Rubik.regular, size: 14))
                .foregroundStyle(dimText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
        }
    }

    @ViewBuilder
    private func reminderCard(_ item: LoadedReminder) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title.lowercased())
                    .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                    .tracking(-0.16)
                    .foregroundStyle(cream)
                Text(subtitleLabel(for: item))
                    .font(.custom(FontFamily.Rubik.medium, size: 12))
                    .foregroundStyle(accentPurple)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let amount = item.amount {
                Text(amount)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                    .tracking(-0.18)
                    .foregroundStyle(cream)
            }

            Button {
                cancel(item)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(mutedText)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle().stroke(
                            mutedText.opacity(0.6),
                            style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                        )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18).fill(accentPurple.opacity(0.06)))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accentPurple.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        )
    }

    private func subtitleLabel(for item: LoadedReminder) -> String {
        let prefix = formattedDate(for: item.date)
        if let rec = item.recurrence {
            return "\(prefix) · \(rec)"
        }
        return "\(prefix) · \(item.kindLabel)"
    }

    private func formattedDate(for date: Date) -> String {
        let cal = Calendar.current
        let f = DateFormatter()
        if cal.isDateInToday(date) {
            f.dateFormat = "'today at' h:mm a"
        } else if cal.isDateInTomorrow(date) {
            f.dateFormat = "'tomorrow at' h:mm a"
        } else if cal.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            f.dateFormat = "EEEE 'at' h:mm a"
        } else {
            f.dateFormat = "MMM d 'at' h:mm a"
        }
        return f.string(from: date).lowercased()
    }

    // MARK: - Data

    private func loadReminders() async {
        isLoading = true
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix("ai_reminder_") || $0.content.categoryIdentifier == "BILL_REMINDER" }

        let cal = Calendar.current
        let now = Date()
        var loaded: [LoadedReminder] = []
        for req in requests {
            guard let trigger = req.trigger as? UNCalendarNotificationTrigger,
                  let next = trigger.nextTriggerDate(),
                  next >= cal.startOfDay(for: now)
            else { continue }

            let isBill = req.content.categoryIdentifier == "BILL_REMINDER"
            let amountString: String? = {
                if let amt = req.content.userInfo["amount"] as? Double {
                    let f = NumberFormatter()
                    f.numberStyle = .currency
                    return f.string(from: NSNumber(value: amt))
                }
                return nil
            }()

            let title: String = {
                if isBill, let billName = req.content.userInfo["billName"] as? String, !billName.isEmpty {
                    return billName
                }
                return req.content.title
            }()

            let recurrenceRaw = req.content.userInfo["recurrence"] as? String
            let recurrence = (recurrenceRaw == "none" ? nil : recurrenceRaw)

            loaded.append(LoadedReminder(
                id: req.identifier,
                title: title,
                date: next,
                kindLabel: isBill ? "bill" : "reminder",
                amount: amountString,
                recurrence: recurrence
            ))
        }

        reminders = loaded.sorted { $0.date < $1.date }
        isLoading = false
    }

    private func cancel(_ item: LoadedReminder) {
        NotificationService.shared.cancelAIReminder(identifier: item.id)
        // If this reminder originated from a note token, clear its
        // confirmedAt so the chip on the note flips back to dashed and
        // the next LLM re-extraction's preservation logic doesn't zombie
        // a fresh OS notification back into existence.
        if let tokenId = NoteRepository.parseReminderTokenId(from: item.id) {
            NoteRepository(context: modelContext).unconfirmReminder(tokenId: tokenId)
        }
        reminders.removeAll { $0.id == item.id }
    }
}

#Preview {
    Color.black
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            RemindersSheet(isPresented: .constant(true))
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
}
