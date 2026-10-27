//
//  AgentThread.swift
//  Norma
//
//  Reusable agent thread sheet from the Agents board. Not wired into a screen.
//  Every color is a NormaTheme token. Row heights are minimums so type can grow.
//

import SwiftUI
import UIKit

// MARK: - Model

struct AgentThreadModel: Equatable {
    var rows: [AgentThreadRow]

    var spacerHeights: [CGFloat] {
        rows.compactMap { row in
            if case .spacer(let height) = row.kind { return height }
            return nil
        }
    }

    var events: [AgentThreadEvent] {
        rows.compactMap { row in
            if case .event(let event) = row.kind { return event }
            return nil
        }
    }

    var replies: [AgentThreadReply] {
        rows.compactMap { row in
            if case .reply(let reply) = row.kind { return reply }
            return nil
        }
    }

    /// Sample thread: header, yesterday, today with an idle and an active event,
    /// Stash, Ratio, and Norma, then You. Spacers between those groups are 10, 20, 12, 16.
    static let board = AgentThreadModel(rows: [
        AgentThreadRow(id: "header", kind: .header(AgentThreadHeader(title: "Everyone", agentCount: 5))),
        AgentThreadRow(id: "spacer-after-header", kind: .spacer(AgentThreadMetrics.spacerAfterHeader)),
        AgentThreadRow(
            id: "yesterday",
            kind: .yesterday(
                AgentThreadYesterday(
                    title: "Yesterday",
                    date: "Oct 26",
                    amount: "$146.20",
                    summary: "Rent cleared. Stash set $40 aside.",
                    faces: [NormaTheme.threadFaceWarm, NormaTheme.threadFaceCool, NormaTheme.ink]
                ))
        ),
        AgentThreadRow(id: "spacer-after-yesterday", kind: .spacer(AgentThreadMetrics.spacerAfterYesterday)),
        AgentThreadRow(
            id: "today",
            kind: .day(AgentThreadDay(title: "Today", date: "Oct 27", total: "$84.00"))
        ),
        AgentThreadRow(
            id: "event-idle",
            kind: .event(AgentThreadEvent(title: "Grocery run", time: "8:40 AM", isActive: false))
        ),
        AgentThreadRow(
            id: "event-active",
            kind: .event(AgentThreadEvent(title: "Paycheck landed", time: "9:15 AM", isActive: true))
        ),
        AgentThreadRow(id: "spacer-after-today", kind: .spacer(AgentThreadMetrics.spacerAfterToday)),
        AgentThreadRow(
            id: "reply-stash",
            kind: .reply(
                AgentThreadReply(
                    name: "Stash",
                    message: "Set $40 aside from yesterday's rent.",
                    mark: .stash
                ))
        ),
        AgentThreadRow(
            id: "reply-ratio",
            kind: .reply(
                AgentThreadReply(
                    name: "Ratio",
                    message: "That leaves 12 days at this pace.",
                    mark: .ratio
                ))
        ),
        AgentThreadRow(
            id: "reply-norma",
            kind: .reply(
                AgentThreadReply(
                    name: "Norma",
                    message: "Grocery is still open. Paycheck landed, so today is covered.",
                    mark: .norma
                ))
        ),
        AgentThreadRow(id: "spacer-before-you", kind: .spacer(AgentThreadMetrics.spacerBeforeYou)),
        AgentThreadRow(
            id: "you",
            kind: .you(AgentThreadYou(label: "You", message: "Move another $20."))
        ),
    ])

    /// A reply long enough to wrap inside the list, used to lock growth.
    static let longReply = AgentThreadReply(
        name: "Norma",
        message: "Norma kept the grocery hold open after the paycheck landed, and this longer note wraps onto several lines so the row can grow with Dynamic Type instead of clipping.",
        mark: .norma
    )
}

struct AgentThreadRow: Identifiable, Equatable {
    let id: String
    let kind: AgentThreadRowKind

