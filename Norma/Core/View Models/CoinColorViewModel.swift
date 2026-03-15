//
//  CoinColorViewModel.swift
//  Norma
//
//  Created by Claude on 3/14/26.
//

import SwiftUI

/// Provides the current coin tier color as an environment object.
/// Updated whenever the user's arc count changes.
@MainActor
class CoinColorViewModel: ObservableObject {
    @Published var coinColor: Color = .gray

    private var sessionViewModel: SessionViewModel
    private var billViewModel: BillViewModel

    init(sessionViewModel: SessionViewModel, billViewModel: BillViewModel) {
        self.sessionViewModel = sessionViewModel
        self.billViewModel = billViewModel
        updateColor()
    }

    func updateColor() {
        let freedomFund = sessionViewModel.currentUser?.settings.freedomFund ?? 0
        let totalBills = billViewModel.bills.reduce(0.0) { $0 + $1.amount }
        let largestBill = billViewModel.bills.map { $0.amount }.max() ?? 0

        let arcCount: Int
        if freedomFund < largestBill {
            arcCount = 0
        } else if totalBills > 0 {
            arcCount = Int(floor(freedomFund / totalBills))
        } else {
            arcCount = 0
        }

        coinColor = CoinTierService.currentCoinTier(for: arcCount).glowColor
    }
}
