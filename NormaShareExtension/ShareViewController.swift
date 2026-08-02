//
//  ShareViewController.swift
//  NormaShareExtension
//
//  Share Extension for uploading receipt images to Norma
//

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    // MARK: - Properties

    private var imageData: Data?
    private var isProcessing = false

    // MARK: - UI Elements

    private let containerView = UIView()
    private let handleBar = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let statusLabel = UILabel()
    private let imagePreview = UIImageView()
    private let sendButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let cancelDashBorder = CAShapeLayer()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Constants

    private let edgeFunctionURL = URL(string: "https://tafoviioqavefsyxskpo.supabase.co/functions/v1/extract-transactions")!

    // MARK: - Brand Colors (D9/D10 dark editorial palette)

    private let normaBg = UIColor(red: 0x16/255, green: 0x16/255, blue: 0x1A/255, alpha: 1.0)
    private let normaCream = UIColor(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255, alpha: 1.0)
    private let normaMuted = UIColor(red: 0x7A/255, green: 0x76/255, blue: 0x70/255, alpha: 1.0)
    private let normaDim = UIColor(red: 0x5C/255, green: 0x58/255, blue: 0x52/255, alpha: 1.0)
    private let normaOnAccent = UIColor(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255, alpha: 1.0)
    private let normaCoral = UIColor(red: 0xE0/255, green: 0x7B/255, blue: 0x6F/255, alpha: 1.0)

    /// The user's accent theme, mirrored into the app-group defaults by the
    /// main app (see AppTheme.mirrorToSharedDefaults). UIColor copies of the
    /// AppTheme presets; falls back to brand lavender if never mirrored.
    private lazy var normaAccent: UIColor = {
        let presets: [String: UIColor] = [
            "lavender": UIColor(red: 0.588, green: 0.463, blue: 0.851, alpha: 1.0),
            "ocean": UIColor(red: 0.380, green: 0.541, blue: 0.780, alpha: 1.0),
            "sage": UIColor(red: 0.573, green: 0.663, blue: 0.494, alpha: 1.0),
            "amber": UIColor(red: 0.827, green: 0.639, blue: 0.361, alpha: 1.0),
            "berry": UIColor(red: 0.780, green: 0.412, blue: 0.573, alpha: 1.0),
        ]
        let id = UserDefaults(suiteName: "group.com.myndfruit.norma")?
            .string(forKey: "selectedAccentThemeID")
        return id.flatMap { presets[$0] } ?? presets["lavender"]!
    }()

    // MARK: - Fonts

    private func rubikFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        // Check if Rubik font family is available
        let availableFonts = UIFont.fontNames(forFamilyName: "Rubik")

        if !availableFonts.isEmpty {
            // Rubik is available - create font with weight
            let fontDescriptor = UIFontDescriptor(fontAttributes: [
                .family: "Rubik"
            ]).addingAttributes([
                .traits: [UIFontDescriptor.TraitKey.weight: weight]
            ])

            return UIFont(descriptor: fontDescriptor, size: size)
        }

        // Fallback to system font
        return UIFont.systemFont(ofSize: size, weight: weight)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        extractImage()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cancelDashBorder.frame = cancelButton.bounds
        cancelDashBorder.path = UIBezierPath(
            roundedRect: cancelButton.bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: cancelButton.bounds.height / 2
        ).cgPath
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Fade in animation for full-screen
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.containerView.alpha = 1
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = normaBg
        overrideUserInterfaceStyle = .dark

        // Container - full screen
        containerView.backgroundColor = normaBg
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.alpha = 0
        view.addSubview(containerView)

        // Handle bar
        handleBar.backgroundColor = normaCream.withAlphaComponent(0.2)
        handleBar.layer.cornerRadius = 2
        handleBar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(handleBar)

        // Title — D9/D10 hero treatment, lowercase
        titleLabel.text = "your screenshot."
        titleLabel.font = rubikFont(size: 32, weight: .heavy)
        titleLabel.textAlignment = .left
        titleLabel.textColor = normaCream
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        // Subtitle — muted eyebrow under hero
        subtitleLabel.text = "norma will read it and file what matters"
        subtitleLabel.font = rubikFont(size: 14, weight: .medium)
        subtitleLabel.textAlignment = .left
        subtitleLabel.textColor = normaMuted
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subtitleLabel)

        // Image Preview — cream card fill + hairline stroke, matching the
        // in-app field cards (cream 4% fill / cream 8% stroke, radius 16)
        imagePreview.contentMode = .scaleAspectFit
        imagePreview.clipsToBounds = true
        imagePreview.layer.cornerRadius = 16
        imagePreview.layer.cornerCurve = .continuous
        imagePreview.backgroundColor = normaCream.withAlphaComponent(0.04)
        imagePreview.layer.borderWidth = 1
        imagePreview.layer.borderColor = normaCream.withAlphaComponent(0.08).cgColor
        imagePreview.translatesAutoresizingMaskIntoConstraints = false
        imagePreview.setContentHuggingPriority(.defaultLow, for: .vertical)
        imagePreview.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        containerView.addSubview(imagePreview)

        // Status Label
        statusLabel.text = "ready to send."
        statusLabel.font = rubikFont(size: 13, weight: .medium)
        statusLabel.textColor = normaAccent
        statusLabel.textAlignment = .left
        statusLabel.numberOfLines = 2
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusLabel)

        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = normaAccent
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(activityIndicator)

        // Send Button — active capsule: solid accent fill with dark text
        sendButton.setTitle("send to norma", for: .normal)
        sendButton.titleLabel?.font = rubikFont(size: 16, weight: .semibold)
        sendButton.backgroundColor = normaAccent
        sendButton.setTitleColor(normaOnAccent, for: .normal)
        sendButton.setTitleColor(normaOnAccent.withAlphaComponent(0.7), for: .highlighted)
        sendButton.setTitleColor(normaOnAccent.withAlphaComponent(0.5), for: .disabled)
        sendButton.layer.cornerRadius = 26
        sendButton.layer.cornerCurve = .continuous
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(sendButton)

        // Cancel Button — inactive capsule: dashed border (dash [3,3], 1pt),
        // drawn by a CAShapeLayer sized in viewDidLayoutSubviews
        var cancelConfig = UIButton.Configuration.plain()
        cancelConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 24, bottom: 10, trailing: 24)
        cancelConfig.attributedTitle = AttributedString(
            "cancel",
            attributes: AttributeContainer([
                .font: rubikFont(size: 14, weight: .medium),
                .foregroundColor: normaMuted,
            ])
        )
        cancelButton.configuration = cancelConfig
        cancelDashBorder.fillColor = nil
        cancelDashBorder.strokeColor = normaMuted.withAlphaComponent(0.6).cgColor
        cancelDashBorder.lineWidth = 1
        cancelDashBorder.lineDashPattern = [3, 3]
        cancelButton.layer.addSublayer(cancelDashBorder)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cancelButton)

        // Constraints - full screen layout
        NSLayoutConstraint.activate([
            // Container fills entire screen
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Handle bar at top
            handleBar.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: 12),
            handleBar.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            handleBar.widthAnchor.constraint(equalToConstant: 36),
            handleBar.heightAnchor.constraint(equalToConstant: 5),

            // Title below handle
            titleLabel.topAnchor.constraint(equalTo: handleBar.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            // Subtitle below title
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            // Image preview - flexible height, fills space between subtitle and status
            imagePreview.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            imagePreview.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            imagePreview.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            imagePreview.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -16),

            // Status label above buttons
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),

            // Send button
            sendButton.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            sendButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            sendButton.heightAnchor.constraint(equalToConstant: 52),

            // Cancel button at bottom
            cancelButton.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 12),
            cancelButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    // MARK: - Image Extraction

    private func extractImage() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            statusLabel.text = "no image found."
            statusLabel.textColor = normaCoral
            sendButton.isEnabled = false
            return
        }

        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] item, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.statusLabel.text = "failed to load image."
                            self?.statusLabel.textColor = self?.normaCoral
                            self?.sendButton.isEnabled = false
                            print("Error loading image: \(error)")
                            return
                        }

                        if let url = item as? URL,
                           let data = try? Data(contentsOf: url),
                           let image = UIImage(data: data) {
                            self?.imageData = self?.compressImage(image)
                            self?.imagePreview.image = image
                        } else if let image = item as? UIImage {
                            self?.imageData = self?.compressImage(image)
                            self?.imagePreview.image = image
                        } else if let data = item as? Data,
                                  let image = UIImage(data: data) {
                            self?.imageData = self?.compressImage(image)
                            self?.imagePreview.image = image
                        }
                    }
                }
                break
            }
        }
    }

    private func compressImage(_ image: UIImage) -> Data? {
        // Compress to reduce upload size (max 1MB)
        var compression: CGFloat = 0.8
        var data = image.jpegData(compressionQuality: compression)

        while let currentData = data, currentData.count > 1_000_000 && compression > 0.1 {
            compression -= 0.1
            data = image.jpegData(compressionQuality: compression)
        }

        return data
    }

    // MARK: - Actions

    @objc private func sendTapped() {
        guard !isProcessing else { return }
        guard let imageData = imageData else {
            statusLabel.text = "no image to send."
            statusLabel.textColor = normaCoral
            return
        }

        let userId = SharedKeychainHelper.getUserId()
        let authToken = userId.flatMap { SharedKeychainHelper.getAuthToken(for: $0) }

        guard let userId, let authToken else {
            let hasUser = userId != nil
            statusLabel.text = hasUser ? "session missing. re-open norma." : "no credentials found. please log in to norma."
            statusLabel.textColor = normaCoral
            print("🔴 Share ext auth: userId=\(hasUser), token=\(authToken != nil)")
            return
        }

        isProcessing = true
        sendButton.isEnabled = false
        activityIndicator.startAnimating()
        statusLabel.text = "uploading receipt…"
        statusLabel.textColor = normaMuted

        // Animate button
        UIView.animate(withDuration: 0.2) {
            self.sendButton.alpha = 0.6
        }

        uploadAndProcess(imageData: imageData, authToken: authToken, userId: userId)
    }

    private func uploadAndProcess(imageData: Data, authToken: String, userId: String, isRetry: Bool = false) {
        var request = URLRequest(url: edgeFunctionURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Convert image to base64
        let base64Image = imageData.base64EncodedString()

        // Build request body with device token for push notifications
        var body: [String: Any] = [
            "image_base64": base64Image
        ]

        // Include device token if available for push notification
        if let deviceToken = SharedKeychainHelper.getDeviceToken() {
            body["device_token"] = deviceToken
        }

        // Include APNs environment for push notification routing
        #if DEBUG
        body["apns_environment"] = "development"
        #else
        body["apns_environment"] = "production"
        #endif

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            DispatchQueue.main.async {
                self.handleError("Failed to prepare request")
            }
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.activityIndicator.stopAnimating()
                    self?.handleError("Network error: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.activityIndicator.stopAnimating()
                    self?.handleError("Invalid response")
                    return
                }

                if httpResponse.statusCode == 200 {
                    self?.activityIndicator.stopAnimating()
                    self?.handleSuccess(data: data)
                } else if httpResponse.statusCode == 401 && !isRetry {
                    // Token expired — attempt refresh
                    self?.statusLabel.text = "refreshing session…"
                    self?.attemptTokenRefreshAndRetry(imageData: imageData, userId: userId)
                } else {
                    self?.activityIndicator.stopAnimating()
                    self?.handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
                }
            }
        }.resume()
    }

    // MARK: - Token Refresh

    private func attemptTokenRefreshAndRetry(imageData: Data, userId: String) {
        guard let refreshToken = SharedKeychainHelper.getRefreshToken(for: userId),
              let config = SharedKeychainHelper.getSupabaseConfig() else {
            activityIndicator.stopAnimating()
            handleError("session expired. please open norma to sign in again.")
            return
        }

        refreshAccessToken(supabaseURL: config.url, anonKey: config.anonKey, refreshToken: refreshToken) { [weak self] newAccessToken, newRefreshToken in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let newAccessToken = newAccessToken {
                    // Store new tokens in keychain
                    _ = SharedKeychainHelper.storeAuthToken(newAccessToken, for: userId)
                    if let newRefreshToken = newRefreshToken {
                        _ = SharedKeychainHelper.storeRefreshToken(newRefreshToken, for: userId)
                    }

                    // Retry upload with new token
                    self.uploadAndProcess(imageData: imageData, authToken: newAccessToken, userId: userId, isRetry: true)
                } else {
                    self.activityIndicator.stopAnimating()
                    self.handleError("session expired. please open norma to sign in again.")
                }
            }
        }
    }

    private func refreshAccessToken(supabaseURL: String, anonKey: String, refreshToken: String, completion: @escaping (String?, String?) -> Void) {
        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=refresh_token") else {
            completion(nil, nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = ["refresh_token": refreshToken]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(nil, nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String else {
                completion(nil, nil)
                return
            }

            let newRefreshToken = json["refresh_token"] as? String
            completion(accessToken, newRefreshToken)
        }.resume()
    }

    private func handleSuccess(data: Data?) {
        var message = "receipt sent."

        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let serverMessage = json["message"] as? String {
            message = serverMessage.lowercased()
        }

        statusLabel.text = message
        statusLabel.textColor = normaAccent

        // Success animation
        UIView.animate(withDuration: 0.3) {
            self.sendButton.backgroundColor = self.normaAccent
            self.sendButton.alpha = 1
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Auto-close after success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.dismissWithAnimation()
        }
    }

    private func handleErrorResponse(data: Data?, statusCode: Int) {
        var errorMessage = "upload failed (error \(statusCode))."

        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let serverError = json["error"] as? String {
            errorMessage = serverError.lowercased()
        }

        handleError(errorMessage)
    }

    private func handleError(_ message: String) {
        statusLabel.text = message
        statusLabel.textColor = normaCoral
        sendButton.isEnabled = true
        isProcessing = false

        UIView.animate(withDuration: 0.2) {
            self.sendButton.alpha = 1
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    @objc private func cancelTapped() {
        dismissWithAnimation()
    }

    private func dismissWithAnimation() {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.containerView.alpha = 0
        } completion: { _ in
            self.extensionContext?.cancelRequest(withError: NSError(domain: "NormaShareExtension", code: 0, userInfo: nil))
        }
    }
}
