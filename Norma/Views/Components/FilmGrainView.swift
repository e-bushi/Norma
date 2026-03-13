//
//  FilmGrainView.swift
//  Norma
//
//  Created by Claude on 3/12/26.
//

import SwiftUI

/// Subtle animated film grain overlay that gives video a cinematic texture.
struct FilmGrainView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 8.0)) { timeline in
            Canvas { context, size in
                let seed = timeline.date.timeIntervalSinceReferenceDate
                // Use a simple hash to generate pseudo-random noise per frame
                var rng = SeededRNG(seed: UInt64(seed * 1000))

                let step: CGFloat = 4
                let cols = Int(size.width / step) + 1
                let rows = Int(size.height / step) + 1

                for row in 0..<rows {
                    for col in 0..<cols {
                        let value = rng.nextFloat()
                        if value > 0.5 {
                            let opacity = Double(value - 0.5) * 0.12
                            let rect = CGRect(
                                x: CGFloat(col) * step,
                                y: CGFloat(row) * step,
                                width: step,
                                height: step
                            )
                            context.fill(
                                Path(rect),
                                with: .color(.white.opacity(opacity))
                            )
                        }
                    }
                }
            }
        }
        .blendMode(.overlay)
        .opacity(0.4)
    }
}

/// Simple seeded random number generator for deterministic per-frame grain
private struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func nextFloat() -> Float {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Float(state % 1000) / 1000.0
    }
}
