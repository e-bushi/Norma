//
//  ScreenshotMode.swift
//  Norma
//
//  A frozen home screen for screenshot baselines. Launch with `--screenshot`
//  and the home screen is October 2026 with the same bills every run, so a
//  pixel diff means the layout changed.
//

import SwiftData
import SwiftUI

enum ScreenshotMode {
    static let isActive = ProcessInfo.processInfo.arguments.contains("--screenshot")

    /// Noon on the requested calendar day, in the device calendar, so month
    /// names and "days late" do not follow the wall clock.
    static let referenceDate: Date = {
        let calendar = Calendar.current
        let raw = argument(prefixed: "--reference-date=") ?? "2026-10-15"
        let parts = raw.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return Date() }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12)) ?? Date()
    }()

    static var now: Date { isActive ? referenceDate : Date() }

    /// Default Dynamic Type is `.large`. Accessibility is AX5, the largest size.
    static var dynamicTypeSize: DynamicTypeSize {
        argument(prefixed: "--dynamic-type=") == "accessibility" ? .accessibility5 : .large
    }

    static var animation: Animation? { isActive ? nil : .snappy }

    @MainActor
    static func seed(_ container: ModelContainer) {
        guard isActive else { return }
        let calendar = Calendar.current
        let today = referenceDate
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)
        func day(_ day: Int) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? today
        }

        let context = container.mainContext
        let profile = UserProfile(incomeAmount: 4000, incomeCadence: .monthly(day: 1))
        context.insert(profile)

        let rent = Bill(name: "rent", amount: 1500, dueDate: day(1), frequency: .monthly, isReminderOn: false)
        let internet = Bill(name: "internet", amount: 60, dueDate: day(5), frequency: .monthly, isReminderOn: false)
        let phone = Bill(name: "phone", amount: 80, dueDate: day(20), frequency: .monthly, isReminderOn: false)
        context.insert(rent)
        context.insert(internet)
        context.insert(phone)
        internet.setPaid(true, for: day(5), calendar: calendar)
        do {
            try context.save()
        } catch {
            fatalError("Failed to seed screenshot data: \(error)")
        }
    }

    private static func argument(prefixed prefix: String) -> String? {
        ProcessInfo.processInfo.arguments.first { $0.hasPrefix(prefix) }.map { String($0.dropFirst(prefix.count)) }
    }
}

struct ScreenshotHomeMarker: ViewModifier {
    func body(content: Content) -> some View {
        if ScreenshotMode.isActive {
            content.accessibilityIdentifier("screenshot-home")
        } else {
            content
        }
    }
}
