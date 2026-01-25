//
//  FinancialOverviewView.swift
//  Norma
//
//  Created by Claude on 12/24/25.
//

import SwiftUI

struct FinancialOverviewView: View {
    @Binding var isMenuOpen: Bool
    var showMenuButton: Bool = true
    var onClose: (() -> Void)? = nil
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var billViewModel: BillViewModel
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel

    @State private var animateBills = false
    @State private var animateStats = false
    @State private var animateChallenge = false
    @State private var animateProgress = false
    @State private var animateHistory = false

    // Animated number values (start at 0, animate to real values)
    @State private var displayedRemaining: Double = 0

    // MARK: - Computed Properties

    private var monthlyIncome: Double {
        sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
    }

    private var totalBills: Double {
        billViewModel.totalMonthlyBills
    }

    private var totalExpenses: Double {
        expenseViewModel.currentMonthExpenses
    }

    private var discretionaryIncome: Double {
        max(0, monthlyIncome - totalBills)
    }

    private var remainingAfterExpenses: Double {
        discretionaryIncome - totalExpenses
    }

    private var spendingProgress: Double {
        guard discretionaryIncome > 0 else { return 0 }
        return min(1.0, totalExpenses / discretionaryIncome)
    }

    private var freedomFund: Double {
        sessionViewModel.currentUser?.settings.freedomFund ?? 0
    }

    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    private var hasUpcomingBills: Bool {
        !billViewModel.upcomingBills.filter { bill in
            bill.calculateStatus(from: expenseViewModel.expenses) != .paid
        }.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Main Balance Section
                balanceSection

                // Bills Due Section
                if hasUpcomingBills {
                    UpcomingBillsSection()
                        .opacity(animateBills ? 1 : 0)
                        .offset(y: animateBills ? 0 : 25)
                }

                // Stats Grid
                statsGrid
                    .opacity(animateStats ? 1 : 0)
                    .offset(y: animateStats ? 0 : 25)

                // Challenge Section
                if let challenge = challengeViewModel.activeChallenge {
                    challengeSection(challenge: challenge)
                        .opacity(animateChallenge ? 1 : 0)
                        .offset(y: animateChallenge ? 0 : 25)
                }

                // Spending Progress Section
                spendingProgressSection
                    .opacity(animateProgress ? 1 : 0)
                    .offset(y: animateProgress ? 0 : 25)

                // History Section
                HistoryBentoGrid(monthlyStats: dataManager.monthlyStats)
                    .opacity(animateHistory ? 1 : 0)
                    .offset(y: animateHistory ? 0 : 25)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showMenuButton {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isMenuOpen = true
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Overview")
                    .font(.normaTitle(20))
            }

            if onClose != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        onClose?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.15))
                            )
                    }
                }
            }
        }
        .onAppear {
            startStaggeredAnimations()
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Animation

    private func startStaggeredAnimations() {
        let baseDelay: Double = 0.1
        let stagger: Double = 0.08

        // Animate main balance number
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(baseDelay)) {
            displayedRemaining = remainingAfterExpenses
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(baseDelay + stagger)) {
            animateBills = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(baseDelay + stagger * 2)) {
            animateStats = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(baseDelay + stagger * 3)) {
            animateChallenge = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(baseDelay + stagger * 4)) {
            animateProgress = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(baseDelay + stagger * 5)) {
            animateHistory = true
        }
    }

    // MARK: - Balance Section

    private var balanceSection: some View {
        VStack(spacing: 8) {
            // Current month and year
            Text(currentMonthYear.uppercased())
                .font(.normaFinancial(18))
                .foregroundColor(.secondary)
                .tracking(1.2)

            // Remaining amount with numeric animation
            Text(profileViewModel.formatCurrency(displayedRemaining))
                .font(.normaHeadline(72))
                .foregroundColor(remainingAfterExpenses >= 0 ? .primary : Color("NormaPastelCoral"))
                .shadow(color: Color("NormaPastelCoral").opacity(0.25), radius: 20, y: 4)
                .contentTransition(.numericText())

            // Label
            Text("Remaining this month")
                .font(.normaInput(14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                tappableStatCard(
                    title: "Income",
                    value: profileViewModel.formatCurrency(monthlyIncome),
                    icon: "arrow.down.circle.fill",
                    color: Color("NormaPastelTeal")
                ) {
                    // Tap action for income
                }

                statCard(
                    title: "Bills",
                    value: profileViewModel.formatCurrency(totalBills),
                    icon: "doc.text.fill",
                    color: Color("NormaPastelPurple")
                )
            }

            HStack(spacing: 12) {
                statCard(
                    title: "Spent",
                    value: profileViewModel.formatCurrency(totalExpenses),
                    icon: "creditcard.fill",
                    color: Color("NormaPastelCoral")
                )

                tappableStatCard(
                    title: "Freedom Fund",
                    value: profileViewModel.formatCurrency(freedomFund),
                    icon: "shield.fill",
                    color: Color("NormaPastelBeige")
                ) {
                    // Tap action for freedom fund
                }
            }
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.normaInput(12))
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.normaFinancial(20))
                    .foregroundColor(.primary)
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

    private func tappableStatCard(title: String, value: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.normaInput(12))
                        .foregroundColor(.secondary)

                    Text(value)
                        .font(.normaFinancial(20))
                        .foregroundColor(.primary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.4), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(StatCardPressStyle())
    }

    // MARK: - Challenge Section

    private func challengeSection(challenge: Challenge) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIVE CHALLENGE")
                .font(.normaInput(12))
                .foregroundColor(.secondary)
                .tracking(1.5)

            HStack(spacing: 16) {
                // Challenge progress circle
                ZStack {
                    Circle()
                        .stroke(Color("NormaPastelPurple").opacity(0.2), lineWidth: 6)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: challenge.percentageSpent)
                        .stroke(Color("NormaPastelPurple"), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "target")
                        .font(.system(size: 20))
                        .foregroundColor(Color("NormaPastelPurple"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(profileViewModel.formatCurrency(challenge.amountRemaining))
                        .font(.normaFinancial(24))
                        .foregroundColor(.primary)

                    Text("\(challenge.daysRemaining) days remaining")
                        .font(.normaInput(14))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color("NormaPastelPurple").opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Spending Progress Section

    private var spendingProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SPENDING PROGRESS")
                .font(.normaInput(12))
                .foregroundColor(.secondary)
                .tracking(1.5)

            VStack(spacing: 16) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(spendingProgress > 0.8 ? Color("NormaPastelCoral") : Color("NormaPastelTeal"))
                            .frame(width: geometry.size.width * spendingProgress, height: 12)
                    }
                }
                .frame(height: 12)

                // Labels
                HStack {
                    Text("\(Int(spendingProgress * 100))% spent")
                        .font(.normaInput(14))
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(profileViewModel.formatCurrency(discretionaryIncome - totalExpenses)) left")
                        .font(.normaFinancial(14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Financial Overview Overlay

struct FinancialOverviewOverlay: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            FinancialOverviewView(
                isMenuOpen: .constant(false),
                showMenuButton: false,
                onClose: {
                    isPresented = false
                }
            )
        }
        .background {
            Rectangle()
                .fill(.clear)
                .glassEffect(in: Rectangle())
                .ignoresSafeArea()
        }
        .persistentSystemOverlays(.hidden)
    }
}

// MARK: - Button Style

struct StatCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let billViewModel = BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let expenseViewModel = ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let challengeViewModel = ChallengeViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)

    NavigationStack {
        FinancialOverviewView(isMenuOpen: .constant(false))
            .environmentObject(sessionViewModel)
            .environmentObject(dataManager)
            .environmentObject(billViewModel)
            .environmentObject(expenseViewModel)
            .environmentObject(challengeViewModel)
            .environmentObject(profileViewModel)
    }
}
