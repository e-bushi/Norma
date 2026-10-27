//
//  NormaTheme.swift
//  Norma
//
//  Rebuild tokens from Brand Identity Bill. Screens still read NormaPalette;
//  nothing here restyles them. The disabled color is out of scope.
//

import SwiftUI

enum NormaTheme {
    struct Swatch: Identifiable, Equatable {
        let name: String
        let hex: UInt32

        var id: String { name }

        var color: Color {
            Color(
                .sRGB,
                red: Double((hex >> 16) & 0xFF) / 255,
                green: Double((hex >> 8) & 0xFF) / 255,
                blue: Double(hex & 0xFF) / 255,
                opacity: 1
            )
        }

        var hexString: String {
            let digits = String(hex, radix: 16, uppercase: true)
            let padding = String(repeating: "0", count: max(0, 6 - digits.count))
            return "#" + padding + digits
        }
    }

    enum StyleKind {
        case text
        case number
        case realBalance
    }

    struct TypeStyle: Identifiable, Equatable {
        let name: String
        let kind: StyleKind
        let postScriptName: String
        let size: CGFloat

        var id: String { name }

        var font: Font {
            .custom(postScriptName, size: size)
        }

        var sample: String {
            if name == "caption" {
                return "Oct 26"
            }
            switch kind {
            case .text:
                return "The quick brown fox"
            case .number, .realBalance:
                return "1,234.50"
            }
        }
    }

    struct Radius: Identifiable, Equatable {
        let name: String
        let value: CGFloat

        var id: String { name }
    }

    /// #E4E6E8
    static let silver = Swatch(name: "silver", hex: 0xE4E6E8)
    /// #111111
    static let ink = Swatch(name: "ink", hex: 0x111111)
    /// #222E38
    static let navy = Swatch(name: "navy", hex: 0x222E38)
    /// #667387
    static let slate = Swatch(name: "slate", hex: 0x667387)
    /// #51474F
    static let plum = Swatch(name: "plum", hex: 0x51474F)
    /// #CC664D
    static let coral = Swatch(name: "coral", hex: 0xCC664D)
    /// Pressed tag-button navy, #13191F.
    static let pressedTagButtonNavy = Swatch(name: "pressed tag-button navy", hex: 0x13191F)
    /// Pressed tag-button coral, #70382A.
    static let pressedTagButtonCoral = Swatch(name: "pressed tag-button coral", hex: 0x70382A)
    /// Card fill under the warm activity gradient, #FFFFFF.
    static let paper = Swatch(name: "paper", hex: 0xFFFFFF)
    /// Activity gradient top, #FFFDF9.
    static let paperHighlight = Swatch(name: "paper highlight", hex: 0xFFFDF9)
    /// Activity gradient at 35%, #F7F2EA.
    static let paperMid = Swatch(name: "paper mid", hex: 0xF7F2EA)
    /// Activity gradient bottom, #ECE3D5.
    static let paperShade = Swatch(name: "paper shade", hex: 0xECE3D5)
    /// Activity card stroke, #DED6CA.
    static let paperStroke = Swatch(name: "paper stroke", hex: 0xDED6CA)
    /// Activity rail stroke, #D6CEC1.
    static let paperRail = Swatch(name: "paper rail", hex: 0xD6CEC1)
    /// Activity entry dot, #B3AA9C.
    static let paperDot = Swatch(name: "paper dot", hex: 0xB3AA9C)
    /// Active insight ring, #FCF9F3.
    static let paperRing = Swatch(name: "paper ring", hex: 0xFCF9F3)
    /// Day dot fill, #F5EFE5.
    static let paperDay = Swatch(name: "paper day", hex: 0xF5EFE5)
    /// Alternate day dot fill, #F1E9DD.
    static let paperDayAlt = Swatch(name: "paper day alt", hex: 0xF1E9DD)
    /// Secondary activity title, #4A5058.
    static let graphite = Swatch(name: "graphite", hex: 0x4A5058)
    /// Dates, summaries, and quiet meta, #8A9199.
    static let mist = Swatch(name: "mist", hex: 0x8A9199)

    static let swatches: [Swatch] = [
        silver,
        ink,
        navy,
        slate,
        plum,
        coral,
        pressedTagButtonNavy,
        pressedTagButtonCoral,
        paper,
        paperHighlight,
        paperMid,
        paperShade,
        paperStroke,
        paperRail,
        paperDot,
        paperRing,
        paperDay,
        paperDayAlt,
        graphite,
        mist,
    ]

