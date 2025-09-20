//
//  VoiceModeInstruction.swift
//  Norma
//
//  Created by Claude on 8/15/25.
//

import SwiftUI

struct VoiceModeInstruction: View {
    let explanationButtonAppeared: Bool
    let onActivate: () -> Void
    
    var body: some View {
        Button(action: {
            // Activate voice mode
            onActivate()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text("Talk to Norma")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.blue)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 24)
        .padding(.horizontal)
        .scaleEffect(explanationButtonAppeared ? 1 : 0.9)
        .opacity(explanationButtonAppeared ? 1 : 0)
        .offset(y: explanationButtonAppeared ? 0 : 10)
        .transition(.asymmetric(
            insertion: .push(from: .top).combined(with: .opacity),
            removal: .push(from: .bottom).combined(with: .opacity)
        ))
    }
}

#Preview {
    VoiceModeInstruction(explanationButtonAppeared: true) {
        print("Voice mode activated")
    }
}
