//
//  MiniExpenseCalendarView.swift
//  Norma
//
//  Created by Claude on 8/2/25.
//

import SwiftUI

struct MiniExpenseCalendarView: View {
    let appeared: Bool

    @State private var dayStates: [Bool] = Array(repeating: false, count: 31)

    var body: some View {
        VStack(spacing: 16) {
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
                        let index = day - 1
                        Text("\(day)")
                            .font(.system(size: 10))
                            .foregroundColor(.primary)
                            .frame(width: 20, height: 20)
                            .padding(.vertical, 4)
                            .background(
                                Circle()
                                    .fill(day % 3 == 0 ? Color("NormaPastelTeal").opacity(0.1) : Color.clear)
                                    .scaleEffect(dayStates[index] ? 1.0 : 0.3)
                                    .opacity(dayStates[index] ? 1.0 : 0)
                            )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.clear)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 16))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
            )
        }
        .onChange(of: appeared) { _, isAppeared in
            if isAppeared {
                animateDaysStaggered()
            } else {
                resetAnimations()
            }
        }
    }

    private func animateDaysStaggered() {
        for i in 0..<dayStates.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    dayStates[i] = true
                }
            }
        }
    }

    private func resetAnimations() {
        dayStates = Array(repeating: false, count: 31)
    }
}

#Preview {
    MiniExpenseCalendarView(appeared: true)
        .padding()
}