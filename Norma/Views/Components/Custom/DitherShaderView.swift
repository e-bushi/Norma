//
//  DitherShaderView.swift
//  Norma
//
//  Animated dot-grid dither behind the landing screen and the onboarding
//  celebration. Tint follows the user's selected AppTheme accent
//  (NormaPalette.lavender). Reduce Motion holds a single frame instead of
//  the 30fps timeline.
//

import SwiftUI

struct DitherShaderView: View {
    /// 0.0 = invisible, 1.0 = full accent dot opacity.
    var intensity: Double = 1.0

    /// Points per dither cell. 2.0 = original full-screen canvas look;
    /// drop to 0.7–1.0 for finer dots on small surfaces.
    var dotSize: Double = 2.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()

    var body: some View {
        GeometryReader { geo in
            if reduceMotion {
                ditherFrame(size: geo.size, time: 0)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    ditherFrame(size: geo.size, time: timeline.date.timeIntervalSince(startDate))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func ditherFrame(size: CGSize, time: TimeInterval) -> some View {
        Rectangle()
            .fill(Color.white)
            .colorEffect(
                ShaderLibrary.normaDither(
                    .float2(size.width, size.height),
                    .float(Float(time)),
                    .float(Float(intensity)),
                    .float(Float(dotSize)),
                    .color(NormaPalette.lavender)
                )
            )
    }
}

#Preview("Full intensity") {
    ZStack {
        NormaPalette.canvas.ignoresSafeArea()
        DitherShaderView(intensity: 1.0)
    }
}

#Preview("Half intensity") {
    ZStack {
        NormaPalette.canvas.ignoresSafeArea()
        DitherShaderView(intensity: 0.5)
    }
}

#Preview("Off") {
    ZStack {
        NormaPalette.canvas.ignoresSafeArea()
        DitherShaderView(intensity: 0.0)
    }
}
