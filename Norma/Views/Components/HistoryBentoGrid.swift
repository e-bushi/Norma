//
//  HistoryBentoGrid.swift
//  Norma
//
//  Created by Claude on 12/31/25.
//

import SwiftUI

struct HistoryBentoGrid: View {
    let monthlyStats: [MonthlyStats]
    @EnvironmentObject var profileViewModel: ProfileViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let maxMonthsToShow = 12

    /// Filter out current month and sort by most recent first
    private var historicalStats: [MonthlyStats] {
        monthlyStats
            .filter { !$0.isCurrentMonth }
            .sorted { $0.sortKey > $1.sortKey }
            .prefix(maxMonthsToShow)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Divider
            Divider()
                .padding(.bottom, 4)

            // Section header
            Text("HISTORY")
                .font(.normaInput(12))
                .foregroundColor(.secondary)
                .tracking(1.5)

            // Grid of monthly cards
            if historicalStats.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(historicalStats) { stats in
                        MonthlyHistoryCard(stats: stats)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No history yet")
                .font(.normaInput(14))
                .foregroundColor(.secondary)

            Text("Your monthly stats will appear here")
                .font(.normaInput(12))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)

    let sampleStats = [
        MonthlyStats(id: "1", userId: "user123", month: 11, year: 2025, totalSpent: 2450.00, arcsAdded: 2, challengesCompleted: 3, fundsLeftOver: 550.00),
        MonthlyStats(id: "2", userId: "user123", month: 10, year: 2025, totalSpent: 2100.00, arcsAdded: 1, challengesCompleted: 2, fundsLeftOver: 900.00),
        MonthlyStats(id: "3", userId: "user123", month: 9, year: 2025, totalSpent: 2800.00, arcsAdded: 0, challengesCompleted: 1, fundsLeftOver: 200.00),
        MonthlyStats(id: "4", userId: "user123", month: 8, year: 2025, totalSpent: 2300.00, arcsAdded: 3, challengesCompleted: 4, fundsLeftOver: 700.00)
    ]

    return ScrollView {
        HistoryBentoGrid(monthlyStats: sampleStats)
            .environmentObject(profileViewModel)
            .padding()
    }
    .background(Color("NormaBackground"))
}
