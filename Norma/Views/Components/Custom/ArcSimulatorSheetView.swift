//
//  ArcSimulatorSheetView.swift
//  Norma
//
//  Full interactive sheet where users adjust their freedom fund
//  and watch coins pop into existence on a month timeline.
//

import SwiftUI

struct ArcSimulatorSheetView: View {
    let initialFreedomFund: Double
    let totalMonthlyBills: Double
    let currency: String
    let bills: [Bill]

    @Environment(\.dismiss) private var dismiss
    @State private var sliderValue: Double
    @State private var simulatedArcs: Int = 0
    @State private var previousArcs: Int = 0
    @State private var visibleMonths: Set<Int> = []

    private let monthCount = 12
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // Currency formatter
    private var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currency
        f.maximumFractionDigits = 0
        return f
    }

    private var sliderMax: Double {
        max(totalMonthlyBills * 12, initialFreedomFund * 2)
    }

    // Month labels starting from current month
    private var monthLabels: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let calendar = Calendar.current
        let now = Date()
        return (0..<monthCount).map { offset in
            let date = calendar.date(byAdding: .month, value: offset, to: now)!
            return formatter.string(from: date)
        }
    }

    init(initialFreedomFund: Double, totalMonthlyBills: Double, currency: String, bills: [Bill]) {
        self.initialFreedomFund = initialFreedomFund
        self.totalMonthlyBills = totalMonthlyBills
        self.currency = currency
        self.bills = bills
        self._sliderValue = State(initialValue: initialFreedomFund)
    }

    var body: some View {
        ZStack {
            Color("NormaBackground").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header (dismiss only, no title)
                header
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                Spacer().frame(height: 24)

                // Freedom fund display
                freedomFundDisplay
                    .padding(.horizontal, 20)

                Spacer().frame(height: 20)

                // Summary text
                summaryText
                    .padding(.horizontal, 20)

                Spacer().frame(height: 28)

                // Slider
                sliderSection
                    .padding(.horizontal, 20)

                Spacer().frame(height: 8)

                // Slider labels
                sliderLabels
                    .padding(.horizontal, 20)

                Spacer().frame(height: 28)

                // Coin grid (below slider)
                coinGrid
                    .padding(.horizontal, 20)

                Spacer()
            }
        }
        .onAppear {
            recalculateArcs()
            // Show initial months
            for i in 0..<simulatedArcs {
                visibleMonths.insert(i)
            }
        }
        .onChange(of: sliderValue) { _, _ in
            let oldArcs = simulatedArcs
            recalculateArcs()
            if simulatedArcs != oldArcs {
                animateArcChange(from: oldArcs, to: simulatedArcs)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(Color("NormaText").opacity(0.08))
                    )
            }
        }
    }

    // MARK: - Freedom Fund Display

    private var freedomFundDisplay: some View {
        VStack(spacing: 6) {
            Text("Balance")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text(formatter.string(from: NSNumber(value: sliderValue)) ?? "\(Int(sliderValue))")
                .font(.normaFinancial(48))
                .foregroundColor(.primary)
                .contentTransition(.numericText(value: sliderValue))
                .animation(.snappy(duration: 0.2), value: sliderValue)
        }
    }

    // MARK: - Coin Grid

    private var coinGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(0..<monthCount, id: \.self) { index in
                monthCell(at: index)
            }
        }
    }

    private func monthCell(at index: Int) -> some View {
        let isCovered = index < simulatedArcs
        let isVisible = visibleMonths.contains(index)
        let tier = CoinTierService.currentCoinTier(for: index + 1)

        return VStack(spacing: 6) {
            ZStack {
                if isCovered && isVisible {
                    // Glow behind coin
                    Circle()
                        .fill(tier.glowColor.opacity(0.25))
                        .frame(width: 60, height: 60)
                        .blur(radius: 8)

                    // Coin
                    StaticCoin3DView(fileName: tier.fileName)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .transition(.scale.combined(with: .opacity))
                } else {
                    // Empty placeholder
                    Circle()
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                        )
                        .foregroundColor(.gray.opacity(0.3))
                        .frame(width: 48, height: 48)
                }
            }
            .frame(width: 60, height: 60)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isCovered && isVisible)

            // Month label
            Text(monthLabels[index])
                .font(.system(size: 11, weight: isCovered ? .semibold : .regular))
                .foregroundColor(isCovered ? .primary : .secondary.opacity(0.6))

            // Arc number
            Text("Arc \(index + 1)")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(isCovered ? Color("NormaPastelTeal") : .clear)
        }
    }

    // MARK: - Summary

    private var summaryText: some View {
        Group {
            if simulatedArcs > 0 {
                Text("Your balance covers **\(simulatedArcs) month\(simulatedArcs == 1 ? "" : "s")** of bills")
                    .font(.normaInput(15))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Slide to see how saving more builds your arcs")
                    .font(.normaInput(15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: simulatedArcs)
    }

    // MARK: - Slider

    private var sliderSection: some View {
        Slider(value: $sliderValue, in: 0...sliderMax, step: totalMonthlyBills > 0 ? totalMonthlyBills * 0.05 : 100)
            .tint(Color("NormaPastelTeal"))
    }

    private var sliderLabels: some View {
        HStack {
            Text(formatter.string(from: NSNumber(value: 0)) ?? "0")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()

            Text(formatter.string(from: NSNumber(value: sliderMax)) ?? "\(Int(sliderMax))")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Calculation

    private func recalculateArcs() {
        simulatedArcs = ArcCalculationService.calculateArcs(freedomFund: sliderValue, bills: bills)
    }

    private func animateArcChange(from oldArcs: Int, to newArcs: Int) {
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.prepare()

        if newArcs > oldArcs {
            // Coins popping in
            for i in oldArcs..<min(newArcs, monthCount) {
                let delay = Double(i - oldArcs) * 0.08
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        visibleMonths.insert(i)
                    }
                    feedback.impactOccurred(intensity: 0.6)
                }
            }
        } else {
            // Coins disappearing
            for i in stride(from: min(oldArcs - 1, monthCount - 1), through: newArcs, by: -1) {
                let delay = Double(oldArcs - 1 - i) * 0.06
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        _ = visibleMonths.remove(i)
                    }
                }
            }
        }
    }
}

#Preview {
    ArcSimulatorSheetView(
        initialFreedomFund: 3000,
        totalMonthlyBills: 1500,
        currency: "USD",
        bills: []
    )
}
