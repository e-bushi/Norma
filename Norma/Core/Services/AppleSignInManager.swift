//
//  AppleSignInManager.swift
//  Norma
//
//  Created by Claude on 12/2/25.
//

import Foundation
import AuthenticationServices
import CryptoKit

@MainActor
class AppleSignInManager: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var isSigningIn = false
    @Published var error: Error?

    // MARK: - Private Properties
    private var currentNonce: String?
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?

    // MARK: - Public Methods

    /// Initiates Apple Sign In flow
    /// - Returns: AppleSignInResult containing idToken and optional user info
    func signIn() async throws -> AppleSignInResult {
        isSigningIn = true
        error = nil

        // Generate nonce for security
        let nonce = randomNonceString()
        currentNonce = nonce

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - Private Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInManager: ASAuthorizationControllerDelegate {

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            isSigningIn = false

            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                continuation?.resume(throwing: AuthError.appleSignInError("Invalid credential type"))
                continuation = nil
                return
            }

            guard let identityTokenData = appleIDCredential.identityToken,
                  let idToken = String(data: identityTokenData, encoding: .utf8) else {
                continuation?.resume(throwing: AuthError.appleSignInError("Unable to get identity token"))
                continuation = nil
                return
            }

            // Extract name (only available on first sign-in)
            let fullName = appleIDCredential.fullName
            let firstName = fullName?.givenName
            let lastName = fullName?.familyName
            let email = appleIDCredential.email

            let result = AppleSignInResult(
                idToken: idToken,
                nonce: currentNonce,
                firstName: firstName,
                lastName: lastName,
                email: email,
                userIdentifier: appleIDCredential.user
            )

            continuation?.resume(returning: result)
            continuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            isSigningIn = false
            self.error = error

            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    continuation?.resume(throwing: AuthError.appleSignInError("Sign in was canceled"))
                case .failed:
                    continuation?.resume(throwing: AuthError.appleSignInError("Authorization failed"))
                case .invalidResponse:
                    continuation?.resume(throwing: AuthError.appleSignInError("Invalid response from Apple"))
                case .notHandled:
                    continuation?.resume(throwing: AuthError.appleSignInError("Request not handled"))
                case .unknown:
                    continuation?.resume(throwing: AuthError.appleSignInError("Unknown error occurred"))
                case .notInteractive:
                    continuation?.resume(throwing: AuthError.appleSignInError("Request is not interactive"))
                @unknown default:
                    continuation?.resume(throwing: AuthError.appleSignInError("An unknown error occurred"))
                }
            } else {
                continuation?.resume(throwing: error)
            }
            continuation = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window scene found")
        }
        return window
    }
}

// MARK: - Supporting Types

struct AppleSignInResult {
    let idToken: String
    let nonce: String?
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
