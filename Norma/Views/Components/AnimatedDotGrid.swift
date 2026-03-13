//
//  AnimatedDotGrid.swift
//  Norma
//
//  Created by Claude on 3/12/26.
//

import SwiftUI

/// Metal-powered animated dot grid with sonar ripple effect.
struct AnimatedDotGrid: View {
    var dotColor: Color = .white
    var spacing: CGFloat = 22
    var dotRadius: CGFloat = 1.5
    var rippleOrigin: UnitPoint = .center

    @State private var startTime: Date = .now

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let elapsed = Float(timeline.date.timeIntervalSince(startTime))

                Rectangle()
                    .fill(dotColor)
                    .colorEffect(
                        ShaderLibrary.dotGridRipple(
                            .float2(geo.size.width, geo.size.height),
                            .float(elapsed),
                            .float(Float(spacing)),
                            .float(Float(dotRadius)),
                            .float(Float(rippleOrigin.x)),
                            .float(Float(rippleOrigin.y))
                        )
                    )
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.black
        AnimatedDotGrid(dotColor: .white, rippleOrigin: .topTrailing)
    }
    .ignoresSafeArea()
}
