//
//  FinancialContextPopover.swift
//  Norma
//
//  Created by Claude on 12/3/25.
//

import SwiftUI

// MARK: - Inline Chip Component
struct InlineChip: View {
    let icon: String?
    let text: String
    let color: Color

    init(icon: String? = nil, text: String, color: Color) {
        self.icon = icon
        self.text = text
        self.color = color
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 10))
            }
            Text(text)
                .font(.custom(FontFamily.Rubik.medium, size: 12))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
        .foregroundColor(color)
    }
}

// MARK: - Financial Context Popover
struct FinancialContextPopover: View {
    @Binding var isPresented: Bool
    @State private var appeared = false

    // Mock data - will be replaced with real data later
    private let spendingTrend = "+12%"
    private let billsDueCount = 3
    private let billsTotal = "$450"
    private let groceryProgress = "80%"

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Dismiss overlay
            Color.black.opacity(appeared ? 0.3 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Popover content
            VStack(alignment: .leading, spacing: 12) {
                // Spending trend line
                HStack(spacing: 6) {
                    Text("Your spending is trending")
                        .font(.custom(FontFamily.Rubik.regular, size: 14))
                        .foregroundColor(.primary)
                    InlineChip(
                        icon: "arrow.up.right",
                        text: spendingTrend,
                        color: Color("NormaPastelCoral")
                    )
                    Text("this month.")
                        .font(.custom(FontFamily.Rubik.regular, size: 14))
                        .foregroundColor(.primary)
                }

                // Bills due line
                HStack(spacing: 6) {
                    Text("You have")
                        .font(.custom(FontFamily.Rubik.regular, size: 14))
                        .foregroundColor(.primary)
                    InlineChip(
                        icon: "calendar",
                        text: "\(billsDueCount) bills",
                        color: Color("NormaPastelTeal")
                    )
                    Text("due soon totaling")
                        .font(.custom(FontFamily.Rubik.regular, size: 14))
                        .foregroundColor(.primary)
                    InlineChip(
                        icon: "dollarsign",
                        text: billsTotal,
                        color: Color("NormaPastelTeal")
                    )
                    Text(".")
                        .font(.custom(FontFamily.Rubik.regular, size: 14))
                        .foregroundColor(.primary)
                }

                // Budget status line
                HStack(spacing: 6) {
                    InlineChip(
                        icon: "cart.fill",
                        text: "Groceries",
                        color: Color("NormaPastelPurple")
                    )
                    Text("is at \(groceryProgress),")
                        .font(.custom(FontFamily.Rubik.regular, size: 14))
                        .foregroundColor(.primary)
                    InlineChip(
                        icon: "film.fill",
                        text: "Entertainment",
                        color: Color("NormaPastelCoral")
                    )
                    Text("is over budget.")
                        .font(.custom(FontFamily.Rubik.regular, size: 14))
                        .foregroundColor(.primary)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.clear)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 16))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            )
            .padding(.top, 60) // Offset below nav bar
            .padding(.trailing, 16)
            .scaleEffect(appeared ? 1 : 0.8, anchor: .topTrailing)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            appeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}


#Preview {
    ZStack {
        Color("NormaBackground")
            .ignoresSafeArea()

        FinancialContextPopover(isPresented: .constant(true))
    }
}
