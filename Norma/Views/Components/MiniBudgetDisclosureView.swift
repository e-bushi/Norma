//
//  MiniBudgetDisclosureView.swift
//  Norma
//
//  Created by Claude on 8/2/25.
//

import SwiftUI

struct MiniBudgetDisclosureView: View {
    let appeared: Bool

    @State private var itemStates: [Bool] = Array(repeating: false, count: 6)

    var body: some View {
        VStack(spacing: 16) {
            // Mini budget categories
            VStack(spacing: 12) {
                HStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("🍕")
                                .font(.system(size: 14))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Food & Dining")
                            .font(.normaInput(12))
                            .foregroundColor(.primary)
                        Text("$450 of $600")
                            .font(.normaInput(10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("$150")
                        .font(.normaFinancial(12))
                        .foregroundColor(Color("NormaPastelTeal"))
                }
                .opacity(itemStates[0] ? 1 : 0)
                .offset(x: itemStates[0] ? 0 : -20)
                
                HStack {
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("🎬")
                                .font(.system(size: 14))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Entertainment")
                            .font(.normaInput(12))
                            .foregroundColor(.primary)
                        Text("$280 of $300")
                            .font(.normaInput(10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("$20")
                        .font(.normaFinancial(12))
                        .foregroundColor(.orange)
                }
                .opacity(itemStates[1] ? 1 : 0)
                .offset(x: itemStates[1] ? 0 : -20)

                HStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("🚗")
                                .font(.system(size: 14))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Transportation")
                            .font(.normaInput(12))
                            .foregroundColor(.primary)
                        Text("$180 of $250")
                            .font(.normaInput(10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("$70")
                        .font(.normaFinancial(12))
                        .foregroundColor(Color("NormaPastelTeal"))
                }
                .opacity(itemStates[2] ? 1 : 0)
                .offset(x: itemStates[2] ? 0 : -20)

                HStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("🛍️")
                                .font(.system(size: 14))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Shopping")
                            .font(.normaInput(12))
                            .foregroundColor(.primary)
                        Text("$320 of $200")
                            .font(.normaInput(10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("-$120")
                        .font(.normaFinancial(12))
                        .foregroundColor(.red)
                }
                .opacity(itemStates[3] ? 1 : 0)
                .offset(x: itemStates[3] ? 0 : -20)

                HStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("💊")
                                .font(.system(size: 14))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Healthcare")
                            .font(.normaInput(12))
                            .foregroundColor(.primary)
                        Text("$150 of $200")
                            .font(.normaInput(10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("$50")
                        .font(.normaFinancial(12))
                        .foregroundColor(Color("NormaPastelTeal"))
                }
                .opacity(itemStates[4] ? 1 : 0)
                .offset(x: itemStates[4] ? 0 : -20)

                HStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("💡")
                                .font(.system(size: 14))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Utilities")
                            .font(.normaInput(12))
                            .foregroundColor(.primary)
                        Text("$240 of $250")
                            .font(.normaInput(10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("$10")
                        .font(.normaFinancial(12))
                        .foregroundColor(Color("NormaPastelTeal"))
                }
                .opacity(itemStates[5] ? 1 : 0)
                .offset(x: itemStates[5] ? 0 : -20)
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
                animateItemsStaggered()
            } else {
                resetAnimations()
            }
        }
    }

    private func animateItemsStaggered() {
        for i in 0..<itemStates.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    itemStates[i] = true
                }
            }
        }
    }

    private func resetAnimations() {
        itemStates = Array(repeating: false, count: 6)
    }
}

#Preview {
    MiniBudgetDisclosureView(appeared: true)
        .padding()
}