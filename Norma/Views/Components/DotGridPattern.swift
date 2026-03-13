//
//  DotGridPattern.swift
//  Norma
//
//  Created by Assistant on 3/10/26.
//

import SwiftUI

struct DotGridPattern: View {
    var dotColor: Color = Color("NormaText")
    var dotRadius: CGFloat = 1.2
    var spacing: CGFloat = 20
    var opacity: Double = 0.12

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let cols = Int(size.width / spacing) + 1
                let rows = Int(size.height / spacing) + 1

                for row in 0..<rows {
                    for col in 0..<cols {
                        let x = CGFloat(col) * spacing
                        let y = CGFloat(row) * spacing
                        let rect = CGRect(
                            x: x - dotRadius,
                            y: y - dotRadius,
                            width: dotRadius * 2,
                            height: dotRadius * 2
                        )
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(dotColor.opacity(opacity))
                        )
                    }
                }
            }
            .mask(
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 0.35),
                        .init(color: .clear, location: 0.75)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: max(geo.size.width, geo.size.height) * 0.6
                )
            )
        }
        .allowsHitTesting(false)
    }
}
