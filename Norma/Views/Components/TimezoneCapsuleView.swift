//
//  TimezoneCapsuleView.swift
//  Norma
//
//  Individual timezone capsule with live-updating time display
//

import SwiftUI

struct TimezoneCapsuleView: View {
    let timezone: TimezoneInfo
    var color: Color = Color("NormaPastelTeal")
    let onTap: () -> Void

    @ObservedObject private var timezoneManager = TimezoneManager.shared

    var body: some View {
        Button {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        } label: {
            HStack(spacing: 6) {
                // City name
                Text(timezone.city)
                    .font(.normaFinancial(15))

                    .lineLimit(1)
                    .fixedSize()

                // Live time with numeric transition
                HStack(spacing: 1) {
                    Text(timezoneManager.formattedHour(for: timezone))
                        .contentTransition(.numericText())

                    Text(":")

                    Text(timezoneManager.formattedMinute(for: timezone))
                        .contentTransition(.numericText())

                    Text(timezoneManager.formattedPeriod(for: timezone))
                        .textCase(.lowercase)
                }
                .font(.normaFinancial(15))
                .fontWeight(.medium)
                .animation(.easeInOut(duration: 0.3), value: timezoneManager.currentTimes[timezone.id])
            }
            .foregroundColor(Color(.tertiaryLabel))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .buttonStyle(CapsulePressStyle())
    }
}

/// Deck-style timezone card with glass effect background
struct TimezoneCardView: View {
    let timezone: TimezoneInfo
    var color: Color = Color("NormaPastelTeal")
    let onTap: () -> Void

    @ObservedObject private var timezoneManager = TimezoneManager.shared

    var body: some View {
        Button {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        } label: {
            HStack(spacing: 6) {
                // City name
                Text(timezone.city)
                    .font(.normaFinancial(15))
                    .lineLimit(1)
                    .fixedSize()

                // Live time with numeric transition
                HStack(spacing: 1) {
                    Text(timezoneManager.formattedHour(for: timezone))
                        .contentTransition(.numericText())

                    Text(":")

                    Text(timezoneManager.formattedMinute(for: timezone))
                        .contentTransition(.numericText())

                    Text(timezoneManager.formattedPeriod(for: timezone))
                        .textCase(.lowercase)
                }
                .font(.normaFinancial(15))
                .fontWeight(.medium)
                .animation(.easeInOut(duration: 0.3), value: timezoneManager.currentTimes[timezone.id])
            }
            .foregroundColor(Color(.tertiaryLabel))
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .overlay {
                Capsule()
                    .fill(.clear)
                    .glassEffect(in: .capsule)
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(CapsulePressStyle())
    }
}

/// Empty state capsule to add a new timezone
struct AddTimezoneCapsuleView: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))

                Text("Add Timezone")
                    .font(.custom(FontFamily.Rubik.medium, size: 13))
            }
            .foregroundColor(Color("NormaPastelTeal").opacity(0.6))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color("NormaPastelTeal").opacity(0.08))
                    .glassEffect(in: Capsule())
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                    )
                    .foregroundColor(Color("NormaPastelTeal").opacity(0.3))
            )
        }
        .buttonStyle(CapsulePressStyle())
    }
}

#Preview {
    ZStack {
        Color("NormaBackground")
            .ignoresSafeArea()

        VStack(spacing: 12) {
            TimezoneCapsuleView(
                timezone: TimezoneInfo(id: "America/New_York", city: "New York", country: "USA")
            ) {
                print("Tapped New York")
            }

            TimezoneCapsuleView(
                timezone: TimezoneInfo(id: "Europe/London", city: "London", country: "UK")
            ) {
                print("Tapped London")
            }

            AddTimezoneCapsuleView {
                print("Add timezone tapped")
            }
        }
    }
}
