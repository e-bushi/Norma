//
//  BillPeriodVerificationView.swift
//  Norma
//
//  Created by Claude on 7/29/25.
//

import SwiftUI
import CoreHaptics

struct BillPeriodVerificationView: View {
    @StateObject private var verificationService: BillPeriodVerificationService
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showReviewView = false
    @State private var isProcessing = false

    // Animation states
    @State private var animateHero = false
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateBills = false
    @State private var animateButtons = false
    @State private var hapticEngine: CHHapticEngine?

    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    init(verificationService: BillPeriodVerificationService) {
        self._verificationService = StateObject(wrappedValue: verificationService)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with floating orbs
                Color("NormaBackground")
                    .ignoresSafeArea()

                // Floating orbs for ambient effect
                LavaOrb(
                    color: Color("NormaPastelTeal"),
                    size: 180,
                    blur: 50,
                    opacity: 0.15,
                    bounds: geometry.size,
                    speed: 5.0
                )

                LavaOrb(
                    color: Color("NormaPastelPurple"),
                    size: 140,
                    blur: 40,
                    opacity: 0.12,
                    bounds: geometry.size,
                    speed: 6.0
                )

                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 60)

                        // Hero icon
                        ZStack {
                            // Outer glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color("NormaPastelTeal").opacity(0.2),
                                            Color("NormaPastelTeal").opacity(0.05),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 120, height: 120)

                            // Glass circle
                            Circle()
                                .fill(Color("NormaPastelTeal").opacity(0.1))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(Color("NormaPastelTeal").opacity(0.3), lineWidth: 1)
                                )

                            // Icon
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color("NormaPastelTeal"), Color("NormaPastelPurple")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .scaleEffect(animateHero ? 1.0 : 0.5)
                        .opacity(animateHero ? 1.0 : 0.0)
                        .padding(.bottom, 24)

                        // Title - conversational
                        WaveTextView(
                            text: "Hey, it's a new month",
                            font: .normaHeadline(32),
                            color: .primary,
                            isAnimating: animateTitle,
                            alignment: .center
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)

                        // Subtitle - honest about what's happening
                        Text("Want me to update your bills for \(currentMonthName)? If anything's changed—like a bill you cancelled—you can review first.")
                            .normaBody()
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .offset(y: animateSubtitle ? 0 : 20)
                            .opacity(animateSubtitle ? 1.0 : 0.0)
                            .padding(.bottom, 28)

                        // Bills preview
                        if !verificationService.billsToVerify.isEmpty {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("\(verificationService.billsToVerify.count) bill\(verificationService.billsToVerify.count == 1 ? "" : "s") to update")
                                        .normaCaption()
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 4)

                                VStack(spacing: 8) {
                                    ForEach(Array(verificationService.billsToVerify.prefix(3).enumerated()), id: \.element.id) { index, bill in
                                        BillPreviewRow(bill: bill)
                                            .environmentObject(profileViewModel)
                                            .offset(y: animateBills ? 0 : 20)
                                            .opacity(animateBills ? 1.0 : 0.0)
                                            .animation(
                                                .spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.08),
                                                value: animateBills
                                            )
                                    }

                                    if verificationService.billsToVerify.count > 3 {
                                        Text("+ \(verificationService.billsToVerify.count - 3) more")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Color("NormaPastelTeal"))
                                            .padding(.top, 4)
                                            .opacity(animateBills ? 1.0 : 0.0)
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("NormaSurface"))
                            )
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                        }

                        // Action buttons
                        VStack(spacing: 12) {
                            // Primary button - "Sounds Good"
                            Button(action: {
                                playHaptic(intensity: 0.7, sharpness: 0.5)
                                Task {
                                    isProcessing = true
                                    await verificationService.confirmAllBills()
                                    isProcessing = false
                                    dismiss()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    if isProcessing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }

                                    Text(isProcessing ? "Updating..." : "Sounds Good")
                                        .font(.normaHeadline(16))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("NormaPastelTeal"))
                                )
                                .opacity(isProcessing ? 0.8 : 1.0)
                            }
                            .disabled(isProcessing)
                            .buttonStyle(.plain)

                            // Secondary button - "Let Me Check"
                            Button(action: {
                                playHaptic(intensity: 0.5, sharpness: 0.3)
                                showReviewView = true
                            }) {
                                Text("Let Me Check")
                                    .font(.normaHeadline(16))
                                    .foregroundColor(Color("NormaPastelTeal"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color("NormaPastelTeal").opacity(0.1))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                        .offset(y: animateButtons ? 0 : 30)
                        .opacity(animateButtons ? 1.0 : 0.0)

                        Spacer(minLength: 40)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .sheet(isPresented: $showReviewView) {
            BillReviewSelectionView(verificationService: verificationService) {
                dismiss()
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        prepareHaptics()

        // Hero pops in first
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
            animateHero = true
        }
        playHaptic(intensity: 0.6, sharpness: 0.4)

        // Title wave starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            animateTitle = true
            playHaptic(intensity: 0.5, sharpness: 0.3)
        }

        // Subtitle fades in
        withAnimation(.easeOut(duration: 0.4).delay(0.25)) {
            animateSubtitle = true
        }

        // Bills animate in
        withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
            animateBills = true
        }

        // Buttons slide up
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.5)) {
            animateButtons = true
        }
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine error: \(error.localizedDescription)")
        }
    }

    private func playHaptic(intensity: Float, sharpness: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = hapticEngine else { return }

        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensityParam, sharpnessParam], relativeTime: 0)

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic playback error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Bill Preview Row

