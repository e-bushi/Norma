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

    /// Mirrors `logout()` but performs the irreversible account-delete first.
    /// Without resetting the onboarding flow + currentView here the app would
    /// re-render the OnboardingViewModel at its last `currentStep` (often
    /// "save answers"), since `sessionViewModel.deleteAccount` only flips the
    /// auth flag — it doesn't know about the onboarding flow state.
    func deleteAccount() async throws {
        try await sessionViewModel.deleteAccount()
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
                .environmentObject(self.dataManager)
                .environmentObject(self.sessionViewModel)
                .environmentObject(self)
        }
    }
}

// MARK: - Paywall gate

/// Wraps the main app and swaps in the PaywallView when the user is not
/// subscribed and not in a trial. Observes SubscriptionManager so the gate
/// dissolves automatically once a purchase or restore lands.
struct PaywallGate<Content: View>: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack {
            if hasAccess {
                content()
                    .transition(.opacity)
            } else {
                PaywallView(context: paywallContext)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasAccess)
        .task {
            // Refresh subscription status on entry so a returning user's
            // gate reflects the latest reality (trial may have expired
            // server-side, purchase may have been made on another device).
            await subscriptionManager.checkSubscriptionStatus()
        }
    }

    private var hasAccess: Bool {
        subscriptionManager.hasActiveSubscription || subscriptionManager.isInFreeTrial
    }

    /// Returning users who've already burned their trial see the
    /// "your trial wrapped" framing; everyone else sees the onboarding
    /// trial-offer framing.
    private var paywallContext: PaywallContext {
        if subscriptionManager.hasUsedFreeTrial && !subscriptionManager.isInFreeTrial {
            return .trialExpired
        }
        return .onboarding
    }
}

// MARK: - Supporting Types

enum AppView {
    case loading
    case onboarding
    case main
}

enum MainLayerViewType: Hashable {
    case settings
    case notes
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

            case .voicePracticeIntro:
                OnboardingIntroInterstitialView(
                    phases: [
                        "now let's try something different.",
                        "say a money thought out loud — norma will catch it."
                    ],
                    onContinue: { onboardingViewModel.moveToNextStep() }
                )

            case .voicePractice:
                OnboardingVoicePracticeView(
                    onContinue: { onboardingViewModel.moveToNextStep() }
                )

            case .notesValue:
                OnboardingIntroInterstitialView(
                    phases: [
                        "you've got the hang of it.",
                        "you can quickly jot your thoughts before you forget now.",
                        "your notes are the gold.",
                        "write anything — i make sense of all of it.",
                        "now, a few quick facts about your money."
                    ],
                    holdDuration: 2.0,
                    onContinue: { onboardingViewModel.moveToNextStep() }
                )

            case .currencyIncome:
                OnboardingCurrencyIncomeView(
                    onContinue: { onboardingViewModel.moveToNextStep() }
                )
                .environmentObject(onboardingViewModel)

            case .saveAnswers:
                OnboardingSaveAnswersView(
                    onEmailSignUp: {
                        onboardingViewModel.showSignUp = true
                        withAnimation { onboardingViewModel.currentStep = .authentication }
                    },
                    onBack: {
                        withAnimation { onboardingViewModel.currentStep = .currencyIncome }
                    }
                )
                .environmentObject(onboardingViewModel)

            case .readyToStart:
                OnboardingCelebrationView(
                    phrases: [
                        "hi, i'm norma.",
                        "i'm glad you're finally here.",
                        "start with a note — tell me what your bills are."
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

