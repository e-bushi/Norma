//
//  ActivityTimelineModel.swift
//  Norma
//
//  Days, entries, pull states, and the measured layout for ActivityTimeline.
//  Colors stay in NormaTheme. The view reads these values and adds none of
//  its own.
//

import SwiftUI

/// Where the activity card sits, and how strong the header still is.
enum ActivityTimelinePullState: String, CaseIterable, Equatable, Identifiable {
    case home
    case pull1
    case pull2
    case pull3

    var id: String { rawValue }

    /// Distance from the top of the parent. `nil` keeps the card in flow.
    var absoluteTop: CGFloat? {
        switch self {
        case .home:
            return nil
        case .pull1:
            return 430
        case .pull2:
            return 150
        case .pull3:
            return 106
        }
    }

    /// Pull 1 is layer 5. Later pulls stay on that same layer.
    var zIndex: Double {
        switch self {
        case .home:
            return 0
        case .pull1, .pull2, .pull3:
            return 5
        }
    }

    /// Home grows to fill the parent. Pulled cards keep their own height.
    var grows: Bool {
        self == .home
    }

    /// Home is in flow with this padding above the card.
    var paddingTop: CGFloat {
        switch self {
        case .home:
            return 28
        case .pull1, .pull2, .pull3:
            return 0
        }
    }

    var headerBlur: CGFloat {
        switch self {
        case .home:
            return 0
        case .pull1:
            return 5
        case .pull2:
            return 16
        case .pull3:
            return 0
        }
    }

    var headerOpacity: Double {
        switch self {
        case .home:
            return 1
        case .pull1:
            return 0.75
        case .pull2:
            return 0.35
        case .pull3:
            return 0
        }
    }

    var hidesHeader: Bool {
        headerOpacity == 0
    }

    var placement: ActivityTimelinePlacement {
        if let top = absoluteTop {
            return .absolute(top: top, zIndex: zIndex)
        }
        return .flow(paddingTop: paddingTop, grows: grows)
    }

    /// Tall enough for a preview to show the card, its offset, and its shadow.
    var previewHeight: CGFloat {
        ActivityTimelineMetrics.cardHeight
            + (absoluteTop ?? paddingTop)
            + ActivityTimelineMetrics.shadowY
            + ActivityTimelineMetrics.shadowBlur
    }
}

enum ActivityTimelinePlacement: Equatable {
    case flow(paddingTop: CGFloat, grows: Bool)
    case absolute(top: CGFloat, zIndex: Double)
}

enum ActivityDayDot: String, Equatable, Hashable, CaseIterable {
    /// Filled ink. This is the current day.
    case today
    /// Warm day dot. Fill is `NormaTheme.paperDay`.
    case paper
    /// The other warm day dot. Fill is `NormaTheme.paperDayAlt`.
    case paperAlt
}

enum ActivityEntryKind: String, Equatable, Hashable, CaseIterable {
    case insightActive
    case insight
    case expenses
    case event
    case eventWithAmount
}

struct ActivityTimelineEntry: Equatable, Identifiable {
    var id: String
    var kind: ActivityEntryKind
    var title: String
    var meta: String
    var amount: String?
}

struct ActivityTimelineDay: Equatable, Identifiable {
    var id: String
    var title: String
    var date: String
    var total: String
    var dot: ActivityDayDot
    var entries: [ActivityTimelineEntry]
}

struct ActivityTimelineModel: Equatable {
    var summary: String
    var days: [ActivityTimelineDay]

    var rows: [ActivityTimelineRow] {
        days.flatMap { day in
            [ActivityTimelineRow.day(day)] + day.entries.map { ActivityTimelineRow.entry($0) }
        }
    }

    /// Three days that include every row type and both warm day dots.
    static let sample = ActivityTimelineModel(
        summary: "3 days · $271.55 spent",
        days: [
            ActivityTimelineDay(
                id: "today",
                title: "Today",
                date: "Oct 26",
                total: "$128.40",
                dot: .today,
                entries: [
                    ActivityTimelineEntry(
                        id: "dining",
                        kind: .insightActive,
                        title: "Dining is up",
                        meta: "vs last week",
                        amount: nil
                    ),
                    ActivityTimelineEntry(
                        id: "expenses",
                        kind: .expenses,
                        title: "Expenses",
                        meta: "3 charges",
                        amount: "$84.20"
                    ),
                    ActivityTimelineEntry(
                        id: "groceries",
                        kind: .eventWithAmount,
                        title: "Groceries",
                        meta: "Market",
                        amount: "$44.20"
                    ),
                ]
            ),
            ActivityTimelineDay(
                id: "yesterday",
                title: "Yesterday",
                date: "Oct 25",
                total: "$96.15",
                dot: .paper,
                entries: [
                    ActivityTimelineEntry(
                        id: "usual",
                        kind: .insight,
                        title: "Under the usual",
                        meta: "groceries",
                        amount: nil
                    ),
                    ActivityTimelineEntry(
                        id: "paycheck",
                        kind: .event,
                        title: "Paycheck landed",
                        meta: "Income",
                        amount: nil
                    ),
                ]
            ),
            ActivityTimelineDay(
                id: "friday",
                title: "Friday",
                date: "Oct 24",
                total: "$47.00",
                dot: .paperAlt,
                entries: [
                    ActivityTimelineEntry(
                        id: "transit",
                        kind: .eventWithAmount,
                        title: "Transit",
                        meta: "Clipper",
                        amount: "$47.00"
                    )
                ]
            ),
        ]
    )
}

