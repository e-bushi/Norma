//
//  ExpenseCardStack.swift
//  Norma
//
//  Created by Claude on 10/11/25.
//

import SwiftUI

struct ExpenseCardStack: View {
    let expenses: [Expense]
    @State private var visibleCards: Int = 0
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    // Generate consistent random rotations based on expense ID
    private func rotation(for index: Int, expenseId: String?) -> Double {
        guard let id = expenseId else { return 0 }
        let hash = abs(id.hashValue)
        let rotation = Double((hash % 7) - 3) // Random between -3 and +3 degrees
        return rotation
    }

    var body: some View {
        ZStack {
            ForEach(Array(expenses.enumerated()), id: \.element.id) { index, expense in
                ExpenseCardItem(expense: expense)
                    .opacity(index < visibleCards ? 1 : 0)
                    .offset(y: index < visibleCards ? 0 : 20)
                    .rotationEffect(.degrees(rotation(for: index, expenseId: expense.id)))
                    .scaleEffect(index < visibleCards ? 1 : 0.95)
                    .zIndex(Double(expenses.count - index))
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            animateCardsIn()
        }
    }

    private func animateCardsIn() {
        for i in 0..<expenses.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    visibleCards = i + 1
                }
            }
        }
    }
}

struct ExpenseCardItem: View {
    let expense: Expense
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    private var expenseDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: expense.expenseDate) ?? Date()
    }

    var body: some View {
        HStack {
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.purple)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text(expenseDate, format: .dateTime.month().day())
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(profileViewModel.formatCurrency(expense.amount))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("NormaCard"))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}
