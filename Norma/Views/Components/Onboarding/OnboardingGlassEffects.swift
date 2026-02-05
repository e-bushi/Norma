//
//  OnboardingGlassEffects.swift
//  Norma
//
//  Created by Claude on 1/31/26.
//

import SwiftUI

// MARK: - Lava Lamp Orb

/// A floating orb that wanders randomly like a lava lamp
struct LavaOrb: View {
    let color: Color
    let size: CGFloat
    let blur: CGFloat
    let opacity: Double
    let bounds: CGSize
    let speed: Double

    @State private var position: CGPoint = .zero
    @State private var isInitialized = false

    var body: some View {
        Circle()
            .fill(color.opacity(opacity))
            .frame(width: size, height: size)
            .blur(radius: blur)
            .position(position)
            .onAppear {
                if !isInitialized {
                    // Start at random position
                    position = randomPosition()
                    isInitialized = true

                    // Begin wandering
                    startWandering()
                }
            }
    }

    private func randomPosition() -> CGPoint {
        let minX = size / 2
        let maxX = max(minX, bounds.width - size / 2)
        let minY = size / 2
        let maxY = max(minY, bounds.height - size / 2)

        return CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )
    }

    private func startWandering() {
        wanderToNewPosition()
    }

    private func wanderToNewPosition() {
        let newPosition = randomPosition()
        let duration = speed + Double.random(in: -1.5...1.5)

        withAnimation(.easeInOut(duration: max(2.0, duration))) {
            position = newPosition
        }

        // Schedule next movement
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            wanderToNewPosition()
        }
    }
}
