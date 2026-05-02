//
//  NotesListScreen.swift
//  Norma
//
//  Created by Claude on 4/27/26.
//
//  D5 — the notes list. Lists every note in last-edited order, grouped into
//  today / month buckets. Tapping a row pushes NoteCanvasView. Visual matches
//  the Paper D5d design: warm off-white ink on near-black, lavender accent,
//  italic indices, dashed pill tag row.
//

import SwiftUI
import SwiftData

struct NotesListScreen: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var appCoordinator: AppCoordinator
    @ObservedObject private var plaidService = PlaidService.shared
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]

    @State private var titleText: String = "your notes"
    @State private var repo: NoteRepository?
    @State private var activeTag: String = "#all"
    @State private var path: [Note] = []
    @State private var showArcDetail = false
    @State private var isSearching = false
    @State private var searchText: String = ""
    @FocusState private var searchFieldFocused: Bool
    @State private var showForecast = false
    @State private var showCalendar = false
    @State private var showConverter = false
    @State private var showSettings = false
    @State private var showPending = false

    // Entrance choreography
    @State private var hasAnimated = false
    @State private var showNav = false
    @State private var showHeroLine1 = false
    @State private var showHeroLine2 = false
    @State private var showHeroCount = false
    @State private var showTags = false
    @State private var showList = false
    @State private var showBottom = false

    private var freedomFund: Double {
        if let arcAccountId = sessionViewModel.currentUser?.settings.arcAccountId,
           let account = PlaidService.shared.connectedAccounts.first(where: { $0.accountId == arcAccountId }),
           let balance = account.balances.current {
            return balance
        }
        return sessionViewModel.currentUser?.settings.freedomFund ?? 0
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private var totalMonthlyBills: Double {
        billViewModel.bills.reduce(0.0) { $0 + $1.amount }
    }

    private var arcCount: Int {
        let largestBill = billViewModel.bills.map { $0.amount }.max() ?? 0
        if freedomFund < largestBill { return 0 }
        if totalMonthlyBills > 0 {
            return Int(floor(freedomFund / totalMonthlyBills))
        }
        return 0
    }

    private var filteredNotes: [Note] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return notes }
        let q = trimmed.lowercased()
        return notes.filter { note in
            (note.title?.lowercased().contains(q) ?? false) ||
            note.rawText.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                NormaPalette.canvas.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    topNav
                        .opacity(showNav ? 1 : 0)
                        .offset(y: showNav ? 0 : -8)

                    heroBlock

                    tagRow
                        .opacity(showTags ? 1 : 0)
                        .offset(y: showTags ? 0 : 12)

                    ZStack(alignment: .top) {
                        ScrollView(showsIndicators: false) {
                            listBody
                                .padding(.bottom, 140)
                        }
                        .opacity(showList ? 1 : 0)
                        .offset(y: showList ? 0 : 16)

                        LinearGradient(
                            colors: [
                                NormaPalette.canvas,
                                NormaPalette.canvas.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 28)
                        .allowsHitTesting(false)
                    }
                }

                bottomBar
                    .opacity(showBottom ? 1 : 0)
                    .offset(y: showBottom ? 0 : 24)
                    .scaleEffect(showBottom ? 1 : 0.96, anchor: .bottom)
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Note.self) { note in
                if let repo {
                    NoteCanvasView(note: note, repo: repo)
                        .navigationBarHidden(true)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            if repo == nil {
                let r = NoteRepository(context: modelContext)
                self.repo = r
                _ = r.today()
            }
            runEntranceAnimation()
        }
        .sheet(isPresented: $showArcDetail) {
            ArcCountView(
                arcCount: arcCount,
                freedomFund: freedomFund,
                totalMonthlyBills: totalMonthlyBills,
                currency: currency
            )
            .environmentObject(sessionViewModel)
        }
        .sheet(isPresented: $showForecast) {
            ForecastSheet()
                .environmentObject(sessionViewModel)
                .environmentObject(billViewModel)
                .environmentObject(expenseViewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showCalendar) {
            CalendarSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showConverter) {
            ConverterSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(sessionViewModel)
                .environmentObject(dataManager)
                .environmentObject(appCoordinator)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showPending) {
            PendingTransactionsSheet()
                .environmentObject(dataManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Top nav

    private var topNav: some View {
        Group {
            if isSearching {
                searchBar
            } else {
                defaultNav
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private var defaultNav: some View {
        HStack {
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                showPending = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "tray")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(NormaPalette.ink.opacity(0.85))
                        .frame(width: 32, height: 32)
                    if dataManager.pendingTransactions.count > 0 {
                        Circle()
                            .fill(NormaPalette.lavender)
                            .frame(width: 7, height: 7)
                            .overlay(Circle().stroke(NormaPalette.canvas, lineWidth: 1.5))
                            .offset(x: -4, y: 4)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                showArcDetail = true
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(arcCount)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(NormaPalette.ink)
                    Text(arcCount == 1 ? "month left" : "months left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(NormaPalette.ink.opacity(0.6))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.white.opacity(0.04)))
                .overlay(Capsule().stroke(NormaPalette.ink.opacity(0.22), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(NormaPalette.ink.opacity(0.5))
                TextField("search notes", text: $searchText)
                    .focused($searchFieldFocused)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(NormaPalette.ink)
                    .tint(NormaPalette.lavender)
                    .submitLabel(.search)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(NormaPalette.ink.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.white.opacity(0.04)))
            .overlay(Capsule().stroke(NormaPalette.ink.opacity(0.22), lineWidth: 1))

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                    isSearching = false
                    searchText = ""
                }
                searchFieldFocused = false
            } label: {
                Text("cancel")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(NormaPalette.ink.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("your")
                .font(heroFont)
                .tracking(-2.88)  // -0.04em × 72
                .foregroundStyle(NormaPalette.ink)
                .opacity(showHeroLine1 ? 1 : 0)
                .offset(y: showHeroLine1 ? 0 : 18)
                .blur(radius: showHeroLine1 ? 0 : 6)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("notes")
                    .font(heroFont)
                    .tracking(-2.88)
                    .foregroundStyle(NormaPalette.ink)
                    .opacity(showHeroLine2 ? 1 : 0)
                    .offset(y: showHeroLine2 ? 0 : 18)
                    .blur(radius: showHeroLine2 ? 0 : 6)
                Text(".")
                    .font(heroFont)
                    .foregroundStyle(NormaPalette.lavender)
                    .padding(.trailing, 12)
                    .opacity(showHeroLine2 ? 1 : 0)
                    .offset(y: showHeroLine2 ? 0 : 18)
                Text("/\(notes.count)")
                    .font(.system(size: 30, weight: .regular))
                    .tracking(-0.6)
                    .foregroundStyle(NormaPalette.inkMuted)
                    .opacity(showHeroCount ? 1 : 0)
                    .offset(y: showHeroCount ? 0 : 12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, 22)
    }

    private var heroFont: Font { .system(size: 72, weight: .bold) }

    // MARK: - Tag row

    private var tagRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(allTags, id: \.self) { tag in
                    tagPill(tag, active: tag == activeTag)
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 22)
    }

    /// Combines #all with the union of all tags across notes (deduped, ordered).
    private var allTags: [String] {
        var seen: Set<String> = []
        var out: [String] = ["#all"]
        for note in notes {
            for tag in note.tags {
                let key = tag.hasPrefix("#") ? tag : "#\(tag)"
                if seen.insert(key).inserted { out.append(key) }
            }
        }
        return out
    }

    private func tagPill(_ tag: String, active: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                activeTag = tag
            }
        } label: {
            Text(tag)
                .font(.system(size: 13, weight: active ? .semibold : .medium))
                .foregroundStyle(active ? NormaPalette.canvas : NormaPalette.ink)
                .padding(.vertical, 9)
                .padding(.horizontal, 16)
                .background {
                    if active {
                        Capsule().fill(NormaPalette.lavender)
                    }
                }
                .overlay {
                    Capsule().stroke(
                        active ? NormaPalette.lavender : NormaPalette.ink.opacity(0.32),
                        style: StrokeStyle(
                            lineWidth: 1,
                            dash: active ? [] : [3, 3]
                        )
                    )
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - List body

    private var listBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            if sections.isEmpty {
                emptyState
            } else {
                ForEach(sections) { section in
                    sectionView(section)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("nothing yet")
                .font(.system(size: 16))
                .foregroundStyle(NormaPalette.inkSubtle)
            Text("tap today's note to start writing.")
                .font(.system(size: 13))
                .foregroundStyle(NormaPalette.inkMuted)
        }
        .padding(.top, 12)
    }

    private func sectionView(_ section: NoteSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(section.label)
                .font(.system(size: 11, weight: .medium))
                .tracking(0.88)  // 0.08em × 11
                .textCase(.uppercase)
                .foregroundStyle(NormaPalette.inkMuted)
                .padding(.top, 18)
                .padding(.bottom, 10)

            ForEach(section.entries, id: \.note.id) { entry in
                if let repo {
                    NavigationLink(value: entry.note) {
                        row(for: entry.note, index: entry.index)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteNote(entry.note)
                        } label: {
                            Label("delete", systemImage: "trash")
                        }
                    }
                    .transition(
                        .asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                                .combined(with: .move(edge: .leading))
                                .combined(with: .scale(scale: 0.92, anchor: .leading))
                        )
                    )
                }
            }
        }
    }

    private func row(for note: Note, index: Int) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(String(format: "%02d /", index))
                .font(.system(size: 13, weight: .regular))
                .italic()
                .foregroundStyle(NormaPalette.inkMuted)
                .frame(width: 30, alignment: .leading)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(displayTitle(for: note))
                    .font(.system(size: 18, weight: .bold))
                    .tracking(-0.18)  // -0.01em × 18
                    .foregroundStyle(NormaPalette.ink)
                    .lineLimit(1)

                if let preview = previewText(for: note) {
                    Text(preview)
                        .font(.system(size: 13))
                        .foregroundStyle(NormaPalette.inkSubtle)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.up.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(NormaPalette.inkSubtle)
                .frame(width: 24, height: 24)
                .padding(.top, 2)
        }
        .padding(.top, 14)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .overlay(alignment: .top) {
            Rectangle()
                .fill(NormaPalette.ink.opacity(0.10))
                .frame(height: 1)
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                bottomIcon(systemName: "chart.line.uptrend.xyaxis") {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    showForecast = true
                }
                bottomIcon(systemName: "calendar") {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    showCalendar = true
                }
                bottomIcon(systemName: "arrow.left.arrow.right") {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    showConverter = true
                }
                bottomIcon(systemName: "gearshape") {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    showSettings = true
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .glassEffect(in: Capsule())
            .overlay(
                Capsule().stroke(
                    NormaPalette.ink.opacity(0.32),
                    style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                )
            )

            Spacer()

            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                createNewNote()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(NormaPalette.lavender)
                    .frame(width: 56, height: 56)
                    .glassEffect(in: Circle())
                    .overlay(Circle().stroke(NormaPalette.lavender.opacity(0.7), lineWidth: 1))
                    .shadow(color: NormaPalette.lavender.opacity(0.35), radius: 18, x: 0, y: 0)
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }

    private func bottomIcon(systemName: String, action: (() -> Void)? = nil) -> some View {
        Group {
            if let action {
                Button(action: action) {
                    Image(systemName: systemName)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(NormaPalette.ink)
                        .frame(width: 44, height: 44)
                        // Without an explicit content shape the hit-test region
                        // collapses to the SF Symbol glyph itself — taps that
                        // land on the surrounding transparent pixels of the
                        // 44×44 frame fall through. This forces the entire
                        // frame to be tappable.
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(NormaPalette.ink)
                    .frame(width: 44, height: 44)
            }
        }
    }

    private func createNewNote() {
        let note = Note()
        modelContext.insert(note)
        try? modelContext.save()
        path.append(note)
    }

    private func deleteNote(_ note: Note) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            repo?.delete(note)
        }
    }

    private func runEntranceAnimation() {
        guard !hasAnimated else { return }
        hasAnimated = true

        let nav = DispatchTime.now() + 0.05
        let line1 = DispatchTime.now() + 0.18
        let line2 = DispatchTime.now() + 0.32
        let count = DispatchTime.now() + 0.46
        let tags = DispatchTime.now() + 0.55
        let list = DispatchTime.now() + 0.65
        let bottom = DispatchTime.now() + 0.78

        DispatchQueue.main.asyncAfter(deadline: nav) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { showNav = true }
        }
        DispatchQueue.main.asyncAfter(deadline: line1) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) { showHeroLine1 = true }
        }
        DispatchQueue.main.asyncAfter(deadline: line2) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) { showHeroLine2 = true }
        }
        DispatchQueue.main.asyncAfter(deadline: count) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { showHeroCount = true }
        }
        DispatchQueue.main.asyncAfter(deadline: tags) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { showTags = true }
        }
        DispatchQueue.main.asyncAfter(deadline: list) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) { showList = true }
        }
        DispatchQueue.main.asyncAfter(deadline: bottom) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) { showBottom = true }
        }
    }

    // MARK: - Sections / index

    private struct NoteSection: Identifiable {
        let id: String
        let label: String
        let order: Int
        let entries: [(note: Note, index: Int)]
    }

    private var sections: [NoteSection] {
        let cal = Calendar.current
        let now = Date()
        let startOfToday = cal.startOfDay(for: now)
        let startOfWeek = cal.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"

        var buckets: [(key: String, label: String, order: Int, entries: [(Note, Int)])] = []

        for (i, note) in filteredNotes.enumerated() {
            let date = note.createdAt
            let key: String
            let label: String
            let order: Int
            if cal.isDate(date, inSameDayAs: now) {
                key = "today"
                label = "today"
                order = 0
            } else if date >= startOfWeek {
                key = "this-week"
                label = "this week"
                order = 1
            } else {
                let month = monthFormatter.string(from: date).lowercased()
                key = month
                label = month
                let monthsAgo = abs(cal.dateComponents([.month], from: date, to: now).month ?? 0)
                order = 2 + monthsAgo
            }

            if let idx = buckets.firstIndex(where: { $0.key == key }) {
                buckets[idx].entries.append((note, i + 1))
            } else {
                buckets.append((key, label, order, [(note, i + 1)]))
            }
        }

        return buckets
            .sorted { $0.order < $1.order }
            .map { NoteSection(id: $0.key, label: $0.label, order: $0.order, entries: $0.entries) }
    }

    // MARK: - Helpers

    private func displayTitle(for note: Note) -> String {
        if let title = note.title, !title.isEmpty { return title }
        return NoteTitleGenerator.title(for: note.id)
    }

    private func previewText(for note: Note) -> String? {
        let trimmed = note.rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed.replacingOccurrences(of: "\n", with: " · ")
    }
}

private struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview("notes list") {
    NotesListScreen()
        .modelContainer(for: [Note.self, NoteToken.self], inMemory: true)
}
