//
//  ReminderToggleRow.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import SwiftUI

struct ReminderToggleRow: View {
    let isReminderOn: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reminders")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(isReminderOn ? "Notifications enabled" : "Notifications disabled")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Toggle("", isOn: .init(
                get: { isReminderOn },
                set: { onToggle($0) }
            ))
            .labelsHidden()
            .tint(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: 20) {
        ReminderToggleRow(isReminderOn: true) { _ in }
        ReminderToggleRow(isReminderOn: false) { _ in }
    }
    .padding()
}