//
//  OnboardingViewModel.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class OnboardingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Onboarding Flow State
    @Published var currentStep: OnboardingStep = .landing
    @Published var showSignUp = false
    @Published var isVerified = false
    
    // UI State
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isLoading = false
    
    // Authentication State
    @Published var email: String?
    private var temporaryPassword: String? // Store password temporarily for encryption setup
    
    // Collected Data
    @Published var collectedData = UserOnboardingData()

    // Extended Onboarding Responses (Digital Nomad focused)
    // Onboarding answers (May 2026 — financial-journal positioning).
    @Published var triedBefore: [String] = []      // multi-select
    @Published var messyMoney: [String] = []        // multi-select
    @Published var writingFrequency: String = ""
    @Published var incomeShape: String = ""
    @Published var whatsWorking: String = ""

    // Money-shaped-thoughts questions (O3e/f/g).
    @Published var moneyShapedThoughts: String = ""
    @Published var tabsCartsCameraRoll: String = ""
    @Published var thoughtsCameBack: String = ""

    /// True once the user has reached the end of the question flow.
    /// Used to distinguish Apple/Google sign-in from L1 (no answers yet)
    /// vs. from the end-of-flow auth screen (answers in hand).
    var hasAnsweredOnboarding: Bool {
        !whatsWorking.isEmpty
    }

    // MARK: - Dependencies
    private let sessionViewModel: SessionViewModel
    private let supabaseService = SupabaseService.shared
    private let appleSignInManager = AppleSignInManager()
    private let googleSignInManager = GoogleSignInManager()
    var modelContainer: ModelContainer?

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
    
    /// Called after email verification succeeds. Onboarding questions were
    /// already answered before auth, so persist them and show the welcome
    /// interstitial before the app.
    func proceedToWelcome() {
        Task { await proceedToReadyToStart() }
    }

    /// Finalize onboarding by saving profile data and completing
    func finalizeOnboarding() async {
        await saveProfileData()
        completeOnboarding()
    }

    /// New-user completion: persist the collected answers, then show the
    /// post-auth welcome interstitial (`readyToStart`). The interstitial's
    /// continue action calls `completeOnboarding()`, which flips the app to
    /// the main view. Used by the Apple/Google/email new-user paths so the
    /// "hi, i'm norma" screen is the last thing before the app.
    func proceedToReadyToStart() async {
        await saveProfileData()
        withAnimation { currentStep = .readyToStart }
    }

    // MARK: - Apple Sign In Methods

    /// Sign in with Apple
    /// - Returns: True if sign-in was successful
    func signInWithApple(requireExistingAccount: Bool = false) async -> Bool {
        isLoading = true
        clearError()

        // Track sign in started
        AnalyticsService.shared.track(.signInStarted(method: .apple))

        do {
            // Step 1: Get Apple credentials
            print("🍎 Step 1: Getting Apple credentials...")
            let appleResult = try await appleSignInManager.signIn()
            print("🍎 Step 1 complete: Got idToken, nonce: \(appleResult.nonce != nil), name: \(appleResult.fullName ?? "nil"), email: \(appleResult.email ?? "nil")")

            // Step 1.5: On the login path, refuse silent account creation. If no
            // Apple identity with this `sub` exists yet, bail before Supabase
            // creates an auth.users row.
            if requireExistingAccount {
                let exists = try await supabaseService.appleIdentityExists(appleSub: appleResult.userIdentifier)
                if !exists {
                    print("🍎 ❌ No existing account for this Apple ID — refusing auto-create")
                    throw AuthError.accountNotFound
                }
            }

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
                print("🍎 Step 3: Stored name from Apple: \(fullName)")
            }

            // Store email if available
            if let email = appleResult.email {
                self.email = email
            }

            // Step 4: Notify SessionViewModel of successful authentication
            print("🍎 Step 4: Handling auth success...")
            await sessionViewModel.handleAuthenticationSuccess()
            print("🍎 Step 4 complete")

            // Step 5: Set up or unlock encryption using Apple's stable userIdentifier.
            // `hasCompletedOnboarding` is profile-driven and can be false even
            // for a user who already set up encryption (e.g. their profile
            // write failed). The authoritative signal is whether
            // `user_encryption_keys` already has a row server-side.
            let userIdForKeyCheck = supabaseService.currentUser?.id.uuidString.lowercased() ?? sessionViewModel.currentUser?.userId ?? ""
            let keyManager = UserKeyManager(supabaseService: sessionViewModel.supabaseService)
            let isNewUser = !(await keyManager.hasEncryptionEnabled(for: userIdForKeyCheck))
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
                    print("❌ Failed to setup encryption for Apple user: \(error)")
                    await MainActor.run {
                        ToastManager.shared.show(.error(
                            message: "Couldn't finish setting up your account",
                            detail: error.localizedDescription
                        ))
                    }
                }
            } else {
                do {
                    print("🔐 Unlocking encryption for returning Apple user...")
                    try await sessionViewModel.unlockEncryptionForReturningUser(password: appleResult.userIdentifier)
                    print("✅ Encryption unlocked for Apple user")
                    // Now that the master key is back in keychain, re-fetch the
                    // profile and recompute setup status — the earlier fetch
                    // during handleAuthenticationSuccess saw plaintext fallback
                    // (no income) because the key wasn't loaded yet.
                    await sessionViewModel.fetchUserProfile()
                    await sessionViewModel.checkInitialSetupStatus()
                } catch {
                    print("❌ Failed to unlock encryption for Apple user: \(error)")
                    await MainActor.run {
                        ToastManager.shared.show(.error(
                            message: "Couldn't unlock your encrypted data",
                            detail: error.localizedDescription
                        ))
                    }
                }
            }

            isLoading = false

            // Track sign in completed
            AnalyticsService.shared.track(.signInCompleted(method: .apple))

            // For returning users who have completed onboarding, go to main app
            if sessionViewModel.hasCompletedOnboarding && sessionViewModel.hasCompletedInitialSetup {
                print("🍎 Returning user - navigating to main app")
                currentStep = .complete
            } else if hasAnsweredOnboarding {
                // User reached Apple sign-in from the end-of-flow auth screen.
                // Persist their answers, then show the welcome interstitial
                // before handing off to the app.
                print("🍎 New user with answers - showing welcome")
                await proceedToReadyToStart()
            } else {
                print("🍎 New user - starting onboarding questions")
                currentStep = .triedBefore
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

    // MARK: - Google Sign In Methods

    /// Sign in with Google
    /// - Parameter requireExistingAccount: when true, refuses silent account creation.
    ///   The login path should pass `true`; the sign-up path keeps the default `false`.
    /// - Returns: True if sign-in was successful
    func signInWithGoogle(requireExistingAccount: Bool = false) async -> Bool {
        isLoading = true
        clearError()

        // Track sign in started
        AnalyticsService.shared.track(.signInStarted(method: .google))

        do {
            // Step 1: Get Google credentials
            print("🔵 Step 1: Getting Google credentials...")
            let googleResult = try await googleSignInManager.signIn()
            print("🔵 Step 1 complete: Got idToken, name: \(googleResult.fullName ?? "nil"), email: \(googleResult.email ?? "nil")")

            // Step 1.5: On the login path, refuse silent account creation. If no
            // Google identity with this `sub` exists yet, bail before Supabase
            // creates an auth.users row.
            if requireExistingAccount {
                let exists = try await supabaseService.googleIdentityExists(googleSub: googleResult.userIdentifier)
                if !exists {
                    print("🔵 ❌ No existing account for this Google ID — refusing auto-create")
                    throw AuthError.accountNotFound
                }
            }

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
                print("🔵 Step 3: Stored name from Google: \(fullName)")
            }

            // Store email if available
            if let email = googleResult.email {
                self.email = email
            }

            // Step 4: Notify SessionViewModel of successful authentication
            print("🔵 Step 4: Handling auth success...")
            await sessionViewModel.handleAuthenticationSuccess()
            print("🔵 Step 4 complete")

            // Step 5: Set up or unlock encryption using Google's stable userIdentifier.
            // See the Apple path for the rationale — the authoritative signal
            // for new-vs-returning is whether `user_encryption_keys` already
            // has a row server-side, not the profile-driven onboarding flag.
            let userIdForKeyCheck = supabaseService.currentUser?.id.uuidString.lowercased() ?? sessionViewModel.currentUser?.userId ?? ""
            let keyManager = UserKeyManager(supabaseService: sessionViewModel.supabaseService)
            let isNewUser = !(await keyManager.hasEncryptionEnabled(for: userIdForKeyCheck))
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
                    print("❌ Failed to setup encryption for Google user: \(error)")
                    await MainActor.run {
                        ToastManager.shared.show(.error(
                            message: "Couldn't finish setting up your account",
                            detail: error.localizedDescription
                        ))
                    }
                }
            } else {
                do {
                    print("🔐 Unlocking encryption for returning Google user...")
                    try await sessionViewModel.unlockEncryptionForReturningUser(password: googleResult.userIdentifier)
                    print("✅ Encryption unlocked for Google user")
                    // Re-fetch profile + recompute setup status now that the
                    // master key is back in keychain. See the Apple path for
                    // the rationale.
                    await sessionViewModel.fetchUserProfile()
                    await sessionViewModel.checkInitialSetupStatus()
                } catch {
                    print("❌ Failed to unlock encryption for Google user: \(error)")
                    await MainActor.run {
                        ToastManager.shared.show(.error(
                            message: "Couldn't unlock your encrypted data",
                            detail: error.localizedDescription
                        ))
                    }
                }
            }

            isLoading = false

            // Track sign in completed
            AnalyticsService.shared.track(.signInCompleted(method: .google))

            // For returning users who have completed onboarding, go to main app
            if sessionViewModel.hasCompletedOnboarding && sessionViewModel.hasCompletedInitialSetup {
                print("🔵 Returning user - navigating to main app")
                currentStep = .complete
            } else if hasAnsweredOnboarding {
                // User reached Google sign-in from the end-of-flow auth screen.
                // Persist their answers, then show the welcome interstitial
                // before handing off to the app.
                print("🔵 New user with answers - showing welcome")
                await proceedToReadyToStart()
            } else {
                print("🔵 New user - starting onboarding questions")
                currentStep = .triedBefore
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

    // MARK: - Private Methods
    
    private func resetOnboardingState() {
        showSignUp = false
        isVerified = false
        clearError()
        isLoading = false
        collectedData = UserOnboardingData()

        // Clear sensitive data
        email = nil
        temporaryPassword = nil
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

            // Capture the onboarding question answers for the JSONB insights column.
            let insights = OnboardingInsights(
                triedBefore: triedBefore.isEmpty ? nil : triedBefore.joined(separator: ","),
                messyMoney: messyMoney.isEmpty ? nil : messyMoney.joined(separator: ","),
                writingFrequency: writingFrequency.isEmpty ? nil : writingFrequency,
                incomeShape: incomeShape.isEmpty ? nil : incomeShape,
                whatsWorking: whatsWorking.isEmpty ? nil : whatsWorking,
                moneyShapedThoughts: moneyShapedThoughts.isEmpty ? nil : moneyShapedThoughts,
                tabsCartsCameraRoll: tabsCartsCameraRoll.isEmpty ? nil : tabsCartsCameraRoll,
                thoughtsCameBack: thoughtsCameBack.isEmpty ? nil : thoughtsCameBack
            )

            // Check if a real DB-backed profile already exists. `currentUser`
            // may be a non-nil in-memory fallback returned by
            // `DataManager.getCurrentUserProfile` for brand-new sign-ups —
            // those have no `id`, so we must create (not update), otherwise
            // the edge function call throws `missingId` before being invoked.
            if var existingProfile = sessionViewModel.currentUser, existingProfile.id != nil {
                // Update existing profile
                existingProfile.monthlyIncome = collectedData.monthlyIncome
                existingProfile.freedomFund = collectedData.freedomFund
                existingProfile.painPoint = collectedData.painPoint
                existingProfile.settings = settings
                existingProfile.onboardingInsights = insights
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
                    settings: settings,
                    onboardingInsights: insights
                )
                try await sessionViewModel.createUserProfile(newProfile)
            }

            hydrateLocalProfile()
        } catch {
            print("❌ Failed to save profile data: \(error)")
            await MainActor.run {
                ToastManager.shared.show(.error(
                    message: "Couldn't save your profile",
                    detail: error.localizedDescription
                ))
            }
            hydrateLocalProfile()
        }
    }

    /// Mirror onboarding answers into the local SwiftData UserProfile so the
    /// AI always has context about the user — even offline.
    private func hydrateLocalProfile() {
        guard let container = modelContainer else { return }
        let context = container.mainContext

        let descriptor = FetchDescriptor<UserProfile>()
        let profile: UserProfile
        if let existing = try? context.fetch(descriptor).first {
            profile = existing
        } else {
            profile = UserProfile()
            context.insert(profile)
        }

        profile.currency = collectedData.currency
        if collectedData.monthlyIncome > 0 {
            profile.incomeAmount = collectedData.monthlyIncome
        }

        let onboardingFacts = buildOnboardingFacts()
        profile.facts = profile.facts.filter { $0.source != "onboarding" } + onboardingFacts
        profile.updatedAt = Date()
        try? context.save()
    }

    private func buildOnboardingFacts() -> [FinancialFact] {
        var facts: [FinancialFact] = []
        let triedLabels: [String: String] = [
            "budgeting_app": "a budgeting app", "spreadsheet": "spreadsheets",
            "notes_app": "a notes app", "in_my_head": "mental math"
        ]
        let messyLabels: [String: String] = [
            "no_clue": "not knowing where money goes", "bills_surprise": "bills surprising them",
            "subs_creep": "subscriptions creeping up", "decisions": "decisions piling up"
        ]
        let freqLabels: [String: String] = [
            "every_day": "writes things down every day",
            "few_week": "writes things down a few times a week",
            "sometimes": "writes things down sometimes",
            "almost_never": "almost never writes things down"
        ]
        let shapeLabels: [String: String] = [
            "steady": "steady paycheck", "lumpy": "lumpy/freelance income",
            "mix": "mix of salary and extras", "no_fixed": "no fixed income right now"
        ]
        let workingLabels: [String: String] = [
            "less_anx": "feeling less anxious about money",
            "not_behind": "not feeling behind on bills",
            "decisions": "acting on intentions instead of drifting",
            "clarity": "knowing what they actually have"
        ]
        let thoughtsLabels: [String: String] = [
            "few_3": "~3", "many_7": "~7", "lots_15": "~15", "uncount": "too many to count"
        ]
        let tabsLabels: [String: String] = [
            "couple": "a couple", "handful": "a handful",
            "many": "many", "lost": "lost count of"
        ]
        let loopLabels: [String: String] = [
            "once_twice": "money thoughts rarely loop back",
            "a_few": "a few money thoughts loop back unresolved",
            "constant": "money thoughts constantly loop back",
            "not_notice": "doesn't notice money thoughts looping anymore"
        ]

        func fact(_ text: String) { facts.append(FinancialFact(fact: text, source: "onboarding")) }

        if !triedBefore.isEmpty {
            let labels = triedBefore.compactMap { triedLabels[$0] }
            if !labels.isEmpty { fact("has tried \(labels.joined(separator: ", ")) before") }
        }
        if !messyMoney.isEmpty {
            let labels = messyMoney.compactMap { messyLabels[$0] }
            if !labels.isEmpty { fact("messiest money issues: \(labels.joined(separator: ", "))") }
        }
        if let label = freqLabels[writingFrequency] { fact(label) }
        if let label = shapeLabels[incomeShape] { fact("income shape: \(label)") }
        if let label = workingLabels[whatsWorking] { fact("success = \(label)") }
        if let label = thoughtsLabels[moneyShapedThoughts] {
            fact("\(label) unwritten money thoughts per week")
        }
        if let label = tabsLabels[tabsCartsCameraRoll] {
            fact("\(label) undecided items sitting in tabs/carts")
        }
        if let label = loopLabels[thoughtsCameBack] { fact(label) }

        return facts
    }
}

