//
//  ThinkingIndicator.swift
//  Norma
//
//  Created by Claude on 1/22/25.
//

import SwiftUI

struct ThinkingIndicator: View {
    @State private var dotCount = 0
    @State private var showContent = false
    @State private var shouldBlur = false

    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack(spacing: 4) {
                Text("Thinking")
                    .font(.normaInput(16))
                    .foregroundColor(Color("NormaText").opacity(0.7))

                // Animated dots
                Text(dots)
                    .font(.normaInput(16))
                    .foregroundColor(Color("NormaText").opacity(0.7))
                    .frame(width: 24, alignment: .leading)
            }
            .fluidBlur(isActive: shouldBlur)
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.95)
            .offset(y: showContent ? 0 : 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                // Start blur immediately
                shouldBlur = true

                // Soft pop animation
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showContent = true
                }
            }
            .onReceive(timer) { _ in
                // Cycle through 0, 1, 2, 3 dots
                dotCount = (dotCount + 1) % 4
            }

            Spacer(minLength: 0)
                .frame(width: UIScreen.main.bounds.width * 0.02)
        }
    }

    private var dots: String {
        String(repeating: ".", count: dotCount)
    }
}

#Preview {
    VStack(spacing: 16) {
        ThinkingIndicator()
    }
    .padding()
    .background(Color("NormaBackground"))
}
