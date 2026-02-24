//
//  ChatBubbleView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage
    var shouldAnimate: Bool = false
    var onArcSimulatorTap: ((Int, Double, Double, String) -> Void)?

    var body: some View {
        if !message.isVisible {
            EmptyView()
        } else if message.role == .user {
            UserMessageBubble(content: message.content)
        } else {
            AIMessageBubble(content: message.content, uiComponent: message.uiComponent, revealDirection: .leftToRight, shouldAnimate: shouldAnimate, onArcSimulatorTap: onArcSimulatorTap)
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