    var railMark: AgentThreadRailMark? {
        switch kind {
        case .reply(let reply): return reply.mark
        case .you: return .you
        case .header, .yesterday, .day, .event, .spacer: return nil
        }
    }

    var voiceOverLabel: String {
        switch kind {
        case .header(let header): return header.voiceOverLabel
        case .yesterday(let yesterday): return yesterday.voiceOverLabel
        case .day(let day): return day.voiceOverLabel
        case .event(let event): return event.voiceOverLabel
        case .reply(let reply): return reply.voiceOverLabel
        case .you(let you): return you.voiceOverLabel
        case .spacer: return ""
        }
    }
}

enum AgentThreadRowKind: Equatable {
    case header(AgentThreadHeader)
    case yesterday(AgentThreadYesterday)
    case day(AgentThreadDay)
    case event(AgentThreadEvent)
    case reply(AgentThreadReply)
    case you(AgentThreadYou)
    case spacer(CGFloat)
}

struct AgentThreadHeader: Equatable {
    var title: String
    var agentCount: Int

    var countText: String {
        let noun = agentCount == 1 ? "agent" : "agents"
        return "\u{00B7} \(agentCount) \(noun)"
    }

    var voiceOverLabel: String { "\(title), \(agentCount) agents" }
}

struct AgentThreadYesterday: Equatable {
    var title: String
    var date: String
    var amount: String
    var summary: String
    var faces: [NormaTheme.Swatch]

    var voiceOverLabel: String { "\(title), \(date), \(amount), \(summary)" }
}

struct AgentThreadDay: Equatable {
    var title: String
    var date: String
    var total: String

    var voiceOverLabel: String { "\(title), \(date), \(total)" }
}

struct AgentThreadEvent: Equatable {
    var title: String
    var time: String
    var isActive: Bool

    var voiceOverLabel: String { "\(title), \(time)" }
}

struct AgentThreadReply: Equatable {
    var name: String
    var message: String
    var mark: AgentThreadRailMark

    var voiceOverLabel: String { "\(name), \(message)" }
}

struct AgentThreadYou: Equatable {
    var label: String
    var message: String

    var voiceOverLabel: String { "\(label), \(message)" }
}

enum AgentThreadRailMark: Equatable {
    case stash
    case ratio
    case norma
    case you
}

struct AgentThreadEventStyle: Equatable {
    var title: NormaTheme.Swatch
    var time: NormaTheme.Swatch

    static func resolve(_ isActive: Bool) -> AgentThreadEventStyle {
        if isActive {
            return AgentThreadEventStyle(title: NormaTheme.ink, time: NormaTheme.coral)
        }
        return AgentThreadEventStyle(title: NormaTheme.threadSecondary, time: NormaTheme.threadMuted)
    }
}

struct AgentThreadRailStyle: Equatable {
    var fill: NormaTheme.Swatch
    var stroke: NormaTheme.Swatch
    var strokeWidth: CGFloat
    var radius: CGFloat

    var diameter: CGFloat { radius * 2 }
}

/// Board weight 600 is Instrument Sans SemiBold. The bundle ships Regular 400,
/// Medium 500, and Bold 700. Medium is the nearest face, so 600 renders as Medium.
struct AgentThreadText: Equatable {
    var name: String
    var postScriptName: String
    var size: CGFloat
    var lineHeight: CGFloat
    var weight: Int
    var color: NormaTheme.Swatch

    var font: Font { .custom(postScriptName, size: size, relativeTo: .body) }

    var extraLineSpacing: CGFloat {
        let fontLineHeight = UIFont(name: postScriptName, size: size)?.lineHeight ?? size
        return max(0, lineHeight - fontLineHeight)
    }

    func colored(_ color: NormaTheme.Swatch) -> AgentThreadText {
        var copy = self
        copy.color = color
        return copy
    }
}

// MARK: - Metrics

