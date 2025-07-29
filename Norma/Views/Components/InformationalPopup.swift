//
//  InformationalPopup.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import SwiftUI

// MARK: - Supporting Views

struct PopupLoadingView: View {
    let loadingState: PopupLoadingState?
    @State private var rotationAngle: Double = 0
    @State private var textAppeared = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Loading spinner
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.3)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(
                        Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
                        value: rotationAngle
                    )
            }
            .onAppear {
                rotationAngle = 360
            }
            
            // Loading text
            VStack(spacing: 4) {
                Text(loadingState?.title ?? "Loading...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                if let subtitle = loadingState?.subtitle {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .opacity(textAppeared ? 1 : 0)
            .offset(y: textAppeared ? 0 : 10)
        }
        .frame(height: 48) // Match button height
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                textAppeared = true
            }
        }
    }
}

struct PopupSuccessView: View {
    let successState: PopupSuccessState?
    let onContinue: () -> Void
    @State private var checkmarkScale: Double = 0
    @State private var textAppeared = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Success checkmark with animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Circle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: 60, height: 60)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.green)
                    .scaleEffect(checkmarkScale)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: checkmarkScale)
            }
            .onAppear {
                checkmarkScale = 1.0
            }
            
            // Success text
            VStack(spacing: 8) {
                Text(successState?.title ?? "Success!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                if let subtitle = successState?.subtitle {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .opacity(textAppeared ? 1 : 0)
            .offset(y: textAppeared ? 0 : 10)
            
            // Continue button
            Button(action: onContinue) {
                Text(successState?.actionTitle ?? "Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .opacity(textAppeared ? 1 : 0)
            .offset(y: textAppeared ? 0 : 20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
                textAppeared = true
            }
        }
    }
}

struct PasswordInputView: View {
    @Binding var password: String
    @Binding var isPasswordVisible: Bool
    let errorMessage: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Password input field
            HStack {
                if isPasswordVisible {
                    TextField("Enter your password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    SecureField("Enter your password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 4)
            
            // Error message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 8)
    }
}

struct PopupFeatureRow: View {
    let feature: PopupFeature
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon container
            ZStack {
                Circle()
                    .fill(feature.iconColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(feature.iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(feature.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

struct InformationalPopup: View {
    @Binding var isPresented: Bool
    let config: PopupConfig
    let onPrimaryAction: () -> Void
    let onSecondaryAction: (() -> Void)?
    let onDismiss: () -> Void
    
    @State private var cardAppeared = false
    @State private var contentAppeared = false
    @State private var isLoading = false
    @State private var showSuccess = false
    
    init(
        isPresented: Binding<Bool>,
        config: PopupConfig,
        onPrimaryAction: @escaping () -> Void,
        onSecondaryAction: (() -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self.config = config
        self.onPrimaryAction = onPrimaryAction
        self.onSecondaryAction = onSecondaryAction
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            // Overlay background with blur effect
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    if config.allowDismissOnTap && !isLoading {
                        dismissPopup()
                    }
                }
            
            // Main card matching app style
            VStack(spacing: 24) {
                // Header section
                VStack(spacing: 12) {
                    // Icon with gradient background
                    if let iconConfig = config.icon {
                        ZStack {
                            Circle()
                                .fill(iconConfig.backgroundGradient)
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: iconConfig.systemName)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(iconConfig.color)
                        }
                    }
                    
                    if let category = config.category {
                        Text(category.uppercased())
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(1.2)
                    }
                    
                    Text(config.title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    if let subtitle = config.subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 20)
                
                // Features section
                if !config.features.isEmpty {
                    VStack(spacing: 16) {
                        ForEach(config.features, id: \.title) { feature in
                            PopupFeatureRow(feature: feature)
                        }
                    }
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 30)
                }
                
                // Custom content section
                if let customContent = config.customContent {
                    customContent
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 30)
                }
                
                // Action buttons, loading state, or success state
                VStack(spacing: 12) {
                    if showSuccess {
                        // Success state
                        PopupSuccessView(
                            successState: config.successState,
                            onContinue: {
                                dismissPopup()
                            }
                        )
                    } else if isLoading {
                        // Loading state
                        PopupLoadingView(loadingState: config.loadingState)
                    } else {
                        // Primary action button
                        Button(action: {
                            onPrimaryAction()
                        }) {
                            HStack {
                                if let primaryIcon = config.primaryAction.icon {
                                    Image(systemName: primaryIcon)
                                        .font(.system(size: 16, weight: .medium))
                                }
                                Text(config.primaryAction.title)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(config.primaryAction.style.textColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(config.primaryAction.style.background)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                        
                        // Secondary action button (optional)
                        if let secondaryAction = config.secondaryAction {
                            Button(action: {
                                if let action = onSecondaryAction {
                                    action()
                                } else {
                                    dismissPopup()
                                }
                            }) {
                                Text(secondaryAction.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(secondaryAction.style.textColor)
                            }
                            .disabled(isLoading)
                        }
                    }
                }
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 40)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(
                        color: Color.black.opacity(0.15),
                        radius: 40,
                        x: 0,
                        y: 20
                    )
            )
            .padding(.horizontal, 24)
            .scaleEffect(cardAppeared ? 1 : 0.9)
            .opacity(cardAppeared ? 1 : 0)
        }
        .onAppear {
            // Staggered animations matching app style
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                cardAppeared = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    contentAppeared = true
                }
            }
        }
    }
    
    private func dismissPopup() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            cardAppeared = false
            contentAppeared = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Configuration Models

struct PopupConfig {
    let title: String
    let subtitle: String?
    let category: String?
    let icon: PopupIcon?
    let features: [PopupFeature]
    let primaryAction: PopupAction
    let secondaryAction: PopupAction?
    let allowDismissOnTap: Bool
    let loadingState: PopupLoadingState?
    let successState: PopupSuccessState?
    let customContent: AnyView?
    
    init(
        title: String,
        subtitle: String? = nil,
        category: String? = nil,
        icon: PopupIcon? = nil,
        features: [PopupFeature] = [],
        primaryAction: PopupAction,
        secondaryAction: PopupAction? = nil,
        allowDismissOnTap: Bool = true,
        loadingState: PopupLoadingState? = nil,
        successState: PopupSuccessState? = nil,
        customContent: AnyView? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.icon = icon
        self.features = features
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.allowDismissOnTap = allowDismissOnTap
        self.loadingState = loadingState
        self.successState = successState
        self.customContent = customContent
    }
}

struct PopupIcon {
    let systemName: String
    let color: Color
    let backgroundGradient: LinearGradient
    
    init(systemName: String, color: Color, backgroundColors: [Color]) {
        self.systemName = systemName
        self.color = color
        self.backgroundGradient = LinearGradient(
            gradient: Gradient(colors: backgroundColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct PopupFeature {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    
    init(icon: String, title: String, description: String, iconColor: Color = .blue) {
        self.icon = icon
        self.title = title
        self.description = description
        self.iconColor = iconColor
    }
}

struct PopupAction {
    let title: String
    let icon: String?
    let style: PopupActionStyle
    
    init(title: String, icon: String? = nil, style: PopupActionStyle = .primary) {
        self.title = title
        self.icon = icon
        self.style = style
    }
}

struct PopupLoadingState {
    let title: String
    let subtitle: String?
    let icon: String?
    
    init(title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
}

struct PopupSuccessState {
    let title: String
    let subtitle: String?
    let actionTitle: String
    
    init(title: String, subtitle: String? = nil, actionTitle: String = "Continue") {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
    }
}

enum PopupActionStyle {
    case primary
    case secondary
    case destructive
    case custom(background: AnyView, textColor: Color)
    
    var background: AnyView {
        switch self {
        case .primary:
            return AnyView(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue,
                        Color.blue.opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .secondary:
            return AnyView(Color.clear)
        case .destructive:
            return AnyView(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.red,
                        Color.red.opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .custom(let background, _):
            return background
        }
    }
    
    var textColor: Color {
        switch self {
        case .primary, .destructive:
            return .white
        case .secondary:
            return .secondary
        case .custom(_, let textColor):
            return textColor
        }
    }
}

// MARK: - Convenience Extensions

extension PopupConfig {
    // Preset configurations for common use cases
    
    static func encryptionMigration(
        onMigrate: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) -> PopupConfig {
        PopupConfig(
            title: "Secure Your Financial Data",
            category: "Enhanced Security",
            icon: PopupIcon(
                systemName: "lock.shield",
                color: .blue,
                backgroundColors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)]
            ),
            features: [
                PopupFeature(
                    icon: "key.fill",
                    title: "End-to-End Encryption",
                    description: "Your sensitive data is encrypted with your personal key"
                ),
                PopupFeature(
                    icon: "iphone.and.arrow.forward",
                    title: "Device Security",
                    description: "Keys are securely stored in your device's keychain"
                ),
                PopupFeature(
                    icon: "arrow.counterclockwise",
                    title: "Recovery Options",
                    description: "Secure recovery phrase for account restoration"
                )
            ],
            primaryAction: PopupAction(
                title: "Enable Encryption",
                icon: "shield.checkered",
                style: .primary
            ),
            secondaryAction: PopupAction(
                title: "Maybe Later",
                style: .secondary
            ),
            loadingState: PopupLoadingState(
                title: "Setting up encryption...",
                subtitle: "This may take a few moments"
            )
        )
    }
    
    static func encryptionMigrationLoading() -> PopupConfig {
        PopupConfig(
            title: "Setting up encryption...",
            subtitle: "Please wait while we secure your data",
            category: "Migrating Data",
            icon: PopupIcon(
                systemName: "lock.shield",
                color: .blue,
                backgroundColors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)]
            ),
            features: [],
            primaryAction: PopupAction(title: "Setting up...", style: .primary),
            allowDismissOnTap: false,
            loadingState: PopupLoadingState(
                title: "Encrypting your financial data...",
                subtitle: "This process may take a few minutes"
            )
        )
    }
    
    static func encryptionMigrationSuccess() -> PopupConfig {
        PopupConfig(
            title: "Encryption Enabled!",
            subtitle: "Your financial data is now fully protected",
            category: "Success",
            icon: PopupIcon(
                systemName: "checkmark.shield.fill",
                color: .green,
                backgroundColors: [Color.green.opacity(0.2), Color.mint.opacity(0.1)]
            ),
            features: [],
            primaryAction: PopupAction(title: "Continue", style: .primary),
            allowDismissOnTap: false,
            successState: PopupSuccessState(
                title: "Encryption Complete!",
                subtitle: "Your financial data is now secure and encrypted",
                actionTitle: "Continue to App"
            )
        )
    }
    
    static func encryptionPasswordEntry(password: Binding<String>, isPasswordVisible: Binding<Bool>, errorMessage: String) -> PopupConfig {
        PopupConfig(
            title: "Enter Your Password",
            subtitle: "Please confirm your password to enable encryption",
            category: "Security Verification",
            icon: PopupIcon(
                systemName: "key.fill",
                color: .blue,
                backgroundColors: [Color.blue.opacity(0.2), Color.indigo.opacity(0.1)]
            ),
            features: [],
            primaryAction: PopupAction(
                title: "Verify & Continue",
                icon: "arrow.right.circle",
                style: .primary
            ),
            secondaryAction: PopupAction(
                title: "Cancel",
                style: .secondary
            ),
            allowDismissOnTap: true,
            customContent: AnyView(
                PasswordInputView(
                    password: password,
                    isPasswordVisible: isPasswordVisible,
                    errorMessage: errorMessage
                )
            )
        )
    }
    
    static func encryptionMigrationError(errorMessage: String) -> PopupConfig {
        PopupConfig(
            title: "Verification Failed",
            subtitle: errorMessage,
            category: "Error",
            icon: PopupIcon(
                systemName: "exclamationmark.triangle.fill",
                color: .red,
                backgroundColors: [Color.red.opacity(0.2), Color.orange.opacity(0.1)]
            ),
            features: [],
            primaryAction: PopupAction(
                title: "Try Again",
                icon: "arrow.clockwise",
                style: .primary
            ),
            allowDismissOnTap: false
        )
    }
    
    static func appUpdate(
        version: String,
        features: [String],
        onUpdate: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) -> PopupConfig {
        PopupConfig(
            title: "App Update Available",
            subtitle: "Version \(version) is now available with new features",
            category: "What's New",
            icon: PopupIcon(
                systemName: "arrow.up.circle.fill",
                color: .green,
                backgroundColors: [Color.green.opacity(0.2), Color.mint.opacity(0.1)]
            ),
            features: features.map { feature in
                PopupFeature(
                    icon: "checkmark.circle.fill",
                    title: feature,
                    description: "",
                    iconColor: .green
                )
            },
            primaryAction: PopupAction(
                title: "Update Now",
                icon: "arrow.down.circle",
                style: .primary
            ),
            secondaryAction: PopupAction(
                title: "Later",
                style: .secondary
            ),
            loadingState: PopupLoadingState(
                title: "Downloading update...",
                subtitle: "This may take a few minutes"
            )
        )
    }
    
    static func dataBackup(
        lastBackup: String,
        onBackup: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) -> PopupConfig {
        PopupConfig(
            title: "Backup Your Data",
            subtitle: "Last backup: \(lastBackup)",
            category: "Data Protection",
            icon: PopupIcon(
                systemName: "icloud.and.arrow.up",
                color: .blue,
                backgroundColors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.1)]
            ),
            features: [
                PopupFeature(
                    icon: "checkmark.shield.fill",
                    title: "Secure Cloud Storage",
                    description: "Your data is safely stored in encrypted cloud storage"
                ),
                PopupFeature(
                    icon: "arrow.clockwise",
                    title: "Automatic Sync",
                    description: "Access your data across all your devices"
                )
            ],
            primaryAction: PopupAction(
                title: "Backup Now",
                icon: "icloud.and.arrow.up",
                style: .primary
            ),
            secondaryAction: PopupAction(
                title: "Skip",
                style: .secondary
            ),
            loadingState: PopupLoadingState(
                title: "Backing up your data...",
                subtitle: "Securing your financial information"
            )
        )
    }
    
    static func featureIntroduction(
        featureTitle: String,
        description: String,
        benefits: [PopupFeature],
        onTryNow: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) -> PopupConfig {
        PopupConfig(
            title: featureTitle,
            subtitle: description,
            category: "New Feature",
            icon: PopupIcon(
                systemName: "sparkles",
                color: .purple,
                backgroundColors: [Color.purple.opacity(0.2), Color.pink.opacity(0.1)]
            ),
            features: benefits,
            primaryAction: PopupAction(
                title: "Try Now",
                icon: "play.circle",
                style: .primary
            ),
            secondaryAction: PopupAction(
                title: "Maybe Later",
                style: .secondary
            ),
            loadingState: PopupLoadingState(
                title: "Initializing feature...",
                subtitle: "Setting up your personalized experience"
            )
        )
    }
    
    static func criticalNotice(
        title: String,
        message: String,
        actionTitle: String = "Got It",
        isDestructive: Bool = false,
        onAction: @escaping () -> Void
    ) -> PopupConfig {
        PopupConfig(
            title: title,
            subtitle: message,
            category: "Important",
            icon: PopupIcon(
                systemName: isDestructive ? "exclamationmark.triangle.fill" : "info.circle.fill",
                color: isDestructive ? .red : .orange,
                backgroundColors: isDestructive ? 
                    [Color.red.opacity(0.2), Color.orange.opacity(0.1)] :
                    [Color.orange.opacity(0.2), Color.yellow.opacity(0.1)]
            ),
            features: [],
            primaryAction: PopupAction(
                title: actionTitle,
                style: isDestructive ? .destructive : .primary
            ),
            allowDismissOnTap: false
        )
    }
    
    static func billPeriodVerification(
        billCount: Int,
        onConfirmAll: @escaping () -> Void,
        onReviewBills: @escaping () -> Void
    ) -> PopupConfig {
        PopupConfig(
            title: "New Billing Period",
            subtitle: "A new billing period has started. Will the bills you have carry over to this month?",
            category: "Bill Verification",
            icon: PopupIcon(
                systemName: "calendar.badge.exclamationmark",
                color: .blue,
                backgroundColors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.1)]
            ),
            features: [
                PopupFeature(
                    icon: "doc.text.fill",
                    title: "\(billCount) Bills to Review",
                    description: "Bills marked as paid that may need status updates",
                    iconColor: .blue
                ),
                PopupFeature(
                    icon: "checkmark.circle.fill",
                    title: "Quick Confirmation",
                    description: "Confirm all bills carry over or review individually",
                    iconColor: .green
                )
            ],
            primaryAction: PopupAction(
                title: "Yes",
                icon: "checkmark.circle.fill",
                style: .primary
            ),
            secondaryAction: PopupAction(
                title: "Review Bills",
                style: .secondary
            ),
            allowDismissOnTap: false
        )
    }
}

// MARK: - Preview

#Preview {
    InformationalPopup(
        isPresented: .constant(true),
        config: .encryptionMigration(
            onMigrate: { print("Migrate") },
            onDismiss: { print("Dismiss") }
        ),
        onPrimaryAction: { print("Primary action") },
        onSecondaryAction: { print("Secondary action") },
        onDismiss: { print("Dismiss") }
    )
    .preferredColorScheme(.dark)
}
