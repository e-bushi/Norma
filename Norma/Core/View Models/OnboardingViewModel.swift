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
    @Published var currentStep: OnboardingStep = .authentication
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
    
    // Collected Data
    @Published var collectedData = UserOnboardingData()
    
    // MARK: - Dependencies
    private let sessionViewModel: SessionViewModel
    private let anthropicService = AnthropicService.shared
    private let supabaseService = SupabaseService.shared
    
    // MARK: - Initialization
    
    init(sessionViewModel: SessionViewModel) {
        self.sessionViewModel = sessionViewModel
    }
    
    // MARK: - Onboarding Flow Methods
    
    func startOnboardingFlow() {
        resetOnboardingState()
        currentStep = .authentication
    }
    
    func moveToNextStep() {
        withAnimation {
            currentStep = currentStep.next()
        }
    }
    
    func completeOnboarding() {
        sessionViewModel.completeOnboarding()
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, fullName: String) async throws {
        isLoading = true
        clearError()
        
        // Split name into first and last name (simple approach)
        let nameParts = fullName.split(separator: " ")
        let firstName = String(nameParts.first ?? "")
        let lastName = nameParts.count > 1 ? String(nameParts[1...].joined(separator: " ")) : ""
        
        _ = try await supabaseService.signUp(
            email: email, 
            password: password, 
            firstName: firstName, 
            lastName: lastName
        )
        
        // Store email and name for later use
        self.email = email
        collectedData.name = fullName
        
        isLoading = false
        currentStep = .verification
    }
    
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        clearError()
        
        do {
            _ = try await supabaseService.signIn(email: email, password: password)
            
            // Notify SessionViewModel of successful authentication
            await sessionViewModel.handleAuthenticationSuccess()
            
            isLoading = false
            return true
            
        } catch {
            isLoading = false
            showError(error.localizedDescription)
            return false
        }
    }
    
    func verifyCode(email: String, code: String) async throws {
        isLoading = true
        clearError()
        
        _ = try await supabaseService.verifyOTP(email: email, code: code)
        
        isVerified = true
        isLoading = false
        // Don't update currentStep here - let the view handle navigation after transition
    }
    
    func proceedToWelcome() {
        currentStep = .welcome
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
    }
    
    private func addUserMessage(_ text: String) {
        withAnimation {
            messages.append(ChatMessage(text: text, isUser: true))
        }
    }
    
    private func addNormaMessage(_ text: String) {
        withAnimation {
            messages.append(ChatMessage(text: text, isUser: false))
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
            
            let primaryGoal = input["primaryGoal"] as? String ?? ""
            let reminderPreference = input["reminderPreference"] as? String ?? ""
            
            let extractedData = UserOnboardingData(
                name: name,
                currency: currency,
                monthlyIncome: monthlyIncome,
                primaryGoal: primaryGoal,
                reminderPreference: reminderPreference
            )
            
            
            // Check if we have ALL required data
            if !extractedData.name.isEmpty &&
               !extractedData.currency.isEmpty &&
               !extractedData.primaryGoal.isEmpty &&
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
                print("Data incomplete from tool - name: '\(extractedData.name)', currency: '\(extractedData.currency)', goal: '\(extractedData.primaryGoal)', income: \(extractedData.monthlyIncome), reminder: '\(extractedData.reminderPreference)'")
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
                primaryGoal: collectedData.primaryGoal,
                notificationsEnabled: collectedData.reminderPreference != "No reminders",
                billReminderDays: reminderDays
            )
            
            // Check if profile already exists
            if let existingProfile = try await supabaseService.fetchProfile(userId: supabaseUser.id.uuidString) {
                // Update existing profile
                var updatedProfile = existingProfile
                updatedProfile.settings = settings
                let savedProfile = try await supabaseService.updateProfile(updatedProfile)
                
                // Update SessionViewModel with the new profile data
                await MainActor.run {
                    sessionViewModel.currentUser = savedProfile
                }
            } else {
                // Create new profile
                let newProfile = Profile(
                    userId: supabaseUser.id.uuidString,
                    email: supabaseUser.email ?? "",
                    name: collectedData.name,
                    settings: settings
                )
                let savedProfile = try await supabaseService.createProfile(newProfile)
                
                // Update SessionViewModel with the new profile data
                await MainActor.run {
                    sessionViewModel.currentUser = savedProfile
                }
            }
            
        } catch {
            print("Failed to save profile data: \(error)")
            // Still allow completion view to show
        }
    }
}

// MARK: - Supporting Types

enum OnboardingStep: CaseIterable {
    case welcome
    case authentication
    case verification
    case normaChat
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