private struct BillPreviewRow: View {
    let bill: Bill
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color("NormaPastelTeal").opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: "doc.text")
                    .font(.system(size: 16))
                    .foregroundColor(Color("NormaPastelTeal"))
            }

            // Bill info
            VStack(alignment: .leading, spacing: 2) {
                Text(bill.name)
                    .font(.normaHeadline(15))
                    .foregroundColor(.primary)

                Text(bill.frequency.rawValue)
                    .normaCaption()
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Amount
            Text(profileViewModel.formatCurrency(bill.amount))
                .font(.normaFinancial(15))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("NormaBackground"))
        )
    }
}

struct BillReviewSelectionView: View {
    @StateObject private var verificationService: BillPeriodVerificationService
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedBillIds: Set<String> = []
    @State private var isProcessing = false
    @State private var animateContent = false

    let onComplete: () -> Void

    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    init(verificationService: BillPeriodVerificationService, onComplete: @escaping () -> Void) {
        self._verificationService = StateObject(wrappedValue: verificationService)
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("NormaBackground")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Which bills are staying?")
                            .font(.normaHeadline(24))
                            .foregroundColor(.primary)

                        Text("Tap to select the bills you still have. Unselected ones will be removed.")
                            .normaBody()
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                    .offset(y: animateContent ? 0 : 20)
                    .opacity(animateContent ? 1.0 : 0.0)

                    // Bills list
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(verificationService.billsToVerify.enumerated()), id: \.element.id) { index, bill in
                                BillToggleRow(
                                    bill: bill,
                                    isSelected: selectedBillIds.contains(bill.id ?? ""),
                                    onToggle: { isSelected in
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if let billId = bill.id {
                                                if isSelected {
                                                    selectedBillIds.insert(billId)
                                                } else {
                                                    selectedBillIds.remove(billId)
                                                }
                                            }
                                        }
                                        // Light haptic on toggle
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    }
                                )
                                .environmentObject(profileViewModel)
                                .offset(y: animateContent ? 0 : 20)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.05),
                                    value: animateContent
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                    }

                    Spacer(minLength: 0)
                }

                // Bottom action area
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 12) {
                        // Selection count
                        Text("\(selectedBillIds.count) of \(verificationService.billsToVerify.count) selected")
                            .normaCaption()
                            .foregroundColor(.secondary)

                        // Confirm button
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()

                            Task {
                                isProcessing = true
                                await verificationService.reviewBills(selectedBillIds: selectedBillIds)
                                isProcessing = false
                                onComplete()
                            }
                        }) {
                            HStack(spacing: 8) {
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }

                                Text(isProcessing ? "Updating..." : "Update \(currentMonthName) Bills")
                                    .font(.normaHeadline(16))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("NormaPastelTeal"))
                            )
                            .opacity(isProcessing ? 0.8 : 1.0)
                        }
                        .disabled(isProcessing)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        Rectangle()
                            .fill(Color("NormaBackground"))
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                // Pre-select all bills by default
                selectedBillIds = Set(verificationService.billsToVerify.compactMap { $0.id })

                // Start animations
                withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                    animateContent = true
                }
            }
        }
    }
}

