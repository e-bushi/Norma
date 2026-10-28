//
//  AgentStoriesRow.swift
//  Norma
//
//  The agent stories row from the Agents board. Not wired into a screen.
//  Norma's face uses the existing norma-logo image. The mark is not redrawn.
//

import SwiftUI

struct AgentStory: Identifiable, Equatable {
    let name: String
    let face: NormaTheme.Swatch
    let isActive: Bool

    var id: String { name }

    /// The board's Norma entry is the one that carries the mark.
    var showsMark: Bool { name == "Norma" }

    var voiceOverLabel: String { isActive ? "\(name), active" : name }

    /// The five agents on the Agents board, in board order.
    static let board: [AgentStory] = [
        AgentStory(name: "Norma", face: NormaTheme.ink, isActive: true),
        AgentStory(name: "Stash", face: NormaTheme.stash, isActive: true),
        AgentStory(name: "Ratio", face: NormaTheme.ratio, isActive: true),
        AgentStory(name: "Bills", face: NormaTheme.bills, isActive: false),
        AgentStory(name: "Oakline", face: NormaTheme.oakline, isActive: false),
    ]
}

struct AgentStoryStyle: Equatable {
    let ring: NormaTheme.Swatch
    let ringWidth: CGFloat
    let ringPadding: CGFloat
    let label: NormaTheme.Swatch

    static func resolve(_ agent: AgentStory) -> AgentStoryStyle {
        if agent.isActive {
            return AgentStoryStyle(
                ring: AgentStoriesMetrics.activeRing,
                ringWidth: AgentStoriesMetrics.activeRingWidth,
                ringPadding: AgentStoriesMetrics.activeRingPadding,
                label: AgentStoriesMetrics.activeLabel
            )
        }
        return AgentStoryStyle(
            ring: AgentStoriesMetrics.idleRing,
            ringWidth: AgentStoriesMetrics.idleRingWidth,
            ringPadding: AgentStoriesMetrics.idleRingPadding,
            label: AgentStoriesMetrics.idleLabel
        )
    }
}

enum AgentStoriesMetrics {
    static let paddingTop: CGFloat = 14
    static let paddingBottom: CGFloat = 18
    static let paddingInline: CGFloat = 22
    static let columnGap: CGFloat = 14
    static let columnWidth: CGFloat = 62
    static let labelGap: CGFloat = 6
    static let labelLineHeight: CGFloat = 16
    static let labelStyle = NormaTheme.caption

    static let ringSize: CGFloat = 62
    static var ringRadius: CGFloat { ringSize / 2 }
    static let faceSize: CGFloat = 51
    static let faceRadius: CGFloat = 26
    static let activeRingWidth: CGFloat = 2.5
    static let idleRingWidth: CGFloat = 1.5
    static let activeRingPadding: CGFloat = 3
    static let idleRingPadding: CGFloat = 4

    static let markWidth: CGFloat = 30
    static let markHeight: CGFloat = 28
    /// Asset catalog name for the existing norma-logo image.
    static let markAssetName = "NormaMark"

    static let well = NormaTheme.storyWell
    static let activeRing = NormaTheme.coral
    static let idleRing = NormaTheme.idleRing
    static let activeLabel = NormaTheme.ink
    static let idleLabel = NormaTheme.slate

    static let scrollAxis: Axis.Set = .horizontal
}

struct AgentStoriesRow: View {
    let agents: [AgentStory]

    var body: some View {
        ScrollView(AgentStoriesMetrics.scrollAxis, showsIndicators: false) {
            HStack(spacing: AgentStoriesMetrics.columnGap) {
                ForEach(agents) { agent in
                    AgentStoryColumn(agent: agent)
                }
            }
            .padding(.top, AgentStoriesMetrics.paddingTop)
            .padding(.bottom, AgentStoriesMetrics.paddingBottom)
            .padding(.horizontal, AgentStoriesMetrics.paddingInline)
        }
    }
}

private struct AgentStoryColumn: View {
    let agent: AgentStory

    var body: some View {
        let style = AgentStoryStyle.resolve(agent)
        VStack(spacing: AgentStoriesMetrics.labelGap) {
            AgentStoryRing(agent: agent, style: style)
            Text(agent.name)
                .font(AgentStoriesMetrics.labelStyle.font)
                .foregroundStyle(style.label.color)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, minHeight: AgentStoriesMetrics.labelLineHeight)
        }
        .frame(width: AgentStoriesMetrics.columnWidth)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(agent.voiceOverLabel)
    }
}

private struct AgentStoryRing: View {
    let agent: AgentStory
    let style: AgentStoryStyle

    var body: some View {
        ZStack {
            NormaTheme.shape(AgentStoriesMetrics.ringRadius)
                .fill(AgentStoriesMetrics.well.color)
                .overlay {
                    NormaTheme.shape(AgentStoriesMetrics.ringRadius)
                        .strokeBorder(style.ring.color, lineWidth: style.ringWidth)
                }
            face
        }
        .frame(width: AgentStoriesMetrics.ringSize, height: AgentStoriesMetrics.ringSize)
    }

    private var face: some View {
        ZStack {
            NormaTheme.shape(AgentStoriesMetrics.faceRadius)
                .fill(agent.face.color)
            if agent.showsMark {
                // The logo is square. It sits in the 30x28 slot, centered, without stretching.
                Image(AgentStoriesMetrics.markAssetName)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: AgentStoriesMetrics.markWidth, height: AgentStoriesMetrics.markHeight)
            }
        }
        .frame(width: AgentStoriesMetrics.faceSize, height: AgentStoriesMetrics.faceSize)
        .clipShape(NormaTheme.shape(AgentStoriesMetrics.faceRadius))
    }
}

#Preview("Agent stories") {
    AgentStoriesRow(agents: AgentStory.board)
        .background(NormaTheme.silver.color)
}
