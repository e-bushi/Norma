//
//  InsightsView.swift
//  Norma
//
//  Created by Claude on 5/26/26.
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Insight.createdAt, order: .reverse) private var insights: [Insight]
    @State private var showInfo = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                NormaPalette.canvas.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        hero
                        if insights.isEmpty {
                            emptyState
                        } else {
                            insightsList
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(NormaPalette.inkSubtle)
                    }
                }
            }
            .alert("how insights work", isPresented: $showInfo) {
                Button("got it", role: .cancel) {}
            } message: {
                Text("norma reads your notes in the background and looks for patterns, things you keep mentioning but haven't acted on, milestones you've hit, and anything unusual. new insights appear here automatically — no action needed from you.")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            Text("patterns norma noticed in your notes")
                .font(.system(size: 16, weight: .light))
                .italic()
                .foregroundStyle(NormaPalette.inkSubtle)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 36, weight: .thin))
                .foregroundStyle(NormaPalette.lavender.opacity(0.5))

            VStack(alignment: .leading, spacing: 8) {
                Text("nothing yet")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(NormaPalette.ink)

                Text("norma is reading your notes. insights will appear here as patterns emerge.")
                    .font(.system(size: 14))
                    .foregroundStyle(NormaPalette.inkSubtle)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
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
