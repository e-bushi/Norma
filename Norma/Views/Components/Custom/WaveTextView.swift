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
struct WaveTextView: View {
    let text: String
    let font: Font
    let color: Color
    let isAnimating: Bool
    var alignment: HorizontalAlignment = .center

    /// Animation configuration
    private let wordDelay: Double = 0.06
    private let animationDuration: Double = 0.5
    private let initialOffset: CGFloat = 18
    private let initialBlur: CGFloat = 5

    @State private var animatedWordCount: Int = 0

    private var words: [String] {
        text.split(separator: " ").map(String.init)
    }

    var body: some View {
        WaveFlowLayout(spacing: 4, lineSpacing: 6, alignment: alignment) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                WaveWord(
                    word: word,
                    font: font,
                    color: color,
                    isAnimated: index < animatedWordCount,
                    initialOffset: initialOffset,
                    initialBlur: initialBlur,
                    animationDuration: animationDuration
                )
            }
        }
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

    private func startAnimation() {
        // Reset
        animatedWordCount = 0

        // Animate each word with staggered delay
        for index in 0..<words.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * wordDelay) {
                withAnimation(.spring(response: animationDuration, dampingFraction: 0.75)) {
                    animatedWordCount = index + 1
                }
            }
        }
    }
}

/// Individual word view with rise + blur animation
private struct WaveWord: View {
    let word: String
    let font: Font
    let color: Color
    let isAnimated: Bool
    let initialOffset: CGFloat
    let initialBlur: CGFloat
    let animationDuration: Double

    var body: some View {
        Text(word)
            .font(font)
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

#Preview("Wave Text - Success") {
    VStack(spacing: 40) {
        WaveTextView(
            text: "You spent $72.50 of your $100.00 cap and earned 10 points.",
            font: .normaFinancial(20),
            color: .primary,
            isAnimating: true
        )
        .padding(.horizontal, 24)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("NormaBackground"))
}

#Preview("Wave Text - Over Budget") {
    WaveTextView(
        text: "You went $27.30 over your $100.00 cap.",
        font: .normaFinancial(20),
        color: .primary,
        isAnimating: true
    )
    .padding(.horizontal, 24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("NormaBackground"))
}

#Preview("Wave Text - Short") {
    WaveTextView(
        text: "You spent $72.50 of your $100.00 cap.",
        font: .normaFinancial(20),
        color: .primary,
        isAnimating: true
    )
    .padding(.horizontal, 24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("NormaBackground"))
}
