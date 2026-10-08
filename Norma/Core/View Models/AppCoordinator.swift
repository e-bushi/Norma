//
//  AppCoordinator.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftUI
import UIKit
import Combine

@MainActor
class AppCoordinator: ObservableObject {

    // MARK: - Published Properties

    @Published var currentView: AppView
    @Published var mainLayerView: MainLayerViewType = .home

    // MARK: - Core Managers and ViewModels

    let dataManager: DataManager
    let sessionViewModel: SessionViewModel

    // Lazy-loaded ViewModels
    lazy var onboardingViewModel = OnboardingViewModel(sessionViewModel: sessionViewModel)

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        let dataManager = DataManager()
        let sessionViewModel = SessionViewModel(dataManager: dataManager)
        self.dataManager = dataManager
        self.sessionViewModel = sessionViewModel
        self.currentView = sessionViewModel.hasCompletedOnboarding ? .main : .onboarding

        sessionViewModel.$hasCompletedOnboarding
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] completed in
                self?.currentView = completed ? .main : .onboarding
            }
            .store(in: &cancellables)
    }

    // MARK: - Navigation Helpers

    /// Erases everything on device and restarts onboarding from the landing screen.
    func resetAllData() {
        onboardingViewModel.startOnboardingFlow()
        sessionViewModel.resetAllData()
    }

    // MARK: - View Building

    @ViewBuilder
    var currentViewContent: some View {
        switch currentView {
        case .onboarding:
            OnboardingCoordinatorView()
                .environmentObject(onboardingViewModel)
                .environmentObject(sessionViewModel)
                .environmentObject(dataManager)

        case .main:
            RootView()
                .environmentObject(self.dataManager)
                .environmentObject(self.sessionViewModel)
                .environmentObject(self)
        }
    }
}

// MARK: - Supporting Types

enum AppView {
    case onboarding
    case main
}

enum MainLayerViewType: Hashable {
    case settings
    case home
}

// MARK: - Coordinator Views

struct OnboardingCoordinatorView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @EnvironmentObject var sessionViewModel: SessionViewModel
    
    var body: some View {
        ZStack {
            // Persistent backdrop so the screen never flashes a different
            // color while the next step's own background (canvas + dither
            // + gradient) is mounting. Without this, the swap between
            // question screens reads as a tiny "blink."
            NormaPalette.canvas.ignoresSafeArea()

            Group {
                switch onboardingViewModel.currentStep {
            case .landing:
                LandingPageView()
                    .environmentObject(onboardingViewModel)

            // MARK: - Intro interstitial

            case .intro:
                OnboardingIntroInterstitialView(
                    onContinue: {
                        withAnimation { onboardingViewModel.currentStep = .triedBefore }
                    }
                )

            // MARK: - Card-based onboarding questions (May 2026)

            case .triedBefore:
                NormaCardQuestionView(question: .triedBefore) { selected in
                    onboardingViewModel.triedBefore = Array(selected)
                    onboardingViewModel.moveToNextStep()
                }

            case .messyMoney:
                NormaCardQuestionView(question: .messyMoney) { selected in
                    onboardingViewModel.messyMoney = Array(selected)
                    onboardingViewModel.moveToNextStep()
                }

            case .writingFrequency:
                NormaCardQuestionView(question: .writingFrequency) { selected in
                    onboardingViewModel.writingFrequency = selected.first ?? ""
                    onboardingViewModel.moveToNextStep()
                }

            case .celebrationOne:
                OnboardingCelebrationView(
                    phrase: "nice. norma's starting to know you.",
                    onContinue: { onboardingViewModel.moveToNextStep() }
                )

            case .moneyShapedThoughts:
                NormaCardQuestionView(question: .moneyShapedThoughts) { selected in
                    onboardingViewModel.moneyShapedThoughts = selected.first ?? ""
                    onboardingViewModel.moveToNextStep()
                }

            case .tabsCartsCameraRoll:
                NormaCardQuestionView(question: .tabsCartsCameraRoll) { selected in
                    onboardingViewModel.tabsCartsCameraRoll = selected.first ?? ""
                    onboardingViewModel.moveToNextStep()
                }

            case .thoughtsCameBack:
                NormaCardQuestionView(question: .thoughtsCameBack) { selected in
                    onboardingViewModel.thoughtsCameBack = selected.first ?? ""
                    onboardingViewModel.moveToNextStep()
                }

            case .celebrationTwo:
                OnboardingCelebrationView(
                    phrase: "halfway there. one more set.",
                    onContinue: { onboardingViewModel.moveToNextStep() }
                )

            case .incomeShape:
                NormaCardQuestionView(question: .incomeShape) { selected in
                    onboardingViewModel.incomeShape = selected.first ?? ""
                    onboardingViewModel.moveToNextStep()
                }

            case .whatsWorking:
                NormaCardQuestionView(question: .whatsWorking) { selected in
                    onboardingViewModel.whatsWorking = selected.first ?? ""
                    onboardingViewModel.moveToNextStep()
                }

            case .currencyIncome:
                OnboardingCurrencyIncomeView(
                    onContinue: { onboardingViewModel.saveProfileAndContinue() }
                )
                .environmentObject(onboardingViewModel)

            case .readyToStart:
                OnboardingCelebrationView(
                    phrases: [
                        "hi, i'm norma.",
                        "i'm glad you're finally here.",
                        "tell me your bills — i'll show you how long your money lasts."
                    ],
                    onContinue: { onboardingViewModel.completeOnboarding() }
                )

            case .complete:
                // Transition to main app
                EmptyView()
            }
            }
            // Each step gets its own identity so SwiftUI treats the swap
            // as a remove+insert and runs the crossfade. The transition is
            // deliberately short — entrance animations on the new screen
            // handle the rest of the choreography.
            .id(onboardingViewModel.currentStep)
            .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.28), value: onboardingViewModel.currentStep)
        .onChange(of: onboardingViewModel.currentStep) { _, newStep in
            // Track onboarding step viewed
            let stepIndex = OnboardingStep.allCases.firstIndex(of: newStep) ?? 0
            AnalyticsService.shared.track(.onboardingStepViewed(step: String(describing: newStep), index: stepIndex))
        }
        .onAppear {
            // Track initial step on appear
            let stepIndex = OnboardingStep.allCases.firstIndex(of: onboardingViewModel.currentStep) ?? 0
            AnalyticsService.shared.track(.onboardingStepViewed(step: String(describing: onboardingViewModel.currentStep), index: stepIndex))
        }
    }
}

