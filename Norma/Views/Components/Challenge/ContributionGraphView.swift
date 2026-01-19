//
//  ContributionGraphView.swift
//  Norma
//
//  Created by Claude on 1/7/26.
//

import SwiftUI

/// A GitHub-style contribution graph showing daily challenge performance across multiple months
struct ContributionGraphView: View {
    let dayResults: [DayResult]
    var monthsToDisplay: Int = 3
    var selectedDate: Date? = nil  // Triggers wave animation when changed

    // Constants
    private let cellSize: CGFloat = 14
    private let cellSpacing: CGFloat = 4
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]

    // Wave animation state - uses TimelineView for frame-by-frame updates
    @State private var waveAnimationStart: Date? = nil  // When wave started (nil = no wave)
    @State private var waveOriginCol: Int = 0
    @State private var waveOriginRow: Int = 0
    @State private var hasAppearedOnce: Bool = false  // Skip animation on initial load

    // Wave parameters
    private let waveWidth: CGFloat = 3.0  // How "thick" the wave ring is
    private let waveSpeed: CGFloat = 35.0  // Units per second
    private let waveDuration: TimeInterval = 0.8  // Total animation duration

    // Month data structure
    private struct MonthData: Identifiable {
        let id = UUID()
        let name: String
        let weeks: [[DayResult?]]
    }

    // Generate data for all months to display
    private var monthsData: [MonthData] {
        let calendar = Calendar.current
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let monthNameFormatter = DateFormatter()
        monthNameFormatter.dateFormat = "MMM"

        // Create result lookup by date
        var resultsByDate: [String: DayResult] = [:]
        for result in dayResults {
            let key = dateFormatter.string(from: result.date)
            resultsByDate[key] = result
        }

        var allMonths: [MonthData] = []

        // Generate data for each month (going backwards from current month)
        for monthOffset in (0..<monthsToDisplay).reversed() {
            guard let targetMonth = calendar.date(byAdding: .month, value: -monthOffset, to: today),
                  let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: targetMonth)),
                  let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
                continue
            }

            let monthName = monthNameFormatter.string(from: monthStart)
            let startWeekday = calendar.component(.weekday, from: monthStart)
            let daysInMonth = calendar.component(.day, from: monthEnd)

            var weeks: [[DayResult?]] = []
            var currentWeek: [DayResult?] = []

            // Add empty cells for days before month starts
            for _ in 1..<startWeekday {
                currentWeek.append(nil)
            }

            // Add each day of the month
            for day in 1...daysInMonth {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                    let key = dateFormatter.string(from: date)
                    let result = resultsByDate[key]

                    // Only include days up to today
                    if date <= today {
                        currentWeek.append(result ?? DayResult(
                            date: date,
                            dailyCap: 0,
                            amountSpent: 0,
                            wasUnderCap: false,
                            pointsEarned: 0,
                            streakAfter: 0
                        ))
                    } else {
                        currentWeek.append(nil) // Future day
                    }
                }

                // Start new week on Sunday
                if currentWeek.count == 7 {
                    weeks.append(currentWeek)
                    currentWeek = []
                }
            }

            // Add remaining days of last week
            if !currentWeek.isEmpty {
                while currentWeek.count < 7 {
                    currentWeek.append(nil)
                }
                weeks.append(currentWeek)
            }

            allMonths.append(MonthData(name: monthName, weeks: weeks))
        }

        return allMonths
    }

    // MARK: - Wave Animation Helpers

    /// Calculate Euclidean distance between two grid positions
    private func calculateDistance(fromCol: Int, fromRow: Int, toCol: Int, toRow: Int) -> Double {
        let dx = Double(toCol - fromCol)
        let dy = Double(toRow - fromRow)
        return hypot(dx, dy)
    }

    /// Find the cell position (global column, row) for a given date
    /// Returns nil if the date is not visible in the graph
    private func findCellPosition(for date: Date) -> (col: Int, row: Int)? {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let targetKey = dateFormatter.string(from: date)

        var globalCol = 0

        for monthData in monthsData {
            for (weekIndex, week) in monthData.weeks.enumerated() {
                for (dayIndex, dayResult) in week.enumerated() {
                    if let result = dayResult {
                        let resultKey = dateFormatter.string(from: result.date)
                        if resultKey == targetKey {
                            return (col: globalCol + weekIndex, row: dayIndex)
                        }
                    }
                }
            }
            globalCol += monthData.weeks.count
        }

        return nil
    }

    /// Find today's cell position as a fallback for future dates
    private func findTodayPosition() -> (col: Int, row: Int)? {
        return findCellPosition(for: Date())
    }

    /// Trigger the wave animation from a given origin position
    private func triggerWaveAnimation(fromCol: Int, fromRow: Int) {
        // Don't trigger if already animating
        guard waveAnimationStart == nil else { return }

        waveOriginCol = fromCol
        waveOriginRow = fromRow
        waveAnimationStart = Date()

        // Stop animation after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + waveDuration) {
            self.waveAnimationStart = nil
        }
    }

    /// Calculate current wave radius based on elapsed time
    private func currentWaveRadius(at date: Date) -> CGFloat {
        guard let start = waveAnimationStart else { return -100 }
        let elapsed = date.timeIntervalSince(start)
        return CGFloat(elapsed) * waveSpeed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with legend
            HStack {
                Text("SPENDING")
                    .font(.normaInput(12))
                    .foregroundColor(.secondary)
                    .tracking(1.5)

                Spacer()

                // Legend - green (low spend) to red (high spend)
                HStack(spacing: 6) {
                    Text("Low")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    ForEach(0..<4) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(legendColorForLevel(level))
                            .frame(width: 10, height: 10)
                    }

                    Text("High")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            // Grid with month labels
            HStack(alignment: .top, spacing: cellSpacing) {
                // Week day labels
                VStack(spacing: cellSpacing) {
                    // Spacer for month label row
                    Text("")
                        .font(.system(size: 10))
                        .frame(height: 14)

                    ForEach(weekDays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 12, height: cellSize)
                    }
                }

                // Contribution cells with month labels - wrapped in TimelineView for wave animation
                TimelineView(.animation(minimumInterval: 1.0/60.0, paused: waveAnimationStart == nil)) { timeline in
                    let waveRadius = currentWaveRadius(at: timeline.date)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: cellSpacing * 2) {
                            ForEach(Array(monthsData.enumerated()), id: \.element.id) { monthIndex, monthData in
                                // Calculate base column for this month
                                let baseCol = monthsData.prefix(monthIndex).reduce(0) { $0 + $1.weeks.count }

                                VStack(alignment: .leading, spacing: cellSpacing) {
                                    // Month label
                                    Text(monthData.name.uppercased())
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .frame(height: 14)

                                    // Weeks for this month
                                    HStack(spacing: cellSpacing) {
                                        ForEach(Array(monthData.weeks.enumerated()), id: \.offset) { weekIndex, week in
                                            let globalCol = baseCol + weekIndex

                                            VStack(spacing: cellSpacing) {
                                                ForEach(0..<7, id: \.self) { dayIndex in
                                                    let distance = calculateDistance(
                                                        fromCol: waveOriginCol,
                                                        fromRow: waveOriginRow,
                                                        toCol: globalCol,
                                                        toRow: dayIndex
                                                    )

                                                    if let dayResult = week[dayIndex] {
                                                        let isCellSelected = selectedDate != nil &&
                                                            Calendar.current.isDate(dayResult.date, inSameDayAs: selectedDate!)

                                                        ContributionCell(
                                                            dayResult: dayResult,
                                                            size: cellSize,
                                                            waveRadius: waveRadius,
                                                            waveWidth: waveWidth,
                                                            distanceFromOrigin: distance,
                                                            isSelected: isCellSelected
                                                        )
                                                    } else {
                                                        // Empty cell (future day or padding)
                                                        RoundedRectangle(cornerRadius: 3)
                                                            .fill(Color.gray.opacity(0.1))
                                                            .frame(width: cellSize, height: cellSize)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.03))
                .glassEffect(in: RoundedRectangle(cornerRadius: 16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
        )
        .onAppear {
            // Delay setting hasAppearedOnce to skip initial selectedDate setting
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                hasAppearedOnce = true
            }
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            // Skip animation on initial load
            guard hasAppearedOnce else { return }
            guard let date = newValue else { return }

            // Find the cell position for the selected date
            if let position = findCellPosition(for: date) {
                triggerWaveAnimation(fromCol: position.col, fromRow: position.row)
            } else if let todayPosition = findTodayPosition() {
                // For future dates not in graph, trigger wave from today's position
                triggerWaveAnimation(fromCol: todayPosition.col, fromRow: todayPosition.row)
            }
        }
    }

    /// Legend colors: green (low spend) → pink (high spend)
    private func legendColorForLevel(_ level: Int) -> Color {
        switch level {
        case 0:
            return Color("NormaPastelTeal") // Low spending - green
        case 1:
            return Color("NormaPastelTeal").opacity(0.5)
        case 2:
            return Color("NormaPastelPink").opacity(0.5)
        case 3:
            return Color("NormaPastelPink") // High spending - pink
        default:
            return Color.gray.opacity(0.15)
        }
    }
}

// MARK: - Contribution Cell

private struct ContributionCell: View {
    let dayResult: DayResult
    let size: CGFloat
    let waveRadius: CGFloat
    let waveWidth: CGFloat
    let distanceFromOrigin: Double
    var isSelected: Bool = false

    /// Color based on spending intensity relative to daily cap
    /// Green = low spending (good), Pink = high spending (watch out), Gray = no challenge
    private var cellColor: Color {
        let cap = dayResult.dailyCap
        let spent = dayResult.amountSpent

        // No challenge that day (cap is 0)
        if cap <= 0 {
            return Color.gray.opacity(0.15)
        }

        let spendingRatio = spent / cap

        if spendingRatio <= 0.33 {
            // Low spending - full green
            return Color("NormaPastelTeal")
        } else if spendingRatio <= 0.66 {
            // Moderate spending - lighter green
            return Color("NormaPastelTeal").opacity(0.5)
        } else if spendingRatio <= 1.0 {
            // High spending but under cap - light pink
            return Color("NormaPastelPink").opacity(0.5)
        } else {
            // Over cap - full pink
            return Color("NormaPastelPink")
        }
    }

    /// Wave intensity based on how close the wave front is to this cell
    /// Returns 0-1 where 1 = center of wave, 0 = outside wave
    private var waveIntensity: CGFloat {
        let distanceFromWaveFront = abs(CGFloat(distanceFromOrigin) - waveRadius)

        // If wave hasn't reached this cell or has passed, intensity is 0
        if distanceFromWaveFront > waveWidth {
            return 0
        }

        // Smooth falloff using cosine for nicer wave shape
        let normalizedDistance = distanceFromWaveFront / waveWidth
        return (1 + cos(normalizedDistance * .pi)) / 2
    }

    /// Scale based on wave intensity - cells "pop" dramatically as wave passes
    private var scale: CGFloat {
        1.0 + (0.5 * waveIntensity)  // Scale from 1.0 to 1.5
    }

    /// Brightness boost as wave passes
    private var brightness: Double {
        0.35 * Double(waveIntensity)
    }

    /// Shadow radius for depth effect
    private var shadowRadius: CGFloat {
        4 * waveIntensity
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(cellColor)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .brightness(brightness)
            .shadow(color: cellColor.opacity(0.6 * Double(waveIntensity)), radius: shadowRadius, y: 2)
            .overlay(
                isSelected ? RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.white, lineWidth: 2) : nil
            )
    }
}

// MARK: - Skeleton Loader

/// Skeleton loading state for the contribution graph
struct ContributionGraphSkeleton: View {
    @State private var isAnimating = false

    private let cellSize: CGFloat = 14
    private let cellSpacing: CGFloat = 4
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header skeleton
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 70, height: 14)

                Spacer()

                // Legend skeleton
                HStack(spacing: 6) {
                    ForEach(0..<6, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 10, height: 10)
                    }
                }
            }

            // Grid skeleton
            HStack(alignment: .top, spacing: cellSpacing) {
                // Week day labels
                VStack(spacing: cellSpacing) {
                    Text("")
                        .font(.system(size: 10))
                        .frame(height: 14)

                    ForEach(weekDays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.4))
                            .frame(width: 12, height: cellSize)
                    }
                }

                // Skeleton cells - 3 months worth
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: cellSpacing * 2) {
                        ForEach(0..<3, id: \.self) { monthIndex in
                            VStack(alignment: .leading, spacing: cellSpacing) {
                                // Month label skeleton
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.gray.opacity(0.12))
                                    .frame(width: 30, height: 14)

                                // Weeks skeleton
                                HStack(spacing: cellSpacing) {
                                    ForEach(0..<5, id: \.self) { weekIndex in
                                        VStack(spacing: cellSpacing) {
                                            ForEach(0..<7, id: \.self) { dayIndex in
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(Color.gray.opacity(shimmerOpacity(monthIndex: monthIndex, weekIndex: weekIndex, dayIndex: dayIndex)))
                                                    .frame(width: cellSize, height: cellSize)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }

    private func shimmerOpacity(monthIndex: Int, weekIndex: Int, dayIndex: Int) -> Double {
        let baseOpacity = 0.08
        let variation = isAnimating ? 0.08 : 0
        // Create a wave effect across cells
        let offset = Double(monthIndex * 5 + weekIndex + dayIndex) * 0.02
        return baseOpacity + variation * sin(offset * .pi)
    }
}

// MARK: - Preview

#Preview("Contribution Graph") {
    VStack {
        ContributionGraphView(dayResults: [])
            .padding()
    }
    .background(Color("NormaBackground"))
}

#Preview("Skeleton") {
    VStack {
        ContributionGraphSkeleton()
            .padding()
    }
    .background(Color("NormaBackground"))
}
