//
//  DoubleTapHoldGesture.swift
//  Norma
//
//  Created by Claude on 8/6/25.
//

import SwiftUI

struct DoubleTapHoldGesture: ViewModifier {
    @Binding var isPressed: Bool
    let onDoubleTapHold: () -> Void
    
    @State private var tapCount = 0
    @State private var lastTapTime: Date = Date()
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onTapGesture(count: 2) {
                // Double tap detected - provide feedback
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }
                
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Reset after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onChanged { _ in
                        // Check if this is the second tap in a double-tap sequence
                        let now = Date()
                        let timeSinceLastTap = now.timeIntervalSince(lastTapTime)
                        
                        if timeSinceLastTap < 0.5 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                isPressed = true
                            }
                        }
                    }
                    .onEnded { _ in
                        // Check if this completes a double-tap-hold
                        let now = Date()
                        let timeSinceLastTap = now.timeIntervalSince(lastTapTime)
                        
                        if timeSinceLastTap < 1.0 {
                            onDoubleTapHold()
                            // Strong haptic for activation
                            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                            impactFeedback.impactOccurred()
                        }
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isPressed = false
                        }
                    }
            )
            .onTapGesture {
                // Track single taps for the double-tap-hold pattern
                lastTapTime = Date()
                tapCount += 1
                
                // Reset tap count after timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if Date().timeIntervalSince(lastTapTime) >= 0.5 {
                        tapCount = 0
                    }
                }
            }
    }
}

extension View {
    func doubleTapHold(isPressed: Binding<Bool>, onActivate: @escaping () -> Void) -> some View {
        self.modifier(DoubleTapHoldGesture(isPressed: isPressed, onDoubleTapHold: onActivate))
    }
}