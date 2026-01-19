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
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Constants

    private let edgeFunctionURL = URL(string: "https://tafoviioqavefsyxskpo.supabase.co/functions/v1/extract-transactions")!

    // MARK: - Brand Colors

    private var normaTeal: UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.520, green: 0.580, blue: 0.560, alpha: 1.0)
            } else {
                return UIColor(red: 0.400, green: 0.600, blue: 0.580, alpha: 1.0)
            }
        }
    }

    private var normaBackground: UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.137, green: 0.110, blue: 0.094, alpha: 1.0)
            } else {
                return UIColor(red: 1.0, green: 0.996, blue: 0.984, alpha: 1.0)
            }
        }
    }

    private var normaCard: UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.180, green: 0.160, blue: 0.140, alpha: 1.0)
            } else {
                return UIColor.white
            }
        }
    }

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Fade in animation for full-screen
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.containerView.alpha = 1
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = normaBackground

        // Container - full screen
        containerView.backgroundColor = normaBackground
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.alpha = 0
        view.addSubview(containerView)

        // Handle bar (iOS sheet style)
        handleBar.backgroundColor = UIColor.systemGray3
        handleBar.layer.cornerRadius = 2.5
        handleBar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(handleBar)

        // Title
        titleLabel.text = "Your Screenshot"
        titleLabel.font = rubikFont(size: 22, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        // Subtitle
        subtitleLabel.text = "Scan receipt for expense tracking"
        subtitleLabel.font = rubikFont(size: 14, weight: .regular)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subtitleLabel)

        // Image Preview - flexible sizing for different image sizes
        imagePreview.contentMode = .scaleAspectFit
        imagePreview.clipsToBounds = true
        imagePreview.layer.cornerRadius = 16
        imagePreview.layer.cornerCurve = .continuous
        imagePreview.backgroundColor = UIColor.secondarySystemBackground
        imagePreview.layer.borderWidth = 1
        imagePreview.layer.borderColor = UIColor.separator.cgColor
        imagePreview.translatesAutoresizingMaskIntoConstraints = false
        imagePreview.setContentHuggingPriority(.defaultLow, for: .vertical)
        imagePreview.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        containerView.addSubview(imagePreview)

        // Status Label
        statusLabel.text = "Ready to scan"
        statusLabel.font = rubikFont(size: 13, weight: .medium)
        statusLabel.textColor = normaTeal
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusLabel)

        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = normaTeal
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(activityIndicator)

        // Send Button
        sendButton.setTitle("Send to Norma", for: .normal)
        sendButton.titleLabel?.font = rubikFont(size: 17, weight: .semibold)
        sendButton.backgroundColor = normaTeal
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .highlighted)
        sendButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
        sendButton.layer.cornerRadius = 14
        sendButton.layer.cornerCurve = .continuous
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(sendButton)

        // Cancel Button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = rubikFont(size: 15, weight: .medium)
        cancelButton.setTitleColor(.secondaryLabel, for: .normal)
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
            statusLabel.text = "No image found"
            statusLabel.textColor = .systemRed
            sendButton.isEnabled = false
            return
        }

        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] item, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.statusLabel.text = "Failed to load image"
                            self?.statusLabel.textColor = .systemRed
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
            statusLabel.text = "No image to send"
            statusLabel.textColor = .systemRed
            return
        }

        guard let userId = SharedKeychainHelper.getUserId(),
              let authToken = SharedKeychainHelper.getAuthToken(for: userId) else {
            statusLabel.text = "Please log in to Norma first"
            statusLabel.textColor = .systemRed
            return
        }

        isProcessing = true
        sendButton.isEnabled = false
        activityIndicator.startAnimating()
        statusLabel.text = "Uploading receipt..."
        statusLabel.textColor = .secondaryLabel

        // Animate button
        UIView.animate(withDuration: 0.2) {
            self.sendButton.alpha = 0.6
        }

        uploadAndProcess(imageData: imageData, authToken: authToken)
    }

    private func uploadAndProcess(imageData: Data, authToken: String) {
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
                self?.activityIndicator.stopAnimating()

                if let error = error {
                    self?.handleError("Network error: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.handleError("Invalid response")
                    return
                }

                if httpResponse.statusCode == 200 {
                    self?.handleSuccess(data: data)
                } else {
                    self?.handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
                }
            }
        }.resume()
    }

    private func handleSuccess(data: Data?) {
        var message = "Receipt sent!"

        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let serverMessage = json["message"] as? String {
            message = serverMessage
        }

        statusLabel.text = message
        statusLabel.textColor = normaTeal

        // Success animation
        UIView.animate(withDuration: 0.3) {
            self.sendButton.backgroundColor = self.normaTeal
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
        var errorMessage = "Upload failed (Error \(statusCode))"

        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let serverError = json["error"] as? String {
            errorMessage = serverError
        }

        handleError(errorMessage)
    }

    private func handleError(_ message: String) {
        statusLabel.text = message
        statusLabel.textColor = .systemRed
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
