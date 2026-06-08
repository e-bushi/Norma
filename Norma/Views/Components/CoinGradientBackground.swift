//
//  CoinGradientBackground.swift
//  Norma
//
//  A subtle vertical gradient derived from a coin color, adapting to the
//  current color scheme. Used as a screen background behind content.
//

import SwiftUI

struct CoinGradientBackground: View {
    let coinColor: Color
    let colorScheme: ColorScheme

    private var rgb: (r: CGFloat, g: CGFloat, b: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(coinColor).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }

    var body: some View {
        let c = rgb

        LinearGradient(
            stops: colorScheme == .dark
                ? [
                    .init(color: Color(red: c.r * 0.22, green: c.g * 0.22, blue: c.b * 0.22), location: 0),
                    .init(color: Color(red: c.r * 0.18, green: c.g * 0.18, blue: c.b * 0.18), location: 0.35),
                    .init(color: Color(red: c.r * 0.14, green: c.g * 0.14, blue: c.b * 0.14), location: 0.65),
                    .init(color: Color(red: c.r * 0.12, green: c.g * 0.12, blue: c.b * 0.12), location: 1.0)
                ]
                : [
                    .init(color: Color(red: 1 - (1 - c.r) * 0.22, green: 1 - (1 - c.g) * 0.22, blue: 1 - (1 - c.b) * 0.22), location: 0),
                    .init(color: Color(red: 1 - (1 - c.r) * 0.16, green: 1 - (1 - c.g) * 0.16, blue: 1 - (1 - c.b) * 0.16), location: 0.35),
                    .init(color: Color(red: 1 - (1 - c.r) * 0.12, green: 1 - (1 - c.g) * 0.12, blue: 1 - (1 - c.b) * 0.12), location: 0.65),
                    .init(color: Color(red: 1 - (1 - c.r) * 0.08, green: 1 - (1 - c.g) * 0.08, blue: 1 - (1 - c.b) * 0.08), location: 1.0)
                ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
