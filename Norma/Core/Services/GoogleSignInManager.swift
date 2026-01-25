//
//  GoogleSignInManager.swift
//  Norma
//
//  Created by Claude on 1/22/26.
//

import Foundation
import GoogleSignIn

@MainActor
class GoogleSignInManager: NSObject, ObservableObject {

    // MARK: - Constants
    private let clientID = "41635629604-l3jvcjf8geiooseih6roaj38tht4b7ia.apps.googleusercontent.com"

    // MARK: - Published Properties
    @Published var isSigningIn = false
    @Published var error: Error?

    // MARK: - Public Methods

    /// Initiates Google Sign In flow
    /// - Returns: GoogleSignInResult containing idToken, accessToken, and user info
    func signIn() async throws -> GoogleSignInResult {
        isSigningIn = true
        error = nil

        defer { isSigningIn = false }

        // Get the presenting view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.googleSignInError("Unable to get root view controller")
        }

        // Find the topmost presented view controller
        let presentingViewController = topViewController(from: rootViewController)

        // Configure Google Sign In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.googleSignInError("Unable to get ID token from Google")
            }

            let accessToken = result.user.accessToken.tokenString
            let profile = result.user.profile

            return GoogleSignInResult(
                idToken: idToken,
                accessToken: accessToken,
                firstName: profile?.givenName,
                lastName: profile?.familyName,
                email: profile?.email,
                userIdentifier: result.user.userID ?? ""
            )
        } catch let error as GIDSignInError {
            self.error = error
            switch error.code {
            case .canceled:
                throw AuthError.googleSignInError("Sign in was canceled")
            case .hasNoAuthInKeychain:
                throw AuthError.googleSignInError("No previous sign-in found")
            case .EMM:
                throw AuthError.googleSignInError("Enterprise mobility management error")
            case .scopesAlreadyGranted:
                throw AuthError.googleSignInError("Requested scopes already granted")
            case .mismatchWithCurrentUser:
                throw AuthError.googleSignInError("User mismatch error")
            @unknown default:
                throw AuthError.googleSignInError("An unknown error occurred: \(error.localizedDescription)")
            }
        } catch {
            self.error = error
            throw AuthError.googleSignInError("Google Sign In failed: \(error.localizedDescription)")
        }
    }

    /// Handles the URL callback from Google Sign In
    /// Call this from your AppDelegate or SceneDelegate
    func handle(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    /// Signs out the current user from Google
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }

    /// Restores a previous sign-in session if available
    func restorePreviousSignIn() async throws -> GoogleSignInResult? {
        do {
            let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()

            guard let idToken = user.idToken?.tokenString else {
                return nil
            }

            let accessToken = user.accessToken.tokenString
            let profile = user.profile

            return GoogleSignInResult(
                idToken: idToken,
                accessToken: accessToken,
                firstName: profile?.givenName,
                lastName: profile?.familyName,
                email: profile?.email,
                userIdentifier: user.userID ?? ""
            )
        } catch {
            return nil
        }
    }

    // MARK: - Private Helpers

    private func topViewController(from viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return topViewController(from: presented)
        }
        if let nav = viewController as? UINavigationController,
           let visible = nav.visibleViewController {
            return topViewController(from: visible)
        }
        if let tab = viewController as? UITabBarController,
           let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        return viewController
    }
}

// MARK: - Supporting Types

struct GoogleSignInResult {
    let idToken: String
    let accessToken: String
    let firstName: String?
    let lastName: String?
    let email: String?
    let userIdentifier: String

    /// Full name combining first and last name
    var fullName: String? {
        let components = [firstName, lastName].compactMap { $0 }.filter { !$0.isEmpty }
        return components.isEmpty ? nil : components.joined(separator: " ")
    }
}
