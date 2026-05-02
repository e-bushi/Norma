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

    @Published var currentView: AppView = .loading
    @Published var isReady = false
    @Published var dataLoaded = false
    @Published var userStartedApp = false
    @Published var mainLayerView: MainLayerViewType = .notes

    /// Loading view removed — go straight to the main app once auth is resolved.
    var shouldShowAppLoadingView: Bool { false }
    
    // MARK: - Core Managers and ViewModels

    let dataManager: DataManager
    let sessionViewModel: SessionViewModel

    // Lazy-loaded ViewModels
    lazy var onboardingViewModel = OnboardingViewModel(sessionViewModel: sessionViewModel)
    lazy var conversationManager = ConversationManager(dataManager: dataManager, sessionViewModel: sessionViewModel)
    
    // MARK: - Initialization
    
    init() {
        // Initialize core components
        self.dataManager = DataManager()
        self.sessionViewModel = SessionViewModel(dataManager: dataManager)

        // Bridge note-extracted bill tokens into the canonical Bill model so
        // recurring bill mentions written in notes surface in BillsView.
        BillTokenBridge.shared.configure(
            dataManager: dataManager,
            sessionViewModel: sessionViewModel
        )

        setupAppFlow()
        setupNotificationObservers()
    }
    
    // MARK: - App Flow Methods
    
    private func setupAppFlow() {
        Task {
            // Initial setup
            await sessionViewModel.checkAuthenticationState()

            // Determine initial view
            updateCurrentView()

            // No artificial loading delay — drop straight into the destination.
            dataLoaded = true
            userStartedApp = true
            isReady = true

            // Observe session changes
            observeSessionChanges()
        }
    }

    /// Legacy hook from the old loading screen — kept for any stragglers, no-op.
    func userTappedStart() {
        userStartedApp = true
        isReady = true
    }
    
    private func setupNotificationObservers() {
        // App lifecycle observers can be added here if needed
    }
    
    private func updateCurrentView() {
        let previousView = currentView

        if sessionViewModel.isLoadingAuth {
            currentView = .loading
        } else if sessionViewModel.shouldShowMainApp {
            currentView = .main
            // Load conversations when entering main app (userId is obtained from sessionViewModel)
            Task {
                await conversationManager.loadConversations()
            }
        } else if sessionViewModel.shouldShowAuthFlow {
            currentView = .onboarding
        } else if sessionViewModel.shouldShowInitialSetup {
            currentView = .onboarding
        } else {
            // Default to onboarding if no other condition is met
            currentView = .onboarding
        }

        if previousView != currentView {
            print("🧭 AppCoordinator: View changed from \(previousView) to \(currentView) | isAuth: \(sessionViewModel.isAuthenticated), hasOnboarding: \(sessionViewModel.hasCompletedOnboarding), hasSetup: \(sessionViewModel.hasCompletedInitialSetup)")
        }
    }
    
    private func observeSessionChanges() {
        // Listen for authentication state changes
        Task {
            for await isAuth in sessionViewModel.$isAuthenticated.values {
                print("👀 Observed isAuthenticated change: \(isAuth)")
                updateCurrentView()
            }
        }

        // Listen for onboarding completion
        Task {
            for await completed in sessionViewModel.$hasCompletedOnboarding.values {
                print("👀 Observed hasCompletedOnboarding change: \(completed)")
                updateCurrentView()
            }
        }

        // Listen for initial setup completion
        Task {
            for await setup in sessionViewModel.$hasCompletedInitialSetup.values {
                print("👀 Observed hasCompletedInitialSetup change: \(setup)")
                updateCurrentView()
            }
        }
    }
    
    // MARK: - Navigation Helpers
    
    func resetToOnboarding() {
        currentView = .onboarding
        onboardingViewModel.startOnboardingFlow()
    }
    
    func completeOnboarding() {
        sessionViewModel.completeOnboarding()
        currentView = .main
    }
    
    func logout() async {
        await sessionViewModel.logout()
        dataManager.clearAllData()
        onboardingViewModel.startOnboardingFlow()
        currentView = .onboarding
    }
    
    // MARK: - View Building
    
    @ViewBuilder
    var currentViewContent: some View {
        switch currentView {
        case .loading:
            // Brief auth-resolution moment — show the canvas color, no spinner.
            Color("NormaBackground").ignoresSafeArea()

        case .onboarding:
            OnboardingCoordinatorView()
                .environmentObject(onboardingViewModel)
                .environmentObject(sessionViewModel)
                .environmentObject(dataManager)
        
        case .main:
            RootView()
                .environmentObject(dataManager)
                .environmentObject(sessionViewModel)
                .environmentObject(conversationManager)
                .environmentObject(self)
        }
    }
}

// MARK: - Supporting Types

enum AppView {
    case loading
    case onboarding
    case main
}

enum MainLayerViewType: Hashable {
    case chat
    case settings
    case notes
}

// MARK: - Coordinator Views

struct OnboardingCoordinatorView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @EnvironmentObject var sessionViewModel: SessionViewModel
    
    var body: some View {
        Group {
            switch onboardingViewModel.currentStep {
            case .landing:
                LandingPageView(
                    showSignUp: $onboardingViewModel.showSignUp,
                    showSignIn: Binding(
                        get: { !onboardingViewModel.showSignUp },
                        set: { onboardingViewModel.showSignUp = !$0 }
                    )
                )
                .environmentObject(onboardingViewModel)

            case .authentication:
                if onboardingViewModel.showSignUp {
                    SignUpView(
                        isAuthenticated: .constant(false),
                        showSignUp: $onboardingViewModel.showSignUp
                    )
                    .environmentObject(onboardingViewModel)
                   
                } else {
                    LoginView(
                        isAuthenticated: .constant(false),
                        showSignUp: $onboardingViewModel.showSignUp
                    )
                    .environmentObject(onboardingViewModel)
                    
                }
            
            case .verification:
                VerifyCodeView(
                    email: onboardingViewModel.email ?? "",
                    isAuthenticated: .constant(false),
                    showVerifyCode: .constant(true)
                )
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
                    onboardingViewModel.triedBefore = selected.first ?? ""
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
                    onContinue: { onboardingViewModel.moveToNextStep() },
                    onBack: {
                        withAnimation { onboardingViewModel.currentStep = .whatsWorking }
                    }
                )
                .environmentObject(onboardingViewModel)

            case .cashCardMix:
                OnboardingCashCardMixView(
                    onContinue: { onboardingViewModel.moveToNextStep() },
                    onBack: {
                        withAnimation { onboardingViewModel.currentStep = .currencyIncome }
                    }
                )
                .environmentObject(onboardingViewModel)

            case .saveAnswers:
                OnboardingSaveAnswersView(
                    onEmailSignUp: {
                        onboardingViewModel.showSignUp = true
                        withAnimation { onboardingViewModel.currentStep = .authentication }
                    },
                    onBack: {
                        withAnimation { onboardingViewModel.currentStep = .cashCardMix }
                    }
                )
                .environmentObject(onboardingViewModel)

            case .complete:
                // Transition to main app
                EmptyView()
            }
        }
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

