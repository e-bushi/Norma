//
//  VoiceModeInstruction.swift
//  Norma
//
//  Created by Claude on 8/15/25.
//

import SwiftUI

struct VoiceModeInstruction: View {
    let explanationButtonAppeared: Bool
    @State private var isDismissed = false
    
    var body: some View {
        if !isDismissed {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.purple.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
                
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                        
                        Text("Voice Mode")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.purple)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isDismissed = true
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                    
                    Text("Double tap and hold the chart to activate voice mode. If you want to end the conversation, tap the end button.")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                .padding(20)
            }
            .padding(.horizontal, 24)
            .padding(.horizontal )
            .scaleEffect(explanationButtonAppeared ? 1 : 0.9)
            .opacity(explanationButtonAppeared ? 1 : 0)
            .offset(y: explanationButtonAppeared ? 0 : 10)
            .transition(.asymmetric(
                insertion: .push(from: .top).combined(with: .opacity),
                removal: .push(from: .bottom).combined(with: .opacity)
            ))
        }
    }
}

#Preview {
    VoiceModeInstruction(explanationButtonAppeared: true)
}
