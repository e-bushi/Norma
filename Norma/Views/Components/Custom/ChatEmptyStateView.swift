//
//  ChatEmptyStateView.swift
//  Norma
//
//  Created by Claude on 5/10/25.
//

import SwiftUI

struct ChatEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Spacer()
            Spacer()

            Image("norma")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .brightness(0.4)

            Text("How can I help with your finances?")
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundColor(Color("NormaText"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ChatEmptyStateView()
        .background(Color("NormaBackground"))
}
