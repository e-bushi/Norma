//
//  NormaCard.swift
//  Norma
//
//  Reusable card container. Radius, outline, and padding come from
//  NormaTheme. The outline is a hairline stroke and there is no shadow.
//

import SwiftUI

/// Hairline card container. Padding, radius, and outline come from `NormaTheme`.
struct NormaCard<Content: View>: View {
    let padding: CGFloat
    private let content: Content

    @Environment(\.displayScale) private var displayScale

    init(padding: CGFloat = NormaTheme.spacing16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var shape: RoundedRectangle {
        NormaTheme.shape(NormaTheme.cardRadius)
    }

    func borderWidth(displayScale: CGFloat) -> CGFloat {
        NormaTheme.hairline(displayScale: displayScale)
    }

    var body: some View {
        content
            .padding(self.padding)
            .background {
                shape.strokeBorder(
                    NormaTheme.ink.color,
                    lineWidth: borderWidth(displayScale: displayScale)
                )
            }
    }
}

// AC-6
#Preview("NormaCard") {
    NormaCard {
        VStack(alignment: .leading, spacing: NormaTheme.spacing8) {
            Text("Left this month")
                .font(NormaTheme.body.font)
                .foregroundStyle(NormaTheme.ink.color)
            Text("1,234.50")
                .font(NormaTheme.number.font)
                .foregroundStyle(NormaTheme.ink.color)
        }
    }
    .padding(NormaTheme.spacing24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(NormaTheme.silver.color)
}
