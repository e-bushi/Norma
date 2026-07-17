//
//  RunwayShareCard.swift
//  Norma
//
//  The shareable "runway card" — Norma's virality play. Shares the *insight,
//  not the ledger*: runway as a unit of time (a flex, never a balance), plus a
//  flight-status tier driven by runway × bill-load. Load RAISES the tier, so
//  honesty is the dominant strategy and no one is shamed for a tight ratio.
//
//  Presented like the iOS widget gallery: a paged sheet of style variants the
//  user swipes through, then shares the selected one as an image.
//
//  In-app status tiers stay Urgency…Abundant (the calm daily read); these
//  flight tiers are scoped to the social card only (decision 2026-07-17).
//

import SwiftUI

// MARK: - Flight tier (runway × load)

enum RunwayTier {
    case grounded, gliding, climbing, soaring

    /// Runway floor (days) below which you're not airborne yet.
    private static let floorDays = 60
    /// Long-runway gate (days) for the top tier.
    private static let longDays = 180

    var title: String {
        switch self {
        case .grounded: return "Grounded"
        case .gliding:  return "Gliding"
        case .climbing: return "Climbing"
        case .soaring:  return "Soaring"
        }
    }

    var icon: String {
        switch self {
        case .grounded: return "airplane"
        case .gliding:  return "paperplane.fill"
        case .climbing: return "airplane.departure"
        case .soaring:  return "sparkles"
        }
    }

    var blurb: String {
        switch self {
        case .grounded: return "building toward liftoff."
        case .gliding:  return "comfortable and climbing."
        case .climbing: return "runway holding under real weight."
        case .soaring:  return "long runway, heavy load — the hard flex."
        }
    }

    /// Tier from runway + monthly bills + monthly income.
    /// - Grounded when runway is below the floor (any load).
    /// - Above the floor, load decides — and heavier load earns a higher tier,
    ///   so under-reporting bills can't game the badge up (it craters runway).
    /// - Returns nil when airborne but income is unknown (→ runway-only card).
    static func compute(runwayDays: Int, bills: Double, income: Double) -> RunwayTier? {
        if runwayDays < floorDays { return .grounded }
        guard income > 0 else { return nil }
        let load = bills / income
        if runwayDays >= longDays && load >= 0.75 { return .soaring }
        if load >= 0.5 { return .climbing }
        return .gliding
    }
}

// MARK: - Card data

struct RunwayCardData {
    let runwayValue: String   // e.g. "3"
    let runwayUnit: String    // e.g. "months"
    let days: Int
    let tier: RunwayTier?
    let loadPercent: Int?     // bills ÷ income, nil when income unknown
}

// MARK: - Card styles

enum RunwayCardStyle: CaseIterable, Identifiable {
    case nightfall, aurora, sunset, paper

    var id: String { name }

    var name: String {
        switch self {
        case .nightfall: return "Nightfall"
        case .aurora:    return "Aurora"
        case .sunset:    return "Sunset"
        case .paper:     return "Paper"
        }
    }

    var textColor: Color {
        switch self {
        case .paper: return Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
        default:     return Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
        }
    }

    var subtleColor: Color { textColor.opacity(0.6) }

    var accent: Color {
        switch self {
        case .nightfall: return NormaPalette.lavender
        case .aurora:    return Color(red: 0.62, green: 0.80, blue: 0.86)
        case .sunset:    return Color(red: 0.98, green: 0.72, blue: 0.55)
        case .paper:     return NormaPalette.lavender
        }
    }

