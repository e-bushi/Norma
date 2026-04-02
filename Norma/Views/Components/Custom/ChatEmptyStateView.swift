//
//  ChatEmptyStateView.swift
//  Norma
//
//  Created by Claude on 5/10/25.
//

import SwiftUI

struct ChatEmptyStateView: View {
    let arcCount: Int
    var onCoinTapped: () -> Void = {}
    var onShowBills: () -> Void = {}
    var onShowActivity: () -> Void = {}
    var onShowExpenses: () -> Void = {}
    var onShowPendingTransactions: () -> Void = {}
    var pendingTransactionsCount: Int = 0

    @State private var textAnimating: Bool = false
    @State private var coinVisible: Bool = false
    @State private var capsulesVisible: Bool = false
    @State private var visibleCapsuleCount: Int = 0
    @State private var showHint: Bool = false
    @State private var coinPressed: Bool = false
    @State private var subGreetingVisible: Bool = false

    // Timezone state — commented out for later
    // @State private var showTimezoneSelection: Bool = false
    // @ObservedObject private var timezoneManager = TimezoneManager.shared

    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var billViewModel: BillViewModel

    private var userName: String {
        sessionViewModel.currentUser?.name.components(separatedBy: " ").first ?? ""
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = userName.isEmpty ? "" : ", \(userName)"
        switch hour {
        case 5..<12: return "Good morning\(name)."
        case 12..<17: return "Good afternoon\(name)."
        case 17..<22: return "Good evening\(name)."
        default: return "Hey\(name)."
        }
    }

