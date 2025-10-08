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
            
            // Mark as ready
            isReady = true
            
            // Observe session changes
            observeSessionChanges()
        }
    }
    
    private func setupNotificationObservers() {
        // Process pending Siri intents when app becomes active
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.dataManager.processPendingSiriIntents()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func updateCurrentView() {
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
    }
    
    private func observeSessionChanges() {
        // Listen for authentication state changes
        Task {
            for await _ in sessionViewModel.$isAuthenticated.values {
                updateCurrentView()
            }
        }
        
        // Listen for onboarding completion
        Task {
            for await _ in sessionViewModel.$hasCompletedOnboarding.values {
                updateCurrentView()
            }
        }
        
        // Listen for initial setup completion
        Task {
            for await _ in sessionViewModel.$hasCompletedInitialSetup.values {
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
        currentView = .onboarding
    }
    
    // MARK: - View Building
    
    @ViewBuilder
    var currentViewContent: some View {
        switch currentView {
        case .loading:
            LoadingView()
        
        case .onboarding:
            OnboardingCoordinatorView()
                .environmentObject(onboardingViewModel)
                .environmentObject(sessionViewModel)
                .environmentObject(dataManager)
        
        case .main:
            RootView()
                .environmentObject(dataManager)
                .environmentObject(sessionViewModel)
        }
    }
}

// MARK: - Supporting Types

enum AppView {
    case loading
    case onboarding
    case main
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
            
            case .welcome:
                OnboardingView()
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
            
            case .howDidYouHear:
                HowDidYouHearView(
                    onContinue: { option in
                        // Store the selection
                        onboardingViewModel.howDidYouHear = option?.id
                        onboardingViewModel.currentStep = .notifications
                    },
                    onSkip: {
                        onboardingViewModel.currentStep = .notifications
                    }
                )
                .environmentObject(onboardingViewModel)
            
            case .notifications:
                NotificationPermissionView(
                    onPermissionGranted: {
                        onboardingViewModel.currentStep = .normaChat
                    },
                    onSkip: {
                        onboardingViewModel.currentStep = .normaChat
                    }
                )
                .environmentObject(onboardingViewModel)
            
            case .normaChat:
                if onboardingViewModel.showCompletionTransition {
                    OnboardingCompletionView()
                        .environmentObject(onboardingViewModel)
                        .environmentObject(sessionViewModel)
                } else {
                    NormaOnboardingChatView()
                        .environmentObject(onboardingViewModel)
                }
            
            case .complete:
                // Transition to main app
                EmptyView()
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                
                Text("Loading...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}