    // Agent thread sheet. Off `swatches` so the core ramp APP-94 locked stays the same list.
    /// #FFFDF9
    static let threadSheetStart = Swatch(name: "thread sheet start", hex: 0xFFFDF9)
    /// #F7F2EA
    static let threadSheetMid = Swatch(name: "thread sheet mid", hex: 0xF7F2EA)
    /// #ECE3D5
    static let threadSheetEnd = Swatch(name: "thread sheet end", hex: 0xECE3D5)
    /// #DED6CA
    static let threadStroke = Swatch(name: "thread stroke", hex: 0xDED6CA)
    /// #8A9199
    static let threadMuted = Swatch(name: "thread muted", hex: 0x8A9199)
    /// #F1EADF
    static let threadChip = Swatch(name: "thread chip", hex: 0xF1EADF)
    /// #4A5058
    static let threadSecondary = Swatch(name: "thread secondary", hex: 0x4A5058)
    /// #FAF6EF
    static let threadFaceRing = Swatch(name: "thread face ring", hex: 0xFAF6EF)
    /// #CDB3A6
    static let threadFaceWarm = Swatch(name: "thread face warm", hex: 0xCDB3A6)
    /// #B8C3D1
    static let threadFaceCool = Swatch(name: "thread face cool", hex: 0xB8C3D1)
    /// #EDE6DA
    static let threadAgentBubble = Swatch(name: "thread agent bubble", hex: 0xEDE6DA)
    /// #FCF9F3
    static let threadCream = Swatch(name: "thread cream", hex: 0xFCF9F3)
    /// #D6CEC1
    static let threadRail = Swatch(name: "thread rail", hex: 0xD6CEC1)
    /// #B7C4AE
    static let threadStash = Swatch(name: "thread stash", hex: 0xB7C4AE)
    /// #F5EFE5. Yesterday ring fill.
    static let threadRingFill = Swatch(name: "thread ring fill", hex: 0xF5EFE5)
    /// #B3AA9C. Idle event dot on the rail.
    static let threadIdleDot = Swatch(name: "thread idle dot", hex: 0xB3AA9C)

    static let threadSwatches: [Swatch] = [
        threadSheetStart,
        threadSheetMid,
        threadSheetEnd,
        threadStroke,
        threadMuted,
        threadChip,
        threadSecondary,
        threadFaceRing,
        threadFaceWarm,
        threadFaceCool,
        threadAgentBubble,
        threadCream,
        threadRail,
        threadStash,
        threadRingFill,
        threadIdleDot,
    ]

    static let title = TypeStyle(name: "title", kind: .text, postScriptName: "InstrumentSans-Bold", size: 28)
    static let body = TypeStyle(name: "body", kind: .text, postScriptName: "InstrumentSans-Regular", size: 17)
    static let label = TypeStyle(name: "label", kind: .text, postScriptName: "InstrumentSans-Medium", size: 13)
    /// Small notes: dates, and the label above the real balance.
    static let caption = TypeStyle(name: "caption", kind: .text, postScriptName: "InstrumentSans-Regular", size: 12)
    static let number = TypeStyle(name: "number", kind: .number, postScriptName: "CommitMono-Regular", size: 17)
    static let numberLarge = TypeStyle(name: "number large", kind: .number, postScriptName: "CommitMono-Regular", size: 28)
    /// Heaviest number style. CommitMono-Bold is the heaviest Commit Mono face bundled.
    static let realBalance = TypeStyle(name: "real balance", kind: .realBalance, postScriptName: "CommitMono-Bold", size: 48)

    static let textStyles: [TypeStyle] = [title, body, label, caption]
    static let numberStyles: [TypeStyle] = [number, numberLarge]
    static let typeStyles: [TypeStyle] = textStyles + numberStyles + [realBalance]

    static let cardRadius: CGFloat = 36
    static let panelRadius: CGFloat = 28
    static let radii: [Radius] = [
        Radius(name: "card", value: cardRadius),
        Radius(name: "panel", value: panelRadius),
    ]

