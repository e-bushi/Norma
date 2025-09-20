//
//  CalendarVoiceModeInstruction.swift
//  Norma
//
//  Created by Claude on 8/15/25.
//

import SwiftUI

struct CalendarVoiceModeInstruction: View {
    let onActivate: () -> Void
    @State private var isDismissed = false
    @State private var hasAppeared = false
    
    var body: some View {
        if !isDismissed {
            Button(action: {
                // Activate voice mode
                onActivate()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.purple.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                        )
                    
                    HStack(spacing: 12) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.purple)
                        
                        Text("Talk to Norma")
                            .font(.system(size: 18, weight: .semibold))
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
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(20)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 24)
            .scaleEffect(hasAppeared ? 1 : 0.9)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 10)
            .transition(.asymmetric(
                insertion: .push(from: .top).combined(with: .opacity),
                removal: .push(from: .bottom).combined(with: .opacity)
            ))
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    hasAppeared = true
                }
            }
        }
    }
}

#Preview {
    CalendarVoiceModeInstruction {
        print("Voice mode activated")
    }
}