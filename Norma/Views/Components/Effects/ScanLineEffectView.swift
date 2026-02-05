//
//  ScanLineEffectView.swift
//  Norma
//
//  Displays an animated scanning line effect.
//  Creates a glowing horizontal line that sweeps down with a light trail.
//

import SwiftUI

/// A view that displays an animated scanning line effect.
struct ScanLineEffectView: View {
    /// Progress of the scan (0 = top, 1 = bottom)
    let progress: CGFloat

    /// Color of the scan line
    var lineColor: Color = Color("NormaPastelPurple")

    /// Size of the effect area
    let size: CGSize

    // Effect parameters
    private let lineHeight: CGFloat = 2.0
    private let glowHeight: CGFloat = 60.0

    var body: some View {
        Canvas { context, canvasSize in
            let yPosition = progress * canvasSize.height

            // Draw the trailing glow (gradient above the line)
            let glowRect = CGRect(
                x: 0,
                y: max(0, yPosition - glowHeight),
                width: canvasSize.width,
                height: min(glowHeight, yPosition)
            )

            let glowGradient = Gradient(colors: [
                lineColor.opacity(0),
                lineColor.opacity(0.3)
            ])

            context.fill(
                Path(glowRect),
                with: .linearGradient(
                    glowGradient,
                    startPoint: CGPoint(x: canvasSize.width / 2, y: glowRect.minY),
                    endPoint: CGPoint(x: canvasSize.width / 2, y: glowRect.maxY)
                )
            )

            // Draw the main bright scan line
            let lineRect = CGRect(
                x: 0,
                y: yPosition - lineHeight / 2,
                width: canvasSize.width,
                height: lineHeight
            )

            context.fill(
                Path(lineRect),
                with: .color(lineColor)
            )

            // Draw a brighter center glow on the line
            let brightGlowRect = CGRect(
                x: 0,
                y: yPosition - 4,
                width: canvasSize.width,
                height: 8
            )

            context.fill(
                Path(brightGlowRect),
                with: .color(lineColor.opacity(0.5))
            )
        }
        .frame(width: size.width, height: size.height)
        .blendMode(.plusLighter)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var progress: CGFloat = 0

        var body: some View {
            ZStack {
                Color("NormaBackground")
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.2))

                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.gray.opacity(0.3))

                        ScanLineEffectView(
                            progress: progress,
                            size: CGSize(width: 300, height: 400)
                        )
                    }
                    .frame(width: 300, height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button("Scan") {
                        progress = 0
                        withAnimation(.linear(duration: 2.0)) {
                            progress = 1.0
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    return PreviewWrapper()
}
