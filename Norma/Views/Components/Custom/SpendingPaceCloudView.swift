//
//  SpendingPaceCloudView.swift
//  Norma
//
//  Ambient radial gradient orb that communicates spending pace through color.
//  Teal = under budget, Purple = on track, Coral/warm = over pace.
//

import SwiftUI

struct SpendingPaceCloudView: View {
    /// 0.0 = well under budget, 0.5 = on track, 1.0 = over budget
    let pace: Double

    @State private var startDate = Date()

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let time = timeline.date.timeIntervalSince(startDate)

                Rectangle()
                    .fill(Color.white)
                    .colorEffect(
                        ShaderLibrary.spendingPaceCloud(
                            .float2(geo.size.width, geo.size.height),
                            .float(Float(time)),
                            .float(Float(pace))
                        )
                    )
            }
        }
    }
}

#Preview("Under Budget") {
    VStack {
        Spacer()
        SpendingPaceCloudView(pace: 0.15)
            .frame(height: 250)
    }
    .background(Color("NormaBackground"))
}

#Preview("On Track") {
    VStack {
        Spacer()
        SpendingPaceCloudView(pace: 0.5)
            .frame(height: 250)
    }
    .background(Color("NormaBackground"))
}

#Preview("Over Budget") {
    VStack {
        Spacer()
        SpendingPaceCloudView(pace: 0.9)
            .frame(height: 250)
    }
    .background(Color("NormaBackground"))
}
