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
                    VStack(spacing: 2) {
                        Text("Money Tasks")
                            .font(.custom(FontFamily.Rubik.semiBold, size: 17))
                        Text("\(reminders.count) of 64 slots used")
                            .font(.custom(FontFamily.Rubik.regular, size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .alert("About Task Slots", isPresented: $showInfoAlert) {
                Button("Got it", role: .cancel) { }
            } message: {
                Text("iOS limits apps to 64 pending notifications. This is a system-wide limit.\n\nRecurring tasks only use 1 slot, making them efficient for regular reminders like weekly budget check-ins.")
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
                    .listRowInsets(EdgeInsets(top: 4, leading: 24, bottom: 4, trailing: 24))
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
        HStack(spacing: 12) {
            Image(systemName: isRecurring ? "repeat" : "bell.fill")
                .font(.system(size: 16))
                .foregroundColor(Color("NormaPastelCoral"))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color("NormaPastelCoral").opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(reminder.content.title)
                        .font(.custom(FontFamily.Rubik.medium, size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if isRecurring {
                        Text(recurrenceText)
                            .font(.custom(FontFamily.Rubik.medium, size: 10))
                            .foregroundColor(Color("NormaPastelCoral"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color("NormaPastelCoral").opacity(0.15))
                            )
                    }
                }

                Text(formattedDate)
                    .font(.custom(FontFamily.Rubik.regular, size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RemindersSheet(isPresented: .constant(true))
}
