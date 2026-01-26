//
//  RemindersSheet.swift
//  Norma
//
//  Half-sheet displaying scheduled AI reminders
//

import SwiftUI
import UserNotifications

struct RemindersSheet: View {
    @Binding var isPresented: Bool
    @State private var reminders: [UNNotificationRequest] = []
    @State private var isLoading = true
    @State private var showInfoAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if reminders.isEmpty {
                    emptyState
                } else {
                    remindersList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showInfoAlert = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 6) {
                        Text("Money Tasks")
                            .font(.custom(FontFamily.Rubik.semiBold, size: 17))

                        // Segmented progress bar (8 segments, 8 slots each)
                        HStack(spacing: 3) {
                            ForEach(0..<8, id: \.self) { segment in
                                let slotsPerSegment = 8
                                let segmentStart = segment * slotsPerSegment
                                let fillRatio = min(1.0, max(0.0, Double(reminders.count - segmentStart) / Double(slotsPerSegment)))

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(fillRatio > 0 ? Color("NormaPastelTeal") : Color.secondary.opacity(0.2))
                                    .frame(width: 12, height: 6)
                            }
                        }
                    }
                }
            }
            .alert("A little heads up", isPresented: $showInfoAlert) {
                Button("Got it", role: .cancel) { }
            } message: {
                Text("I can keep track of 64 reminders for you at a time. Pro tip: recurring ones only count as one — perfect for weekly check-ins!")
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .task {
            await loadReminders()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No reminders")
                .font(.custom(FontFamily.Rubik.medium, size: 18))
                .foregroundColor(.primary)

            Text("Ask Norma to set a reminder\nand it will appear here")
                .font(.custom(FontFamily.Rubik.regular, size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var remindersList: some View {
        List {
            ForEach(reminders, id: \.identifier) { reminder in
                ReminderRow(reminder: reminder)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
            }
            .onDelete(perform: deleteReminders)
        }
        .listStyle(.plain)
    }

    private func loadReminders() async {
        isLoading = true
        reminders = await NotificationService.shared.getPendingAIReminders()
            .sorted { first, second in
                guard let trigger1 = first.trigger as? UNCalendarNotificationTrigger,
                      let trigger2 = second.trigger as? UNCalendarNotificationTrigger,
                      let date1 = trigger1.nextTriggerDate(),
                      let date2 = trigger2.nextTriggerDate() else {
                    return false
                }
                return date1 < date2
            }
        isLoading = false
    }

    private func deleteReminders(at offsets: IndexSet) {
        for index in offsets {
            let reminder = reminders[index]
            NotificationService.shared.cancelAIReminder(identifier: reminder.identifier)
        }
        reminders.remove(atOffsets: offsets)
    }
}

struct ReminderRow: View {
    let reminder: UNNotificationRequest

    private var triggerDate: Date? {
        guard let trigger = reminder.trigger as? UNCalendarNotificationTrigger else {
            return nil
        }
        return trigger.nextTriggerDate()
    }

    private var recurrence: String? {
        guard let recurrenceValue = reminder.content.userInfo["recurrence"] as? String,
              recurrenceValue != "none" else {
            return nil
        }
        return recurrenceValue
    }

    private var isRecurring: Bool {
        recurrence != nil
    }

    private var formattedDate: String {
        guard let date = triggerDate else { return "Unknown" }

        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow at' h:mm a"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE 'at' h:mm a"
        } else {
            formatter.dateFormat = "MMM d 'at' h:mm a"
        }

        return formatter.string(from: date)
    }

    private var recurrenceText: String {
        guard let rec = recurrence else { return "" }
        switch rec {
        case "daily": return "Daily"
        case "weekly": return "Weekly"
        case "monthly": return "Monthly"
        default: return ""
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isRecurring ? "repeat" : "bell.fill")
                .font(.system(size: 18))
                .foregroundColor(Color("NormaPastelCoral"))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color("NormaPastelCoral").opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(reminder.content.title)
                        .font(.custom(FontFamily.Rubik.medium, size: 17))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if isRecurring {
                        Text(recurrenceText)
                            .font(.custom(FontFamily.Rubik.medium, size: 11))
                            .foregroundColor(Color("NormaPastelCoral"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color("NormaPastelCoral").opacity(0.15))
                            )
                    }
                }

                Text(formattedDate)
                    .font(.custom(FontFamily.Rubik.regular, size: 15))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    RemindersSheet(isPresented: .constant(true))
}
