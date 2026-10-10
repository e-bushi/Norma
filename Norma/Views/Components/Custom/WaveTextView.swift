//
//  WaveTextView.swift
//  Norma
//
//  Created by Claude on 1/18/26.
//

import SwiftUI

/// A text view that animates words with a cascading rise + blur effect.
/// Each word starts low and blurred, then rises up and comes into focus
/// with staggered timing to create a wave traveling through the text.
/// Reduce Motion shows the finished line immediately, with no blur or rise.
struct WaveTextView: View {
    let text: String
    let font: Font
    let color: Color
    let isAnimating: Bool
    var alignment: HorizontalAlignment = .center
    /// Optional accent word appended after `text` (e.g., a trailing "?" or ".").
    var accentSuffix: String? = nil
    /// Color used for the accent suffix (defaults to lavender brand accent).
    var accentColor: Color = Color(red: 0.588, green: 0.463, blue: 0.851)
    /// Negative tightens letter-spacing on each word.
    var tracking: CGFloat = 0
    /// Horizontal spacing between adjacent words.
    var wordSpacing: CGFloat = 4
    /// Vertical spacing between wrapped lines.
    var lineSpacing: CGFloat = 6
    /// Optional per-word callback fired in sync with each word's reveal.
    /// Used by callers (e.g. onboarding interstitials) to layer haptics on
    /// top of the visual wave. Not called when Reduce Motion is on.
    var onWordAppear: ((Int) -> Void)? = nil

    /// Animation configuration
    private let wordDelay: Double = 0.06
    private let animationDuration: Double = 0.5
    private let initialOffset: CGFloat = 18
    private let initialBlur: CGFloat = 5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedWordCount: Int = 0

    private struct Segment {
        let text: String
        let color: Color
    }

    private var segments: [Segment] {
        var segs = text
            .split(separator: " ")
            .map { Segment(text: String($0), color: color) }
        if let suffix = accentSuffix, !suffix.isEmpty {
            segs.append(Segment(text: suffix, color: accentColor))
        }
        return segs
    }

    var body: some View {
        WaveFlowLayout(spacing: wordSpacing, lineSpacing: lineSpacing, alignment: alignment) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, seg in
                WaveWord(
                    word: seg.text,
                    font: font,
                    color: seg.color,
                    tracking: tracking,
                    isAnimated: reduceMotion || index < animatedWordCount,
                    initialOffset: initialOffset,
                    initialBlur: initialBlur,
                    animationDuration: animationDuration
                )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenText)
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                startAnimation()
            }
        }
        .onAppear {
            if isAnimating {
                startAnimation()
            }
        }
    }

    private var spokenText: String {
        if let suffix = accentSuffix, !suffix.isEmpty {
            return "\(text)\(suffix)"
        }
        return text
    }

    private func startAnimation() {
        guard !reduceMotion else { return }
        animatedWordCount = 0

        for index in 0..<segments.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * wordDelay) {
                guard !reduceMotion else { return }
                withAnimation(.spring(response: animationDuration, dampingFraction: 0.75)) {
                    animatedWordCount = index + 1
                }
                onWordAppear?(index)
            }
        }
    }
}

/// Individual word view with rise + blur animation
private struct WaveWord: View {
    let word: String
    let font: Font
    let color: Color
    var tracking: CGFloat = 0
    let isAnimated: Bool
    let initialOffset: CGFloat
    let initialBlur: CGFloat
    let animationDuration: Double

    var body: some View {
        Text(word)
            .font(font)
            .tracking(tracking)
            .foregroundColor(color)
            .opacity(isAnimated ? 1 : 0)
            .offset(y: isAnimated ? 0 : initialOffset)
            .blur(radius: isAnimated ? 0 : initialBlur)
    }
}

/// Flow layout that wraps words to new lines
private struct WaveFlowLayout: Layout {
    let spacing: CGFloat
    let lineSpacing: CGFloat
    var alignment: HorizontalAlignment = .center

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        // Use the proposed width if available so centering works correctly
        let width = proposal.width ?? result.size.width
        return CGSize(width: width, height: result.size.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        var lineStartIndex = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                // Align the current line
                let lineWidth = currentX - spacing
                let offsetX = alignmentOffset(lineWidth: lineWidth, maxWidth: maxWidth)
                for i in lineStartIndex..<index {
                    positions[i].x += offsetX
                }

                // Move to next line
                currentX = 0
                currentY += lineHeight + lineSpacing
                lineHeight = 0
                lineStartIndex = index
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalWidth = max(totalWidth, currentX - spacing)
        }

        // Align the last line
        let lineWidth = currentX - spacing
        let offsetX = alignmentOffset(lineWidth: lineWidth, maxWidth: maxWidth)
        for i in lineStartIndex..<positions.count {
            positions[i].x += offsetX
        }

        return (
            size: CGSize(width: totalWidth, height: currentY + lineHeight),
            positions: positions
        )
    }

    private func alignmentOffset(lineWidth: CGFloat, maxWidth: CGFloat) -> CGFloat {
        switch alignment {
        case .leading:
            return 0
        case .trailing:
            return maxWidth - lineWidth
        default:
            return (maxWidth - lineWidth) / 2
        }
    }
}

// MARK: - Previews

#Preview {
    WaveTextView(
        text: "what's your rhythm",
        font: .system(size: 56, weight: .bold, relativeTo: .largeTitle),
        color: NormaPalette.ink,
        isAnimating: true,
        alignment: .leading,
        accentSuffix: ".",
        accentColor: NormaPalette.lavender
    )
    .padding(.horizontal, 24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(NormaPalette.canvas)
}
