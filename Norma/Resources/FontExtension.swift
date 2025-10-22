//
//  FontExtension.swift
//  Norma
//
//  Created by Claude on 10/17/25.
//

import SwiftUI

extension Font {
    // MARK: - Norma Brand Fonts

    /// Display/Headers - Rubik Semibold
    static func normaTitle(_ size: CGFloat = 24) -> Font {
        .custom(FontFamily.Rubik.semiBold, size: size)
    }

    /// Headers - Rubik Medium
    static func normaHeadline(_ size: CGFloat = 36) -> Font {
        .custom(FontFamily.Rubik.regular, size: size)
    }

    /// Subheadline - Rubik Regular
    static func normaSubheadline(_ size: CGFloat = 16) -> Font {
        .custom(FontFamily.Rubik.regular, size: size)
    }

    /// Chat Interface - Nunito Medium
    static func normaChatText(_ size: CGFloat = 16) -> Font {
        .custom(FontFamily.Nunito.medium, size: size)
    }

    /// Body Text - Nunito Regular
    static func normaBody(_ size: CGFloat = 16) -> Font {
        .custom(FontFamily.Nunito.regular, size: size)
    }

    /// Financial Data - Rubik Medium (tabular)
    static func normaFinancial(_ size: CGFloat = 16) -> Font {
        .custom(FontFamily.Rubik.medium, size: size)
    }

    /// Input Text - Rubik Regular
    static func normaInput(_ size: CGFloat = 16) -> Font {
        .custom(FontFamily.Rubik.regular, size: size)
    }

    /// Micro-copy - Nunito Light
    static func normaMicro(_ size: CGFloat = 13) -> Font {
        .custom(FontFamily.Nunito.light, size: size)
    }

    /// Labels - Nunito SemiBold
    static func normaLabel(_ size: CGFloat = 12) -> Font {
        .custom(FontFamily.Nunito.semiBold, size: size)
    }
}
