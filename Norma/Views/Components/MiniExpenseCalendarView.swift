//
//  MiniExpenseCalendarView.swift
//  Norma
//
//  Created by Claude on 8/2/25.
//

import SwiftUI

struct MiniExpenseCalendarView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Text("AUGUST EXPENSES")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("This Month")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("$1,850")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Active Days")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("12")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.purple)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            
            // Mini calendar grid
            VStack(spacing: 8) {
                HStack {
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                    ForEach(1...31, id: \.self) { day in
                        Text("\(day)")
                            .font(.system(size: 10))
                            .foregroundColor(.primary)
                            .frame(width: 20, height: 20)
                            .padding(.vertical, 4)
                            .background(
                                Circle()
                                    .fill(day % 3 == 0 ? Color.purple.opacity(0.1) : Color.clear)
                            )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    MiniExpenseCalendarView()
        .padding()
}