enum AgentThreadMetrics {
    static let threadWidth: CGFloat = 391
    static let threadHeight: CGFloat = 512
    static let paddingTop: CGFloat = 14
    static let paddingInline: CGFloat = 20
    /// 512 - 14 - 496. Keeps the list frame at the measured 351x496.
    static let paddingBottom: CGFloat = 2
    static let listWidth: CGFloat = 351
    static let listHeight: CGFloat = 496

    static let sheetRadius: CGFloat = 44
    static let strokeWidth: CGFloat = 1
    static let shadowOpacity: Double = 0.08
    static let shadowX: CGFloat = 0
    static let shadowY: CGFloat = 8
    static let shadowBlur: CGFloat = 28
    static let gradientMidLocation: CGFloat = 0.45

    static let gradientStart = NormaTheme.threadSheetStart
    static let gradientMid = NormaTheme.threadSheetMid
    static let gradientEnd = NormaTheme.threadSheetEnd
    static let stroke = NormaTheme.threadStroke
    static let shadowColor = NormaTheme.ink

    static var sheetShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: sheetRadius,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: sheetRadius,
            style: .continuous
        )
    }

    static let headerPaddingTop: CGFloat = 18
    static let headerPaddingHorizontal: CGFloat = 6
    static let headerPaddingBottom: CGFloat = 24
    static let headerGap: CGFloat = 8
    static let headerDotSize: CGFloat = 8
    static let headerDot = NormaTheme.ink

    static let chipRadius: CGFloat = 14
    static let chipPaddingVertical: CGFloat = 8
    static let chipPaddingHorizontal: CGFloat = 14
    static let chipGap: CGFloat = 6
    static let chipFill = NormaTheme.threadChip
    static let yesterdayHeight: CGFloat = 60
    static let yesterdayPaddingLeading: CGFloat = 22
    static let faceSize: CGFloat = 18
    static let faceOverlap: CGFloat = 6
    static let faceStrokeWidth: CGFloat = 1.5
    static let faceRing = NormaTheme.threadFaceRing

    static let dayHeight: CGFloat = 36
    static let dayPaddingLeading: CGFloat = 22
    static let eventHeight: CGFloat = 34
    static let eventPaddingLeading: CGFloat = 38
    static let titleDateGap: CGFloat = 8

    static let replyPaddingLeading: CGFloat = 54
    static let replyGap: CGFloat = 2
    static let namePaddingLeading: CGFloat = 11
    static let youHeight: CGFloat = 48
    static let youPaddingLeading: CGFloat = 38

    static let bubbleRadius: CGFloat = 16
    static let bubblePaddingVertical: CGFloat = 6
    static let bubblePaddingHorizontal: CGFloat = 11
    static var bubbleShape: RoundedRectangle { NormaTheme.shape(bubbleRadius) }
    static let agentBubbleFill = NormaTheme.threadAgentBubble
    static let youBubbleFill = NormaTheme.ink

    static let spacerAfterHeader: CGFloat = 10
    static let spacerAfterYesterday: CGFloat = 20
    static let spacerAfterToday: CGFloat = 12
    static let spacerBeforeYou: CGFloat = 16
    static let groupSpacers: [CGFloat] = [
        spacerAfterHeader,
        spacerAfterYesterday,
        spacerAfterToday,
        spacerBeforeYou,
    ]

    static let railWidth: CGFloat = 60
    static let railHeight: CGFloat = 496
    /// Sits in the header gap (pad 6 + 8pt dot, then the 8pt gap) so the stroke stays left of type that starts at 22.
    static let railLineX: CGFloat = 18
    static let railStrokeWidth: CGFloat = 1.25
    static let railLineCap: CGLineCap = .round
    static let railDash: [CGFloat] = [2, 4]
    static let openingSegmentDashed = true
    static let railColor = NormaTheme.threadRail
    static let chevron = ">"

    static let emphasisFace = "InstrumentSans-Medium"
    static let textFace = "InstrumentSans-Regular"
    static let numberFace = "CommitMono-Regular"

    static let everyone = AgentThreadText(
        name: "everyone", postScriptName: emphasisFace, size: 14, lineHeight: 18, weight: 600, color: NormaTheme.ink)
    static let agentCount = AgentThreadText(
        name: "agent count", postScriptName: numberFace, size: 11, lineHeight: 14, weight: 400, color: NormaTheme.threadMuted)
    static let yesterdayTitle = AgentThreadText(
        name: "yesterday", postScriptName: emphasisFace, size: 15, lineHeight: 20, weight: 600, color: NormaTheme.ink)
    static let date = AgentThreadText(
        name: "date", postScriptName: numberFace, size: 11, lineHeight: 14, weight: 400, color: NormaTheme.threadMuted)
    static let amount = AgentThreadText(
        name: "amount", postScriptName: numberFace, size: 12, lineHeight: 16, weight: 400, color: NormaTheme.ink)
    static let summary = AgentThreadText(
        name: "summary", postScriptName: textFace, size: 13, lineHeight: 18, weight: 400, color: NormaTheme.threadSecondary)
    static let chevronText = AgentThreadText(
        name: "chevron", postScriptName: numberFace, size: 12, lineHeight: 16, weight: 400, color: NormaTheme.threadMuted)
    static let dayTitle = AgentThreadText(
        name: "day title", postScriptName: emphasisFace, size: 16, lineHeight: 20, weight: 600, color: NormaTheme.ink)
    static let dayTotal = AgentThreadText(
        name: "day total", postScriptName: numberFace, size: 13, lineHeight: 16, weight: 400, color: NormaTheme.ink)
    static let eventTitle = AgentThreadText(
        name: "event title", postScriptName: textFace, size: 15, lineHeight: 20, weight: 400, color: NormaTheme.threadSecondary)
    static let eventTime = AgentThreadText(
        name: "event time", postScriptName: numberFace, size: 11, lineHeight: 14, weight: 400, color: NormaTheme.threadMuted)
    static let name = AgentThreadText(
        name: "name", postScriptName: numberFace, size: 11, lineHeight: 14, weight: 400, color: NormaTheme.threadMuted)
    static let agentBody = AgentThreadText(
        name: "agent body", postScriptName: textFace, size: 14, lineHeight: 20, weight: 400, color: NormaTheme.ink)
    static let youBody = AgentThreadText(
        name: "you body", postScriptName: textFace, size: 14, lineHeight: 20, weight: 400, color: NormaTheme.threadCream)

    static func railStyle(_ mark: AgentThreadRailMark) -> AgentThreadRailStyle {
        switch mark {
        case .stash:
            return AgentThreadRailStyle(fill: NormaTheme.threadStash, stroke: NormaTheme.threadCream, strokeWidth: 2, radius: 10)
        case .ratio:
            return AgentThreadRailStyle(fill: NormaTheme.threadFaceCool, stroke: NormaTheme.threadCream, strokeWidth: 2, radius: 10)
        case .norma:
            return AgentThreadRailStyle(fill: NormaTheme.ink, stroke: NormaTheme.threadMuted, strokeWidth: 1.5, radius: 10)
        case .you:
            return AgentThreadRailStyle(fill: NormaTheme.ink, stroke: NormaTheme.threadCream, strokeWidth: 2, radius: 4)
        }
    }

    static func segmentIsDashed(isOpening: Bool) -> Bool {
        isOpening && openingSegmentDashed
    }
}