    /// Every corner goes through this, token radius or otherwise.
    static func shape(_ cornerRadius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    static let spacing: [CGFloat] = [
        spacing4,
        spacing8,
        spacing12,
        spacing16,
        spacing24,
        spacing32,
    ]

    /// One physical pixel, in points, for the display being drawn on.
    static func hairline(displayScale: CGFloat) -> CGFloat {
        1 / displayScale
    }
}

// The preview walks the same lists the tests lock, so every swatch,
// type style, radius, and spacing step is on screen.
#Preview("NormaTheme") {
    NormaThemePreview()
}

private struct NormaThemePreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NormaTheme.spacing24) {
                swatchSection
                typeSection
                radiusSection
                spacingSection
                NormaThemeHairline()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(NormaTheme.spacing16)
        }
        .background(NormaTheme.silver.color)
    }

    private var swatchSection: some View {
        VStack(alignment: .leading, spacing: NormaTheme.spacing12) {
            sectionTitle("Swatches")
            ForEach(NormaTheme.swatches) { swatch in
                HStack(spacing: NormaTheme.spacing12) {
                    NormaTheme.shape(NormaTheme.spacing12)
                        .fill(swatch.color)
                        .frame(width: NormaTheme.spacing32, height: NormaTheme.spacing32)
                        .overlay(
                            NormaTheme.shape(NormaTheme.spacing12)
                                .stroke(NormaTheme.ink.color, lineWidth: 1)
                        )
                    VStack(alignment: .leading, spacing: NormaTheme.spacing4) {
                        Text(swatch.name)
                            .font(NormaTheme.body.font)
                            .foregroundStyle(NormaTheme.ink.color)
                        Text(swatch.hexString)
                            .font(NormaTheme.number.font)
                            .foregroundStyle(NormaTheme.slate.color)
                    }
                }
            }
        }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: NormaTheme.spacing16) {
            sectionTitle("Type")
            ForEach(NormaTheme.typeStyles) { style in
                VStack(alignment: .leading, spacing: NormaTheme.spacing4) {
                    if style.kind == .realBalance {
                        Text("Real balance")
                            .font(NormaTheme.caption.font)
                            .foregroundStyle(NormaTheme.ink.color)
                    }
                    Text(style.sample)
                        .font(style.font)
                        .foregroundStyle(NormaTheme.ink.color)
                    Text("\(style.name)  \(style.postScriptName)  \(Int(style.size))")
                        .font(NormaTheme.label.font)
                        .foregroundStyle(NormaTheme.slate.color)
                }
            }
        }
    }

    private var radiusSection: some View {
        VStack(alignment: .leading, spacing: NormaTheme.spacing12) {
            sectionTitle("Radius")
            ForEach(NormaTheme.radii) { radius in
                VStack(alignment: .leading, spacing: NormaTheme.spacing8) {
                    NormaTheme.shape(radius.value)
                        .fill(NormaTheme.navy.color)
                        .frame(width: 120, height: 72)
                    Text("\(radius.name) \(Int(radius.value))")
                        .font(NormaTheme.body.font)
                        .foregroundStyle(NormaTheme.ink.color)
                }
            }
        }
    }

    private var spacingSection: some View {
        VStack(alignment: .leading, spacing: NormaTheme.spacing12) {
            sectionTitle("Spacing")
            ForEach(Array(NormaTheme.spacing.enumerated()), id: \.offset) { _, step in
                HStack(spacing: NormaTheme.spacing8) {
                    NormaTheme.shape(NormaTheme.spacing4)
                        .fill(NormaTheme.navy.color)
                        .frame(width: step, height: NormaTheme.spacing16)
                    Text("\(Int(step))")
                        .font(NormaTheme.number.font)
                        .foregroundStyle(NormaTheme.ink.color)
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(NormaTheme.label.font)
            .foregroundStyle(NormaTheme.plum.color)
    }
}

private struct NormaThemeHairline: View {
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        VStack(alignment: .leading, spacing: NormaTheme.spacing8) {
            Text("Hairline")
                .font(NormaTheme.label.font)
                .foregroundStyle(NormaTheme.plum.color)
            Text("1/\(displayScale) pt")
                .font(NormaTheme.number.font)
                .foregroundStyle(NormaTheme.ink.color)
            Rectangle()
                .fill(NormaTheme.ink.color)
                .frame(maxWidth: .infinity)
                .frame(height: NormaTheme.hairline(displayScale: displayScale))
        }
    }
}