enum ActivityTimelineRow: Equatable, Identifiable {
    case day(ActivityTimelineDay)
    case entry(ActivityTimelineEntry)

    var id: String {
        switch self {
        case .day(let day):
            return day.id
        case .entry(let entry):
            return entry.id
        }
    }

    var title: String {
        switch self {
        case .day(let day):
            return day.title
        case .entry(let entry):
            return entry.title
        }
    }

    var meta: String {
        switch self {
        case .day(let day):
            return day.date
        case .entry(let entry):
            return entry.meta
        }
    }

    var amount: String? {
        switch self {
        case .day(let day):
            return day.total
        case .entry(let entry):
            return entry.amount
        }
    }

    var accessibilityLabel: String {
        ActivityTimelineMetrics.accessibilityLabel(title: title, meta: meta, amount: amount)
    }
}

struct ActivityTextStyle: Equatable {
    var postScriptName: String
    var weight: Int
    var size: CGFloat
    var lineHeight: CGFloat
    var swatch: NormaTheme.Swatch
    var textStyle: Font.TextStyle

    var font: Font {
        .custom(postScriptName, size: size, relativeTo: textStyle)
    }

    var lineSpacing: CGFloat {
        max(lineHeight - size, 0)
    }
}

struct ActivityRowPresentation: Equatable {
    var height: CGFloat
    var paddingTop: CGFloat
    var paddingLeading: CGFloat
    var spaceBetween: Bool
    var title: ActivityTextStyle
    var meta: ActivityTextStyle
    var amount: ActivityTextStyle?
    var dot: ActivityDotStyle
}

struct ActivityDotStyle: Equatable {
    var radius: CGFloat
    var fill: NormaTheme.Swatch
    var stroke: NormaTheme.Swatch?
    var strokeWidth: CGFloat
}

struct ActivityGradientStop: Equatable {
    var swatch: NormaTheme.Swatch
    var location: CGFloat
}

struct ActivityRailDot: Equatable {
    var centerY: CGFloat
    var radius: CGFloat
    var fill: NormaTheme.Swatch
    var stroke: NormaTheme.Swatch?
    var strokeWidth: CGFloat

    var diameter: CGFloat { radius * 2 }
}

struct ActivityRailLayout: Equatable {
    var height: CGFloat
    var contentHeight: CGFloat
    var centerX: CGFloat
    var lineWidth: CGFloat
    var dash: [CGFloat]
    var roundCaps: Bool
    var stroke: NormaTheme.Swatch
    var drawsSolidLine: Bool
    var solidFromY: CGFloat
    var solidToY: CGFloat
    var drawsDashedTail: Bool
    var dashedFromY: CGFloat
    var dashedToY: CGFloat
    var dots: [ActivityRailDot]
}

/// Measured sizes for the activity card. The view file reads these and has no literals.
enum ActivityTimelineMetrics {
    /// Spec weight 600. The bundle ships Regular 400, Medium 500, and Bold 700.
    /// Medium is the face used wherever the spec says Instrument Sans 600.
    static let semiboldFace = "InstrumentSans-Medium"
    static let regularFace = "InstrumentSans-Regular"
    static let monoFace = "CommitMono-Regular"
    static let semiboldWeight = 600
    static let regularWeight = 400

    static let cardHeight: CGFloat = 780
    static let paddingTop: CGFloat = 32
    static let paddingBottom: CGFloat = 140
    static let paddingInline: CGFloat = 24
    static let cardGap: CGFloat = 24
    static let cardTopRadius: CGFloat = 56
    static let cardBottomRadius: CGFloat = 0
    static let cardStrokeWidth: CGFloat = 1
    static let shadowOpacity: Double = 0.08
    static let shadowX: CGFloat = 0
    static let shadowY: CGFloat = 8
    static let shadowBlur: CGFloat = 28

    static let columnWidth: CGFloat = 343
    static let columnGap: CGFloat = 18
    static let listWidth: CGFloat = 343
    static let listHeight: CGFloat = 528
    static let rowSpacerHeight: CGFloat = 12
    static let baselineGap: CGFloat = 8

