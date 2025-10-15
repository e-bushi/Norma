//
//  BudgetCardStack.swift
//  Norma
//
//  Created by Claude on 10/11/25.
//

import SwiftUI

struct BudgetCardStack: View {
    let budgets: [Budget]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(budgets, id: \.id) { budget in
                // Placeholder for budget card view
                Text("Budget: \(budget.name) - $\(budget.amount, specifier: "%.2f")")
                    .padding()
                    .background(Color("NormaCard"))
                    .cornerRadius(8)
            }
        }
    }
}
