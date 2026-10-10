//
//  VariableFont.swift
//  Norma
//
//  Rubik ships as one variable file (PostScript name Rubik-Light, wght
//  300–900). SwiftGen still emits names like Rubik-Light_SemiBold, which
//  are not in the file, so every face is built from Rubik-Light plus the
//  weight axis. Body text scales with the same text styles as `relativeTo:`.
//

import CoreText
import SwiftUI
import UIKit

enum VariableFont {
    /// OpenType tag 'wght'.
    static let wghtTag = NSNumber(value: Int32(0x77676874))

    /// The only PostScript name in Rubik-Variable.ttf.
    static func postScriptName(for face: FontConvertible) -> String {
        if face.family == "Rubik" || face.path == "Rubik-Variable.ttf" {
            return "Rubik-Light"
        }
        return face.name
    }

    /// wght axis value for a SwiftGen face name. `Rubik-Light` is the 300
    /// master; `Rubik-Light_SemiBold` and the other suffixes are styles.
    static func weightAxis(for face: FontConvertible) -> CGFloat {
        let style = face.name.split(separator: "_").last.map(String.init) ?? face.name
        switch style {
        case "Thin": return 100
        case "ExtraLight", "UltraLight": return 200
        case "Light", "Rubik-Light": return 300
        case "Regular": return 400
        case "Medium": return 500
        case "SemiBold", "Semibold", "DemiBold": return 600
        case "Bold": return 700
        case "ExtraBold", "UltraBold": return 800
        case "Black", "Heavy": return 900
        default: return 400
        }
    }

    /// Point size at `dynamicTypeSize`, using the same metrics as
    /// `Font.custom(_:size:relativeTo:)`.
    static func scaledSize(
        _ size: CGFloat,
        relativeTo textStyle: Font.TextStyle,
        dynamicTypeSize: DynamicTypeSize
    ) -> CGFloat {
        let metrics = UIFontMetrics(forTextStyle: textStyle.uiFontTextStyle)
        let traits = UITraitCollection(preferredContentSizeCategory: dynamicTypeSize.contentSizeCategory)
        return metrics.scaledValue(for: size, compatibleWith: traits)
    }

    /// Rubik at `size` with this face's weight axis. Nil when the file did not register.
    static func uiFont(_ face: FontConvertible, size: CGFloat) -> UIFont? {
        face.register()
        let postScript = postScriptName(for: face) as CFString
        let base = CTFontCreateWithName(postScript, size, nil)
        let baseName = (CTFontCopyPostScriptName(base) as String).lowercased()
        let family = (CTFontCopyFamilyName(base) as String).lowercased()
        guard baseName.contains("rubik") || family.contains("rubik") else { return nil }

        let variedDescriptor = CTFontDescriptorCreateCopyWithVariation(
            CTFontCopyFontDescriptor(base),
            wghtTag,
            weightAxis(for: face)
        )
        return CTFontCreateWithFontDescriptor(variedDescriptor, size, nil) as UIFont
    }

    static func swiftUIFont(
        _ face: FontConvertible,
        size: CGFloat,
        relativeTo textStyle: Font.TextStyle?,
        dynamicTypeSize: DynamicTypeSize,
        italic: Bool = false
    ) -> Font {
        let resolvedSize: CGFloat
        if let textStyle {
            resolvedSize = scaledSize(size, relativeTo: textStyle, dynamicTypeSize: dynamicTypeSize)
        } else {
            resolvedSize = size
        }
        guard let uiFont = uiFont(face, size: resolvedSize) else {
            var fallback = Font.system(size: resolvedSize, weight: swiftUIWeight(for: face))
            if italic { fallback = fallback.italic() }
            return fallback
        }
        var font = Font(uiFont as CTFont)
        if italic { font = font.italic() }
        return font
    }

    static func swiftUIWeight(for face: FontConvertible) -> Font.Weight {
        switch weightAxis(for: face) {
        case ..<350: return .light
        case ..<450: return .regular
        case ..<550: return .medium
        case ..<650: return .semibold
        case ..<750: return .bold
        case ..<850: return .heavy
        default: return .black
        }
    }
}

extension View {
    /// Rubik at a design size that scales with `textStyle`, the same contract as `relativeTo:`.
    func rubik(
        _ face: FontConvertible,
        size: CGFloat,
        relativeTo textStyle: Font.TextStyle,
        italic: Bool = false
    ) -> some View {
        modifier(RubikFontModifier(face: face, size: size, textStyle: textStyle, italic: italic))
    }
}

private struct RubikFontModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let face: FontConvertible
    let size: CGFloat
    let textStyle: Font.TextStyle
    var italic = false

    func body(content: Content) -> some View {
        content.font(
            VariableFont.swiftUIFont(
                face,
                size: size,
                relativeTo: textStyle,
                dynamicTypeSize: dynamicTypeSize,
                italic: italic
            )
        )
    }
}

extension Font.TextStyle {
    var uiFontTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }
}

extension DynamicTypeSize {
    var contentSizeCategory: UIContentSizeCategory {
        switch self {
        case .xSmall: return .extraSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .extraLarge
        case .xxLarge: return .extraExtraLarge
        case .xxxLarge: return .extraExtraExtraLarge
        case .accessibility1: return .accessibilityMedium
        case .accessibility2: return .accessibilityLarge
        case .accessibility3: return .accessibilityExtraLarge
        case .accessibility4: return .accessibilityExtraExtraLarge
        case .accessibility5: return .accessibilityExtraExtraExtraLarge
        @unknown default: return .large
        }
    }
}
