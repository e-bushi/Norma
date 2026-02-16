//
//  LavaOrb.swift
//  Norma
//
//  Ambient floating orb effect used for background decoration.
//

import SwiftUI

struct LavaOrb: View {
    let color: Color
    let size: CGFloat
    let blur: CGFloat
    let opacity: Double
    let bounds: CGSize
    let speed: Double

    @State private var position: CGPoint = .zero
    @State private var targetPosition: CGPoint = .zero

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: blur)
            .opacity(opacity)
            .position(position)
            .onAppear {
                let initial = randomPosition()
                position = initial
                targetPosition = randomPosition()
                startAnimation()
            }
    }

    private func randomPosition() -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: size / 2...(max(bounds.width - size / 2, size / 2 + 1))),
            y: CGFloat.random(in: size / 2...(max(bounds.height - size / 2, size / 2 + 1)))
        )
    }

    private func startAnimation() {
        withAnimation(
            .easeInOut(duration: speed)
            .repeatForever(autoreverses: true)
        ) {
            position = targetPosition
        }
    }
}
