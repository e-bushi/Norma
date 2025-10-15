//
//  UserMessageBubble.swift
//  Norma
//
//  Created by Claude on 10/11/25.
//

import SwiftUI

struct UserMessageBubble: View {
    let content: String

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer(minLength: 0)
                .frame(width: UIScreen.main.bounds.width * 0.1)

            Text(content)
                .font(.system(size: 16))
                .lineSpacing(4)
                .foregroundColor(Color("NormaText"))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color("NormaUserBubble"))
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
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
