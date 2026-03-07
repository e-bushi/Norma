//
//  ColoredWaveTextView.swift
//  Norma
//
//  Created by Claude on 12/24/25.
//

import SwiftUI

/// A wave text view that supports per-word colors.
/// Each word rises up from below with a blur-to-sharp transition, staggered to create a wave.
struct ColoredWaveTextView: View {
    let words: [(word: String, color: Color)]
    let font: Font
    let isAnimating: Bool
    var alignment: HorizontalAlignment = .leading

    private let wordDelay: Double = 0.06
    private let animationDuration: Double = 0.5
    private let initialOffset: CGFloat = 18
    private let initialBlur: CGFloat = 5

    @State private var animatedWordCount: Int = 0

    var body: some View {
        WaveColorFlowLayout(spacing: 6, lineSpacing: 2, alignment: alignment) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, item in
                Text(item.word)
                    .font(font)
                    .foregroundColor(item.color)
                    .opacity(index < animatedWordCount ? 1 : 0)
                    .offset(y: index < animatedWordCount ? 0 : initialOffset)
                    .blur(radius: index < animatedWordCount ? 0 : initialBlur)
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue { startAnimation() }
        }
        .onAppear {
            if isAnimating { startAnimation() }
        }
    }

    private func startAnimation() {
        animatedWordCount = 0
        for index in 0..<words.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * wordDelay) {
                withAnimation(.spring(response: animationDuration, dampingFraction: 0.75)) {
                    animatedWordCount = index + 1
                }
            }
        }
    }
}

/// Flow layout for colored wave words
struct WaveColorFlowLayout: Layout {
    let spacing: CGFloat
    let lineSpacing: CGFloat
    var alignment: HorizontalAlignment = .leading

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
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
                let lineWidth = currentX - spacing
                let offsetX = alignmentOffset(lineWidth: lineWidth, maxWidth: maxWidth)
                for i in lineStartIndex..<index {
                    positions[i].x += offsetX
                }
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