    @ViewBuilder
    var background: some View {
        switch self {
        case .nightfall:
            ZStack {
                Color(red: 0x14/255, green: 0x14/255, blue: 0x18/255)
                RadialGradient(
                    colors: [NormaPalette.lavender.opacity(0.28), .clear],
                    center: .topLeading, startRadius: 8, endRadius: 340
                )
            }
        case .aurora:
            LinearGradient(
                colors: [
                    Color(red: 0x1B/255, green: 0x16/255, blue: 0x2E/255),
                    Color(red: 0x2A/255, green: 0x2B/255, blue: 0x55/255),
                    Color(red: 0x14/255, green: 0x2A/255, blue: 0x38/255)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .sunset:
            LinearGradient(
                colors: [
                    Color(red: 0x2A/255, green: 0x12/255, blue: 0x2E/255),
                    Color(red: 0x5A/255, green: 0x22/255, blue: 0x3A/255),
                    Color(red: 0x8A/255, green: 0x3A/255, blue: 0x2E/255)
                ],
                startPoint: .top, endPoint: .bottom
            )
        case .paper:
            Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
        }
    }
}

// MARK: - The card

struct RunwayCard: View {
    let data: RunwayCardData
    let style: RunwayCardStyle

    static let size = CGSize(width: 320, height: 400)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("NORMA")
                    .font(.custom(FontFamily.Rubik.bold, size: 14))
                    .tracking(2)
                    .foregroundColor(style.textColor.opacity(0.8))
                Spacer()
                if let tier = data.tier {
                    tierBadge(tier)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: -2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(data.runwayValue)
                        .font(.custom(FontFamily.Rubik.bold, size: 84))
                        .foregroundColor(style.textColor)
                    Text(data.runwayUnit)
                        .font(.custom(FontFamily.Rubik.semiBold, size: 26))
                        .foregroundColor(style.textColor.opacity(0.85))
                }
                Text("of freedom")
                    .font(.custom(FontFamily.Rubik.medium, size: 20))
                    .foregroundColor(style.accent)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text(data.tier?.blurb ?? "how long does your money last?")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundColor(style.subtleColor)
                if let load = data.loadPercent {
                    Text("flying at \(load)% bill-load")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 13))
                        .foregroundColor(style.textColor.opacity(0.75))
                }
            }
        }
        .padding(28)
        .frame(width: Self.size.width, height: Self.size.height, alignment: .leading)
        .background(style.background)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func tierBadge(_ tier: RunwayTier) -> some View {
        HStack(spacing: 6) {
            Image(systemName: tier.icon)
                .font(.system(size: 12, weight: .bold))
            Text(tier.title.lowercased())
                .font(.custom(FontFamily.Rubik.semiBold, size: 13))
        }
        .foregroundColor(style.accent)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(Capsule().fill(style.accent.opacity(0.16)))
        .overlay(Capsule().stroke(style.accent.opacity(0.5), lineWidth: 1))
    }
}

// MARK: - Widget-gallery share sheet

struct RunwayShareSheet: View {
    let data: RunwayCardData

    @Environment(\.dismiss) private var dismiss
    @State private var styleIndex = 0

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private var accent: Color { NormaPalette.lavender }

    private var styles: [RunwayCardStyle] { RunwayCardStyle.allCases }

    var body: some View {
        VStack(spacing: 0) {
            Text("share your runway")
                .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                .foregroundColor(cream)
                .padding(.top, 24)

            Text("swipe for a style")
                .font(.custom(FontFamily.Rubik.medium, size: 13))
                .foregroundColor(mutedText)
                .padding(.top, 4)

            TabView(selection: $styleIndex) {
                ForEach(Array(styles.enumerated()), id: \.offset) { index, style in
                    RunwayCard(data: data, style: style)
                        .shadow(color: .black.opacity(0.45), radius: 24, y: 12)
                        .padding(.vertical, 24)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: RunwayCard.size.height + 80)

            shareButton
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            Button { dismiss() } label: {
                Text("done")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundColor(mutedText)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var shareButton: some View {
        if let image = renderedImage {
            ShareLink(
                item: image,
                preview: SharePreview("my runway", image: image)
            ) {
                shareLabel
            }
            .simultaneousGesture(TapGesture().onEnded {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            })
        } else {
            shareLabel.opacity(0.5)
        }
    }

    private var shareLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 16, weight: .semibold))
            Text("share")
                .font(.custom(FontFamily.Rubik.semiBold, size: 16))
        }
        .foregroundColor(cream)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Capsule().fill(accent.opacity(0.16)))
        .overlay(Capsule().stroke(accent.opacity(0.55), lineWidth: 1))
    }

    /// Rasterize the currently-selected style for sharing.
    @MainActor private var renderedImage: Image? {
        let style = styles[min(styleIndex, styles.count - 1)]
        let renderer = ImageRenderer(content: RunwayCard(data: data, style: style))
        renderer.scale = 3
        guard let ui = renderer.uiImage else { return nil }
        return Image(uiImage: ui)
    }
}
