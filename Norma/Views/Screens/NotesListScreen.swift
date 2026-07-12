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
import AVFoundation
import UIKit

struct NotesListScreen: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var appCoordinator: AppCoordinator
    @ObservedObject private var plaidService = PlaidService.shared
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]

    @State private var titleText: String = "your notes"
    @State private var repo: NoteRepository?
    /// Last fully-settled arc count, persisted across launches. Used as the
    /// cold-launch placeholder so the hero doesn't flicker from a stale 0
    /// while bills + Plaid balance are still in flight.
    @AppStorage("cachedArcCount") private var cachedArcCount: Int = 0
    /// Last fully-settled freedom-fund balance, persisted across launches so
    /// the nav-bar capsule renders immediately with a correct number instead
    /// of jumping when the Plaid balance lands ~3-5s later. Written from
    /// onChange(of: freedomFund) once Plaid (if wired) has resolved.
    @AppStorage("cachedFreedomFund") private var cachedFreedomFund: Double = 0

    // Voice dictation (waveform button in bottom bar). Streams a Deepgram
    // transcript and appends the final text to the most recent note — or
    // creates a fresh note if the list is empty. Same Deepgram + AVAudioEngine
    // wiring as the NoteCanvasView FAB.
    @StateObject private var deepgramService = DeepgramService.shared
    @State private var isRecording: Bool = false
    @State private var voicePulse: Bool = false
    @State private var voiceTranscript: String = ""
    @State private var voiceAudioEngine: AVAudioEngine?
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false

    // Hard paywall (non-dismissible). Distinct from `showPaywall`, which is the
    // soft, dismissible per-action sheet. The hard wall is the gate: it lands
    // after the user has felt extraction across their first couple of notes,
    // or immediately when a previously-used subscription/trial has lapsed.
    @State private var showHardWall = false
    /// Sticky, monotonic count of notes this user has created. Incremented on
    /// each new note, never decremented — so deleting notes can't drop a user
    /// back under the wall. The wall lands once this reaches `freeNoteLimit`.
    @AppStorage("com.norma.notesCreatedCount") private var notesCreatedCount = 0
    /// Free notes a user gets before the hard wall. They feel extraction on
    /// these, then are asked to subscribe.
    private let freeNoteLimit = 2

    /// Observed for the per-row "extraction in progress" pulsing dot.
    @State private var syncQueue = NoteSyncQueue.shared
    @State private var path: [Note] = []
    @State private var showArcDetail = false
    @State private var searchText: String = ""
    @State private var showForecast = false
    @State private var showCalendar = false
    @State private var showInsights = false
    @State private var showSettings = false

    // Entrance choreography
    @State private var hasAnimated = false
    @State private var showNav = false
    @State private var showHeroLine1 = false
    @State private var showHeroLine2 = false
    @State private var showHeroCount = false
    @State private var showList = false
    @State private var showBottom = false
    @State private var isVisible = false

    /// Empty-state hero — the soft tick fires per word as the line waves in.
    /// The text is held back a brief beat before it waves in.
    @State private var showEmptyText = false
    private let emptyWordHaptic = UIImpactFeedbackGenerator(style: .soft)

    private var hasAccess: Bool {
        subscriptionManager.hasActiveSubscription || subscriptionManager.isInFreeTrial
    }

    /// Whether the non-dismissible hard wall should be standing. A user without
    /// access hits it once they've either (a) burned a prior trial/subscription
    /// — gate immediately — or (b) created their first couple of notes, so
    /// they've already felt extraction do its thing. A user still under the
    /// free-note limit passes.
    private var shouldHardWall: Bool {
        guard !hasAccess else { return false }
        return subscriptionManager.hasUsedFreeTrial || notesCreatedCount >= freeNoteLimit
    }

    /// Returning users who already spent their trial see the "trial wrapped"
    /// framing; first-timers see the onboarding trial offer.
    private var hardWallContext: PaywallContext {
        if subscriptionManager.hasUsedFreeTrial && !subscriptionManager.isInFreeTrial {
            return .trialExpired
        }
        return .onboarding
    }

    private var freedomFund: Double {
        if let arcAccountId = sessionViewModel.currentUser?.settings.arcAccountId,
           let account = PlaidService.shared.connectedAccounts.first(where: { $0.accountId == arcAccountId }),
           let balance = account.balances.current {
            return balance
        }
        return sessionViewModel.currentUser?.settings.freedomFund ?? 0
    }

    /// The freedom-fund value used by the nav-bar capsule. Falls back to the
    /// cached amount during the window between cold launch and the live
    /// Plaid balance landing, so the capsule never renders zero or a stale
    /// settings value just to flip moments later.
    private var displayedFreedomFund: Double {
        if isPlaidPending && cachedFreedomFund > 0 {
            return cachedFreedomFund
        }
        return freedomFund
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

    /// The value rendered in the hero. Prefers the cached count until bills
    /// have arrived; once live data is ready the computed value takes over.
    private var displayedArcCount: Int {
        isBillDataReady ? arcCount : cachedArcCount
    }

    /// Bills are loaded once we have any non-empty list — or once the data
    /// manager has completed at least one sync (covers the "user genuinely
    /// has zero bills" case so we don't shimmer forever).
    private var isBillDataReady: Bool {
        !billViewModel.bills.isEmpty || dataManager.lastSyncDate != nil
    }

    /// Plaid is pending when the user has wired a specific account to the
    /// freedom fund but the live balance hasn't been fetched yet. Shimmer
    /// runs during this window so the user knows the number may shift.
    private var isPlaidPending: Bool {
        // With Plaid dormant no balance fetch is ever in flight — without
        // this guard, a user with a wired arcAccountId would shimmer forever.
        guard FeatureFlags.plaidEnabled else { return false }
        guard let arcAccountId = sessionViewModel.currentUser?.settings.arcAccountId else {
            return false
        }
        return !PlaidService.shared.connectedAccounts.contains(where: { $0.accountId == arcAccountId })
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

    /// Whether the user is actively searching. While searching we suppress the
    /// Pinned section and let every match flow into the date buckets.
    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Pinned notes, kept in the @Query's updatedAt-desc order. Only surfaced
    /// when not searching.
    private var pinnedNotes: [Note] {
        filteredNotes.filter { $0.isPinned }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                NormaPalette.canvas.ignoresSafeArea()
                // Subtle lavender wash over the canvas — gives the screen a
                // slight purple cast without changing NormaPalette.canvas
                // itself (other screens stay neutral). 4% opacity is enough
                // to register on a dark surface without competing with the
                // lavender accents on chips and capsules.
                NormaPalette.lavender.opacity(0.04).ignoresSafeArea()

                if filteredNotes.isEmpty {
                    emptyHero
                        .opacity(showList ? 1 : 0)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            listBody
                                .padding(.bottom, 140)
                                .opacity(showList ? 1 : 0)
                                .offset(y: showList ? 0 : 16)
                        }
                    }
                }

                bottomBar
                    .opacity(showBottom ? 1 : 0)
                    .offset(y: showBottom ? 0 : 24)
                    .scaleEffect(showBottom ? 1 : 0.96, anchor: .bottom)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    freedomFundToolbarItem
                        .opacity(showNav ? 1 : 0)
                }
                .sharedBackgroundVisibility(.hidden)

                ToolbarItem(placement: .topBarTrailing) {
                    settingsToolbarItem
                        .opacity(showNav ? 1 : 0)
                }
                .sharedBackgroundVisibility(.hidden)
            }
            .navigationDestination(for: Note.self) { note in
                if let repo {
                    NoteCanvasView(note: note, repo: repo)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
        .task {
            if repo == nil {
                self.repo = NoteRepository(context: modelContext)
            }
            runEntranceAnimation()
            Task.detached { @MainActor in
                await InsightEngine.shared.analyzeIfNeeded(modelContext: modelContext)
            }
            // Hard-wall gate: refresh entitlement state, then raise the wall
            // if this user no longer has access (expired sub, or first note
            // already written). A brand-new user with no notes passes through.
            await subscriptionManager.checkSubscriptionStatus()
            presentHardWallIfNeeded()
        }
        .onChange(of: arcCount) { _, newValue in
            guard isVisible else { return }
            if isBillDataReady && !isPlaidPending {
                cachedArcCount = newValue
            }
        }
        .onChange(of: freedomFund) { _, newValue in
            guard isVisible else { return }
            if !isPlaidPending && newValue > 0 {
                cachedFreedomFund = newValue
            }
            if isBillDataReady && !isPlaidPending {
                cachedArcCount = arcCount
            }
        }
        .onChange(of: path) { _, newPath in
            // Safety net: if the user navigates into a note (or anywhere
            // else) while dictation is live, stop the recording and append
            // whatever was captured. Without this, a stray tap on a row
            // mid-recording would leave Deepgram streaming in the
            // background after the user has moved on.
            if !newPath.isEmpty && isRecording {
                stopVoiceRecording()
            }
            // Returned to the list (canvas popped). If the user just wrote
            // their first note without access, this is where the hard wall
            // lands — after they've felt extraction, not mid-write.
            if newPath.isEmpty {
                presentHardWallIfNeeded()
            }
        }
        .onChange(of: hasAccess) { _, nowHasAccess in
            // A successful purchase/restore dissolves the wall.
            if nowHasAccess { showHardWall = false }
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
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showInsights) {
            InsightsView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showCalendar) {
            CalendarSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
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
        // The hard wall. A fullScreenCover (not a sheet) so it can't be
        // swiped away; the .onboarding/.trialExpired contexts also hide the
        // close button — the only way past is purchase or restore.
        .fullScreenCover(isPresented: $showHardWall) {
            PaywallView(context: hardWallContext)
        }
    }

    // MARK: - Toolbar

    /// Leading toolbar item: Norma's custom capsule pattern ("freedom fund · $X")
    /// that opens ArcCountView. The system's per-item Liquid Glass wrap is
    /// suppressed via `.sharedBackgroundVisibility(.hidden)` on the
    /// ToolbarItem itself, so this capsule's own fill + stroke render
    /// directly against the nav bar's glass material.
    private var freedomFundToolbarItem: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            showArcDetail = true
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("freedom fund")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NormaPalette.ink.opacity(0.6))
                Text("·")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NormaPalette.ink.opacity(0.4))
                Text(formatCapsuleCurrency(displayedFreedomFund))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NormaPalette.ink)
                    .contentTransition(.numericText())
                    .animation(isVisible ? .spring(response: 0.5, dampingFraction: 0.82) : .none, value: displayedFreedomFund)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.white.opacity(0.04)))
            .overlay(Capsule().stroke(NormaPalette.ink.opacity(0.22), lineWidth: 1))
            .fixedSize()
        }
        .buttonStyle(.plain)
    }

    /// Trailing toolbar item: settings gear with a live dither shader as its
    /// background. Sized to match the leading freedom-fund capsule so both
    /// nav-bar pills read as part of the same family. iOS 26's default glass
    /// wrap is suppressed via `.sharedBackgroundVisibility(.hidden)` on the
    /// ToolbarItem.
    private var settingsToolbarItem: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            showSettings = true
        } label: {
            Color.clear
                .frame(width: 14, height: 14)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    DitherShaderView(intensity: 1.0, dotSize: 0.8)
                        .clipShape(Capsule())
                )
                .overlay(Capsule().stroke(NormaPalette.ink.opacity(0.22), lineWidth: 1))
                .fixedSize()
        }
        .buttonStyle(.plain)
    }

    private func formatCapsuleCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(Int(amount))"
    }

    // MARK: - List body

    private var listBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Pinned section sits above the date buckets. Hidden while
            // searching so matches aren't split across two surfaces.
            if !isSearching {
                pinnedSection
            }
            ForEach(sections) { section in
                sectionView(section)
            }
        }
        .padding(.horizontal, 20)
    }

    /// The Pinned section: a header matching the date-section treatment, then
    /// either the pinned rows (same builder as date sections) or an
    /// understated hint explaining how to pin.
    private var pinnedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("pinned")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.88)  // 0.08em × 11
                .textCase(.uppercase)
                .foregroundStyle(NormaPalette.inkMuted)
                .padding(.top, 18)
                .padding(.bottom, 10)

            if pinnedNotes.isEmpty {
                pinnedEmptyHint
            } else {
                ForEach(Array(pinnedNotes.enumerated()), id: \.element.id) { offset, note in
                    if repo != nil {
                        NavigationLink(value: note) {
                            row(for: note, index: offset + 1)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            noteContextMenu(for: note)
                        }
                    }
                }
            }
        }
    }

    /// Hint row shown when no notes are pinned yet. Understated — a small
    /// lavender pin glyph beside muted instructional copy, not a hero.
    private var pinnedEmptyHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "pin")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(NormaPalette.lavender)
            Text("touch and hold a note to pin it here.")
                .font(.system(size: 14))
                .foregroundStyle(NormaPalette.inkSubtle)
        }
        .padding(.top, 4)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Empty state, structured like the onboarding celebration screens: the
    /// instruction waves in word-by-word as the screen's full-bleed hero.
    private var emptyHero: some View {
        ZStack {
            if showEmptyText {
                WaveTextView(
                    text: "",
                    font: .system(size: 56, weight: .bold),
                    color: NormaPalette.ink,
                    isAnimating: true,
                    alignment: .leading,
                    tracking: -1.5,
                    wordSpacing: 12,
                    lineSpacing: 0,
                    onWordAppear: { _ in
                        emptyWordHaptic.impactOccurred(intensity: 0.55)
                        emptyWordHaptic.prepare()
                    },
                    tokens: [
                        .init(kind: .word("tap")),
                        .init(kind: .word("+"), color: NormaPalette.lavender),
                        .init(kind: .word("to")),
                        .init(kind: .word("write")),
                        .init(kind: .word("a")),
                        .init(kind: .word("note")),
                        .init(kind: .word("or")),
                        .init(kind: .symbol("waveform"), color: NormaPalette.lavender),
                        .init(kind: .word("to")),
                        .init(kind: .word("speak")),
                        .init(kind: .word("one."))
                    ]
                )
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            emptyWordHaptic.prepare()
            // Brief beat before the line waves in.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showEmptyText = true
            }
        }
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
                        noteContextMenu(for: entry.note)
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
                HStack(spacing: 8) {
                    Text(displayTitle(for: note))
                        .font(.system(size: 18, weight: .bold))
                        .tracking(-0.18)  // -0.01em × 18
                        .foregroundStyle(NormaPalette.ink)
                        .lineLimit(1)

                    extractionPulseDot(for: note)
                }

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

    /// Small lavender dot that fades in and pulses while the AI extractor
    /// is running for this note. Mirrors NoteCanvasView's DitherShader hint
    /// in a compact form — gives the list-view a heartbeat indicator so the
    /// user can see that just-dictated text is being processed without
    /// having to open the note.
    @ViewBuilder
    private func extractionPulseDot(for note: Note) -> some View {
        let isSyncing = syncQueue.state(for: note.id) == .syncing
        Circle()
            .fill(NormaPalette.lavender)
            .frame(width: 6, height: 6)
            .modifier(ShimmerModifier(active: isSyncing))
            .opacity(isSyncing ? 1 : 0)
            .animation(.easeInOut(duration: 0.25), value: isSyncing)
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
                bottomIcon(systemName: "point.3.connected.trianglepath.dotted") {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    if hasAccess {
                        showInsights = true
                    } else {
                        showPaywall = true
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .glassEffect(in: Capsule())
            .overlay(
                Capsule().stroke(NormaPalette.ink.opacity(0.22), lineWidth: 1)
            )

            HStack(spacing: 0) {
                bottomIcon(systemName: "plus") {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    createNewNote()
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .glassEffect(in: Capsule())
            .overlay(
                Capsule().stroke(NormaPalette.ink.opacity(0.22), lineWidth: 1)
            )

            Spacer()

            voiceButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    /// Voice-dictation button. Tapping starts a Deepgram live transcription;
    /// tapping again stops it and appends the final transcript to the most
    /// recent note (or creates a new note if the list is empty), then shows
    /// a confirmation toast. Mirrors the visual states of NoteCanvasView's
    /// voiceFAB: lavender fill + pulse while recording, glass otherwise.
    private var voiceButton: some View {
        Button(action: handleVoiceTap) {
            ZStack {
                if isRecording {
                    DitherShaderView(intensity: 1.0, dotSize: 0.8)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(.clear)
                        .glassEffect(in: Circle())
                }

                Image(systemName: isRecording ? "stop.fill" : "waveform")
                    .font(.system(size: isRecording ? 18 : 22, weight: .medium))
                    .foregroundStyle(isRecording ? Color.white : NormaPalette.lavender)
            }
            .frame(width: 56, height: 56)
            .overlay(
                Circle().stroke(
                    NormaPalette.lavender.opacity(0.7),
                    lineWidth: 1
                )
            )
            .shadow(
                color: NormaPalette.lavender.opacity(isRecording ? 0.65 : 0.35),
                radius: isRecording ? 24 : 18,
                x: 0, y: 0
            )
            .scaleEffect(voicePulse ? 1.08 : 1.0)
            // Extend the hit area beyond the 56pt visual so taps that land
            // just outside the circle (common with thumbs at the bottom of
            // the screen, especially mid-recording when the user is trying
            // to stop) still register on the button instead of falling
            // through to a note row underneath.
            .frame(width: 80, height: 80)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .onChange(of: isRecording) { _, recording in
            if recording {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    voicePulse = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    voicePulse = false
                }
            }
        }
    }

    private func handleVoiceTap() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        if isRecording {
            stopVoiceRecording()
        } else if hasAccess {
            startVoiceRecording()
        } else {
            showPaywall = true
        }
    }

    private func startVoiceRecording() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                guard granted else {
                    print("NotesListScreen: microphone permission denied")
                    return
                }
                self.beginVoiceTranscription()
            }
        }
    }

    private func beginVoiceTranscription() {
        voiceTranscript = ""
        isRecording = true

        Task { @MainActor in
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.record, mode: .measurement, options: .duckOthers)
                try session.setActive(true, options: .notifyOthersOnDeactivation)

                let engine = AVAudioEngine()
                voiceAudioEngine = engine

                try await deepgramService.startLiveTranscription(
                    audioEngine: engine,
                    onPartialResult: { transcript in
                        self.voiceTranscript = transcript
                    },
                    onFinalResult: { transcript in
                        self.voiceTranscript = transcript
                    },
                    onError: { error in
                        print("NotesListScreen: deepgram error: \(error)")
                        self.stopVoiceRecording()
                    }
                )
            } catch {
                print("NotesListScreen: failed to start voice input: \(error)")
                isRecording = false
                ToastManager.shared.show(.error(message: "Couldn't start voice", detail: "Please try again"))
            }
        }
    }

    private func stopVoiceRecording() {
        deepgramService.stopTranscription()
        isRecording = false
        voiceAudioEngine = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("NotesListScreen: failed to deactivate audio session: \(error)")
        }

        let captured = voiceTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        voiceTranscript = ""
        guard !captured.isEmpty else { return }

        appendDictationToLatestNote(captured)
    }

    /// Appends the captured transcript to the most-recent note (the @Query is
    /// already sorted by updatedAt desc, so notes.first is the latest). If
    /// the list is empty, a fresh note is created to hold the transcript.
    /// Bumps updatedAt so the note bubbles to the top of the list, then
    /// shows a confirmation toast.
    private func appendDictationToLatestNote(_ text: String) {
        guard let repo else { return }

        let target: Note
        if let latest = notes.first {
            target = latest
            let trimmedExisting = latest.rawText.trimmingCharacters(in: .whitespacesAndNewlines)
            let newText = trimmedExisting.isEmpty
                ? text
                : latest.rawText + (latest.rawText.hasSuffix("\n") ? "" : "\n") + text
            repo.updateText(newText, on: latest)
        } else {
            let fresh = Note()
            modelContext.insert(fresh)
            target = fresh
            repo.updateText(text, on: fresh)
        }

        ToastManager.shared.show(.noteProcessing(noteTitle: target.title))
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
        // Count this note toward the free limit. The hard wall keys off this
        // when they return to the list, so they feel extraction on their first
        // couple of notes before being asked to subscribe.
        notesCreatedCount += 1
        let note = Note()
        modelContext.insert(note)
        try? modelContext.save()
        path.append(note)
    }

    /// Raise the hard wall if the gating conditions are met. Called only at
    /// safe moments — never while a note canvas is pushed — so it can't yank
    /// the user out of editing.
    private func presentHardWallIfNeeded() {
        if shouldHardWall { showHardWall = true }
    }

    /// Shared context menu for note rows — pin/unpin toggle above the
    /// destructive delete. Used by both the Pinned section and the date
    /// sections so the two surfaces stay in lockstep.
    @ViewBuilder private func noteContextMenu(for note: Note) -> some View {
        Button {
            togglePin(note)
        } label: {
            if note.isPinned {
                Label("unpin", systemImage: "pin.slash")
            } else {
                Label("pin", systemImage: "pin")
            }
        }
        Button(role: .destructive) {
            deleteNote(note)
        } label: {
            Label("delete", systemImage: "trash")
        }
    }

    /// Most notes a user may keep pinned at once. Unpinning is never blocked.
    private let maxPinnedNotes = 3

    private func togglePin(_ note: Note) {
        // Enforce the pin cap only when turning a pin on. Count from the full
        // `notes` array (not `pinnedNotes`, which filters by search) so a pin
        // from a date row while searching can't slip past the limit.
        if !note.isPinned && notes.filter({ $0.isPinned }).count >= maxPinnedNotes {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            ToastManager.shared.show(.info(message: "you can pin up to 3 notes"))
            return
        }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            note.isPinned.toggle()
        }
        // Pinning deliberately leaves updatedAt untouched so the note keeps
        // its place within its date bucket when unpinned.
        try? modelContext.save()
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
        let list = DispatchTime.now() + 0.55
        let bottom = DispatchTime.now() + 0.68

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

        // When not searching, pinned notes live exclusively in the Pinned
        // section, so exclude them from the date buckets. While searching we
        // keep current behavior and bucket everything.
        let dateNotes = isSearching ? filteredNotes : filteredNotes.filter { !$0.isPinned }

        for (i, note) in dateNotes.enumerated() {
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

/// Soft opacity pulse applied to a single chunk of text — used on the hero
/// digit while Plaid's balance fetch is still in flight, signalling that the
/// value may shift. Pulsing rather than gradient-sweeping because the digit
/// is small; a sweep would barely register on one or two characters.
struct ShimmerModifier: ViewModifier {
    let active: Bool
    @State private var pulsing: Bool = false

    func body(content: Content) -> some View {
        content
            .opacity(active ? (pulsing ? 0.45 : 1.0) : 1.0)
            .onChange(of: active) { _, isActive in
                if isActive {
                    pulsing = false
                    withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                        pulsing = true
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.25)) {
                        pulsing = false
                    }
                }
            }
            .onAppear {
                guard active else { return }
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
    }
}

#Preview("notes list") {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)

    NotesListScreen()
        .modelContainer(for: [Note.self, NoteToken.self], inMemory: true)
        .environmentObject(dataManager)
        .environmentObject(sessionViewModel)
        .environmentObject(BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        .environmentObject(AppCoordinator())
        .preferredColorScheme(.dark)
}
