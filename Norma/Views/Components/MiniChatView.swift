//
//  MiniChatView.swift
//  Norma
//
//  Created by Claude on 8/2/25.
//

import SwiftUI

struct MiniChatView: View {
    let appeared: Bool

    @State private var messageStates: [Bool] = Array(repeating: false, count: 4)

    var body: some View {
        VStack(spacing: 16) {
            // Chat messages
            VStack(spacing: 12) {
                // User message
                HStack {
                    Spacer()
                    Text("Help me budget for vacation")
                        .font(.normaInput(12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("NormaPastelTeal"))
                        )
                }
                .scaleEffect(messageStates[0] ? 1.0 : 0.5)
                .opacity(messageStates[0] ? 1.0 : 0)

                // AI response
                HStack {
                    Circle()
                        .fill(Color("NormaPastelTeal").opacity(0.1))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("🤖")
                                .font(.system(size: 10))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Based on your spending, I suggest saving $200/month for 6 months. You can reduce dining out by $50/month.")
                            .font(.normaInput(11))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.1))
                    )

                    Spacer()
                }
                .scaleEffect(messageStates[1] ? 1.0 : 0.5)
                .opacity(messageStates[1] ? 1.0 : 0)

                // Another user message
                HStack {
                    Spacer()
                    Text("Show me my top expenses")
                        .font(.normaInput(12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("NormaPastelTeal"))
                        )
                }
                .scaleEffect(messageStates[2] ? 1.0 : 0.5)
                .opacity(messageStates[2] ? 1.0 : 0)

                // AI response with suggestions
                HStack {
                    Circle()
                        .fill(Color("NormaPastelTeal").opacity(0.1))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("🤖")
                                .font(.system(size: 10))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your top 3: Food ($450), Entertainment ($280), Shopping ($320). Try cooking more meals at home!")
                            .font(.normaInput(11))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.1))
                    )

                    Spacer()
                }
                .scaleEffect(messageStates[3] ? 1.0 : 0.5)
                .opacity(messageStates[3] ? 1.0 : 0)
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
                animateMessagesStaggered()
            } else {
                resetAnimations()
            }
        }
    }

    private func animateMessagesStaggered() {
        for i in 0..<messageStates.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    messageStates[i] = true
                }
            }
        }
    }

    private func resetAnimations() {
        messageStates = Array(repeating: false, count: 4)
    }
}

#Preview {
    MiniChatView(appeared: true)
        .padding()
}