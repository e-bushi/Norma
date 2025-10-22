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

    /// Financial Data - Rubik Medium (tabular)
    static func normaFinancial(_ size: CGFloat = 16) -> Font {
        .custom(FontFamily.Rubik.medium, size: size)
    }

    /// Input Text - Rubik Regular
    static func normaInput(_ size: CGFloat = 16) -> Font {
        .custom(FontFamily.Rubik.regular, size: size)
    }
}
