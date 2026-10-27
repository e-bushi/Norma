//
//  ActivityTimeline.swift
//  Norma
//
//  Activity timeline card. It is not wired into a screen. Pull state moves
//  the card and fades the header. Every color and size comes from
//  NormaTheme or ActivityTimelineMetrics.
//

import SwiftUI

/// Paper activity card: a header, a rail, and one row per day or entry.
struct ActivityTimeline: View {
    var model: ActivityTimelineModel
    var pullState: ActivityTimelinePullState = .home

    var body: some View {
        switch pullState.placement {
        case .flow(let paddingTop, let grows):
            card
                .padding(.top, paddingTop)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: grows ? .infinity : nil,
                    alignment: .top
                )
        case .absolute(let top, let zIndex):
            Spacer()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .top) {
                    card
                        .offset(y: top)
                        .zIndex(zIndex)
                }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: ActivityTimelineMetrics.cardGap) {
            content
        }
        .padding(.top, ActivityTimelineMetrics.paddingTop)
        .padding(.bottom, ActivityTimelineMetrics.paddingBottom)
        .padding(.horizontal, ActivityTimelineMetrics.paddingInline)
        .frame(minHeight: ActivityTimelineMetrics.cardHeight, alignment: .top)
        .background { cardChrome }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: ActivityTimelineMetrics.columnGap) {
            header
            ActivityTimelineList(rows: model.rows)
        }
        .frame(width: ActivityTimelineMetrics.columnWidth, alignment: .leading)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: ActivityTimelineMetrics.baselineGap) {
            styled(ActivityTimelineMetrics.headerTitleText, ActivityTimelineMetrics.headerTitle)
            Spacer(minLength: ActivityTimelineMetrics.baselineGap)
            styled(model.summary, ActivityTimelineMetrics.headerSummary)
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: ActivityTimelineMetrics.headerTitle.lineHeight, alignment: .leading)
        .blur(radius: pullState.headerBlur)
        .opacity(pullState.headerOpacity)
        .accessibilityElement(children: .combine)
        .accessibilityHidden(pullState.hidesHeader)
    }

    private var cardChrome: some View {
        let shape = ActivityTimelineMetrics.cardShape
        return
            shape
            .fill(ActivityTimelineMetrics.cardFill.color)
            .overlay {
                shape.fill(ActivityTimelineMetrics.cardGradient)
            }
            .overlay {
                shape.strokeBorder(
                    ActivityTimelineMetrics.cardStroke.color,
                    lineWidth: ActivityTimelineMetrics.cardStrokeWidth
                )
            }
            .shadow(
                color: ActivityTimelineMetrics.shadowColor,
                radius: ActivityTimelineMetrics.shadowBlur,
                x: ActivityTimelineMetrics.shadowX,
                y: ActivityTimelineMetrics.shadowY
            )
    }

    private func styled(_ text: String, _ style: ActivityTextStyle) -> some View {
        Text(text)
            .font(style.font)
            .foregroundStyle(style.swatch.color)
            .lineSpacing(style.lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct ActivityTimelineList: View {
    let rows: [ActivityTimelineRow]

    var body: some View {
        let layout = ActivityTimelineMetrics.railLayout(for: rows)
        ScrollView {
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: ActivityTimelineMetrics.rowSpacerHeight) {
                    ForEach(rows) { row in
                        ActivityTimelineRowView(row: row)
                    }
                }
                .frame(width: ActivityTimelineMetrics.listWidth, alignment: .leading)
                ActivityTimelineRail(layout: layout)
            }
            .frame(
                width: ActivityTimelineMetrics.listWidth,
                height: layout.height,
                alignment: .topLeading
            )
        }
        .frame(
            width: ActivityTimelineMetrics.listWidth,
            height: ActivityTimelineMetrics.listHeight,
            alignment: .top
        )
        .scrollIndicators(.hidden)
    }
}

private struct ActivityTimelineRowView: View {
    let row: ActivityTimelineRow