    static let dayHeight: CGFloat = 36
    static let dayPaddingTop: CGFloat = 0
    static let dayPaddingLeading: CGFloat = 22
    static let entryHeight: CGFloat = 44
    static let entryPaddingTop: CGFloat = 4
    static let entryPaddingLeading: CGFloat = 38

    static let railWidth: CGFloat = 30
    static let railLineWidth: CGFloat = 1.25
    static let railDash: [CGFloat] = [2, 4]
    static let dayDotRadius: CGFloat = 4
    static let entryDotRadius: CGFloat = 3
    static let activeDotRadius: CGFloat = 5
    static let dayDotStrokeWidth: CGFloat = 1.5
    static let activeDotStrokeWidth: CGFloat = 2.5

    static var railCenterX: CGFloat { railWidth / 2 }

    static let cardFill = NormaTheme.paper
    static let cardStroke = NormaTheme.paperStroke

    static let gradientStops: [ActivityGradientStop] = [
        ActivityGradientStop(swatch: NormaTheme.paperHighlight, location: 0),
        ActivityGradientStop(swatch: NormaTheme.paperMid, location: 0.35),
        ActivityGradientStop(swatch: NormaTheme.paperShade, location: 1),
    ]

    static var cardShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: cardTopRadius,
            bottomLeadingRadius: cardBottomRadius,
            bottomTrailingRadius: cardBottomRadius,
            topTrailingRadius: cardTopRadius,
            style: .continuous
        )
    }

    static var cardGradient: LinearGradient {
        LinearGradient(
            stops: gradientStops.map { stop in
                Gradient.Stop(color: stop.swatch.color, location: stop.location)
            },
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var shadowColor: Color {
        NormaTheme.ink.color.opacity(shadowOpacity)
    }

    static let headerTitleText = "Activity"

    static let headerTitle = ActivityTextStyle(
        postScriptName: semiboldFace,
        weight: semiboldWeight,
        size: 15,
        lineHeight: 20,
        swatch: NormaTheme.ink,
        textStyle: .subheadline
    )

    static let headerSummary = ActivityTextStyle(
        postScriptName: monoFace,
        weight: regularWeight,
        size: 11,
        lineHeight: 14,
        swatch: NormaTheme.mist,
        textStyle: .caption2
    )

    static let dayTitle = ActivityTextStyle(
        postScriptName: semiboldFace,
        weight: semiboldWeight,
        size: 16,
        lineHeight: 20,
        swatch: NormaTheme.ink,
        textStyle: .callout
    )

    static let dayDate = ActivityTextStyle(
        postScriptName: monoFace,
        weight: regularWeight,
        size: 11,
        lineHeight: 14,
        swatch: NormaTheme.mist,
        textStyle: .caption2
    )

    static let dayTotal = ActivityTextStyle(
        postScriptName: monoFace,
        weight: regularWeight,
        size: 13,
        lineHeight: 16,
        swatch: NormaTheme.ink,
        textStyle: .footnote
    )

    static let insightActiveTitle = ActivityTextStyle(
        postScriptName: regularFace,
        weight: regularWeight,
        size: 15,
        lineHeight: 20,
        swatch: NormaTheme.ink,
        textStyle: .subheadline
    )

    static let insightActiveMeta = ActivityTextStyle(
        postScriptName: monoFace,
        weight: regularWeight,
        size: 11,
        lineHeight: 14,
        swatch: NormaTheme.coral,
        textStyle: .caption2
    )

    static let insightTitle = ActivityTextStyle(
        postScriptName: regularFace,
        weight: regularWeight,
        size: 15,
        lineHeight: 20,
        swatch: NormaTheme.graphite,
        textStyle: .subheadline
    )

    static let insightMeta = ActivityTextStyle(
        postScriptName: monoFace,
        weight: regularWeight,
        size: 11,
        lineHeight: 14,
        swatch: NormaTheme.mist,
        textStyle: .caption2
    )

    static let eventAmount = ActivityTextStyle(
        postScriptName: monoFace,
        weight: regularWeight,
        size: 12,
        lineHeight: 20,
        swatch: NormaTheme.coral,
        textStyle: .caption
    )

    static let entryDot = ActivityDotStyle(
        radius: entryDotRadius,
        fill: NormaTheme.paperDot,
        stroke: nil,
        strokeWidth: 0
    )

    static let activeDot = ActivityDotStyle(
        radius: activeDotRadius,
        fill: NormaTheme.coral,
        stroke: NormaTheme.paperRing,
        strokeWidth: activeDotStrokeWidth
    )

    static func dayDotStyle(_ dot: ActivityDayDot) -> ActivityDotStyle {
        switch dot {
        case .today:
            return ActivityDotStyle(radius: dayDotRadius, fill: NormaTheme.ink, stroke: nil, strokeWidth: 0)
        case .paper:
            return ActivityDotStyle(
                radius: dayDotRadius,
                fill: NormaTheme.paperDay,
                stroke: NormaTheme.mist,
                strokeWidth: dayDotStrokeWidth
            )
        case .paperAlt:
            return ActivityDotStyle(
                radius: dayDotRadius,
                fill: NormaTheme.paperDayAlt,
                stroke: NormaTheme.mist,
                strokeWidth: dayDotStrokeWidth
            )
        }
    }

    static func presentation(for row: ActivityTimelineRow) -> ActivityRowPresentation {
        switch row {
        case .day(let day):
            return ActivityRowPresentation(
                height: dayHeight,
                paddingTop: dayPaddingTop,
                paddingLeading: dayPaddingLeading,
                spaceBetween: true,
                title: dayTitle,
                meta: dayDate,
                amount: dayTotal,
                dot: dayDotStyle(day.dot)
            )
        case .entry(let entry):
            return entryPresentation(entry.kind)
        }
    }

    static func railLayout(for rows: [ActivityTimelineRow]) -> ActivityRailLayout {
        var y: CGFloat = 0
        var dots: [ActivityRailDot] = []
        for (index, row) in rows.enumerated() {
            let rowPresentation = presentation(for: row)
            let centerY = y + rowPresentation.height / 2
            let dot = rowPresentation.dot
            dots.append(
                ActivityRailDot(
                    centerY: centerY,
                    radius: dot.radius,
                    fill: dot.fill,
                    stroke: dot.stroke,
                    strokeWidth: dot.strokeWidth
                )
            )
            y += rowPresentation.height
            if index < rows.count - 1 {
                y += rowSpacerHeight
            }
        }
        let contentHeight = y
        let height = max(contentHeight, listHeight)
        let solidToY = dots.last?.centerY ?? 0
        let drawsSolidLine = !dots.isEmpty
        let dashedFromY = drawsSolidLine ? solidToY : 0
        return ActivityRailLayout(
            height: height,
            contentHeight: contentHeight,
            centerX: railCenterX,
            lineWidth: railLineWidth,
            dash: railDash,
            roundCaps: true,
            stroke: NormaTheme.paperRail,
            drawsSolidLine: drawsSolidLine,
            solidFromY: 0,
            solidToY: solidToY,
            drawsDashedTail: height > dashedFromY,
            dashedFromY: dashedFromY,
            dashedToY: height,
            dots: dots
        )
    }

    /// Title and meta stay together unless a space-between row has no amount to trail.
    static func showsMetaBesideTitle(spaceBetween: Bool, hasAmount: Bool) -> Bool {
        !spaceBetween || hasAmount
    }

    /// VoiceOver order for one row: title, then meta, then amount.
    static func accessibilityLabel(title: String, meta: String, amount: String?) -> String {
        var parts: [String] = []
        if !title.isEmpty {
            parts.append(title)
        }
        if !meta.isEmpty {
            parts.append(meta)
        }
        if let amount, !amount.isEmpty {
            parts.append(amount)
        }
        return parts.joined(separator: ", ")
    }

    private static func entryPresentation(_ kind: ActivityEntryKind) -> ActivityRowPresentation {
        switch kind {
        case .insightActive:
            return entryFrame(
                spaceBetween: false,
                title: insightActiveTitle,
                meta: insightActiveMeta,
                amount: nil,
                dot: activeDot
            )
        case .insight:
            return entryFrame(
                spaceBetween: false,
                title: insightTitle,
                meta: insightMeta,
                amount: nil,
                dot: entryDot
            )
        case .expenses:
            // Same colors as a quiet insight. The trailing total uses the day-total face.
            return entryFrame(
                spaceBetween: true,
                title: insightTitle,
                meta: insightMeta,
                amount: dayTotal,
                dot: entryDot
            )
        case .event:
            return entryFrame(
                spaceBetween: false,
                title: insightTitle,
                meta: insightMeta,
                amount: nil,
                dot: entryDot
            )
        case .eventWithAmount:
            return entryFrame(
                spaceBetween: true,
                title: insightTitle,
                meta: insightMeta,
                amount: eventAmount,
                dot: entryDot
            )
        }
    }

    private static func entryFrame(
        spaceBetween: Bool,
        title: ActivityTextStyle,
        meta: ActivityTextStyle,
        amount: ActivityTextStyle?,
        dot: ActivityDotStyle
    ) -> ActivityRowPresentation {
        ActivityRowPresentation(
            height: entryHeight,
            paddingTop: entryPaddingTop,
            paddingLeading: entryPaddingLeading,
            spaceBetween: spaceBetween,
            title: title,
            meta: meta,
            amount: amount,
            dot: dot
        )
    }
}
