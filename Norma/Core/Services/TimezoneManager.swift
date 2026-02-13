//
//  TimezoneManager.swift
//  Norma
//
//  Manages user's selected timezones with persistence
//

import Foundation
import Combine

/// Represents a timezone with display info
struct TimezoneInfo: Identifiable, Codable, Equatable {
    let id: String  // TimeZone identifier (e.g., "America/New_York")
    let city: String
    let country: String

    var timeZone: TimeZone? {
        TimeZone(identifier: id)
    }

    var abbreviation: String {
        timeZone?.abbreviation() ?? ""
    }
}

/// Manages selected timezones with live updates
@MainActor
class TimezoneManager: ObservableObject {
    static let shared = TimezoneManager()

    private let storageKey = "selectedTimezones"
    private let maxTimezones = 3

    @Published private(set) var selectedTimezones: [TimezoneInfo] = []
    @Published private(set) var currentTimes: [String: Date] = [:]

    private var timer: Timer?

    private init() {
        loadTimezones()
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Public Methods

    func addTimezone(_ timezone: TimezoneInfo) {
        guard selectedTimezones.count < maxTimezones else { return }
        guard !selectedTimezones.contains(where: { $0.id == timezone.id }) else { return }

        selectedTimezones.append(timezone)
        saveTimezones()
        updateTimes()
    }

    func removeTimezone(_ timezone: TimezoneInfo) {
        selectedTimezones.removeAll { $0.id == timezone.id }
        currentTimes.removeValue(forKey: timezone.id)
        saveTimezones()
    }

    func replaceTimezone(at index: Int, with timezone: TimezoneInfo) {
        guard index < selectedTimezones.count else { return }
        guard !selectedTimezones.contains(where: { $0.id == timezone.id }) else { return }

        let oldId = selectedTimezones[index].id
        currentTimes.removeValue(forKey: oldId)
        selectedTimezones[index] = timezone
        saveTimezones()
        updateTimes()
    }

    var canAddMore: Bool {
        selectedTimezones.count < maxTimezones
    }

    func currentTime(for timezone: TimezoneInfo) -> Date {
        currentTimes[timezone.id] ?? Date()
    }

    func formattedTime(for timezone: TimezoneInfo) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone.timeZone
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }

    func formattedHour(for timezone: TimezoneInfo) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone.timeZone
        formatter.dateFormat = "h"
        return formatter.string(from: Date())
    }

    func formattedMinute(for timezone: TimezoneInfo) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone.timeZone
        formatter.dateFormat = "mm"
        return formatter.string(from: Date())
    }

    func formattedPeriod(for timezone: TimezoneInfo) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone.timeZone
        formatter.dateFormat = "a"
        return formatter.string(from: Date())
    }

    // MARK: - Private Methods

    private func startTimer() {
        updateTimes()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimes()
            }
        }
    }

    private func updateTimes() {
        let now = Date()
        for timezone in selectedTimezones {
            currentTimes[timezone.id] = now
        }
        objectWillChange.send()
    }

    private func saveTimezones() {
        if let data = try? JSONEncoder().encode(selectedTimezones) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadTimezones() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let timezones = try? JSONDecoder().decode([TimezoneInfo].self, from: data) else {
            return
        }
        selectedTimezones = timezones
    }

    // MARK: - Available Timezones

    static let popularTimezones: [TimezoneInfo] = [
        TimezoneInfo(id: "America/New_York", city: "New York", country: "USA"),
        TimezoneInfo(id: "America/Los_Angeles", city: "Los Angeles", country: "USA"),
        TimezoneInfo(id: "America/Chicago", city: "Chicago", country: "USA"),
        TimezoneInfo(id: "America/Denver", city: "Denver", country: "USA"),
        TimezoneInfo(id: "America/Phoenix", city: "Phoenix", country: "USA"),
        TimezoneInfo(id: "America/Toronto", city: "Toronto", country: "Canada"),
        TimezoneInfo(id: "America/Vancouver", city: "Vancouver", country: "Canada"),
        TimezoneInfo(id: "America/Mexico_City", city: "Mexico City", country: "Mexico"),
        TimezoneInfo(id: "America/Sao_Paulo", city: "Sao Paulo", country: "Brazil"),
        TimezoneInfo(id: "America/Buenos_Aires", city: "Buenos Aires", country: "Argentina"),
        TimezoneInfo(id: "Europe/London", city: "London", country: "UK"),
        TimezoneInfo(id: "Europe/Paris", city: "Paris", country: "France"),
        TimezoneInfo(id: "Europe/Berlin", city: "Berlin", country: "Germany"),
        TimezoneInfo(id: "Europe/Rome", city: "Rome", country: "Italy"),
        TimezoneInfo(id: "Europe/Madrid", city: "Madrid", country: "Spain"),
        TimezoneInfo(id: "Europe/Amsterdam", city: "Amsterdam", country: "Netherlands"),
        TimezoneInfo(id: "Europe/Zurich", city: "Zurich", country: "Switzerland"),
        TimezoneInfo(id: "Europe/Stockholm", city: "Stockholm", country: "Sweden"),
        TimezoneInfo(id: "Europe/Moscow", city: "Moscow", country: "Russia"),
        TimezoneInfo(id: "Europe/Istanbul", city: "Istanbul", country: "Turkey"),
        TimezoneInfo(id: "Asia/Dubai", city: "Dubai", country: "UAE"),
        TimezoneInfo(id: "Asia/Mumbai", city: "Mumbai", country: "India"),
        TimezoneInfo(id: "Asia/Kolkata", city: "Kolkata", country: "India"),
        TimezoneInfo(id: "Asia/Bangkok", city: "Bangkok", country: "Thailand"),
        TimezoneInfo(id: "Asia/Singapore", city: "Singapore", country: "Singapore"),
        TimezoneInfo(id: "Asia/Hong_Kong", city: "Hong Kong", country: "China"),
        TimezoneInfo(id: "Asia/Shanghai", city: "Shanghai", country: "China"),
        TimezoneInfo(id: "Asia/Tokyo", city: "Tokyo", country: "Japan"),
        TimezoneInfo(id: "Asia/Seoul", city: "Seoul", country: "South Korea"),
        TimezoneInfo(id: "Australia/Sydney", city: "Sydney", country: "Australia"),
        TimezoneInfo(id: "Australia/Melbourne", city: "Melbourne", country: "Australia"),
        TimezoneInfo(id: "Australia/Perth", city: "Perth", country: "Australia"),
        TimezoneInfo(id: "Pacific/Auckland", city: "Auckland", country: "New Zealand"),
        TimezoneInfo(id: "Pacific/Honolulu", city: "Honolulu", country: "USA"),
        TimezoneInfo(id: "Africa/Cairo", city: "Cairo", country: "Egypt"),
        TimezoneInfo(id: "Africa/Johannesburg", city: "Johannesburg", country: "South Africa"),
        TimezoneInfo(id: "Africa/Lagos", city: "Lagos", country: "Nigeria"),
    ]
}
