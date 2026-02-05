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
    @Published var mainLayerView: MainLayerViewType = .chat

    /// Only show the fancy loading view if user is authenticated (loading their data)
    var shouldShowAppLoadingView: Bool {
        sessionViewModel.isAuthenticated && !userStartedApp
    }
    
    // MARK: - Core Managers and ViewModels

    let dataManager: DataManager
    let sessionViewModel: SessionViewModel

    // Challenge ViewModel for daily calculations during loading
    private var challengeViewModel: ChallengeViewModel?

    // Lazy-loaded ViewModels
    lazy var onboardingViewModel = OnboardingViewModel(sessionViewModel: sessionViewModel)
    lazy var conversationManager = ConversationManager(dataManager: dataManager, sessionViewModel: sessionViewModel)
    
    // MARK: - Initialization
    
    init() {
        // Initialize core components
        self.dataManager = DataManager()
        self.sessionViewModel = SessionViewModel(dataManager: dataManager)
        
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

            // Add delay for authenticated users to show loading screen
            if sessionViewModel.isAuthenticated {
                // Run daily calculations during loading to create any pending rewards
                await runDailyCalculationsDuringLoading()

                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds remaining for loading
                dataLoaded = true
            } else {
                // Non-authenticated users skip loading screen
                isReady = true
            }

            // Observe session changes
            observeSessionChanges()
        }
    }

    /// Run daily challenge calculations during app loading.
    /// This creates any pending rewards BEFORE fetchAndQueuePendingRewards() runs.
    private func runDailyCalculationsDuringLoading() async {
        // Create a temporary ChallengeViewModel to run calculations
        let tempChallengeVM = ChallengeViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
        self.challengeViewModel = tempChallengeVM

        // Load challenge data
        tempChallengeVM.loadChallenge()
        await tempChallengeVM.loadChallengeStats()

        // Run daily calculations - this creates rewards and persists them to backend
        await tempChallengeVM.runDailyCalculations()

        print("🎁 Daily calculations completed during loading")
    }

    /// Called when user taps Start button on loading screen
    func userTappedStart() {
        userStartedApp = true
        isReady = true

        // Now fetch pending rewards that were created during loading
        Task {
            await RewardQueueManager.shared.fetchAndQueuePendingRewards()
        }
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
            AppLoadingView(isDataReady: dataLoaded, onStart: { self.userTappedStart() })

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
    case currencyConverter
    case overview
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

            case .previewMode:
                PreviewModeChatView()
                    .environmentObject(sessionViewModel)
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

            // MARK: - Extended Onboarding: Personal Questions (4 screens - Digital Nomad focused)

            case .runwayCheck:
                OnboardingQuestionView(question: .runwayCheck) { selected in
                    onboardingViewModel.runwayStatus = selected
                    onboardingViewModel.moveToNextStep()
                }

            case .nomadChallenges:
                OnboardingQuestionView(question: .nomadChallenges) { selected in
                    onboardingViewModel.nomadChallenges = selected
                    onboardingViewModel.moveToNextStep()
                }

            case .moneyStoppedYou:
                OnboardingQuestionView(question: .moneyStoppedYou) { selected in
                    onboardingViewModel.moneyStoppedYou = selected
                    onboardingViewModel.moveToNextStep()
                }

            case .winningLooksLike:
                OnboardingQuestionView(question: .winningLooksLike) { selected in
                    onboardingViewModel.winningLooksLike = selected
                    onboardingViewModel.moveToNextStep()
                }

            // MARK: - Final Screens: Privacy & Welcome

            case .privacy:
                PrivacyView {
                    onboardingViewModel.moveToNextStep()
                }

            case .welcomeJourney:
                WelcomeJourneyView {
                    onboardingViewModel.moveToNextStep()
                }

            case .notifications:
                NotificationPermissionView(
                    onPermissionGranted: {
                        Task {
                            await onboardingViewModel.finalizeOnboarding()
                        }
                    },
                    onSkip: {
                        Task {
                            await onboardingViewModel.finalizeOnboarding()
                        }
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