// MARK: - Supporting Types

enum OnboardingStep: CaseIterable {
    case landing

    // Brief animated interstitial after L1 "begin" — sets expectations
    // before peppering the user with questions.
    case intro

    // Card-based questions — invest the user before asking for credentials.
    // Order here drives flow order via `next()`.
    case triedBefore           // O3  — "what have you tried before?"
    case messyMoney            // O3c — "what's the messiest part of money?" (multi-select)
    case writingFrequency      // O3b — "how often do you write things down?"

    // Milestone celebration #1 — after 3 questions. Dither pulse + a single
    // line of celebratory copy; auto-advances.
    case celebrationOne

    case moneyShapedThoughts   // O3e — "money-shaped thoughts you didn't write down"
    case tabsCartsCameraRoll   // O3f — "tabs, carts, camera roll waiting for a decision"
    case thoughtsCameBack      // O3g — "money thoughts that came back twice"

    // Milestone celebration #2 — after 6 questions.
    case celebrationTwo

    case incomeShape           // O4b — "how does your income show up?"
    case whatsWorking          // O4c — "what would 'this is working' feel like?"

    // Quantitative questions.
    case currencyIncome        // O4  — currency + monthly take-home (after tax)

    // Auth tail.
    case saveAnswers          // O2  — apple/google or "prefer email? sign up"
    case authentication       // email signup form (when chosen from saveAnswers)
    case verification         // verify code (after email signup)

    // Post-auth welcome — "hi, i'm norma" + "tell me your bills, i'll show you
    // how long your money lasts". Shown once, only for brand-new users, right
    // before the app.
    case readyToStart

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