// MARK: - Sheet

struct AgentThread: View {
    let model: AgentThreadModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            rows
        }
        .padding(.top, AgentThreadMetrics.paddingTop)
        .padding(.horizontal, AgentThreadMetrics.paddingInline)
        .padding(.bottom, AgentThreadMetrics.paddingBottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(sheetFill)
        .clipShape(AgentThreadMetrics.sheetShape)
        .overlay {
            AgentThreadMetrics.sheetShape.strokeBorder(
                AgentThreadMetrics.stroke.color,
                lineWidth: AgentThreadMetrics.strokeWidth
            )
        }
        .shadow(
            color: AgentThreadMetrics.shadowColor.color.opacity(AgentThreadMetrics.shadowOpacity),
            radius: AgentThreadMetrics.shadowBlur,
            x: AgentThreadMetrics.shadowX,
            y: AgentThreadMetrics.shadowY
        )
    }

    private var rows: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(model.rows) { row in
                AgentThreadRowView(row: row)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .backgroundPreferenceValue(AgentThreadRailAnchorKey.self) { anchors in
            GeometryReader { proxy in
                AgentThreadRail(
                    marks: anchors.map { item in
                        AgentThreadRailPlacement(id: item.id, y: proxy[item.anchor].midY, mark: item.mark)
                    },
                    height: proxy.size.height
                )
            }
        }
    }

    private var sheetFill: some View {
        LinearGradient(
            stops: [
                Gradient.Stop(color: AgentThreadMetrics.gradientStart.color, location: 0),
                Gradient.Stop(color: AgentThreadMetrics.gradientMid.color, location: AgentThreadMetrics.gradientMidLocation),
                Gradient.Stop(color: AgentThreadMetrics.gradientEnd.color, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Rows

private struct AgentThreadRowView: View {
    let row: AgentThreadRow

    var body: some View {
        if case .spacer(let height) = row.kind {
            Color.clear
                .frame(height: height)
                .accessibilityHidden(true)
        } else {
            rowContent
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(row.voiceOverLabel)
                .modifier(AgentThreadRailAnchorModifier(row: row))
        }
    }

    @ViewBuilder
    private var rowContent: some View {
        switch row.kind {
        case .header(let header):
            AgentThreadHeaderView(header: header)
        case .yesterday(let yesterday):
            AgentThreadYesterdayView(yesterday: yesterday)
        case .day(let day):
            AgentThreadDayView(day: day)
        case .event(let event):
            AgentThreadEventView(event: event)
        case .reply(let reply):
            AgentThreadReplyView(reply: reply)
        case .you(let you):
            AgentThreadYouView(you: you)
        case .spacer:
            EmptyView()
        }
    }
}

private struct AgentThreadHeaderView: View {
    let header: AgentThreadHeader

    var body: some View {
        HStack(spacing: AgentThreadMetrics.headerGap) {
            NormaTheme.shape(AgentThreadMetrics.headerDotSize / 2)
                .fill(AgentThreadMetrics.headerDot.color)
                .frame(width: AgentThreadMetrics.headerDotSize, height: AgentThreadMetrics.headerDotSize)
            Text(header.title)
                .thread(AgentThreadMetrics.everyone)
            Text(header.countText)
                .thread(AgentThreadMetrics.agentCount)
            Spacer(minLength: 0)
        }
        .padding(.top, AgentThreadMetrics.headerPaddingTop)
        .padding(.horizontal, AgentThreadMetrics.headerPaddingHorizontal)
        .padding(.bottom, AgentThreadMetrics.headerPaddingBottom)
    }
}

private struct AgentThreadYesterdayView: View {
    let yesterday: AgentThreadYesterday

    var body: some View {
        HStack(alignment: .center, spacing: AgentThreadMetrics.chipGap) {
            AgentThreadFaces(faces: yesterday.faces)
            VStack(alignment: .leading, spacing: AgentThreadMetrics.chipGap) {
                HStack(alignment: .firstTextBaseline, spacing: AgentThreadMetrics.titleDateGap) {
                    Text(yesterday.title)
                        .thread(AgentThreadMetrics.yesterdayTitle)
                    Text(yesterday.date)
                        .thread(AgentThreadMetrics.date)
                    Spacer(minLength: AgentThreadMetrics.titleDateGap)
                    Text(yesterday.amount)
                        .thread(AgentThreadMetrics.amount)
                }
                HStack(alignment: .firstTextBaseline, spacing: AgentThreadMetrics.chipGap) {
                    Text(yesterday.summary)
                        .thread(AgentThreadMetrics.summary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(AgentThreadMetrics.chevron)
                        .thread(AgentThreadMetrics.chevronText)
                }
            }
        }
        .padding(.horizontal, AgentThreadMetrics.chipPaddingHorizontal)
        .padding(.vertical, AgentThreadMetrics.chipPaddingVertical)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            NormaTheme.shape(AgentThreadMetrics.chipRadius)
                .fill(AgentThreadMetrics.chipFill.color)
        }
        .padding(.leading, AgentThreadMetrics.yesterdayPaddingLeading)
        .frame(minHeight: AgentThreadMetrics.yesterdayHeight, alignment: .center)
    }
}

private struct AgentThreadFaces: View {
    let faces: [NormaTheme.Swatch]

    var body: some View {
        let size = AgentThreadMetrics.faceSize
        let step = size - AgentThreadMetrics.faceOverlap
        let width = faces.isEmpty ? 0 : size + step * CGFloat(faces.count - 1)
        ZStack(alignment: .leading) {
            ForEach(Array(faces.enumerated()), id: \.offset) { index, face in
                NormaTheme.shape(size / 2)
                    .fill(face.color)
                    .overlay {
                        NormaTheme.shape(size / 2)
                            .strokeBorder(AgentThreadMetrics.faceRing.color, lineWidth: AgentThreadMetrics.faceStrokeWidth)
                    }
                    .frame(width: size, height: size)
                    .offset(x: step * CGFloat(index))
            }
        }
        .frame(width: width, height: size, alignment: .leading)
        .accessibilityHidden(true)
    }
}

private struct AgentThreadDayView: View {
    let day: AgentThreadDay

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AgentThreadMetrics.titleDateGap) {
            Text(day.title)
                .thread(AgentThreadMetrics.dayTitle)
            Text(day.date)
                .thread(AgentThreadMetrics.date)
            Spacer(minLength: AgentThreadMetrics.titleDateGap)
            Text(day.total)
                .thread(AgentThreadMetrics.dayTotal)
        }
        .padding(.leading, AgentThreadMetrics.dayPaddingLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: AgentThreadMetrics.dayHeight, alignment: .center)
    }
}

private struct AgentThreadEventView: View {
    let event: AgentThreadEvent

    var body: some View {
        let style = AgentThreadEventStyle.resolve(event.isActive)
        HStack(alignment: .firstTextBaseline, spacing: AgentThreadMetrics.titleDateGap) {
            Text(event.title)
                .thread(AgentThreadMetrics.eventTitle.colored(style.title))
            Spacer(minLength: AgentThreadMetrics.titleDateGap)
            Text(event.time)
                .thread(AgentThreadMetrics.eventTime.colored(style.time))
        }
        .padding(.leading, AgentThreadMetrics.eventPaddingLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: AgentThreadMetrics.eventHeight, alignment: .center)
    }
}

private struct AgentThreadReplyView: View {
    let reply: AgentThreadReply

    var body: some View {
        VStack(alignment: .leading, spacing: AgentThreadMetrics.replyGap) {
            Text(reply.name)
                .thread(AgentThreadMetrics.name)
                .padding(.leading, AgentThreadMetrics.namePaddingLeading)
            AgentThreadBubble(message: reply.message, fill: AgentThreadMetrics.agentBubbleFill, text: AgentThreadMetrics.agentBody)
        }
        .padding(.leading, AgentThreadMetrics.replyPaddingLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AgentThreadYouView: View {
    let you: AgentThreadYou

    var body: some View {
        VStack(alignment: .leading, spacing: AgentThreadMetrics.replyGap) {
            Text(you.label)
                .thread(AgentThreadMetrics.name)
            AgentThreadBubble(message: you.message, fill: AgentThreadMetrics.youBubbleFill, text: AgentThreadMetrics.youBody)
        }
        .padding(.leading, AgentThreadMetrics.youPaddingLeading)
        .frame(maxWidth: .infinity, minHeight: AgentThreadMetrics.youHeight, alignment: .leading)
    }
}

private struct AgentThreadBubble: View {
    let message: String
    let fill: NormaTheme.Swatch
    let text: AgentThreadText

    var body: some View {
        Text(message)
            .thread(text)
            .padding(.horizontal, AgentThreadMetrics.bubblePaddingHorizontal)
            .padding(.vertical, AgentThreadMetrics.bubblePaddingVertical)
            .background(fill.color, in: AgentThreadMetrics.bubbleShape)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension Text {
    private func thread(_ style: AgentThreadText) -> some View {
        font(style.font)
            .foregroundStyle(style.color.color)
            .lineSpacing(style.extraLineSpacing)
            .multilineTextAlignment(.leading)
            .frame(minHeight: style.lineHeight, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Rail

private struct AgentThreadRailAnchor {
    let id: String
    let mark: AgentThreadRailMark
    let anchor: Anchor<CGRect>
}

private struct AgentThreadRailAnchorKey: PreferenceKey {
    static var defaultValue: [AgentThreadRailAnchor] = []

    static func reduce(value: inout [AgentThreadRailAnchor], nextValue: () -> [AgentThreadRailAnchor]) {
        value.append(contentsOf: nextValue())
    }
}

private struct AgentThreadRailAnchorModifier: ViewModifier {
    let row: AgentThreadRow

    func body(content: Content) -> some View {
        if let mark = row.railMark {
            content.anchorPreference(key: AgentThreadRailAnchorKey.self, value: .bounds) { anchor in
                [AgentThreadRailAnchor(id: row.id, mark: mark, anchor: anchor)]
            }
        } else {
            content
        }
    }
}

private struct AgentThreadRailPlacement: Identifiable {
    let id: String
    let y: CGFloat
    let mark: AgentThreadRailMark
}

private struct AgentThreadRail: View {
    let marks: [AgentThreadRailPlacement]
    let height: CGFloat

    var body: some View {
        let sorted = marks.sorted { $0.y < $1.y }
        let openingEnd = sorted.first?.y ?? height
        ZStack(alignment: .topLeading) {
            segment(from: 0, to: openingEnd, isOpening: true)
            segment(from: openingEnd, to: height, isOpening: false)
            ForEach(sorted) { placement in
                AgentThreadRailMarkView(mark: placement.mark)
                    .position(x: AgentThreadMetrics.railLineX, y: placement.y)
            }
        }
        .frame(width: AgentThreadMetrics.railWidth, height: height, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func segment(from start: CGFloat, to end: CGFloat, isOpening: Bool) -> some View {
        AgentThreadRailLine(x: AgentThreadMetrics.railLineX, start: start, end: end)
            .stroke(
                AgentThreadMetrics.railColor.color,
                style: StrokeStyle(
                    lineWidth: AgentThreadMetrics.railStrokeWidth,
                    lineCap: AgentThreadMetrics.railLineCap,
                    dash: AgentThreadMetrics.segmentIsDashed(isOpening: isOpening) ? AgentThreadMetrics.railDash : []
                )
            )
            .frame(width: AgentThreadMetrics.railWidth, height: height, alignment: .topLeading)
    }
}

private struct AgentThreadRailLine: Shape {
    var x: CGFloat
    var start: CGFloat
    var end: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard end > start else { return path }
        path.move(to: CGPoint(x: x, y: start))
        path.addLine(to: CGPoint(x: x, y: end))
        return path
    }
}

private struct AgentThreadRailMarkView: View {
    let mark: AgentThreadRailMark

    var body: some View {
        let style = AgentThreadMetrics.railStyle(mark)
        NormaTheme.shape(style.radius)
            .fill(style.fill.color)
            .overlay {
                NormaTheme.shape(style.radius)
                    .strokeBorder(style.stroke.color, lineWidth: style.strokeWidth)
            }
            .frame(width: style.diameter, height: style.diameter)
    }
}

// AC-7
#Preview("Agent thread") {
    AgentThread(model: .board)
        .frame(width: AgentThreadMetrics.threadWidth, height: AgentThreadMetrics.threadHeight)
}
