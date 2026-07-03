//
//  UserMessageBubble.swift
//  Norma
//
//  Created by Claude on 10/11/25.
//

import SwiftUI

struct UserMessageBubble: View {
    let content: String
    var accentColor: Color = NormaPalette.lavender

    @State private var showContent = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer(minLength: 0)
                .frame(width: UIScreen.main.bounds.width * 0.1)

            Text(content)
                .font(.normaInput(16))
                .lineSpacing(4)
                .foregroundColor(Color("NormaText"))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.clear)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.95)
                .offset(y: showContent ? 0 : 10)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .onAppear {
                    // Instant pop animation
                    withAnimation(.spring(response: 0.08, dampingFraction: 0.6)) {
                        showContent = true
                    }
                }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        UserMessageBubble(content: "How much did I spend on groceries last month?")
        UserMessageBubble(content: "Can you help me create a budget?")
    }
    .padding()
    .background(Color("NormaBackground"))
}
