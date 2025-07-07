//
//  ChatBubbleView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp = Date()
}

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if !message.isUser {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 24, height: 24)
                            
                            Text("N")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(UIColor.systemBackground))
                        }
                        
                        Text("Norma")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(message.text)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: 
                                        message.isUser ? [
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
                                                message.isUser ? [
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
                    .foregroundColor(message.isUser ? .blue : .primary)
                    .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ChatBubbleView(message: ChatMessage(text: "Hello! I'm Norma, your AI financial assistant.", isUser: false))
        ChatBubbleView(message: ChatMessage(text: "Hi Norma! Can you help me with my budget?", isUser: true))
    }
    .padding()
}