struct BillToggleRow: View {
    let bill: Bill
    let isSelected: Bool
    let onToggle: (Bool) -> Void

    @EnvironmentObject private var profileViewModel: ProfileViewModel

    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack(spacing: 14) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? Color("NormaPastelTeal") : Color.clear)
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color("NormaPastelTeal") : Color.secondary.opacity(0.3),
                                    lineWidth: 2
                                )
                        )

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

                // Bill info
                VStack(alignment: .leading, spacing: 3) {
                    Text(bill.name)
                        .font(.normaHeadline(16))
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        Text(bill.frequency.rawValue)
                            .normaCaption()
                            .foregroundColor(.secondary)

                        Text("•")
                            .normaCaption()
                            .foregroundColor(.secondary.opacity(0.5))

                        Text("Due \(formatDueDate(bill.dueDate))")
                            .normaCaption()
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Amount
                Text(profileViewModel.formatCurrency(bill.amount))
                    .font(.normaFinancial(16))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color("NormaPastelTeal").opacity(0.08) : Color("NormaSurface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color("NormaPastelTeal").opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview("New Month View") {
    let dataManager = DataManager()
    let verificationService = BillPeriodVerificationService(dataManager: dataManager)

    // Add some sample bills for preview
    verificationService.billsToVerify = [
        Bill(
            id: "1",
            userId: "user1",
            name: "Rent",
            dueDate: Date(),
            amount: 1200.0,
            status: .paid,
            frequency: .monthly
        ),
        Bill(
            id: "2",
            userId: "user1",
            name: "Internet",
            dueDate: Date(),
            amount: 89.99,
            status: .paid,
            frequency: .monthly
        ),
        Bill(
            id: "3",
            userId: "user1",
            name: "Phone",
            dueDate: Date(),
            amount: 45.00,
            status: .paid,
            frequency: .monthly
        ),
        Bill(
            id: "4",
            userId: "user1",
            name: "Netflix",
            dueDate: Date(),
            amount: 15.99,
            status: .paid,
            frequency: .monthly
        )
    ]

    return BillPeriodVerificationView(verificationService: verificationService)
        .environmentObject({
            let sessionViewModel = SessionViewModel(dataManager: dataManager)
            return ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
        }())
        .preferredColorScheme(.dark)
}

#Preview("Review Bills") {
    let dataManager = DataManager()
    let verificationService = BillPeriodVerificationService(dataManager: dataManager)

    verificationService.billsToVerify = [
        Bill(
            id: "1",
            userId: "user1",
            name: "Rent",
            dueDate: Date(),
            amount: 1200.0,
            status: .paid,
            frequency: .monthly
        ),
        Bill(
            id: "2",
            userId: "user1",
            name: "Internet",
            dueDate: Date(),
            amount: 89.99,
            status: .paid,
            frequency: .monthly
        ),
        Bill(
            id: "3",
            userId: "user1",
            name: "Phone",
            dueDate: Date(),
            amount: 45.00,
            status: .paid,
            frequency: .monthly
        )
    ]

    return BillReviewSelectionView(verificationService: verificationService) {}
        .environmentObject({
            let sessionViewModel = SessionViewModel(dataManager: dataManager)
            return ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
        }())
        .preferredColorScheme(.dark)
}