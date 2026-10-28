//
//  AgentThreadRail.swift
//  Norma
//
//  Measured rail from Agents board 1DPK-0. Coordinates are list points:
//  x is from the list's leading edge, y is from 10pt above the Yesterday card.
//

import SwiftUI

enum AgentThreadRailHop: Equatable {
    case straight
    case angleRight
    case angleLeft
}

enum AgentThreadBoardRail {
    static let dashX: CGFloat = 5
    static let dashStartY: CGFloat = 2
    static let dashEndY: CGFloat = 28
    static let dash: [CGFloat] = [2, 4]

    /// M5 28 V126 L21 138 V172 L37 184 V234 L21 250 V284 L37 296 V398 L21 414 V446
    static let solid: [CGPoint] = [
        CGPoint(x: 5, y: 28),
        CGPoint(x: 5, y: 126),
        CGPoint(x: 21, y: 138),
        CGPoint(x: 21, y: 172),
        CGPoint(x: 37, y: 184),
        CGPoint(x: 37, y: 234),
        CGPoint(x: 21, y: 250),
        CGPoint(x: 21, y: 284),
        CGPoint(x: 37, y: 296),
        CGPoint(x: 37, y: 398),
        CGPoint(x: 21, y: 414),
        CGPoint(x: 21, y: 446),
    ]

    static func hop(from start: CGPoint, to end: CGPoint) -> AgentThreadRailHop {
        let delta = end.x - start.x
        if abs(delta) < 0.5 {
            return .straight
        }
        return delta > 0 ? .angleRight : .angleLeft
    }

    static var hops: [AgentThreadRailHop] {
        zip(solid, solid.dropFirst()).map { hop(from: $0, to: $1) }
    }

    static func translated(originY: CGFloat) -> (dash: [CGPoint], solid: [CGPoint]) {
        let dash = [
            CGPoint(x: dashX, y: dashStartY + originY),
            CGPoint(x: dashX, y: dashEndY + originY),
        ]
        let solid = solid.map { CGPoint(x: $0.x, y: $0.y + originY) }
        return (dash, solid)
    }
}

struct AgentThreadRailMarkerAnchor: ViewModifier {
    let id: String
    let mark: AgentThreadRailMark

    func body(content: Content) -> some View {
        content.anchorPreference(key: AgentThreadRailAnchorKey.self, value: .bounds) { anchor in
            [AgentThreadRailAnchor(id: id, mark: mark, anchor: anchor)]
        }
    }
}

extension View {
    func agentThreadMarker(id: String, mark: AgentThreadRailMark) -> some View {
        modifier(AgentThreadRailMarkerAnchor(id: id, mark: mark))
    }
}

struct AgentThreadRailAnchor {
    let id: String
    let mark: AgentThreadRailMark
    let anchor: Anchor<CGRect>
}

struct AgentThreadRailAnchorKey: PreferenceKey {
    static var defaultValue: [AgentThreadRailAnchor] = []

    static func reduce(value: inout [AgentThreadRailAnchor], nextValue: () -> [AgentThreadRailAnchor]) {
        value.append(contentsOf: nextValue())
    }
}

struct AgentThreadRailOverlay: View {
    let anchors: [AgentThreadRailAnchor]

    var body: some View {
        GeometryReader { proxy in
            let placed = anchors.map { item in
                AgentThreadPlacedMarker(
                    id: item.id,
                    mark: item.mark,
                    y: proxy[item.anchor].midY
                )
            }
            ZStack(alignment: .topLeading) {
                AgentThreadMeasuredRail()
                ForEach(placed) { marker in
                    AgentThreadRailMarkView(mark: marker.mark)
                        .position(
                            x: AgentThreadMetrics.columnX(marker.mark),
                            y: marker.y
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }
    }
}

private struct AgentThreadPlacedMarker: Identifiable {
    let id: String
    let mark: AgentThreadRailMark
    let y: CGFloat
}

private struct AgentThreadMeasuredRail: View {
    var body: some View {
        let drawn = AgentThreadBoardRail.translated(originY: AgentThreadMetrics.railOriginY)
        ZStack(alignment: .topLeading) {
            AgentThreadPolyline(points: drawn.dash)
                .stroke(
                    AgentThreadMetrics.railColor.color,
                    style: StrokeStyle(
                        lineWidth: AgentThreadMetrics.railStrokeWidth,
                        lineCap: AgentThreadMetrics.railLineCap,
                        lineJoin: AgentThreadMetrics.railLineJoin,
                        dash: AgentThreadMetrics.segmentIsDashed(isOpening: true) ? AgentThreadBoardRail.dash : []
                    )
                )
            AgentThreadPolyline(points: drawn.solid)
                .stroke(
                    AgentThreadMetrics.railColor.color,
                    style: StrokeStyle(
                        lineWidth: AgentThreadMetrics.railStrokeWidth,
                        lineCap: AgentThreadMetrics.railLineCap,
                        lineJoin: AgentThreadMetrics.railLineJoin,
                        dash: AgentThreadMetrics.segmentIsDashed(isOpening: false) ? AgentThreadBoardRail.dash : []
                    )
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct AgentThreadPolyline: Shape {
    var points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }
}

struct AgentThreadRailMarkView: View {
    let mark: AgentThreadRailMark

    var body: some View {
        let style = AgentThreadMetrics.railStyle(mark)
        NormaTheme.shape(style.radius)
            .fill(style.fill.color)
            .overlay {
                if style.strokeWidth > 0 {
                    NormaTheme.shape(style.radius)
                        .strokeBorder(style.stroke.color, lineWidth: style.strokeWidth)
                }
            }
            .frame(width: style.diameter, height: style.diameter)
    }
}
