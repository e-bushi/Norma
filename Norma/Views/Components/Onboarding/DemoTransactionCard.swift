//
//  DemoTransactionCard.swift
//  Norma
//
//  A demo transaction card for the onboarding screenshot feature.
//  Shows fake "extracted" transactions from a screenshot.
//

import SwiftUI

struct DemoTransactionCard: View {
    @Binding var animate: Bool

    private let transactions: [(name: String, amount: String, icon: String)] = [
        ("Whole Foods", "$67.43", "cart.fill"),
        ("Shell Gas", "$45.00", "fuelpump.fill"),
        ("Netflix", "$15.99", "play.tv.fill"),
        ("Starbucks", "$8.45", "cup.and.saucer.fill"),
        ("Amazon", "$34.99", "shippingbox.fill"),
    ]

    private let staggerDelay: Double = 0.12

    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<transactions.count, id: \.self) { index in
                let transaction = transactions[index]
                DemoTransactionRow(
                    name: transaction.name,
                    amount: transaction.amount,
                    icon: transaction.icon
                )
                .opacity(animate ? 1.0 : 0.0)
                .offset(y: animate ? 0 : 20)
                .animation(
                    .easeOut(duration: 0.4).delay(Double(index) * staggerDelay),
                    value: animate
                )
            }
        }
        .padding(14)
        .frame(maxWidth: 260)
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

struct DemoTransactionRow: View {
    let name: String
    let amount: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color("NormaPastelCoral").opacity(0.15))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color("NormaPastelCoral"))
                )

            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            Text(amount)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var animate = false

        var body: some View {
            VStack(spacing: 20) {
                DemoTransactionCard(animate: $animate)

                Button("Animate") {
                    animate = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        animate = true
                    }
                }
            }
            .padding()
            .background(Color("NormaBackground"))
        }
    }

    return PreviewWrapper()
}
