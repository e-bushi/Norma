//
//  FluidBlurModifier.swift
//  Norma
//
//  Created by Claude on 7/16/25.
//

import SwiftUI

// MARK: - Fluid Blur Animation Modifier
struct FluidBlurModifier: ViewModifier {
    let isActive: Bool
    
    @State private var blurRadius: CGFloat = 0
    @State private var blurScale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .blur(radius: blurRadius)
            .scaleEffect(blurScale)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    startBlurAnimation()
                } else {
                    resetBlurAnimation()
                }
            }
    }
    
    private func startBlurAnimation() {
        // Start with extreme blur
        blurScale = 3.0
        blurRadius = 50
        
        // Faster fluid bounce animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0.2)) {
            blurScale = 1.0
            blurRadius = 25
        }
        
        // Fade out the blur with shorter delay and faster duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.6)) {
                blurRadius = 0
                blurScale = 1.0
            }
        }
    }
    
    private func resetBlurAnimation() {
        blurRadius = 0
        blurScale = 1.0
    }
}

extension View {
    func fluidBlur(isActive: Bool) -> some View {
        modifier(FluidBlurModifier(isActive: isActive))
    }
}