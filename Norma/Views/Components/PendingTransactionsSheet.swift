//
//  PendingTransactionsSheet.swift
//  Norma
//
//  Sheet for reviewing and confirming pending transactions with date selection
//

import SwiftUI

struct PendingTransactionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var sessionViewModel: SessionViewModel

    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var selectedTransactionIds: Set<String> = []
    @State private var isProcessing = false
    @State private var isLoading = false
    @State private var isCalendarExpanded = false
    @State private var showInfoAlert = false

    // Wave animation state
    @State private var waveAnimationStart: Date? = nil
    @State private var waveOriginCol: Int = 0
    @State private var waveOriginRow: Int = 0

    // Wave parameters
    private let waveWidth: CGFloat = 2.5
    private let waveSpeed: CGFloat = 25.0
    private let waveDuration: TimeInterval = 0.6

    private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    private var pendingTransactions: [PendingTransaction] {
        dataManager.getPendingTransactionsList()
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private var totalAmount: Double {
        pendingTransactions.compactMap { $0.amount }.reduce(0, +)
    }

    private var selectedTransactions: [PendingTransaction] {
        pendingTransactions.filter { transaction in
            guard let id = transaction.id else { return false }
            return selectedTransactionIds.contains(id)
        }
    }

    private var selectedAmount: Double {
        selectedTransactions.compactMap { $0.amount }.reduce(0, +)
    }

    private var allSelected: Bool {
        !pendingTransactions.isEmpty &&
        pendingTransactions.allSatisfy { transaction in
            guard let id = transaction.id else { return false }
            return selectedTransactionIds.contains(id)
        }
    }

    private var dateDisplayText: String {
        if Calendar.current.isDateInToday(selectedDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return "Today, \(formatter.string(from: selectedDate))"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return "Yesterday, \(formatter.string(from: selectedDate))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: selectedDate)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    collapsibleCalendarSection
                    if pendingTransactions.isEmpty {
                        emptyState
                    } else {
                        transactionsSectionHeader
                        transactionsSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 140)
            }
            .background(Color("NormaBackground"))
            .navigationTitle("Review Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showInfoAlert = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color("NormaPastelPurple"))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom(FontFamily.Rubik.medium, size: 16))
                    .foregroundColor(Color("NormaPastelPurple"))
                }
            }
            .alert("Pending Transactions", isPresented: $showInfoAlert) {
                Button("Got it", role: .cancel) { }
            } message: {
                Text("These are transactions shared with Norma that haven't been confirmed yet. Pick a date, select the ones you want to keep, then tap Confirm to add them to your records.")
            }
            .safeAreaInset(edge: .bottom) {
                if !pendingTransactions.isEmpty {
                    floatingActionBar
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            refreshPendingTransactions()
        }
        .onChange(of: pendingTransactions.count) { _, newCount in
            if newCount == 0 {
                dismiss()
            }
        }
    }

    // MARK: - Collapsible Calendar Section

    private var collapsibleCalendarSection: some View {
        VStack(spacing: 20) {
            // Tappable date bar
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isCalendarExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(Color("NormaPastelPurple"))

                    Text("Date:")
                        .font(.custom(FontFamily.Rubik.regular, size: 14))
                        .foregroundColor(.secondary)

                    Text(dateDisplayText)
                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                        .foregroundColor(Color("NormaPastelPurple"))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isCalendarExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.clear)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)

            if isCalendarExpanded {
                calendarContent
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
    }

    private var calendarContent: some View {
        VStack(spacing: 20) {
            // Month navigation header
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("NormaPastelPurple"))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color("NormaPastelPurple").opacity(0.1))
                        )
                }

                Spacer()

                Text(monthYearFormatter.string(from: currentMonth).uppercased())
                    .font(.normaFinancial(16))
                    .foregroundColor(.secondary)
                    .tracking(1.2)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(canGoForward ? Color("NormaPastelPurple") : Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(canGoForward ? Color("NormaPastelPurple").opacity(0.1) : Color.gray.opacity(0.05))
                        )
                }
                .disabled(!canGoForward)
            }
            .padding(.horizontal, 8)

            // Calendar container
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: colorScheme == .dark ? [
                                Color(red: 0.160, green: 0.128, blue: 0.102),
                                Color(red: 0.180, green: 0.145, blue: 0.118)
                            ] : [
                                Color(UIColor.systemBackground),
                                Color.gray.opacity(0.02)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.2),
                                        Color.gray.opacity(0.05)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )

                TimelineView(.animation(minimumInterval: 1.0/60.0, paused: waveAnimationStart == nil)) { timeline in
                    let waveRadius = currentWaveRadius(at: timeline.date)

                    VStack(spacing: 16) {
                        // Day labels
                        HStack(spacing: 0) {
                            ForEach(days, id: \.self) { day in
                                Text(day)
                                    .font(.normaInput(12))
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)

                        // Calendar grid
                        let dates = extractDates()
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                                let row = index / 7
                                let col = index % 7
                                let distance = calculateDistance(
                                    fromCol: waveOriginCol,
                                    fromRow: waveOriginRow,
                                    toCol: col,
                                    toRow: row
                                )

                                if let date = date {
                                    PendingDayCell(
                                        date: date,
                                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                        isToday: Calendar.current.isDateInToday(date),
                                        isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month),
                                        isFuture: date > Date(),
                                        waveRadius: waveRadius,
                                        waveWidth: waveWidth,
                                        distanceFromOrigin: distance
                                    )
                                    .onTapGesture {
                                        // Only allow selecting today or past dates
                                        if date <= Date() {
                                            // Trigger wave animation
                                            triggerWaveAnimation(fromCol: col, fromRow: row)

                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                selectedDate = date
                                            }
                                        }
                                    }
                                } else {
                                    Rectangle()
                                        .foregroundColor(.clear)
                                        .frame(height: 40)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                }
            }
        }
    }

    private var canGoForward: Bool {
        let calendar = Calendar.current
        let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let todayMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        return currentMonthStart < todayMonthStart
    }

    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }

    private func extractDates() -> [Date?] {
        let calendar = Calendar.current

        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingEmptyCells = firstWeekday - 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        let totalCellsNeeded = leadingEmptyCells + daysInMonth
        let rows = (totalCellsNeeded + 6) / 7
        let totalCells = rows * 7
        let trailingEmptyCells = totalCells - daysInMonth - leadingEmptyCells

        var dates: [Date?] = []

        for _ in 0..<leadingEmptyCells {
            dates.append(nil)
        }

        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                dates.append(date)
            }
        }

        for _ in 0..<trailingEmptyCells {
            dates.append(nil)
        }

        return dates
    }

    // MARK: - Wave Animation Helpers

    private func calculateDistance(fromCol: Int, fromRow: Int, toCol: Int, toRow: Int) -> Double {
        let dx = Double(toCol - fromCol)
        let dy = Double(toRow - fromRow)
        return hypot(dx, dy)
    }

    private func currentWaveRadius(at date: Date) -> CGFloat {
        guard let start = waveAnimationStart else { return -100 }
        let elapsed = date.timeIntervalSince(start)
        return CGFloat(elapsed) * waveSpeed
    }

    private func triggerWaveAnimation(fromCol: Int, fromRow: Int) {
        guard waveAnimationStart == nil else { return }

        waveOriginCol = fromCol
        waveOriginRow = fromRow
        waveAnimationStart = Date()

        DispatchQueue.main.asyncAfter(deadline: .now() + waveDuration) {
            self.waveAnimationStart = nil
        }
    }

    // MARK: - Transactions Section Header

    private var transactionsSectionHeader: some View {
        HStack {
            Text("Transactions")
                .font(.custom(FontFamily.Rubik.medium, size: 16))
                .foregroundColor(.primary)

            Text("\(pendingTransactions.count) pending")
                .font(.custom(FontFamily.Rubik.regular, size: 13))
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Transactions Section

    private var transactionsSection: some View {
        VStack(spacing: 12) {
            ForEach(pendingTransactions) { transaction in
                SelectableTransactionRow(
                    transaction: transaction,
                    currency: currency,
                    isSelected: isTransactionSelected(transaction),
                    onToggle: { toggleSelection(transaction) },
                    onDelete: { deleteTransaction(transaction) }
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.clear)
                .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }

    // MARK: - Floating Action Bar

    private var floatingActionBar: some View {
        VStack(spacing: 16) {
            // Top row: Select All + count
            HStack(spacing: 10) {
                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    toggleSelectAll()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: allSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 13, weight: .medium))
                        Text(allSelected ? "Deselect All" : "Select All")
                            .font(.custom(FontFamily.Rubik.medium, size: 13))
                    }
                    .foregroundColor(Color("NormaPastelPurple"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color("NormaPastelPurple").opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color("NormaPastelPurple").opacity(0.25), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)

                Text("\(selectedTransactionIds.count) of \(pendingTransactions.count)")
                    .font(.custom(FontFamily.Rubik.regular, size: 13))
                    .foregroundColor(.secondary)

                Spacer()
            }

            // Confirm button - full width
            Button {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                confirmSelectedTransactions()
            } label: {
                HStack(spacing: 8) {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                    }

                    if selectedTransactionIds.isEmpty {
                        Text("Select transactions")
                            .font(.custom(FontFamily.Rubik.medium, size: 15))
                    } else {
                        Text("Confirm \(selectedTransactionIds.count)")
                            .font(.custom(FontFamily.Rubik.medium, size: 15))

                        Text("•")
                            .font(.system(size: 10))
                            .opacity(0.6)

                        Text(formatCurrency(selectedAmount))
                            .font(.custom(FontFamily.Rubik.regular, size: 14))
                            .opacity(0.9)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(selectedTransactionIds.isEmpty ?
                              Color.gray.opacity(0.4) :
                              Color("NormaPastelTeal"))
                )
            }
            .buttonStyle(.plain)
            .disabled(selectedTransactionIds.isEmpty || isProcessing)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.clear)
                .glassEffect(in: RoundedRectangle(cornerRadius: 24))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.gray.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 20, y: -5)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(Color("NormaPastelTeal"))

            VStack(spacing: 8) {
                Text("All caught up!")
                    .font(.normaFinancial(20))
                    .foregroundColor(.primary)

                Text("No pending transactions to review")
                    .font(.normaInput(14))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.clear)
                .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }

    // MARK: - Helper Methods

    private func isTransactionSelected(_ transaction: PendingTransaction) -> Bool {
        guard let id = transaction.id else { return false }
        return selectedTransactionIds.contains(id)
    }

    private func toggleSelection(_ transaction: PendingTransaction) {
        guard let id = transaction.id else { return }

        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        if selectedTransactionIds.contains(id) {
            selectedTransactionIds.remove(id)
        } else {
            selectedTransactionIds.insert(id)
        }
    }

    private func toggleSelectAll() {
        if allSelected {
            selectedTransactionIds.removeAll()
        } else {
            selectedTransactionIds = Set(pendingTransactions.compactMap { $0.id })
        }
    }

    private func refreshPendingTransactions() {
        guard let userId = sessionViewModel.currentUser?.userId else { return }

        isLoading = true

        Task {
            do {
                try await dataManager.fetchPendingTransactions(userId: userId)
            } catch {
                print("Failed to fetch pending transactions: \(error)")
            }

            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func confirmSelectedTransactions() {
        guard !selectedTransactions.isEmpty else { return }

        isProcessing = true

        Task {
            do {
                try await dataManager.confirmPendingTransactions(selectedTransactions, withDate: selectedDate)

                await MainActor.run {
                    isProcessing = false
                    selectedTransactionIds.removeAll()

                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    print("Failed to confirm transactions: \(error)")
                }
            }
        }
    }

    private func deleteTransaction(_ transaction: PendingTransaction) {
        Task {
            do {
                try await dataManager.rejectPendingTransaction(transaction)

                await MainActor.run {
                    if let id = transaction.id {
                        selectedTransactionIds.remove(id)
                    }
                }
            } catch {
                print("Failed to delete transaction: \(error)")
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

// MARK: - Pending Day Cell

private struct PendingDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let isFuture: Bool
    let waveRadius: CGFloat
    let waveWidth: CGFloat
    let distanceFromOrigin: Double

    /// Wave intensity based on how close the wave front is to this cell
    private var waveIntensity: CGFloat {
        let distanceFromWaveFront = abs(CGFloat(distanceFromOrigin) - waveRadius)

        if distanceFromWaveFront > waveWidth {
            return 0
        }

        let normalizedDistance = distanceFromWaveFront / waveWidth
        return (1 + cos(normalizedDistance * .pi)) / 2
    }

    /// Scale based on wave intensity
    private var scale: CGFloat {
        1.0 + (0.3 * waveIntensity)
    }

    /// Brightness boost as wave passes
    private var brightness: Double {
        0.25 * Double(waveIntensity)
    }

    /// Shadow radius for depth effect
    private var shadowRadius: CGFloat {
        3 * waveIntensity
    }

    private var cellColor: Color {
        if isSelected {
            return Color("NormaPastelPurple")
        } else if isToday {
            return Color("NormaPastelPurple").opacity(0.08)
        } else {
            return Color.clear
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(cellTextColor)
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("NormaPastelPurple"))

                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("NormaPastelPurple").opacity(0.6), lineWidth: 1.5)
                } else if isToday {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("NormaPastelPurple").opacity(0.08))

                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("NormaPastelPurple").opacity(0.25), lineWidth: 1)
                }
            }
        )
        .scaleEffect(scale)
        .brightness(brightness)
        .shadow(color: Color("NormaPastelPurple").opacity(0.4 * Double(waveIntensity)), radius: shadowRadius, y: 2)
        .opacity(cellOpacity)
    }

    private var cellTextColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Color("NormaPastelPurple")
        } else if isFuture {
            return .secondary.opacity(0.3)
        } else if !isCurrentMonth {
            return .secondary.opacity(0.5)
        } else {
            return .primary
        }
    }

    private var cellOpacity: Double {
        if isFuture {
            return 0.5
        } else if !isCurrentMonth {
            return 0.3
        }
        return 1
    }
}

