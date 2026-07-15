//
//  WrappingFlowLayout.swift
//  Norma
//
//  Created by Claude on 4/25/26.
//

import SwiftUI

/// Flows subviews left-to-right and wraps to the next row when the proposed
/// width is exceeded. Each subview stays atomic — used to mix word-Text views
/// with ChipView nodes for inline note rendering.
struct WrappingFlowLayout: Layout {
    var horizontalSpacing: CGFloat = 4
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(subviews: subviews, maxWidth: maxWidth)
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * verticalSpacing
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        let rows = computeRows(subviews: subviews, maxWidth: maxWidth)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            let rowBottom = y + row.height
            for item in row.items {
                let size = item.size
                subviews[item.index].place(
                    at: CGPoint(x: x, y: rowBottom),
                    anchor: .bottomLeading,
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )
                x += size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    private struct RowItem {
        let index: Int
        let size: CGSize
    }

    private struct Row {
        var items: [RowItem] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.init(width: maxWidth, height: nil))
            let projected = current.width + size.width + (current.items.isEmpty ? 0 : horizontalSpacing)

            if projected > maxWidth && !current.items.isEmpty {
                rows.append(current)
                current = Row()
            }

            if !current.items.isEmpty { current.width += horizontalSpacing }
            current.items.append(RowItem(index: index, size: size))
            current.width += size.width
            current.height = max(current.height, size.height)
        }

        if !current.items.isEmpty { rows.append(current) }
        return rows
    }
}
