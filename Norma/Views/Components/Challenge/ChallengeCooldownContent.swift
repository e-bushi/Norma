//
//  ChallengeCooldownContent.swift
//  Norma
//
//  Created by Claude on 1/17/26.
//

import SwiftUI
import Combine
import SceneKit
import UserNotifications

/// Content shown when user has already started a challenge today (cooldown state)
struct ChallengeCooldownContent: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel

    // MARK: - State

    @State private var timeRemaining: TimeInterval = 0
    @State private var timerSubscription: AnyCancellable?

    @State private var birdAppeared = false
    @State private var textAppeared = false
    @State private var statsAppeared = false
    @State private var progressAppeared = false
    @State private var actionsAppeared = false

    @State private var glowPulse = false
    @State private var showBirdCollection = false
    @State private var reminderSet = false

    // MARK: - Countdown Helpers

    private var midnightTarget: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
    }

    private var hours: Int { Int(timeRemaining) / 3600 }
    private var minutes: Int { (Int(timeRemaining) % 3600) / 60 }
    private var seconds: Int { Int(timeRemaining) % 60 }

    private var headlineMessage: String {
        "Over Budget Today"
    }

    private var subtitleMessage: String {
        "Every day is a fresh start. You'll get another shot tomorrow."
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // MARK: Hero Bird with Glow + Progress Ring
            heroBirdSection

            Spacer()
                .frame(height: 24)

            // MARK: Message + Countdown
            countdownSection

            Spacer()
                .frame(height: 32)

            // MARK: Stats + Tier Progress
            statsSection

            Spacer()
                .frame(height: 32)

            // MARK: Action Buttons
            actionsSection

            Spacer()
        }
        .padding(.horizontal, 20)
        .onAppear {
            startTimer()

            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                birdAppeared = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                textAppeared = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35)) {
                statsAppeared = true
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5)) {
                progressAppeared = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5)) {
                actionsAppeared = true
            }
        }
        .onDisappear {
            stopTimer()
        }
        .sheet(isPresented: $showBirdCollection) {
            BirdCollectionView(totalPoints: challengeViewModel.totalPoints)
        }
    }

    // MARK: - Hero Bird Section

    private var heroBirdSection: some View {
        ZStack {
            // Ambient pulsing glow
            Circle()
                .fill(challengeViewModel.currentTier.glowColor.opacity(0.15))
                .frame(width: 180, height: 180)
                .blur(radius: 40)
                .scaleEffect(glowPulse ? 1.1 : 0.9)
                .opacity(birdAppeared ? 1 : 0)

            // Progress ring background
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 5)
                .frame(width: 150, height: 150)
                .opacity(birdAppeared ? 1 : 0)

            // Progress ring foreground
            Circle()
                .trim(from: 0, to: progressAppeared ? CGFloat(challengeViewModel.progressToNextTier) : 0)
                .stroke(
                    challengeViewModel.currentTier.glowColor,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(-90))
                .opacity(birdAppeared ? 1 : 0)

            // 3D Spinning Bird
            HeroSpinningBird3DView(fileName: challengeViewModel.currentTier.fileName)
                .id(challengeViewModel.currentTier.fileName)
                .frame(width: 110, height: 110)
                .scaleEffect(birdAppeared ? 1 : 0)
                .opacity(birdAppeared ? 1 : 0)
        }
    }

    // MARK: - Countdown Section

    private var countdownSection: some View {
        VStack(spacing: 12) {
            Text(headlineMessage)
                .font(.custom(FontFamily.Rubik.bold, size: 28))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text(subtitleMessage)
                .font(.custom(FontFamily.Rubik.regular, size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
                .frame(height: 4)

            // Countdown timer
            HStack(alignment: .top, spacing: 4) {
                CountdownDigitPair(value: hours, unit: "h")

                Text(":")
                    .font(.custom(FontFamily.Rubik.medium, size: 32))
                    .foregroundColor(.secondary)
                    .frame(height: 38, alignment: .top)

                CountdownDigitPair(value: minutes, unit: "m")

                Text(":")
                    .font(.custom(FontFamily.Rubik.medium, size: 32))
                    .foregroundColor(.secondary)
                    .frame(height: 38, alignment: .top)

                CountdownDigitPair(value: seconds, unit: "s")
            }
        }
        .opacity(textAppeared ? 1 : 0)
        .offset(y: textAppeared ? 0 : 10)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                StatPill(
                    icon: "flame.fill",
                    value: "\(challengeViewModel.currentStreak)",
                    label: "streak"
                )

                StatPill(
                    icon: "star.fill",
                    value: "\(challengeViewModel.totalPoints)",
                    label: "points"
                )
            }

            // Tier progress bar
            if let nextTier = challengeViewModel.nextTier {
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(challengeViewModel.currentTier.glowColor)
                                .frame(
                                    width: progressAppeared
                                        ? geo.size.width * CGFloat(challengeViewModel.progressToNextTier)
                                        : 0,
                                    height: 6
                                )
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text(challengeViewModel.currentTier.displayName)
                            .font(.custom(FontFamily.Rubik.medium, size: 12))
                            .foregroundColor(challengeViewModel.currentTier.glowColor)

                        Spacer()

                        Text("\(challengeViewModel.pointsToNextTier) pts to \(nextTier.displayName)")
                            .font(.custom(FontFamily.Rubik.regular, size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .opacity(statsAppeared ? 1 : 0)
        .offset(y: statsAppeared ? 0 : 10)
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                showBirdCollection = true
            } label: {
                Text("View Collection")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 17))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("NormaPastelTeal"))
                    )
            }

            Button {
                scheduleReminderForTomorrow()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: reminderSet ? "bell.badge.fill" : "bell.badge")
                        .font(.system(size: 15))
                    Text(reminderSet ? "Reminder Set!" : "Remind Me Tomorrow")
                        .font(.custom(FontFamily.Rubik.medium, size: 16))
                }
                .foregroundColor(reminderSet ? Color("NormaPastelTeal") : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        .fill(Color.gray.opacity(0.04))
                )
            }
            .disabled(reminderSet)
        }
        .opacity(actionsAppeared ? 1 : 0)
        .offset(y: actionsAppeared ? 0 : 10)
    }

    // MARK: - Timer

    private func startTimer() {
        timeRemaining = max(0, midnightTarget.timeIntervalSince(Date()))

        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let remaining = midnightTarget.timeIntervalSince(Date())
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    timeRemaining = max(0, remaining)
                }
            }
    }

    private func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }

    // MARK: - Reminder

    private func scheduleReminderForTomorrow() {
        let content = UNMutableNotificationContent()
        content.title = "Your new challenge awaits!"
        content.body = "A fresh spending challenge is ready. Can you beat yesterday?"
        content.sound = .default

        var dateComponents = DateComponents()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let tomorrowComponents = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        dateComponents.year = tomorrowComponents.year
        dateComponents.month = tomorrowComponents.month
        dateComponents.day = tomorrowComponents.day
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "challenge-reminder-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if error == nil {
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        reminderSet = true
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        }
    }
}

// MARK: - Countdown Digit Pair

struct CountdownDigitPair: View {
    let value: Int
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(.custom(FontFamily.Rubik.semiBold, size: 32))
                .monospacedDigit()
                .foregroundColor(.primary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: value)

            Text(unit)
                .font(.custom(FontFamily.Rubik.regular, size: 11))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))

            HStack(spacing: 3) {
                Text(value)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 14))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)

                Text(label)
                    .font(.custom(FontFamily.Rubik.medium, size: 14))
            }
        }
        .foregroundColor(.primary.opacity(0.8))
        .fixedSize()
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.clear)
                .glassEffect(in: Capsule())
        )
    }
}

// MARK: - Previews

#Preview("Cooldown State") {
    ChallengeCooldownContent()
        .background(Color("NormaBackground"))
        .environmentObject(ChallengeViewModel(
            dataManager: DataManager(),
            sessionViewModel: SessionViewModel(dataManager: DataManager())
        ))
}

#Preview("Stat Pills") {
    HStack(spacing: 12) {
        StatPill(icon: "flame.fill", value: "5", label: "streak")
        StatPill(icon: "star.fill", value: "42", label: "points")
    }
    .padding(24)
    .background(Color("NormaBackground"))
}