    private var presentation: ActivityRowPresentation {
        ActivityTimelineMetrics.presentation(for: row)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: ActivityTimelineMetrics.baselineGap) {
            leading
            if presentation.spaceBetween {
                Spacer(minLength: ActivityTimelineMetrics.baselineGap)
                trailing
            }
        }
        .padding(.top, presentation.paddingTop)
        .padding(.leading, presentation.paddingLeading)
        .frame(maxWidth: .infinity, minHeight: presentation.height, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.accessibilityLabel)
    }

    private var leading: some View {
        HStack(alignment: .firstTextBaseline, spacing: ActivityTimelineMetrics.baselineGap) {
            styled(row.title, presentation.title)
            if showsMetaWithTitle {
                styled(row.meta, presentation.meta)
            }
        }
    }

    private var trailing: some View {
        Group {
            if let amount = row.amount, let style = presentation.amount {
                styled(amount, style)
            } else {
                styled(row.meta, presentation.meta)
            }
        }
    }

    /// Title and meta share a baseline. Space-between keeps them together when an amount trails.
    private var showsMetaWithTitle: Bool {
        ActivityTimelineMetrics.showsMetaBesideTitle(
            spaceBetween: presentation.spaceBetween,
            hasAmount: row.amount != nil
        )
    }

    private func styled(_ text: String, _ style: ActivityTextStyle) -> some View {
        Text(text)
            .font(style.font)
            .foregroundStyle(style.swatch.color)
            .lineSpacing(style.lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct ActivityTimelineRail: View {
    let layout: ActivityRailLayout

    var body: some View {
        Canvas { context, _ in
            if layout.drawsSolidLine {
                stroke(from: layout.solidFromY, to: layout.solidToY, dashed: false, in: &context)
            }
            if layout.drawsDashedTail {
                stroke(from: layout.dashedFromY, to: layout.dashedToY, dashed: true, in: &context)
            }
            for dot in layout.dots {
                draw(dot, in: &context)
            }
        }
        .frame(width: ActivityTimelineMetrics.railWidth, height: layout.height, alignment: .topLeading)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func stroke(from startY: CGFloat, to endY: CGFloat, dashed: Bool, in context: inout GraphicsContext) {
        var path = Path()
        path.move(to: CGPoint(x: layout.centerX, y: startY))
        path.addLine(to: CGPoint(x: layout.centerX, y: endY))
        var style = StrokeStyle()
        style.lineWidth = layout.lineWidth
        style.lineCap = layout.roundCaps ? .round : .butt
        if dashed {
            style.dash = layout.dash
        }
        context.stroke(path, with: .color(layout.stroke.color), style: style)
    }

    private func draw(_ dot: ActivityRailDot, in context: inout GraphicsContext) {
        let rect = CGRect(
            x: layout.centerX - dot.radius,
            y: dot.centerY - dot.radius,
            width: dot.diameter,
            height: dot.diameter
        )
        let path = Path(ellipseIn: rect)
        context.fill(path, with: .color(dot.fill.color))
        if let stroke = dot.stroke {
            var style = StrokeStyle()
            style.lineWidth = dot.strokeWidth
            context.stroke(path, with: .color(stroke.color), style: style)
        }
    }
}

// AC-7
#Preview("Activity home") {
    ActivityTimelinePreview(pullState: .home)
}

#Preview("Activity pull 1") {
    ActivityTimelinePreview(pullState: .pull1)
}

#Preview("Activity pull 2") {
    ActivityTimelinePreview(pullState: .pull2)
}

#Preview("Activity pull 3") {
    ActivityTimelinePreview(pullState: .pull3)
}

private struct ActivityTimelinePreview: View {
    let pullState: ActivityTimelinePullState

    var body: some View {
        ActivityTimeline(model: .sample, pullState: pullState)
            .frame(height: pullState.previewHeight, alignment: .top)
            .background(NormaTheme.silver.color)
    }
}
