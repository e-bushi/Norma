//
//  ArcSimulatorCardView.swift
//  Norma
//
//  Inline tappable card rendered in chat that opens the Arc Simulator sheet.
//

import SwiftUI

struct ArcSimulatorCardView: View {
    let currentArcs: Int
    let currency: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Coin preview
                StaticCoin3DView(fileName: CoinTierService.currentCoinFileName(for: max(currentArcs, 1)))
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text("Arc Simulator")
                        .font(.normaHeadline(15))
                        .foregroundColor(.primary)

                    Text("See what happens when you save more")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("NormaPastelTeal").opacity(0.1))
                    .glassEffect(in: RoundedRectangle(cornerRadius: 14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color("NormaPastelTeal").opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        ArcSimulatorCardView(currentArcs: 3, currency: "USD") {
            print("Tapped!")
        }
        .padding()
    }
    .background(Color("NormaBackground"))
}
