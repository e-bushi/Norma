//
//  MainLayerView.swift
//  Norma
//
//  Created by Claude on 10/20/25.
//

import SwiftUI

struct MainLayerView: View {
    @EnvironmentObject private var appCoordinator: AppCoordinator
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var challengeViewModel: ChallengeViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    @State private var isMenuOpen = false
    @State private var dragOffset: CGFloat = 0

    // Edge threshold for detecting swipe from left edge
    private let edgeThreshold: CGFloat = 25

    // Velocity threshold for completing gesture
    private let velocityThreshold: CGFloat = 500

    var body: some View {
        GeometryReader { geometry in
            let menuWidth = geometry.size.width * 0.85
            let baseOffset = isMenuOpen ? menuWidth : 0
            let totalOffset = calculateTotalOffset(baseOffset: baseOffset, menuWidth: menuWidth)

            mainLayerContent
                .offset(x: totalOffset)
                .shadow(color: Color.black.opacity(shadowOpacity(totalOffset: totalOffset, menuWidth: menuWidth)), radius: 10)
                .gesture(menuDragGesture(menuWidth: menuWidth))
                .onTapGesture {
                    if isMenuOpen {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isMenuOpen = false
                        }
                    }
                }
                .background(
                    ChatMenuView(isMenuOpen: $isMenuOpen, mainLayerView: $appCoordinator.mainLayerView)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                )
        }
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Drag Gesture

    private func menuDragGesture(menuWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                let translation = value.translation.width
                let isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height)

                guard isHorizontalDrag else { return }

                if isMenuOpen {
                    // Menu is open - allow dragging left to close (anywhere on content)
                    // Clamp between -menuWidth and 0
                    dragOffset = min(0, max(-menuWidth, translation))
                } else {
                    // Menu is closed - only allow edge swipe to open
                    if value.startLocation.x < edgeThreshold {
                        // Clamp between 0 and menuWidth
                        dragOffset = min(menuWidth, max(0, translation))
                    }
                }
            }
            .onEnded { value in
                let velocity = value.velocity.width
                let translation = value.translation.width
                let isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height)

                // Only process if it was a horizontal drag
                guard isHorizontalDrag else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                    return
                }

                var shouldOpen: Bool

                if isMenuOpen {
                    // Currently open - check if should close
                    // Close if dragged past halfway OR velocity is fast enough leftward
                    let shouldClose = dragOffset < -menuWidth / 2 || velocity < -velocityThreshold
                    shouldOpen = !shouldClose
                } else {
                    // Currently closed - check if should open
                    // Only if started from edge
                    if value.startLocation.x < edgeThreshold {
                        // Open if dragged past halfway OR velocity is fast enough rightward
                        shouldOpen = dragOffset > menuWidth / 2 || velocity > velocityThreshold
                    } else {
                        shouldOpen = false
                    }
                }

                // Provide haptic feedback on state change
                if shouldOpen != isMenuOpen {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                }

                // Animate to final state
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isMenuOpen = shouldOpen
                    dragOffset = 0
                }
            }
    }

    // MARK: - Offset Calculations

    private func calculateTotalOffset(baseOffset: CGFloat, menuWidth: CGFloat) -> CGFloat {
        let total = baseOffset + dragOffset
        // Clamp between 0 and menuWidth
        return max(0, min(menuWidth, total))
    }

    private func shadowOpacity(totalOffset: CGFloat, menuWidth: CGFloat) -> Double {
        // Shadow opacity proportional to how open the menu is
        let progress = totalOffset / menuWidth
        return Double(progress) * 0.3
    }

    // MARK: - Content

    @ViewBuilder
    private var mainLayerContent: some View {
        switch appCoordinator.mainLayerView {
        case .chat:
            MainChatView(isMenuOpen: $isMenuOpen)
                .environmentObject(sessionViewModel)
                .environmentObject(dataManager)
                .environmentObject(billViewModel)
                .environmentObject(expenseViewModel)

        case .settings:
            NavigationStack {
                SettingsView(isMenuOpen: $isMenuOpen)
                    .environmentObject(sessionViewModel)
                    .environmentObject(dataManager)
            }

        case .currencyConverter:
            NavigationStack {
                CurrencyConverterView(isMenuOpen: $isMenuOpen)
            }

        case .overview:
            NavigationStack {
                FinancialOverviewView(isMenuOpen: $isMenuOpen)
                    .environmentObject(sessionViewModel)
                    .environmentObject(dataManager)
                    .environmentObject(billViewModel)
                    .environmentObject(expenseViewModel)
                    .environmentObject(challengeViewModel)
                    .environmentObject(profileViewModel)
            }
        }
    }
}

#Preview {
    let appCoordinator = AppCoordinator()

    return MainLayerView()
        .environmentObject(appCoordinator)
        .environmentObject(appCoordinator.dataManager)
        .environmentObject(appCoordinator.sessionViewModel)
}