// MARK: - Selectable Transaction Row

private struct SelectableTransactionRow: View {
    let transaction: PendingTransaction
    let currency: String
    let isSelected: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void

    private var subtitleText: String? {
        if let createdAt = transaction.createdAt {
            return relativeTimestamp(from: createdAt)
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color("NormaPastelTeal") : Color.gray.opacity(0.4))
            }
            .buttonStyle(.plain)

            // Transaction info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(transaction.merchant ?? "Unknown")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    if let amount = transaction.amount {
                        Text(formatCurrency(amount))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }

                if let subtitle = subtitleText {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }

    private func relativeTimestamp(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: isoString) else {
            // Try without fractional seconds
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]
            guard let fallbackDate = fallback.date(from: isoString) else {
                return "Shared recently"
            }
            return relativeString(from: fallbackDate)
        }
        return relativeString(from: date)
    }

    private func relativeString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if minutes < 1 {
            return "Shared just now"
        } else if minutes < 60 {
            return "Shared \(minutes)m ago"
        } else if hours < 24 {
            return "Shared \(hours)h ago"
        } else {
            return "Shared \(days)d ago"
        }
    }
}

#Preview {
    PendingTransactionsSheet()
        .environmentObject(DataManager())
        .environmentObject(SessionViewModel(dataManager: DataManager()))
}
