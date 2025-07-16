//
//  BudgetExpensePicker.swift
//  Norma
//
//  Created by Claude on 5/19/25.
//

import SwiftUI

struct BudgetExpensePicker: View {
    @Binding var selection: ViewType
    
    enum ViewType: String, CaseIterable {
        case budget = "Budget"
        case expenses = "Expenses"
        
        var icon: String {
            switch self {
            case .budget: return "target"
            case .expenses: return "creditcard.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .budget: return .blue
            case .expenses: return .purple
            }
        }
    }
    
    var body: some View {
        // Custom picker container matching ExpenseTrackerChartView style
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(UIColor.systemBackground),
                            Color.gray.opacity(0.02)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.2),
                                    Color.gray.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
            
            HStack(spacing: 0) {
                ForEach(ViewType.allCases, id: \.self) { option in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selection = option
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: option.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selection == option ? option.color : .secondary)
                            
                            Text(option.rawValue)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selection == option ? option.color : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if selection == option {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(option.color.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(option.color.opacity(0.2), lineWidth: 1)
                                        )
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .scale.combined(with: .opacity)
                                        ))
                                }
                            }
                        )
                        .padding(.horizontal, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
        }
        .frame(height: 48)
    }
}

struct BudgetExpensePicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BudgetExpensePicker(selection: .constant(.budget))
            BudgetExpensePicker(selection: .constant(.expenses))
        }
        .padding()
        .preferredColorScheme(.light)
    }
}