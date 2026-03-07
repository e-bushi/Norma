//
//  DotPatternView.swift
//  Norma
//
//  Created by Claude on 3/7/26.
//

import SwiftUI

struct DotPatternView: View {
    var dotSize: CGFloat = 3
    var spacing: CGFloat = 18
    var dotOpacity: Double = 0.25

    var body: some View {
        Canvas { context, size in
            let cols = Int(size.width / spacing) + 1
            let rows = Int(size.height / spacing) + 1

            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * spacing + spacing / 2
                    let y = CGFloat(row) * spacing + spacing / 2
                    let rect = CGRect(
                        x: x - dotSize / 2,
                        y: y - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(Color.secondary.opacity(dotOpacity))
                    )
                }
            }
        }
        .mask(
            RadialGradient(
                gradient: Gradient(colors: [
                    .white,
                    .white.opacity(0.6),
                    .white.opacity(0)
                ]),
                center: .center,
                startRadius: 40,
                endRadius: 350
            )
        )
    }
}
