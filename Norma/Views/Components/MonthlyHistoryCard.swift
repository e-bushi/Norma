//
//  MonthlyHistoryCard.swift
//  Norma
//
//  Created by Claude on 12/31/25.
//

import SwiftUI

struct MonthlyHistoryCard: View {
    let stats: MonthlyStats
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Month header
            Text(stats.displayTitle)
                .font(.normaFinancial(16))
                .foregroundColor(.primary)
                .lineLimit(1)

            // Stats grid
            VStack(alignment: .leading, spacing: 8) {
                // Total Spent
                statRow(
                    label: "Spent",
                    value: profileViewModel.formatCurrency(stats.totalSpent),
                    color: Color("NormaPastelCoral")
                )

                // Arcs Added
                statRow(
                    label: "Arcs",
                    value: "+\(stats.arcsAdded)",
                    color: Color("NormaPastelTeal")
                )

                // Challenges Completed
                statRow(
                    label: "Challenges",
                    value: "\(stats.challengesCompleted)",
                    color: Color("NormaPastelPurple")
                )

                // Funds Left Over
                statRow(
                    label: "Left Over",
                    value: profileViewModel.formatCurrency(stats.fundsLeftOver),
                    color: stats.fundsLeftOver >= 0 ? Color("NormaPastelTeal") : Color("NormaPastelCoral")
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.normaInput(11))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.normaFinancial(12))
                .foregroundColor(color)
        }
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)

    let sampleStats = MonthlyStats(
        id: "1",
        userId: "user123",
        month: 11,
        year: 2025,
        totalSpent: 2450.00,
        arcsAdded: 2,
        challengesCompleted: 3,
        fundsLeftOver: 550.00
    )

    return MonthlyHistoryCard(stats: sampleStats)
        .environmentObject(profileViewModel)
        .padding()
        .background(Color("NormaBackground"))
}
