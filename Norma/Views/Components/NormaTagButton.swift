//
//  NormaTagButton.swift
//  Norma
//
//  Raised tag button. The face sits on a 2pt darker lip and a soft shadow,
//  and drops onto the lip without a shadow while pressed. Tag buttons are
//  the only component allowed a shadow. No screen uses this yet.
//

import SwiftUI

/// Navy or coral tag button. Coral is for Approve and other money moments.
struct NormaTagButton: View {
    enum Variant: Equatable {
        /// Navy face on the darker navy lip.
        case navy
        /// Coral face on the darker coral lip, with an ink label. Approve and
        /// money moments only.
        case coral

        var face: NormaTheme.Swatch {
            switch self {
            case .navy: return NormaTheme.navy
            case .coral: return NormaTheme.coral
            }
        }

        var base: NormaTheme.Swatch {
            switch self {
            case .navy: return NormaTheme.pressedTagButtonNavy
            case .coral: return NormaTheme.pressedTagButtonCoral
            }
        }

        var label: NormaTheme.Swatch {
            switch self {
            case .navy: return NormaTheme.silver
            case .coral: return NormaTheme.ink
            }
        }
    }

    /// Face offset and shadow for one press state.
    struct Chrome: Equatable {
        var faceOffset: CGFloat
        var shadowRadius: CGFloat
        var shadowY: CGFloat
        var shadowOpacity: Double
    }

    /// Rest and pressed geometry. The face reads `chrome(isPressed:)` so the
    /// lip, the shadow, and the 2pt travel stay in one place.
    enum Metrics {
        /// Darker lip under the face, in points.
        static let lip: CGFloat = 2
        /// Continuous corner. The theme has no tag radius; 16 is on the 4pt grid.
        static let cornerRadius = NormaTheme.spacing16
        static let restShadowRadius = NormaTheme.spacing8
        static let restShadowY = NormaTheme.spacing4
        static let restShadowOpacity = 0.25

        static var cornerShape: RoundedRectangle {
            NormaTheme.shape(cornerRadius)
        }

        static func chrome(isPressed: Bool) -> Chrome {
            if isPressed {
                return Chrome(faceOffset: lip, shadowRadius: 0, shadowY: 0, shadowOpacity: 0)
            }
            return Chrome(
                faceOffset: 0,
                shadowRadius: restShadowRadius,
                shadowY: restShadowY,
                shadowOpacity: restShadowOpacity
            )
        }
    }

    /// One cell of `#Preview("NormaTagButton")`: a variant at rest or pressed.
    struct PreviewSample: Equatable, Identifiable {
        var title: String
        var variant: Variant
        var isPressed: Bool

        var id: String {
            switch variant {
            case .navy: return "navy-\(isPressed)"
            case .coral: return "coral-\(isPressed)"
            }
        }
    }

    /// Both variants, at rest and pressed. The preview renders this list.
    static let previewSamples: [PreviewSample] = [
        PreviewSample(title: "Skip", variant: .navy, isPressed: false),
        PreviewSample(title: "Approve", variant: .coral, isPressed: false),
        PreviewSample(title: "Skip", variant: .navy, isPressed: true),
        PreviewSample(title: "Approve", variant: .coral, isPressed: true),
    ]

    let title: String
    let variant: Variant
    let action: () -> Void

    /// VoiceOver label. It is the button title.
    var accessibilityLabelText: String { title }

    /// VoiceOver trait applied with `accessibilityLabelText`.
    var accessibilityTraitsValue: AccessibilityTraits { .isButton }

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(NormaTagButtonStyle(variant: variant))
        // AC-6: the label and button trait come from the properties above.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityAddTraits(accessibilityTraitsValue)
    }
}

/// Pressed state follows `configuration.isPressed`.
struct NormaTagButtonStyle: ButtonStyle {
    let variant: NormaTagButton.Variant

    func makeBody(configuration: Configuration) -> some View {
        // AC-4
        NormaTagButtonFace(
            variant: variant,
            isPressed: configuration.isPressed,
            label: configuration.label
        )
    }
}

/// The face, the lip, and the shadow. Previews pass `isPressed` directly so
/// rest and pressed can sit on screen together.
private struct NormaTagButtonFace<Label: View>: View {
    let variant: NormaTagButton.Variant
    let isPressed: Bool
    let label: Label

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let chrome = NormaTagButton.Metrics.chrome(isPressed: isPressed)
        let shape = NormaTagButton.Metrics.cornerShape
        // The base is the face shape, shifted down by the lip. At rest the
        // face covers all but that 2pt strip and casts a shadow. Pressed,
        // the face moves down onto the strip and the shadow is gone.
        label
            .font(NormaTheme.label.font)
            .foregroundStyle(variant.label.color)
            .padding(.horizontal, NormaTheme.spacing16)
            .padding(.vertical, NormaTheme.spacing12)
            .background { shape.fill(variant.face.color) }
            .shadow(
                color: NormaTheme.ink.color.opacity(chrome.shadowOpacity),
                radius: chrome.shadowRadius,
                y: chrome.shadowY
            )
            .offset(y: chrome.faceOffset)
            .background {
                shape
                    .fill(variant.base.color)
                    .offset(y: NormaTagButton.Metrics.lip)
            }
            .padding(.bottom, NormaTagButton.Metrics.lip)
            .contentShape(Rectangle())
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isPressed)
    }
}

// AC-7: both variants, at rest and pressed.
#Preview("NormaTagButton") {
    NormaTagButtonPreview()
}

private struct NormaTagButtonPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: NormaTheme.spacing32) {
            Text("Tag button")
                .font(NormaTheme.title.font)
                .foregroundStyle(NormaTheme.ink.color)
            HStack(alignment: .top, spacing: NormaTheme.spacing32) {
                column(title: "At rest", isPressed: false)
                column(title: "Pressed", isPressed: true)
            }
        }
        .padding(NormaTheme.spacing24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(NormaTheme.silver.color)
    }

    private func column(title: String, isPressed: Bool) -> some View {
        let samples = NormaTagButton.previewSamples.filter { $0.isPressed == isPressed }
        return VStack(alignment: .leading, spacing: NormaTheme.spacing16) {
            Text(title)
                .font(NormaTheme.label.font)
                .foregroundStyle(NormaTheme.plum.color)
            ForEach(samples) { item in
                labeled(caption(item.variant)) {
                    control(item)
                }
            }
        }
    }

    private func caption(_ variant: NormaTagButton.Variant) -> String {
        switch variant {
        case .navy: return "Navy"
        case .coral: return "Coral"
        }
    }

    private func labeled(_ caption: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: NormaTheme.spacing8) {
            content()
            Text(caption)
                .font(NormaTheme.caption.font)
                .foregroundStyle(NormaTheme.slate.color)
        }
    }

    @ViewBuilder
    private func control(_ item: NormaTagButton.PreviewSample) -> some View {
        if item.isPressed {
            NormaTagButtonFace(variant: item.variant, isPressed: true, label: Text(item.title))
        } else {
            NormaTagButton(title: item.title, variant: item.variant) {}
        }
    }
}
