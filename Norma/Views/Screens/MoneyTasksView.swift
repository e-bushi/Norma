//
//  MoneyTasksView.swift
//  Norma
//
//  Minimal full-screen view for managing AI-scheduled reminders.
//

import SwiftUI
import UserNotifications

struct MoneyTasksView: View {
    @Binding var isMenuOpen: Bool
    @State private var reminders: [UNNotificationRequest] = []
    @State private var isLoading = true

    var body: some View {
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
        .background(Color("NormaBackground"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isMenuOpen = true
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Money Tasks")
                    .font(.custom(FontFamily.Rubik.medium, size: 22))
                    .foregroundColor(.primary)
            }
        }
        .task {
            await loadReminders()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))

            Text("No tasks yet")
                .font(.custom(FontFamily.Rubik.medium, size: 18))
                .foregroundColor(.primary)

            Text("Ask Norma to set a reminder\nand it will appear here")
                .font(.custom(FontFamily.Rubik.regular, size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var remindersList: some View {
        List {
            ForEach(reminders, id: \.identifier) { reminder in
                ReminderRow(reminder: reminder)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
            }
            .onDelete(perform: deleteReminders)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
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

#Preview {
    NavigationStack {
        MoneyTasksView(isMenuOpen: .constant(false))
    }
}
