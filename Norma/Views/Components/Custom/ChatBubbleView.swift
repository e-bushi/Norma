//
//  ChatBubbleView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser {
                Spacer()
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors:
                                        isUser ? [
                                            Color.blue.opacity(0.05),
                                            Color.blue.opacity(0.05)
                                        ] : [
                                            Color(UIColor.systemBackground),
                                            Color.gray.opacity(0.02)
                                        ]
                                    ),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors:
                                                isUser ? [
                                                    Color.blue.opacity(0.1),
                                                    Color.blue.opacity(0.1)
                                                ] : [
                                                    Color.gray.opacity(0.2),
                                                    Color.gray.opacity(0.05)
                                                ]
                                            ),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .foregroundColor(isUser ? .blue : .primary)
                    .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)
            }

            if !isUser {
                Spacer()
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ChatBubbleView(message: ChatMessage(role: .assistant, content: "Hello! I'm Norma, your AI financial assistant."))
        ChatBubbleView(message: ChatMessage(role: .user, content: "Hi Norma! Can you help me with my budget?"))
    }
    .padding()
}