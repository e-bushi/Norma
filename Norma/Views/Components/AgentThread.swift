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

    /// Board order: header, yesterday, today, then each reply under the event it answers.
    static let board = AgentThreadModel(rows: [
        AgentThreadRow(id: "header", kind: .header(AgentThreadHeader(title: "Everyone", agentCount: 5))),
        AgentThreadRow(
            id: "yesterday",
            kind: .yesterday(
                AgentThreadYesterday(
                    title: "Yesterday",
                    date: "Tue, Oct 20",
                    amount: "-$124.15",
                    summary: "Phone bill paid · 3 messages",
                    faces: [NormaTheme.threadFaceWarm, NormaTheme.threadFaceCool, NormaTheme.ink]
                ))
        ),
        AgentThreadRow(
            id: "today",
            kind: .day(AgentThreadDay(title: "Today", date: "Wed, Oct 21", total: "-$86.40"))
        ),
        AgentThreadRow(
            id: "event-stash",
            kind: .event(AgentThreadEvent(title: "Stash moved $42.10 to savings", time: "9:12 AM", isActive: false))
        ),
        AgentThreadRow(
            id: "reply-stash",
            kind: .reply(AgentThreadReply(name: "Stash", message: "Round-ups from this week.", mark: .stash))
        ),
        AgentThreadRow(
            id: "event-food",
            kind: .event(AgentThreadEvent(title: "Food spend is down 30%.", time: "9:40 AM", isActive: true))
        ),
        AgentThreadRow(
            id: "reply-ratio",
            kind: .reply(AgentThreadReply(name: "Ratio", message: "Mostly fewer delivery nights.", mark: .ratio))
        ),
        AgentThreadRow(
            id: "reply-norma",
            kind: .reply(AgentThreadReply(name: "Norma", message: "That covers your phone bill.", mark: .norma))
        ),
        AgentThreadRow(
            id: "you",
            kind: .you(AgentThreadYou(label: "You · 9:52 AM", message: "Can I do a $90 dinner Friday?"))
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
        case .yesterday: return .yesterdayRing
        case .day: return .todayDot
        case .event(let event): return event.isActive ? .eventActive : .eventIdle
        case .reply(let reply): return reply.mark
        case .you: return .you
        case .header: return nil
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
    case yesterdayRing
    case todayDot
    case eventIdle
    case eventActive
    case stash
    case ratio
    case norma
    case you
}

struct AgentThreadEventStyle: Equatable {
    var title: NormaTheme.Swatch
    var time: NormaTheme.Swatch

    /// Active time is ink. Coral stays on the rail dot (APP-103).
    static func resolve(_ isActive: Bool) -> AgentThreadEventStyle {
        if isActive {
            return AgentThreadEventStyle(title: NormaTheme.ink, time: NormaTheme.ink)
        }
        return AgentThreadEventStyle(title: NormaTheme.threadSecondary, time: NormaTheme.threadMuted)
    }
}

struct AgentThreadRailStyle: Equatable {
    var fill: NormaTheme.Swatch
    var stroke: NormaTheme.Swatch
    var strokeWidth: CGFloat
    var diameter: CGFloat

    var radius: CGFloat { diameter / 2 }
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

    static var headerBlockHeight: CGFloat {
        headerPaddingTop + everyone.lineHeight + headerPaddingBottom
    }

    static let chipRadius: CGFloat = 14
    static let chipPaddingVertical: CGFloat = 8
    static let chipPaddingHorizontal: CGFloat = 14
    static let chipGap: CGFloat = 6
    static let chipFill = NormaTheme.threadChip
    static let yesterdayLineGap: CGFloat = 8
    static let yesterdayLine2Height: CGFloat = 18
    static let yesterdayPaddingLeading: CGFloat = 22
    static let faceSize: CGFloat = 18
    /// Centers of the stacked faces, 12pt apart.
    static let faceCenterSpacing: CGFloat = 12
    static let faceStrokeWidth: CGFloat = 1.5
    static let faceRing = NormaTheme.threadFaceRing
    static let yesterdayFacesOnSecondLine = true

    static let dayHeight: CGFloat = 36
    static let dayPaddingLeading: CGFloat = 22
    static let eventPaddingLeading: CGFloat = 38
    static let titleDateGap: CGFloat = 8
    static let eventTimeBelowTitle = true
    static let eventTimeGap: CGFloat = 0

    static let replyPaddingLeading: CGFloat = 54
    static let replyGap: CGFloat = 2
    static let namePaddingLeading: CGFloat = 11
    static let youPaddingLeading: CGFloat = 38

    static let bubbleRadius: CGFloat = 16
    static let bubblePaddingVertical: CGFloat = 6
    static let bubblePaddingHorizontal: CGFloat = 11
    static var bubbleShape: RoundedRectangle { NormaTheme.shape(bubbleRadius) }
    static let agentBubbleFill = NormaTheme.threadAgentBubble
    static let youBubbleFill = NormaTheme.ink

    static let gapAfterYesterday: CGFloat = 18
    static let gapBeforeFirstEvent: CGFloat = 12
    static let gapTimeToSender: CGFloat = 12
    static let gapBubbleToEvent: CGFloat = 18
    static let gapBubbleToSender: CGFloat = 4

    static func rowGap(from previous: AgentThreadRowKind, to next: AgentThreadRowKind) -> CGFloat {
        switch (previous, next) {
        case (.yesterday(_), .day(_)):
            return gapAfterYesterday
        case (.day(_), .event(_)):
            return gapBeforeFirstEvent
        case (.event(_), .reply(_)):
            return gapTimeToSender
        case (.reply(_), .reply(_)):
            return gapBubbleToSender
        case (.reply(_), .event(_)), (.reply(_), .you(_)):
            return gapBubbleToEvent
        default:
            return 0
        }
    }

    /// Day, event, and reply columns, measured from the list's leading edge.
    static let dayColumnX: CGFloat = 5
    static let eventColumnX: CGFloat = 21
    static let replyColumnX: CGFloat = 37

    static func columnX(_ mark: AgentThreadRailMark) -> CGFloat {
        switch mark {
        case .yesterdayRing, .todayDot: return dayColumnX
        case .eventIdle, .eventActive, .you: return eventColumnX
        case .stash, .ratio, .norma: return replyColumnX
        }
    }

    /// Measured rail y=0 is 10pt above the Yesterday card, which starts when the header ends.
    static var railOriginY: CGFloat {
        headerBlockHeight + yesterdayTitleCenterInCard - AgentThreadBoardRail.dashEndY
    }

    static var yesterdayTitleCenterInCard: CGFloat {
        chipPaddingVertical + yesterdayTitle.lineHeight / 2
    }

    static let railWidth: CGFloat = 60
    static let railHeight: CGFloat = 496
    static let railStrokeWidth: CGFloat = 1.25
    static let railLineCap: CGLineCap = .round
    static let railLineJoin: CGLineJoin = .round
    static let openingSegmentDashed = true
    static let railColor = NormaTheme.threadRail

    static let chevronSymbol = "chevron.right"
    static let chevronSize: CGFloat = 12
    static let chevronGapAfterSummary: CGFloat = 8
    static let chevronColor = NormaTheme.threadMuted

    static let yesterdayRingDiameter: CGFloat = 8
    static let yesterdayRingStroke: CGFloat = 1.5
    static let todayDotDiameter: CGFloat = 8
    static let idleDotDiameter: CGFloat = 6
    static let activeDotDiameter: CGFloat = 10
    static let activeDotStroke: CGFloat = 2.5
    static let replyDotDiameter: CGFloat = 20
    static let replyDotStroke: CGFloat = 2
    static let normaDotStroke: CGFloat = 1.5
    static let youDotDiameter: CGFloat = 8
    static let youDotStroke: CGFloat = 2

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
        case .yesterdayRing:
            return AgentThreadRailStyle(
                fill: NormaTheme.threadRingFill,
                stroke: NormaTheme.threadMuted,
                strokeWidth: yesterdayRingStroke,
                diameter: yesterdayRingDiameter
            )
        case .todayDot:
            return AgentThreadRailStyle(
                fill: NormaTheme.ink,
                stroke: NormaTheme.ink,
                strokeWidth: 0,
                diameter: todayDotDiameter
            )
        case .eventIdle:
            return AgentThreadRailStyle(
                fill: NormaTheme.threadIdleDot,
                stroke: NormaTheme.threadIdleDot,
                strokeWidth: 0,
                diameter: idleDotDiameter
            )
        case .eventActive:
            return AgentThreadRailStyle(
                fill: NormaTheme.coral,
                stroke: NormaTheme.threadCream,
                strokeWidth: activeDotStroke,
                diameter: activeDotDiameter
            )
        case .stash:
            return AgentThreadRailStyle(
                fill: NormaTheme.threadStash,
                stroke: NormaTheme.threadCream,
                strokeWidth: replyDotStroke,
                diameter: replyDotDiameter
            )
        case .ratio:
            return AgentThreadRailStyle(
                fill: NormaTheme.threadFaceCool,
                stroke: NormaTheme.threadCream,
                strokeWidth: replyDotStroke,
                diameter: replyDotDiameter
            )
        case .norma:
            return AgentThreadRailStyle(
                fill: NormaTheme.ink,
                stroke: NormaTheme.threadMuted,
                strokeWidth: normaDotStroke,
                diameter: replyDotDiameter
            )
        case .you:
            return AgentThreadRailStyle(
                fill: NormaTheme.ink,
                stroke: NormaTheme.threadCream,
                strokeWidth: youDotStroke,
                diameter: youDotDiameter
            )
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
            ForEach(Array(model.rows.enumerated()), id: \.element.id) { index, row in
                AgentThreadRowView(row: row)
                    .padding(.top, topGap(at: index))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .backgroundPreferenceValue(AgentThreadRailAnchorKey.self) { anchors in
            AgentThreadRailOverlay(anchors: anchors)
        }
    }

    private func topGap(at index: Int) -> CGFloat {
        guard index > 0 else { return 0 }
        return AgentThreadMetrics.rowGap(from: model.rows[index - 1].kind, to: model.rows[index].kind)
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
        rowContent
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(row.voiceOverLabel)
    }

    @ViewBuilder
    private var rowContent: some View {
        switch row.kind {
        case .header(let header):
            AgentThreadHeaderView(header: header)
        case .yesterday(let yesterday):
            AgentThreadYesterdayView(id: row.id, yesterday: yesterday)
        case .day(let day):
            AgentThreadDayView(id: row.id, day: day)
        case .event(let event):
            AgentThreadEventView(id: row.id, event: event)
        case .reply(let reply):
            AgentThreadReplyView(id: row.id, reply: reply)
        case .you(let you):
            AgentThreadYouView(id: row.id, you: you)
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
    let id: String
    let yesterday: AgentThreadYesterday

    var body: some View {
        VStack(alignment: .leading, spacing: AgentThreadMetrics.yesterdayLineGap) {
            HStack(alignment: .firstTextBaseline, spacing: AgentThreadMetrics.titleDateGap) {
                Text(yesterday.title)
                    .thread(AgentThreadMetrics.yesterdayTitle)
                Text(yesterday.date)
                    .thread(AgentThreadMetrics.date)
                Spacer(minLength: AgentThreadMetrics.titleDateGap)
                Text(yesterday.amount)
                    .thread(AgentThreadMetrics.amount)
            }
            .agentThreadMarker(id: id, mark: .yesterdayRing)
            HStack(alignment: .center, spacing: AgentThreadMetrics.chipGap) {
                AgentThreadFaces(faces: yesterday.faces)
                Text(yesterday.summary)
                    .thread(AgentThreadMetrics.summary)
                Spacer(minLength: AgentThreadMetrics.chevronGapAfterSummary)
                Image(systemName: AgentThreadMetrics.chevronSymbol)
                    .font(.system(size: AgentThreadMetrics.chevronSize, weight: .semibold))
                    .foregroundStyle(AgentThreadMetrics.chevronColor.color)
            }
            .frame(minHeight: AgentThreadMetrics.yesterdayLine2Height, alignment: .center)
        }
        .padding(.horizontal, AgentThreadMetrics.chipPaddingHorizontal)
        .padding(.vertical, AgentThreadMetrics.chipPaddingVertical)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            NormaTheme.shape(AgentThreadMetrics.chipRadius)
                .fill(AgentThreadMetrics.chipFill.color)
        }
        .padding(.leading, AgentThreadMetrics.yesterdayPaddingLeading)
    }
}

private struct AgentThreadFaces: View {
    let faces: [NormaTheme.Swatch]

    var body: some View {
        let size = AgentThreadMetrics.faceSize
        let step = AgentThreadMetrics.faceCenterSpacing
        let width = faces.isEmpty ? 0 : size + step * CGFloat(max(faces.count - 1, 0))
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
    let id: String
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
        .frame(maxWidth: .infinity, minHeight: AgentThreadMetrics.dayHeight, alignment: .center)
        .agentThreadMarker(id: id, mark: .todayDot)
    }
}

private struct AgentThreadEventView: View {
    let id: String
    let event: AgentThreadEvent

    var body: some View {
        let style = AgentThreadEventStyle.resolve(event.isActive)
        VStack(alignment: .leading, spacing: AgentThreadMetrics.eventTimeGap) {
            Text(event.title)
                .thread(AgentThreadMetrics.eventTitle.colored(style.title))
                .agentThreadMarker(id: id, mark: event.isActive ? .eventActive : .eventIdle)
            Text(event.time)
                .thread(AgentThreadMetrics.eventTime.colored(style.time))
        }
        .padding(.leading, AgentThreadMetrics.eventPaddingLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AgentThreadReplyView: View {
    let id: String
    let reply: AgentThreadReply

    var body: some View {
        VStack(alignment: .leading, spacing: AgentThreadMetrics.replyGap) {
            Text(reply.name)
                .thread(AgentThreadMetrics.name)
                .padding(.leading, AgentThreadMetrics.namePaddingLeading)
            AgentThreadBubble(message: reply.message, fill: AgentThreadMetrics.agentBubbleFill, text: AgentThreadMetrics.agentBody)
                .agentThreadMarker(id: id, mark: reply.mark)
        }
        .padding(.leading, AgentThreadMetrics.replyPaddingLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AgentThreadYouView: View {
    let id: String
    let you: AgentThreadYou

    var body: some View {
        VStack(alignment: .leading, spacing: AgentThreadMetrics.replyGap) {
            Text(you.label)
                .thread(AgentThreadMetrics.name)
            AgentThreadBubble(message: you.message, fill: AgentThreadMetrics.youBubbleFill, text: AgentThreadMetrics.youBody)
                .agentThreadMarker(id: id, mark: .you)
        }
        .padding(.leading, AgentThreadMetrics.youPaddingLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
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

// AC-7 AC-20
#Preview("Agent thread") {
    HStack(alignment: .top, spacing: NormaTheme.spacing16) {
        Image("AgentsBoard")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: AgentThreadMetrics.threadWidth)
            .accessibilityHidden(true)
        AgentThread(model: .board)
            .frame(width: AgentThreadMetrics.threadWidth, height: AgentThreadMetrics.threadHeight)
    }
    .padding(NormaTheme.spacing16)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(NormaTheme.ink.color)
}