    private var subGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "How can I help you this morning?"
        case 12..<17: return "How can I help you this afternoon?"
        case 17..<22: return "How can I help you this evening?"
        default: return "How can I help you tonight?"
        }
    }
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var dataManager: DataManager

    // MARK: - Capsule Display Values

    private var totalBillsFormatted: String {
        profileViewModel.formatCurrencyTruncated(billViewModel.totalMonthlyBills)
    }

    private var weeklySpend: Double {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 2), to: today)!
        let dayStart = calendar.startOfDay(for: startOfWeek)
        let now = today

        return dataManager.expenses.filter { expense in
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: expense.expenseDate) {
                return date >= dayStart && date <= now
            }
            if expense.expenseDate.contains("T") {
                return formatter.date(from: expense.expenseDate + "Z").map { $0 >= dayStart && $0 <= now } ?? false
            }
            return formatter.date(from: expense.expenseDate + "T00:00:00Z").map { $0 >= dayStart && $0 <= now } ?? false
        }.reduce(0) { $0 + $1.amount }
    }

    private var weeklySpendFormatted: String {
        profileViewModel.formatCurrencyTruncated(weeklySpend)
    }

    private var monthlySpendFormatted: String {
        profileViewModel.formatCurrencyTruncated(expenseViewModel.currentMonthExpenses)
    }

    private var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: Date())
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 12) {
                // "Tap the coin" hint capsule
                Text("Tap the coin")
                    .font(.custom(FontFamily.Rubik.medium, size: 16))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.clear)
                            .glassEffect(in: Capsule())
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
                    )
                    .scaleEffect(showHint ? 1 : 0.5)
                    .opacity(showHint ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65), value: showHint)

                // Motion coin based on user's current tier (tilts with device)
                CrossfadeView(
                    key: CoinTierService.currentCoinFileName(for: arcCount),
                    duration: 0.45,
                    initialDelay: 0.7
                ) { fileName in
                    MotionCoin3DView(fileName: fileName, hapticsEnabled: false)
                        .id(fileName)
                        .frame(width: scaledCoinSize(for: geometry), height: scaledCoinSize(for: geometry))
                        .allowsHitTesting(false)
                }
                .overlay(
                    Color.clear
                        .contentShape(Circle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !coinPressed {
                                        coinPressed = true
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                    }
                                }
                                .onEnded { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        coinPressed = false
                                        onCoinTapped()
                                    }
                                }
                        )
                )
                .scaleEffect(coinPressed ? 0.9 : (coinVisible ? 1 : 0.3))
                .opacity(coinVisible ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: coinPressed)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: coinVisible)

                // Sub-greeting
                WaveTextView(
                    text: subGreeting,
                    font: .custom(FontFamily.Rubik.medium, size: scaledSubGreetingSize(for: geometry)),
                    color: .white.opacity(0.85),
                    isAnimating: subGreetingVisible,
                    alignment: .center
                )
                .lineSpacing(4)
                .frame(maxWidth: scaledSubGreetingWidth(for: geometry))
                .padding(.horizontal, 24)

                // Navigation capsules
                FlowLayout(spacing: 8) {
                    // Bills
                    navCapsule(title: "Bills \(totalBillsFormatted)", index: 0) {
                        onShowBills()
                    }

                    // Activity (this week)
                    navCapsule(title: "This week \(weeklySpendFormatted)", index: 1) {
                        onShowActivity()
                    }

                    // Expenses (month spend)
                    navCapsule(title: "\(shortMonthName). Spend \(monthlySpendFormatted)", index: 2) {
                        onShowExpenses()
                    }

                    // Pending
                    navCapsule(
                        title: pendingTransactionsCount > 0 ? "Pending (\(pendingTransactionsCount))" : "Pending",
                        index: 3
                    ) {
                        onShowPendingTransactions()
                    }
                }
                .frame(maxWidth: 320)
                .padding(.top, 6)
                .opacity(capsulesVisible ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: capsulesVisible)

                // Timezone capsules — commented out for later
                /*
                FlowLayout(spacing: 8) {
                    ForEach(Array(timezoneManager.selectedTimezones.prefix(3).enumerated()), id: \.element.id) { index, timezone in
                        Button {
                            showTimezoneSelection = true
                        } label: {
                            TimezoneCapsuleView(timezone: timezone, color: capsuleColors[index]) {
                                showTimezoneSelection = true
                            }
                        }
                        .buttonStyle(.plain)
                        .overlay(
                            Capsule()
                                .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        )
                        .opacity(visibleCapsuleCount > index ? 1 : 0)
                        .scaleEffect(visibleCapsuleCount > index ? 1 : 0.8)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.75)
                                .delay(Double(index) * 0.1),
                            value: visibleCapsuleCount
                        )
                    }

                    Button {
                        showTimezoneSelection = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .medium))
                            Text("World Clocks")
                                .font(.normaFinancial(14))
                        }
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .overlay(
                            Capsule()
                                .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
                */
            }
            .frame(width: geometry.size.width)
            .position(x: geometry.size.width / 2, y: (geometry.size.height / 2) - 60)
            .onAppear {
                coinVisible = false
                textAnimating = false
                capsulesVisible = false
                visibleCapsuleCount = 0
                showHint = false
                subGreetingVisible = false

                // Coin pops in first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    coinVisible = true
                }
                // Words follow shortly after
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    textAnimating = true
                }
                // Sub-greeting fades in after text
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    subGreetingVisible = true
                }
                // Hint pops in after everything else has animated in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showHint = true
                }
                // Navigation capsules appear
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    capsulesVisible = true
                    visibleCapsuleCount = 4
                }
                // Hint fades out
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showHint = false
                    }
                }
            }
            .onDisappear {
                coinVisible = false
                textAnimating = false
                capsulesVisible = false
                visibleCapsuleCount = 0
                showHint = false
                subGreetingVisible = false
            }
        }
        // Timezone sheet — commented out for later
        // .sheet(isPresented: $showTimezoneSelection) {
        //     TimezoneSelectionView()
        // }
    }

    // MARK: - Navigation Capsule

    @ViewBuilder
    private func navCapsule(title: String, index: Int, action: @escaping () -> Void) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        } label: {
            Text(title)
                .font(.normaFinancial(16))
                .foregroundColor(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .overlay(
                    Capsule()
                        .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
        }
        .buttonStyle(CapsulePressStyle())
        .opacity(visibleCapsuleCount > index ? 1 : 0)
        .scaleEffect(visibleCapsuleCount > index ? 1 : 0.8)
        .animation(
            .spring(response: 0.45, dampingFraction: 0.75)
                .delay(Double(index) * 0.1),
            value: visibleCapsuleCount
        )
    }

    private func scaledCoinSize(for geometry: GeometryProxy) -> CGFloat {
        let scale = max(geometry.size.height / 874, 0.5)
        return 120 * scale
    }

    private func scaledTextSize(for geometry: GeometryProxy) -> CGFloat {
        let scale = max(geometry.size.height / 874, 0.5)
        return 56 * scale
    }

    private func scaledSubGreetingSize(for geometry: GeometryProxy) -> CGFloat {
        let scale = max(geometry.size.height / 874, 0.5)
        return 36 * scale
    }

    private func scaledSubGreetingWidth(for geometry: GeometryProxy) -> CGFloat {
        let scale = max(geometry.size.height / 874, 0.5)
        return 400 * scale
    }
}

#Preview {
    ZStack {
        Color("NormaBackground")
            .ignoresSafeArea()

        ChatEmptyStateView(arcCount: 3)
    }
}
