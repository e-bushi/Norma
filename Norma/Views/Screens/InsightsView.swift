//
//  InsightsView.swift
//  Norma
//
//  Created by Claude on 5/26/26.
//

import SwiftUI
import SwiftData
import UIKit

struct InsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Insight.createdAt, order: .reverse) private var insights: [Insight]

    // Two-phase empty experience: a wave-text intro interstitial that
    // crossfades into the resting "nothing yet" empty state. Plays whenever
    // the view opens with no insights yet; once insights exist, the list
    // takes over and this never runs. State resets each time the sheet is
    // re-presented (fresh view instance), mirroring the freedom-fund intro.
    private enum EmptyPhase { case intro, resting }
    @State private var emptyPhase: EmptyPhase = .intro
    @State private var introPhaseIndex = 0
    @State private var introDidFinish = false
    @State private var restingVisible = false

    /// What insights are, delivered one line at a time. Plain and factual —
    /// this is a quiet background feature, not a pitch.
    private let introPhases = [
        "norma reads your notes in the background.",
        "nothing to set up — it just runs.",
        "here's the kind of thing it'll catch."
    ]
    /// How long each line lingers after its wave-in before advancing.
    private let introHold: Double = 1.7

    private let wordHaptic = UIImpactFeedbackGenerator(style: .soft)
    private let advanceHaptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                NormaPalette.canvas.ignoresSafeArea()

                if insights.isEmpty {
                    emptyExperience
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            hero
                            insightsList
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Empty experience (intro interstitial → resting empty state)

    private var emptyExperience: some View {
        ZStack(alignment: .top) {
            if emptyPhase == .intro {
                insightsIntro
                    .transition(.opacity)
            } else {
                emptyResting
                    .transition(.opacity)
            }
        }
    }

    private var insightsIntro: some View {
        ZStack(alignment: .leading) {
            // Tap anywhere to skip forward.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { advanceIntro() }

            WaveTextView(
                text: introPhases[introPhaseIndex],
                font: .system(size: 56, weight: .bold),
                color: NormaPalette.ink,
                isAnimating: true,
                alignment: .leading,
                tracking: -1.5,
                wordSpacing: 12,
                lineSpacing: 0,
                onWordAppear: { _ in
                    wordHaptic.impactOccurred(intensity: 0.5)
                    wordHaptic.prepare()
                }
            )
            .id(introPhaseIndex)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onAppear {
            wordHaptic.prepare()
            advanceHaptic.prepare()
            scheduleIntroAdvance()
        }
    }

    private var emptyResting: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                hero
                emptyState
            }
            .opacity(restingVisible ? 1 : 0)
            .offset(y: restingVisible ? 0 : 10)
        }
    }

    private func scheduleIntroAdvance() {
        // Wave-in finishes ~ (0.5 + (n - 1) * 0.06)s, plus a hold, then advance.
        let wordCount = introPhases[introPhaseIndex].split(separator: " ").count
        let inDuration = 0.5 + Double(max(0, wordCount - 1)) * 0.06
        let totalShow = inDuration + introHold
        let snapshot = introPhaseIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + totalShow) {
            guard !introDidFinish, introPhaseIndex == snapshot, emptyPhase == .intro else { return }
            advanceIntro()
        }
    }

    private func advanceIntro() {
        guard !introDidFinish else { return }
        if introPhaseIndex < introPhases.count - 1 {
            withAnimation(.easeInOut(duration: 0.35)) { introPhaseIndex += 1 }
            scheduleIntroAdvance()
        } else {
            finishIntro()
        }
    }

    private func finishIntro() {
        guard !introDidFinish else { return }
        introDidFinish = true
        advanceHaptic.impactOccurred()
        withAnimation(.easeInOut(duration: 0.4)) { emptyPhase = .resting }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                restingVisible = true
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text("insights")
                .font(.system(size: 42, weight: .black))
                .foregroundStyle(NormaPalette.ink)
                .tracking(-1.2)
            Text(".")
                .font(.system(size: 42, weight: .black))
                .foregroundStyle(NormaPalette.lavender)
                .tracking(-1.2)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Empty state

    /// Illustrative insights shown before any real ones exist — one per type.
    /// Plain in-view mock content (never written to SwiftData); rendered dimmed
    /// and tagged "example" so they read as a preview, not real findings.
    private let exampleInsights: [(type: String, headline: String, detail: String)] = [
        ("pattern", "'rent' keeps coming up", "you've written about rent in several notes this month."),
        ("nudge", "the subscription you meant to cancel", "you mentioned it a few weeks ago and it hasn't come up since."),
        ("milestone", "three months of runway", "your freedom fund now covers three months of bills."),
        ("anomaly", "a bill looks higher than usual", "one of your recurring bills jumped this cycle.")
    ]

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("nothing yet")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(NormaPalette.ink)

                Text("as you keep writing, norma leaves notes here when something's worth pointing out. you don't have to do anything — here's the kind of thing you'll see:")
                    .font(.system(size: 14))
                    .foregroundStyle(NormaPalette.inkSubtle)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 0) {
                ForEach(exampleInsights, id: \.headline) { example in
                    exampleRow(type: example.type, headline: example.headline, detail: example.detail)
                }
            }
            .opacity(0.55)
        }
        .padding(.top, 12)
        .padding(.bottom, 32)
    }

    /// Mirrors `insightRow`'s layout, but shows "example" in place of a
    /// timestamp so the preview rows can't be mistaken for real insights.
    private func exampleRow(type: String, headline: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(type)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.44)
                    .foregroundStyle(NormaPalette.lavender)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                NormaPalette.lavender.opacity(0.4),
                                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                            )
                    )

                Text("example")
                    .font(.system(size: 11))
                    .italic()
                    .foregroundStyle(NormaPalette.inkMuted)
            }

            Text(headline)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(NormaPalette.ink)
                .lineSpacing(2)

            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(NormaPalette.inkSubtle)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(NormaPalette.inkMuted.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 24)
        }
    }

    // MARK: - Insights list

    private var insightsList: some View {
        let grouped = groupedInsights
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(grouped.keys.sorted(by: >)), id: \.self) { key in
                sectionHeader(for: key, count: grouped[key]?.count ?? 0)
                ForEach(grouped[key] ?? []) { insight in
                    insightRow(insight)
                }
            }
        }
    }

    private func sectionHeader(for key: String, count: Int) -> some View {
        HStack(spacing: 10) {
            Text(key)
                .font(.system(size: 11, weight: .medium))
                .tracking(0.88)
                .textCase(.uppercase)
                .foregroundStyle(NormaPalette.inkMuted)
                .fixedSize()

            Rectangle()
                .fill(NormaPalette.inkMuted.opacity(0.3))
                .frame(height: 1)

            if key == sectionKey(for: Date()) {
                Text("\(count) new")
                    .font(.system(size: 11))
                    .tracking(0.88)
                    .foregroundStyle(NormaPalette.inkMuted.opacity(0.6))
                    .fixedSize()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private func insightRow(_ insight: Insight) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(insight.type.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.44)
                    .foregroundStyle(NormaPalette.lavender)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                NormaPalette.lavender.opacity(0.4),
                                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                            )
                    )

                Text(insight.createdAt.insightTimestamp)
                    .font(.system(size: 11))
                    .foregroundStyle(NormaPalette.inkMuted)
            }

            Text(insight.headline)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(NormaPalette.ink)
                .lineSpacing(2)

            Text(insight.detail)
                .font(.system(size: 13))
                .foregroundStyle(NormaPalette.inkSubtle)
                .lineSpacing(2)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(NormaPalette.inkMuted.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 24)
        }
    }

    // MARK: - Grouping

    private var groupedInsights: [String: [Insight]] {
        Dictionary(grouping: insights) { sectionKey(for: $0.createdAt) }
    }

    private func sectionKey(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) || calendar.isDateInYesterday(date) ||
            calendar.dateComponents([.day], from: date, to: Date()).day ?? 8 < 7 {
            return "this week"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date).lowercased()
    }
}

// MARK: - Date formatting

private extension Date {
    var insightTimestamp: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "today" }
        if calendar.isDateInYesterday(self) { return "yesterday" }
        let days = calendar.dateComponents([.day], from: self, to: Date()).day ?? 0
        if days < 7 { return "\(days) days ago" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self).lowercased()
    }
}
