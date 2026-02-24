//
//  OnboardingViewModel.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Onboarding Flow State
    @Published var currentStep: OnboardingStep = .landing
    @Published var showSignUp = false
    @Published var isVerified = false
    
    // Chat State
    @Published var messages: [ChatMessage] = []
    @Published var conversationHistory: [AnthropicMessage] = []
    @Published var userInput = ""
    @Published var isTyping = false
    
    // UI State
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isLoading = false
    @Published var showCompletionTransition = false
    
    // Authentication State
    @Published var email: String?
    private var temporaryPassword: String? // Store password temporarily for encryption setup
    
    // Collected Data
    @Published var collectedData = UserOnboardingData()

    // Extended Onboarding Responses (Digital Nomad focused)
    @Published var nomadType: String = ""
    @Published var runwayStatus: String = ""
    @Published var nomadChallenges: String = ""
    @Published var moneyStoppedYou: String = ""
    @Published var winningLooksLike: String = ""

    // MARK: - Dependencies
    private let sessionViewModel: SessionViewModel
    private let anthropicService = AnthropicService.shared
    private let supabaseService = SupabaseService.shared
    private let appleSignInManager = AppleSignInManager()
    private let googleSignInManager = GoogleSignInManager()

    // Preview mode view model - owned here to persist throughout onboarding
    var previewModeViewModel = PreviewModeViewModel()

    // MARK: - Initialization

    init(sessionViewModel: SessionViewModel) {
        self.sessionViewModel = sessionViewModel
    }
    
    // MARK: - Onboarding Flow Methods
    
    func startOnboardingFlow() {
        resetOnboardingState()
        currentStep = .landing
    }
    
    func moveToNextStep() {
        withAnimation {
            currentStep = currentStep.next()
        }
    }
    
    func completeOnboarding() {
        // Track onboarding completed
        AnalyticsService.shared.track(.onboardingCompleted(durationSeconds: 0))

        sessionViewModel.completeOnboarding()
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, fullName: String) async throws {
        isLoading = true
        clearError()

        // Track sign up started
        AnalyticsService.shared.track(.signUpStarted(method: .email))

        // Split name into first and last name (simple approach)
        let nameParts = fullName.split(separator: " ")
        let firstName = String(nameParts.first ?? "")
        let lastName = nameParts.count > 1 ? String(nameParts[1...].joined(separator: " ")) : ""

        do {
            _ = try await supabaseService.signUp(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )

            // Store email, password, and name for later use
            self.email = email
            self.temporaryPassword = password // Store password for encryption setup
            collectedData.name = fullName

            isLoading = false
            currentStep = .verification
        } catch {
            isLoading = false
            AnalyticsService.shared.track(.signUpFailed(method: .email, error: error.localizedDescription))
            throw error
        }
    }
    
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        clearError()

        // Track sign in started
        AnalyticsService.shared.track(.signInStarted(method: .email))

        do {
            _ = try await supabaseService.signIn(email: email, password: password)

            // For login, authenticate and handle success
            // This stores credentials in shared keychain for Share Extension
            await sessionViewModel.handleAuthenticationSuccess()

            // Unlock encryption using the password
            // This derives the master key and stores it in keychain for the session
            do {
                print("🔐 Unlocking encryption for returning user...")
                try await sessionViewModel.unlockEncryptionForReturningUser(password: password)
                print("✅ Encryption unlocked successfully")
            } catch {
                // Don't block login if encryption unlock fails
                // User may not have encryption set up, or there may be an issue
                print("⚠️ Failed to unlock encryption: \(error)")
                // We'll handle this gracefully - user can still use the app
            }

            // Returning users have already completed onboarding
            sessionViewModel.hasCompletedOnboarding = true
            sessionViewModel.hasCompletedInitialSetup = true

            isLoading = false

            // Track sign in completed
            AnalyticsService.shared.track(.signInCompleted(method: .email))

            print("🔑 Login complete - navigating to main app")
            currentStep = .complete

            return true

        } catch {
            isLoading = false
            AnalyticsService.shared.track(.signInFailed(method: .email, error: error.localizedDescription))
            showError(error.localizedDescription)
            return false
        }
    }
    
    func resendCode(email: String) async throws {
        isLoading = true
        clearError()

        do {
            try await supabaseService.resendOTP(email: email)
            isLoading = false
        } catch {
            isLoading = false
            throw error
        }
    }

    func verifyCode(email: String, code: String) async throws {
        isLoading = true
        clearError()

        do {
            _ = try await supabaseService.verifyOTP(email: email, code: code)

            // Track sign up completed (verification is the final step of email sign up)
            AnalyticsService.shared.track(.signUpCompleted(method: .email))

            // Notify SessionViewModel of successful authentication
            await sessionViewModel.handleAuthenticationSuccess()

            // Automatically set up encryption for new users
            if let password = temporaryPassword {
                do {
                    print("🔐 Setting up encryption for new user...")
                    let recoveryPhrase = try await sessionViewModel.setupEncryptionForNewUser(password: password)

                    // Store recovery phrase securely
                    if let userId = sessionViewModel.currentUser?.userId {
                        let userKeyManager = UserKeyManager(supabaseService: sessionViewModel.supabaseService)
                        userKeyManager.storeRecoveryPhrase(recoveryPhrase, for: userId)
                        print("✅ Encryption setup complete for new user")
                    }

                    // Clear temporary password for security
                    temporaryPassword = nil

                } catch {
                    print("❌ Failed to setup encryption for new user: \(error)")
                    // Don't block the onboarding flow - user can continue without encryption
                    temporaryPassword = nil
                }
            }

            isVerified = true
            isLoading = false
            // Don't update currentStep here - let the view handle navigation after transition
        } catch {
            isLoading = false
            throw error
        }
    }
    
    func proceedToWelcome() {
        currentStep = .nomadWelcome
    }

    /// Finalize onboarding by saving profile data from preview mode and completing
    func finalizeOnboarding() async {
        await saveProfileDataFromPreviewMode()
        completeOnboarding()
    }

    /// Handle preview mode completion for already-authenticated users
    /// Saves collected data and proceeds to the welcome/question screens
    func handleAuthenticatedPreviewModeCompletion() async {
        await saveProfileDataFromPreviewMode()
        currentStep = .nomadWelcome
    }

    // MARK: - Apple Sign In Methods

    /// Sign in with Apple
    /// - Parameter fromPreviewMode: Whether this is being called from preview mode (to trigger data transfer)
    /// - Returns: True if sign-in was successful
    func signInWithApple(fromPreviewMode: Bool = false) async -> Bool {
        isLoading = true
        clearError()

        // Track sign in started
        AnalyticsService.shared.track(.signInStarted(method: .apple))

        do {
            // Step 1: Get Apple credentials
            print("🍎 Step 1: Getting Apple credentials...")
            let appleResult = try await appleSignInManager.signIn()
            print("🍎 Step 1 complete: Got idToken, nonce: \(appleResult.nonce != nil), name: \(appleResult.fullName ?? "nil"), email: \(appleResult.email ?? "nil")")

            // Step 2: Sign in with Supabase using the Apple ID token
            print("🍎 Step 2: Signing in with Supabase...")
            let session = try await supabaseService.signInWithApple(
                idToken: appleResult.idToken,
                nonce: appleResult.nonce,
                firstName: appleResult.firstName,
                lastName: appleResult.lastName
            )
            print("🍎 Step 2 complete: Supabase session created, user: \(session.user.id)")

            // Step 3: Store name if available (for profile creation)
            if let fullName = appleResult.fullName {
                collectedData.name = fullName
                previewModeViewModel.userName = fullName  // Sync to previewModeViewModel for profile save
                print("🍎 Step 3: Stored name from Apple: \(fullName)")
            } else if let userName = previewModeViewModel.userName {
                // Fall back to preview mode name
                collectedData.name = userName
                print("🍎 Step 3: Using preview mode name: \(userName)")
            }

            // Store email if available
            if let email = appleResult.email {
                self.email = email
            }

            // Step 4: Notify SessionViewModel of successful authentication
            print("🍎 Step 4: Handling auth success...")
            await sessionViewModel.handleAuthenticationSuccess()
            print("🍎 Step 4 complete")

            // Step 5: Set up or unlock encryption using Apple's stable userIdentifier
            let isNewUser = !sessionViewModel.hasCompletedOnboarding
            if isNewUser {
                do {
                    print("🔐 Setting up encryption for new Apple user...")
                    let recoveryPhrase = try await sessionViewModel.setupEncryptionForNewUser(password: appleResult.userIdentifier)
                    if let userId = sessionViewModel.currentUser?.userId {
                        let userKeyManager = UserKeyManager(supabaseService: sessionViewModel.supabaseService)
                        userKeyManager.storeRecoveryPhrase(recoveryPhrase, for: userId)
                    }
                    print("✅ Encryption setup complete for Apple user")
                } catch {
                    print("⚠️ Failed to setup encryption for Apple user: \(error)")
                }
            } else {
                do {
                    print("🔐 Unlocking encryption for returning Apple user...")
                    try await sessionViewModel.unlockEncryptionForReturningUser(password: appleResult.userIdentifier)
                    print("✅ Encryption unlocked for Apple user")
                } catch {
                    print("⚠️ Failed to unlock encryption for Apple user: \(error)")
                }
            }

            // Step 6: If from preview mode, save profile and transfer data
            if fromPreviewMode {
                print("🍎 Step 6: Saving profile from preview mode...")
                await saveProfileDataFromPreviewMode()
                print("🍎 Step 6 complete")
            }

            isLoading = false

            // Track sign in completed
            AnalyticsService.shared.track(.signInCompleted(method: .apple))

            // For returning users who have completed onboarding, go to main app
            if sessionViewModel.hasCompletedOnboarding && sessionViewModel.hasCompletedInitialSetup {
                print("🍎 Returning user - navigating to main app")
                currentStep = .complete
            } else if fromPreviewMode {
                // New user coming from preview mode - data already collected, proceed to welcome screens
                print("🍎 New user from preview mode - navigating to nomad welcome")
                currentStep = .nomadWelcome
            } else {
                // New user who hasn't been through preview mode - send them through "Talk to Norma" first
                print("🍎 New user - navigating to preview mode to collect info")
                currentStep = .previewMode
            }

            return true

        } catch {
            isLoading = false
            print("🍎 ❌ Apple Sign In error: \(error)")

            // Don't show error for user cancellation
            if let authError = error as? AuthError,
               case .appleSignInError(let message) = authError,
               message.contains("canceled") {
                // User canceled - just return false without showing error
                print("🍎 User canceled sign in")
                return false
            }

            AnalyticsService.shared.track(.signInFailed(method: .apple, error: error.localizedDescription))
            showError(error.localizedDescription)
            return false
        }
    }

    /// Sign in with Apple specifically from preview mode (handles data transfer)
    func signInWithAppleFromPreviewMode() async {
        _ = await signInWithApple(fromPreviewMode: true)
    }

    // MARK: - Google Sign In Methods

    /// Sign in with Google
    /// - Parameter fromPreviewMode: Whether this is being called from preview mode (to trigger data transfer)
    /// - Returns: True if sign-in was successful
    func signInWithGoogle(fromPreviewMode: Bool = false) async -> Bool {
        isLoading = true
        clearError()

        // Track sign in started
        AnalyticsService.shared.track(.signInStarted(method: .google))

        do {
            // Step 1: Get Google credentials
            print("🔵 Step 1: Getting Google credentials...")
            let googleResult = try await googleSignInManager.signIn()
            print("🔵 Step 1 complete: Got idToken, name: \(googleResult.fullName ?? "nil"), email: \(googleResult.email ?? "nil")")

            // Step 2: Sign in with Supabase using the Google ID token
            print("🔵 Step 2: Signing in with Supabase...")
            let session = try await supabaseService.signInWithGoogle(
                idToken: googleResult.idToken,
                accessToken: googleResult.accessToken,
                firstName: googleResult.firstName,
                lastName: googleResult.lastName
            )
            print("🔵 Step 2 complete: Supabase session created, user: \(session.user.id)")

            // Step 3: Store name if available (for profile creation)
            if let fullName = googleResult.fullName {
                collectedData.name = fullName
                previewModeViewModel.userName = fullName  // Sync to previewModeViewModel for profile save
                print("🔵 Step 3: Stored name from Google: \(fullName)")
            } else if let userName = previewModeViewModel.userName {
                // Fall back to preview mode name
                collectedData.name = userName
                print("🔵 Step 3: Using preview mode name: \(userName)")
            }

            // Store email if available
            if let email = googleResult.email {
                self.email = email
            }

            // Step 4: Notify SessionViewModel of successful authentication
            print("🔵 Step 4: Handling auth success...")
            await sessionViewModel.handleAuthenticationSuccess()
            print("🔵 Step 4 complete")

            // Step 5: Set up or unlock encryption using Google's stable userIdentifier
            let isNewUser = !sessionViewModel.hasCompletedOnboarding
            if isNewUser {
                do {
                    print("🔐 Setting up encryption for new Google user...")
                    let recoveryPhrase = try await sessionViewModel.setupEncryptionForNewUser(password: googleResult.userIdentifier)
                    if let userId = sessionViewModel.currentUser?.userId {
                        let userKeyManager = UserKeyManager(supabaseService: sessionViewModel.supabaseService)
                        userKeyManager.storeRecoveryPhrase(recoveryPhrase, for: userId)
                    }
                    print("✅ Encryption setup complete for Google user")
                } catch {
                    print("⚠️ Failed to setup encryption for Google user: \(error)")
                }
            } else {
                do {
                    print("🔐 Unlocking encryption for returning Google user...")
                    try await sessionViewModel.unlockEncryptionForReturningUser(password: googleResult.userIdentifier)
                    print("✅ Encryption unlocked for Google user")
                } catch {
                    print("⚠️ Failed to unlock encryption for Google user: \(error)")
                }
            }

            // Step 6: If from preview mode, save profile and transfer data
            if fromPreviewMode {
                print("🔵 Step 6: Saving profile from preview mode...")
                await saveProfileDataFromPreviewMode()
                print("🔵 Step 6 complete")
            }

            isLoading = false

            // Track sign in completed
            AnalyticsService.shared.track(.signInCompleted(method: .google))

            // For returning users who have completed onboarding, go to main app
            if sessionViewModel.hasCompletedOnboarding && sessionViewModel.hasCompletedInitialSetup {
                print("🔵 Returning user - navigating to main app")
                currentStep = .complete
            } else if fromPreviewMode {
                // New user coming from preview mode - data already collected, proceed to welcome screens
                print("🔵 New user from preview mode - navigating to nomad welcome")
                currentStep = .nomadWelcome
            } else {
                // New user who hasn't been through preview mode - send them through "Talk to Norma" first
                print("🔵 New user - navigating to preview mode to collect info")
                currentStep = .previewMode
            }

            return true

        } catch {
            isLoading = false
            print("🔵 ❌ Google Sign In error: \(error)")

            // Don't show error for user cancellation
            if let authError = error as? AuthError,
               case .googleSignInError(let message) = authError,
               message.contains("canceled") {
                // User canceled - just return false without showing error
                print("🔵 User canceled sign in")
                return false
            }

            AnalyticsService.shared.track(.signInFailed(method: .google, error: error.localizedDescription))
            showError(error.localizedDescription)
            return false
        }
    }

    /// Sign in with Google specifically from preview mode (handles data transfer)
    func signInWithGoogleFromPreviewMode() async {
        _ = await signInWithGoogle(fromPreviewMode: true)
    }

    // MARK: - Chat Methods
    
    func startConversation() async {
        isTyping = true
        clearError()
        
        do {
            let response = try await anthropicService.startOnboardingConversation(userName: collectedData.name)
            
            isTyping = false
            addNormaMessage(response)
            conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(response)))
            
        } catch {
            isTyping = false
            showError(error.localizedDescription)
        }
    }
    
    func sendMessage(_ messageText: String) async {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }

        userInput = ""
        clearError()

        // Add user message
        addUserMessage(trimmedMessage)
        conversationHistory.append(AnthropicMessage(role: "user", content: .text(trimmedMessage)))

        // Only get AI response if we haven't completed onboarding
        if !showCompletionTransition {
            // Delay showing typing indicator to make fast responses feel instant
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Get AI response
            isTyping = true
            
            do {
                let response = try await anthropicService.continueOnboardingConversation(
                    conversationHistory: conversationHistory,
                    userMessage: trimmedMessage,
                    userName: collectedData.name
                )
                
                isTyping = false
                
                // Handle different response types
                switch response {
                case .text(let textResponse):
                    // Regular text response - add to chat
                    addNormaMessage(textResponse)
                    conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(textResponse)))
                    
                case .toolUse(let id, let name, let input):
                    // Claude used the extraction tool - process the data
                    if name == "extract_user_data" {
                        await handleDataExtraction(toolId: id, input: input)
                    }
                    
                case .toolResult(_, _):
                    // Tool result - shouldn't happen in this flow
                    break
                }
                
            } catch {
                isTyping = false
                print(error)
//                showError(error.localizedDescription)
            }
        } else {
            // If we're transitioning, stop the typing indicator
            isTyping = false
        }
    }
    
    // MARK: - Private Methods
    
    private func resetOnboardingState() {
        showSignUp = false
        isVerified = false
        messages.removeAll()
        conversationHistory.removeAll()
        userInput = ""
        isTyping = false
        clearError()
        isLoading = false
        collectedData = UserOnboardingData()
        
        // Clear sensitive data
        email = nil
        temporaryPassword = nil
    }
    
    private func addUserMessage(_ text: String) {
        withAnimation {
            messages.append(ChatMessage(role: .user, content: text))
        }
    }

    private func addNormaMessage(_ text: String) {
        withAnimation {
            messages.append(ChatMessage(role: .assistant, content: text))
        }
    }
    
    private func clearError() {
        showError = false
        errorMessage = ""
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
        
        // Auto-hide error after 5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await MainActor.run {
                clearError()
            }
        }
    }
    
    private func handleDataExtraction(toolId: String, input: [String: Any]) async {
        do {
            
            // Parse the tool input directly
            let name = input["name"] as? String ?? ""
            let currency = input["currency"] as? String ?? "USD"
            
            // Handle different numeric types for monthlyIncome
            var monthlyIncome: Double = 0
            if let incomeDouble = input["monthlyIncome"] as? Double {
                monthlyIncome = incomeDouble
            } else if let incomeInt = input["monthlyIncome"] as? Int {
                monthlyIncome = Double(incomeInt)
            } else if let incomeString = input["monthlyIncome"] as? String, let parsed = Double(incomeString) {
                monthlyIncome = parsed
            }
            
            // Parse freedom fund (similar to monthlyIncome)
            var freedomFund: Double = 0
            if let fundDouble = input["freedomFund"] as? Double {
                freedomFund = fundDouble
            } else if let fundInt = input["freedomFund"] as? Int {
                freedomFund = Double(fundInt)
            } else if let fundString = input["freedomFund"] as? String, let parsed = Double(fundString) {
                freedomFund = parsed
            }

            let painPoint = input["painPoint"] as? String ?? ""
            let reminderPreference = input["reminderPreference"] as? String ?? ""

            let extractedData = UserOnboardingData(
                name: name,
                currency: currency,
                monthlyIncome: monthlyIncome,
                freedomFund: freedomFund,
                painPoint: painPoint,
                reminderPreference: reminderPreference
            )


            // Check if we have ALL required data
            if !extractedData.name.isEmpty &&
               !extractedData.currency.isEmpty &&
               !extractedData.painPoint.isEmpty &&
               extractedData.monthlyIncome > 0 &&
               !extractedData.reminderPreference.isEmpty {
                
                collectedData = extractedData
                
                // Add the tool use to conversation history
                conversationHistory.append(AnthropicMessage(role: "assistant", content: .toolUse(id: toolId, name: "extract_user_data", input: input)))
                
                // Add a friendly completion message to chat
                addNormaMessage("Perfect! I have all the information I need. Let's get you set up! 🎉")
                conversationHistory.append(AnthropicMessage(role: "assistant", content: .text("Perfect! I have all the information I need. Let's get you set up! 🎉")))
                
                // Save the profile data but DON'T complete onboarding yet
                // The completion view will handle that after showing animations
                await saveProfileData()
                
                // Wait a moment to let user read the final message, then show completion view
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                // Set flag to show completion view
                await MainActor.run {
                    showCompletionTransition = true
                }
            } else {
                print("Data incomplete from tool - name: '\(extractedData.name)', currency: '\(extractedData.currency)', painPoint: '\(extractedData.painPoint)', income: \(extractedData.monthlyIncome), freedomFund: \(extractedData.freedomFund), reminder: '\(extractedData.reminderPreference)'")
                // This shouldn't happen if Claude is using the tool correctly
                addNormaMessage("I'm still collecting some information. Let's continue our conversation!")
            }
        }
    }
    
    private func saveProfileData() async {
        do {
            // This method is similar to sessionViewModel.saveOnboardingData
            // but doesn't set completion flags
            
            // Get current authenticated user
            guard let supabaseUser = supabaseService.currentUser else {
                print("No authenticated user found for profile save")
                return
            }
            
            // Convert reminder preference to days
            let reminderDays: Int
            switch collectedData.reminderPreference {
            case "1 day before":
                reminderDays = 1
            case "3 days before":
                reminderDays = 3
            case "1 week before":
                reminderDays = 7
            case "No reminders":
                reminderDays = 0
            default:
                reminderDays = 3
            }
            
            // Create profile settings
            let settings = ProfileSettings(
                currency: collectedData.currency,
                monthlyIncome: collectedData.monthlyIncome,
                freedomFund: collectedData.freedomFund,
                painPoint: collectedData.painPoint,
                notificationsEnabled: collectedData.reminderPreference != "No reminders",
                billReminderDays: reminderDays
            )
            
            // Check if profile already exists
            if var existingProfile = sessionViewModel.currentUser {
                // Update existing profile
                existingProfile.monthlyIncome = collectedData.monthlyIncome
                existingProfile.freedomFund = collectedData.freedomFund
                existingProfile.painPoint = collectedData.painPoint
                existingProfile.settings = settings
                await sessionViewModel.updateUserProfile(existingProfile)
            } else {
                // Create new profile
                let newProfile = Profile(
                    userId: supabaseUser.id.uuidString.lowercased(),
                    email: supabaseUser.email ?? "",
                    name: collectedData.name,
                    monthlyIncome: collectedData.monthlyIncome,
                    freedomFund: collectedData.freedomFund,
                    painPoint: collectedData.painPoint,
                    settings: settings
                )
                try await sessionViewModel.createUserProfile(newProfile)
            }

            // Transfer preview mode data (bills, budgets, expenses) to the real account
            await transferPreviewModeData(userId: supabaseUser.id.uuidString.lowercased())

        } catch {
            print("Failed to save profile data: \(error)")
            // Still allow completion view to show
        }
    }

    /// Save profile data using values collected in preview mode
    private func saveProfileDataFromPreviewMode() async {
        do {
            // Get current authenticated user
            guard let supabaseUser = supabaseService.currentUser else {
                print("No authenticated user found — aborting profile save")
                return
            }

            // Get data from preview mode view model
            let name = previewModeViewModel.userName ?? collectedData.name
            let currency = previewModeViewModel.userCurrency ?? "USD"
            let monthlyIncome = previewModeViewModel.userIncome ?? 0
            let freedomFund = previewModeViewModel.userFreedomFund ?? 0
            let painPoint = ""

            // Validation warnings for missing onboarding data
            if monthlyIncome == 0 {
                print("⚠️ WARNING: Monthly income not collected during onboarding!")
            }
            if freedomFund == 0 {
                print("⚠️ WARNING: Freedom fund not collected during onboarding!")
            }



            // Default reminder days (can be customized later in settings)
            let reminderDays = 3

            // Create profile settings
            let settings = ProfileSettings(
                currency: currency,
                monthlyIncome: monthlyIncome,
                freedomFund: freedomFund,
                painPoint: painPoint,
                notificationsEnabled: true,
                billReminderDays: reminderDays
            )

            // Create onboarding insights from question responses
            let insights = OnboardingInsights(
                nomadType: nomadType.isEmpty ? nil : nomadType,
                runwayStatus: runwayStatus.isEmpty ? nil : runwayStatus,
                nomadChallenges: nomadChallenges.isEmpty ? nil : nomadChallenges,
                moneyStoppedYou: moneyStoppedYou.isEmpty ? nil : moneyStoppedYou,
                winningLooksLike: winningLooksLike.isEmpty ? nil : winningLooksLike
            )

            // Check if profile exists in the database (must have an id)
            let hasDbProfile = sessionViewModel.currentUser?.id != nil

            if hasDbProfile, var existingProfile = sessionViewModel.currentUser {
                // Update existing profile in database
                existingProfile.monthlyIncome = monthlyIncome
                existingProfile.freedomFund = freedomFund
                existingProfile.painPoint = painPoint
                existingProfile.settings = settings
                existingProfile.onboardingInsights = insights
                await sessionViewModel.updateUserProfile(existingProfile)
            } else {
                // Create new profile
                let newProfile = Profile(
                    userId: supabaseUser.id.uuidString.lowercased(),
                    email: supabaseUser.email ?? "",
                    name: name,
                    monthlyIncome: monthlyIncome,
                    freedomFund: freedomFund,
                    painPoint: painPoint,
                    settings: settings,
                    onboardingInsights: insights
                )
                try await sessionViewModel.createUserProfile(newProfile)
            }

            // Transfer preview mode data (bills, budgets, expenses) to the real account
            await transferPreviewModeData(userId: supabaseUser.id.uuidString.lowercased())

        } catch {
            print("Failed to save profile from preview mode: \(error)")
        }
    }

    /// Transfer bills and expenses from preview mode to the real account
    private func transferPreviewModeData(userId: String) async {
        guard previewModeViewModel.hasUserDataToTransfer else {
            print("📦 No preview mode data to transfer")
            return
        }

        print("📦 Transferring preview mode data to user: \(userId)")

        // Get the data ready for transfer (with real userId)
        let billsToTransfer = previewModeViewModel.getUserBillsForTransfer(withUserId: userId)
        let expensesToTransfer = previewModeViewModel.getUserExpensesForTransfer(withUserId: userId)

        // Save bills (encrypted via Edge Function)
        for bill in billsToTransfer {
            do {
                try await sessionViewModel.addBill(bill)
                print("✅ Transferred bill: \(bill.name)")
            } catch {
                print("❌ Failed to transfer bill \(bill.name): \(error)")
            }
        }

        // Save expenses (encrypted via Edge Function)
        for expense in expensesToTransfer {
            do {
                try await sessionViewModel.addExpense(expense)
                print("✅ Transferred expense: \(expense.name)")
            } catch {
                print("❌ Failed to transfer expense \(expense.name): \(error)")
            }
        }

        print("📦 Preview mode data transfer complete")
    }
}

// MARK: - Supporting Types

enum OnboardingStep: CaseIterable {
    case landing
    case previewMode
    case authentication
    case verification

    // Welcome Section (2 screens) - Post-auth context setting
    case nomadWelcome         // Stats: 40M+ nomads, 65+ visas, 3-5 currencies
    case nomadType            // What kind of nomad are you?

    // Personal Section (4 screens) - Digital Nomad focused
    case runwayCheck          // "Be honest — how's your runway?"
    case nomadChallenges      // "What's actually hard about money on the road?"
    case moneyStoppedYou      // "Has money ever stopped you?"
    case winningLooksLike     // "What does winning look like?"

    // Final Screens (2 screens)
    case privacy              // Your data is safe - encryption, trust
    case welcomeJourney       // Celebration - confetti, coins, "best decision"

    case notifications
    case complete

    func next() -> OnboardingStep {
        let allCases = OnboardingStep.allCases
        guard let currentIndex = allCases.firstIndex(of: self),
              currentIndex < allCases.count - 1 else {
            return .complete
        }
        return allCases[currentIndex + 1]
    }
}

