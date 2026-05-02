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

/// Renders a Note's segments: prose flows naturally, each chip lives on its own
/// right-aligned row (toward the voice control), preserving document order.
/// Kinds with 3+ tokens collapse to a single GroupChipView summary pill at
/// the position of their first token.
struct NoteSegmentsView: View {
    let note: Note
    var textFont: Font = .system(size: 17)
    var textColor: Color = .white.opacity(0.92)
    /// When false, prose text segments are suppressed and only chip groupings
    /// render. Used by the editable canvas where the TextField owns the prose.
    var showsProse: Bool = true
    /// Called when the user confirms a reminder chip's date. Wired by the
    /// note canvas to `NoteRepository.confirmReminder`. Nil = reminder chips
    /// stay non-interactive (used by sample-data previews).
    var onConfirmReminder: ((NoteToken, Date) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(grouped.enumerated()), id: \.offset) { _, block in
                if case .text = block, !showsProse { EmptyView() } else {
                    blockView(for: block)
                        .transition(.chipAppear)
                }
            }
        }
        .animation(ChipAnimation.spring, value: note.tokens.count)
        .animation(ChipAnimation.spring, value: note.tokens.map(\.id))
    }

    private var tokensByKind: [NoteToken.Kind: [NoteToken]] {
        Dictionary(grouping: note.tokens, by: { $0.kind })
    }

    private var collapsedKinds: Set<NoteToken.Kind> {
        Set(tokensByKind.filter { $0.value.count >= 3 }.keys)
    }

    @ViewBuilder
    private func blockView(for block: Block) -> some View {
        switch block {
        case .text(let string):
            Text(string)
                .font(textFont)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .chip(let token):
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ChipView(
                        token: token,
                        style: .inline,
                        onConfirmReminder: token.kind == .reminder
                            ? { date in onConfirmReminder?(token, date) }
                            : nil
                    )
                }
                if let label = projectionLabel(for: token) {
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1.6)
                        .foregroundStyle(NormaPalette.lavender.opacity(0.7))
                        .padding(.trailing, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        case .summary(let kind, let tokens):
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                GroupChipView(kind: kind, tokens: tokens)
            }
        }
    }

    private func projectionLabel(for token: NoteToken) -> String? {
        guard let recurrence = token.recurrence else { return nil }
        var parts: [String] = [recurrence.displayLabel]
        if let next = token.nextOccurrence() {
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            parts.append("NEXT \(f.string(from: next).uppercased())")
        }
        if let monthlyUsd = token.monthlyUsdEquivalent {
            let body = NormaPalette.thousandsSeparated(String(format: "%.0f", monthlyUsd))
            parts.append("≈ $\(body) / MO")
        } else if let monthly = token.monthlyEquivalent {
            let body = NormaPalette.thousandsSeparated(String(format: "%.0f", monthly))
            let symbol = NormaPalette.currencySymbol(for: token.currency)
            switch token.currency.uppercased() {
            case "USD", "CAD", "AUD", "NZD":
                parts.append("≈ \(symbol)\(body) / MO")
            default:
                parts.append("≈ \(body)\(symbol) / MO")
            }
        }
        return parts.joined(separator: " · ")
    }

    private enum Block {
        case text(String)
        case chip(NoteToken)
        case summary(NoteToken.Kind, [NoteToken])
    }

    /// Walks segments in document order. Coalesces adjacent text into single
    /// Text blocks; for any kind with 3+ tokens, emits one summary pill at
    /// the position of the first token and skips the rest.
    private var grouped: [Block] {
        let collapsed = collapsedKinds
        var seenCollapsed = Set<NoteToken.Kind>()
        var out: [Block] = []
        var pending = ""
        for segment in note.segments() {
            switch segment {
            case .text(let str):
                pending += str
            case .chip(let token):
                let trimmed = pending.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { out.append(.text(trimmed)) }
                pending = ""
                if collapsed.contains(token.kind) {
                    if !seenCollapsed.contains(token.kind) {
                        seenCollapsed.insert(token.kind)
                        out.append(.summary(token.kind, tokensByKind[token.kind] ?? []))
                    }
                } else {
                    out.append(.chip(token))
                }
            }
        }
        let trimmed = pending.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { out.append(.text(trimmed)) }
        return out
    }
}
