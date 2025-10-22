//
//  TextStyles.swift
//  Norma
//
//  Created by Claude on 10/17/25.
//

import SwiftUI

// MARK: - Text Style Modifiers

/// Large title text style - Used for main page titles
struct NormaTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.normaTitle(28))
            .foregroundColor(.primary)
    }
}

/// Section headline style - Used for section headers
struct NormaHeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.normaHeadline(20))
            .foregroundColor(.primary)
    }
}

/// Subheadline style - Used for smaller headers
struct NormaSubheadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.normaHeadline(17))
            .foregroundColor(.primary)
    }
}

/// Body text style - Used for main content
struct NormaBodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.normaBody(16))
            .foregroundColor(.primary)
    }
}

/// Chat message text style - Used for chat bubbles (Nunito Medium)
struct NormaChatTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.normaChatText(16))
            .foregroundColor(.primary)
            .lineSpacing(4)
    }
}

/// Caption style - Used for small labels and metadata (Nunito Light)
struct NormaCaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.normaMicro(13))
            .foregroundColor(.secondary)
    }
}

/// Tag/Badge text style - Used for category pills (Rubik Medium)
struct NormaTagStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.normaFinancial(13))
            .foregroundColor(.white)
    }
}

/// Number/Currency style - Used for displaying amounts (Rubik Medium, tabular)
struct NormaCurrencyStyle: ViewModifier {
    let emphasis: Bool

    init(emphasis: Bool = false) {
        self.emphasis = emphasis
    }

    func body(content: Content) -> some View {
        content
            .font(emphasis ? .normaFinancial(20) : .normaFinancial(16))
            .foregroundColor(.primary)
            .monospacedDigit()
    }
}

// MARK: - Convenience Extension

extension View {
    /// Apply Norma title style
    func normaTitle() -> some View {
        modifier(NormaTitleStyle())
    }

    /// Apply Norma headline style
    func normaHeadline() -> some View {
        modifier(NormaHeadlineStyle())
    }

    /// Apply Norma subheadline style
    func normaSubheadline() -> some View {
        modifier(NormaSubheadlineStyle())
    }

    /// Apply Norma body text style
    func normaBody() -> some View {
        modifier(NormaBodyStyle())
    }

    /// Apply Norma chat text style
    func normaChatText() -> some View {
        modifier(NormaChatTextStyle())
    }

    /// Apply Norma caption style
    func normaCaption() -> some View {
        modifier(NormaCaptionStyle())
    }

    /// Apply Norma tag/badge style
    func normaTag() -> some View {
        modifier(NormaTagStyle())
    }

    /// Apply Norma currency style
    func normaCurrency(emphasis: Bool = false) -> some View {
        modifier(NormaCurrencyStyle(emphasis: emphasis))
    }

    /// Apply Norma label style
    func normaLabel() -> some View {
        font(.normaLabel(12))
    }
}
