//
//  DitherShaderView.swift
//  Norma
//
//  Animated dot-grid dither, matching the O1 landing artboard. Used as an
//  ambient background while the AI is "thinking" on a note — intensity
//  fades in/out so the layer stays visible only when extraction is
//  actively running. Tint follows the user's selected AppTheme accent
//  (NormaPalette.lavender), not a fixed color.
//

import SwiftUI

struct DitherShaderView: View {
    /// 0.0 = invisible, 1.0 = full lavender dot opacity. Drive this from
    /// the consumer (e.g. NoteSyncQueue state) and animate the change with
    /// `.animation(.easeInOut(duration: 0.4), value: intensity)` on the parent.
    var intensity: Double = 1.0

    /// Points per dither cell. 2.0 = original full-screen canvas look;
    /// drop to 0.7–1.0 for finer dots on small surfaces (toolbar pills,
    /// badges) where the default cells read as chunky squares.
    var dotSize: Double = 2.0

    @State private var startDate = Date()

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let time = timeline.date.timeIntervalSince(startDate)

                Rectangle()
                    .fill(Color.white)
                    .colorEffect(
                        ShaderLibrary.normaDither(
                            .float2(geo.size.width, geo.size.height),
                            .float(Float(time)),
                            .float(Float(intensity)),
                            .float(Float(dotSize)),
                            .color(NormaPalette.lavender)
                        )
                    )
            }
        }
        .allowsHitTesting(false)
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
