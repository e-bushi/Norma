//
//  NoteCanvasView.swift
//  Norma
//
//  Created by Claude on 4/25/26.
//
//  D4 — the planning canvas. A single note rendered as prose with inline
//  chips for any extracted financial tokens.

import SwiftUI
import AVFoundation

struct NoteCanvasView: View {
    @Bindable var note: Note
    /// When provided, the body becomes an editable TextField that drives
    /// `repo.updateText(...)` (which re-runs the local extractor). When nil,
    /// the view is read-only — used by sample-data previews.
    var repo: NoteRepository? = nil
    var onBack: (() -> Void)? = nil
    /// Optional override for the voice FAB. When nil, the FAB toggles live
    /// Deepgram transcription that streams into the note body.
    var onVoice: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var titleText: String = ""
    @State private var bodyText: String = ""
    @State private var saveTask: Task<Void, Never>?
    @State private var titleSaveTask: Task<Void, Never>?
    @State private var syncQueue = NoteSyncQueue.shared
    @State private var appeared: Bool = false
    @State private var waveScale: CGFloat = 0
    @FocusState private var focusedField: Field?

    // Voice transcription state — Deepgram streams into bodyText while active.
    @StateObject private var deepgramService = DeepgramService.shared
    @State private var audioEngine = AVAudioEngine()
    @State private var isRecording: Bool = false
    @State private var voiceBaseText: String = ""
    @State private var voicePulse: Bool = false

    enum Field: Hashable { case title, body }

    private var isEditable: Bool { repo != nil }

    /// Lavender dither only renders while the LLM extractor is actively
    /// running for this note. Other states — pending, queued, synced, error
    /// — collapse the wave back to nothing so the canvas reads clean.
    private var isThinking: Bool {
        syncQueue.state(for: note.id) == .syncing
    }

    /// Body font for the note prose and chip-row text. Nunito's a soft humanist
    /// sans — pairs with the bold hero title without competing for attention.
    private static let bodyFont: Font = .custom(FontFamily.Nunito.regular, size: 18)

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            NormaPalette.canvas.ignoresSafeArea()

            // Ambient lavender dither — radiates outward from the Dynamic
            // Island as a circular wave when the AI extractor starts and
            // collapses back when it finishes. The mask drives visibility;
            // the shader runs at full intensity behind it.
            //
            // Geometry: the mask Circle is sized to twice the screen diagonal
            // and positioned with its center pinned at (width/2, 11) — that's
            // roughly the top edge of the Dynamic Island on every modern
            // iPhone. waveScale 0 = collapsed point at that anchor, 1.0 =
            // full diagonal coverage.
            DitherShaderView(intensity: 1.0)
                .ignoresSafeArea()
                .mask(
                    GeometryReader { geo in
                        let diameter = hypot(geo.size.width, geo.size.height) * 2
                        Circle()
                            .frame(width: diameter, height: diameter)
                            .scaleEffect(waveScale)
                            .position(x: geo.size.width / 2, y: 11)
                    }
                    .ignoresSafeArea()
                )

            // Vertical fade overlay — mirrors the Darken Overlay on the
            // Paper O1 artboard. Lets the dither breathe at the top of the
            // screen and quietly hands the lower portion back to the canvas
            // so it doesn't compete with the prose the user is reading.
            LinearGradient(
                stops: [
                    .init(color: NormaPalette.canvas.opacity(0),    location: 0.00),
                    .init(color: NormaPalette.canvas.opacity(0),    location: 0.18),
                    .init(color: NormaPalette.canvas.opacity(0.55), location: 0.40),
                    .init(color: NormaPalette.canvas.opacity(0.85), location: 0.62),
                    .init(color: NormaPalette.canvas,               location: 0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                topNav.appears(appeared, delay: 0.04)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        dateLabel.appears(appeared, delay: 0.10)
                        heroTitle.appears(appeared, delay: 0.16)
                        Group {
                            if isEditable {
                                editableBody
                            } else {
                                VStack(alignment: .leading, spacing: 24) {
                                    noteBody
                                    cursor
                                }
                            }
                        }
                        .appears(appeared, delay: 0.24)
                        Spacer(minLength: 200)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusedField = nil
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }

            voiceFAB
                .popAppears(appeared, delay: 0.32)
                .padding(.trailing, 20)
                .padding(.bottom, 28)
        }
        .preferredColorScheme(.dark)
        .task(id: note.id) {
            titleText = note.title ?? Self.defaultTitle(for: note)
            bodyText = note.rawText
            // Set wave directly (no animation) for the initial thinking
            // state on mount — animating in from 0 every time the user
            // opens a note that's already syncing would feel jumpy.
            waveScale = isThinking ? 1.0 : 0
        }
        .onChange(of: isThinking) { _, thinking in
            withAnimation(.spring(response: 1.1, dampingFraction: 0.78)) {
                waveScale = thinking ? 1.0 : 0
            }
        }
        .onAppear {
            appeared = true
        }
        .onDisappear {
            if isRecording {
                stopVoiceInput()
            }
        }
    }

    private var topNav: some View {
        HStack(spacing: 8) {
            Button(action: { if let onBack { onBack() } else { dismiss() } }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                    Text("notes")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(NormaPalette.ink.opacity(0.92))
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .glassEffect(in: Capsule())
                .overlay(
                    Capsule().stroke(NormaPalette.ink.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var dateLabel: some View {
        let perNoteState = syncQueue.state(for: note.id)
        return HStack(alignment: .center, spacing: 10) {
            Text(Self.dateLabel(for: note.createdAt))
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.4))
            if let state = perNoteState {
                NoteStatusCapsule(
                    state: state,
                    onTapRetry: { syncQueue.retry(noteId: note.id) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
                .id(state)
            } else if !syncQueue.isOnline {
                // No per-note signal in flight, but the device is offline.
                // The standalone capsule keeps the user oriented to system
                // status without duplicating the wifi.slash glyph that the
                // .queued NoteStatusCapsule already shows.
                OfflineCapsule()
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
            Spacer(minLength: 0)
        }
        .animation(.easeInOut(duration: 0.2), value: perNoteState)
        .animation(.easeInOut(duration: 0.2), value: syncQueue.isOnline)
    }

    private var heroTitle: some View {
        Group {
            if focusedField == .title {
                TextField("", text: $titleText, axis: .vertical)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white)
                    .textFieldStyle(.plain)
                    .lineLimit(1...3)
                    .disabled(!isEditable)
                    .focused($focusedField, equals: .title)
                    .onChange(of: titleText) { _, newValue in
                        scheduleTitleSave(newValue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                (Text(titleText.isEmpty ? " " : titleText)
                    .foregroundColor(.white)
                 +
                 Text(".")
                    .foregroundColor(NormaPalette.lavender))
                    .font(.system(size: 56, weight: .bold))
                    .lineLimit(1...3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard isEditable else { return }
                        focusedField = .title
                    }
            }
        }
    }

    private var noteBody: some View {
        NoteSegmentsView(
            note: note,
            textFont: Self.bodyFont,
            textColor: .white.opacity(0.92),
            onConfirmReminder: confirmReminderHandler
        )
    }

    /// Wires reminder-chip confirmation through the repo. Returns nil in
    /// preview/sample-data contexts so chips stay non-interactive.
    private var confirmReminderHandler: ((NoteToken, Date) -> Void)? {
        guard let repo else { return nil }
        return { token, date in
            repo.confirmReminder(token, remindAt: date, on: note)
        }
    }

    private var editableBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField(
                "what's on your mind?",
                text: $bodyText,
                axis: .vertical
            )
            .font(Self.bodyFont)
            .foregroundStyle(.white.opacity(0.92))
            .tint(NormaPalette.lavender)
            .textFieldStyle(.plain)
            .lineLimit(1...)
            .frame(maxWidth: .infinity, alignment: .leading)
            .focused($focusedField, equals: .body)
            .onChange(of: bodyText) { _, newValue in
                scheduleBodySave(newValue)
            }

            NoteSegmentsView(
                note: note,
                textFont: Self.bodyFont,
                textColor: .white.opacity(0.92),
                showsProse: false,
                onConfirmReminder: confirmReminderHandler
            )
        }
    }

    private func scheduleBodySave(_ text: String) {
        guard let repo else { return }
        // No-op if the text matches what's already persisted — prevents the
        // initial mount's TextField rebind from firing a spurious save.
        guard text != note.rawText else { return }
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            // Debounce typing so we don't fire an LLM call on every keystroke.
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            repo.updateText(text, on: note)
        }
    }

    private func scheduleTitleSave(_ text: String) {
        guard let repo else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized: String? = trimmed.isEmpty ? nil : trimmed
        guard normalized != note.title else { return }
        titleSaveTask?.cancel()
        titleSaveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            repo.updateTitle(normalized, on: note)
        }
    }

    private var cursor: some View {
        Rectangle()
            .fill(NormaPalette.lavender.opacity(0.7))
            .frame(width: 1.5, height: 22)
    }

    private var voiceFAB: some View {
        Button(action: handleVoiceTap) {
            ZStack {
                if isRecording {
                    Circle()
                        .fill(NormaPalette.lavender)
                } else {
                    Circle()
                        .fill(.clear)
                        .glassEffect(in: Circle())
                }

                Image(systemName: isRecording ? "stop.fill" : "waveform")
                    .font(.system(size: isRecording ? 18 : 22, weight: .medium))
                    .foregroundStyle(isRecording ? NormaPalette.canvas : NormaPalette.lavender)
            }
            .frame(width: 56, height: 56)
            .overlay(
                Circle().stroke(
                    NormaPalette.lavender.opacity(isRecording ? 0 : 0.7),
                    lineWidth: 1
                )
            )
            .shadow(
                color: NormaPalette.lavender.opacity(isRecording ? 0.65 : 0.35),
                radius: isRecording ? 24 : 18,
                x: 0, y: 0
            )
            .scaleEffect(voicePulse ? 1.08 : 1.0)
        }
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
        // Honor an external override if the caller wired one.
        if let onVoice {
            onVoice()
            return
        }
        guard repo != nil else { return }
        if isRecording {
            stopVoiceInput()
        } else {
            startVoiceInput()
        }
    }

    private func startVoiceInput() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                guard granted else {
                    print("NoteCanvasView: microphone permission denied")
                    return
                }
                self.beginTranscription()
            }
        }
    }

    private func beginTranscription() {
        // Snapshot the current body so streamed transcripts append rather
        // than overwrite anything the user already typed.
        voiceBaseText = bodyText
        focusedField = nil
        isRecording = true

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            // Fresh engine per session — the previous one may have been torn
            // down by stopTranscription.
            audioEngine = AVAudioEngine()

            try deepgramService.startLiveTranscription(
                audioEngine: audioEngine,
                onPartialResult: { transcript in
                    self.applyTranscript(transcript)
                },
                onFinalResult: { transcript in
                    self.applyTranscript(transcript)
                },
                onError: { error in
                    print("NoteCanvasView: deepgram error: \(error)")
                    self.stopVoiceInput()
                }
            )
        } catch {
            print("NoteCanvasView: failed to start voice input: \(error)")
            isRecording = false
        }
    }

    private func applyTranscript(_ transcript: String) {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        bodyText = voiceBaseText.isEmpty
            ? trimmed
            : voiceBaseText + " " + trimmed
    }

    private func stopVoiceInput() {
        deepgramService.stopTranscription()
        isRecording = false

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("NoteCanvasView: failed to deactivate audio session: \(error)")
        }

        // Force a final save now rather than waiting for the body-save debounce.
        if let repo, bodyText != note.rawText {
            saveTask?.cancel()
            repo.updateText(bodyText, on: note)
        }
    }

    private static func dateLabel(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE · MMM d"
        return f.string(from: date).lowercased()
    }

    private static func defaultTitle(for note: Note) -> String {
        NoteTitleGenerator.title(for: note.id)
    }
}

#Preview("D4 — base") {
    NoteCanvasView(note: NoteCanvasSample.mixed)
}

#Preview("D4a — single") {
    NoteCanvasView(note: NoteCanvasSample.singleExpense)
}

#Preview("D4b — bill") {
    NoteCanvasView(note: NoteCanvasSample.recurringBill)
}

#Preview("D4c — grouped expenses") {
    NoteCanvasView(note: NoteCanvasSample.groupedExpenses)
}

#Preview("D4d — prose + numbers") {
    NoteCanvasView(note: NoteCanvasSample.proseAndNumbers)
}

#Preview("D4e — multi-group ribbons") {
    NoteCanvasView(note: NoteCanvasSample.multipleGroups)
}

#Preview("D4f — income & projection") {
    NoteCanvasView(note: NoteCanvasSample.incomeBiweekly)
}

enum NoteCanvasSample {
    static let mixed: Note = {
        let raw = "lunch with marcus at peppermint, 450฿ "
        let end = raw.utf16.count
        let token = NoteToken(
            kind: .expense,
            amount: 450,
            currency: "THB",
            usdEquivalent: 13.50,
            category: .takeout,
            subject: "lunch at peppermint",
            counterparty: "marcus",
            sourceStart: end,
            sourceEnd: end
        )
        return Note(title: "today", rawText: raw, tokens: [token], tags: ["food", "marcus"])
    }()

    static let singleExpense: Note = {
        let raw = "scooter for the day, 250฿ "
        let end = raw.utf16.count
        let token = NoteToken(
            kind: .expense,
            amount: 250,
            currency: "THB",
            usdEquivalent: 7.40,
            category: .transport,
            subject: "scooter",
            sourceStart: end,
            sourceEnd: end
        )
        return Note(title: "today", rawText: raw, tokens: [token])
    }()

    static let recurringBill: Note = {
        let raw = "split rent with marcus, 18,000฿ monthly "
        let end = raw.utf16.count
        let token = NoteToken(
            kind: .bill,
            amount: 18000,
            currency: "THB",
            usdEquivalent: 540,
            category: .utilities,
            subject: "rent",
            counterparty: "marcus",
            recurrence: .monthly,
            sourceStart: end,
            sourceEnd: end
        )
        return Note(title: "today", rawText: raw, tokens: [token])
    }()

    static let groupedExpenses: Note = {
        let raw = "out and about all day. "
        let end = raw.utf16.count
        func t(_ amount: Double, _ usd: Double, _ category: NoteToken.Category, _ subject: String) -> NoteToken {
            NoteToken(
                kind: .expense,
                amount: amount,
                currency: "THB",
                usdEquivalent: usd,
                category: category,
                subject: subject,
                sourceStart: end,
                sourceEnd: end
            )
        }
        let tokens: [NoteToken] = [
            t(320, 9.50, .takeout, "breakfast at the cafe"),
            t(250, 7.40, .transport, "scooter for the day"),
            t(1200, 35.50, .leisure, "beach club entry"),
            t(480, 14.20, .takeout, "dinner with the crew"),
            t(180, 5.30, .takeout, "one drink at home")
        ]
        return Note(title: "today", rawText: raw, tokens: tokens)
    }()

    static let incomeBiweekly: Note = {
        let raw = "got paid by acme today, +$4,500 biweekly. "
        let end = raw.utf16.count
        let token = NoteToken(
            kind: .income,
            amount: 4500,
            currency: "USD",
            usdEquivalent: 4500,
            category: .work,
            subject: "acme paycheck",
            counterparty: "acme",
            recurrence: .biweekly,
            occurredAt: Date(),
            sourceStart: end,
            sourceEnd: end
        )
        return Note(title: "today", rawText: raw, tokens: [token])
    }()

    static let multipleGroups: Note = {
        let raw = "rolling month-end. closing out a few things. "
        let end = raw.utf16.count
        func e(_ amount: Double, _ usd: Double, _ category: NoteToken.Category, _ subject: String) -> NoteToken {
            NoteToken(
                kind: .expense, amount: amount, currency: "THB", usdEquivalent: usd,
                category: category, subject: subject,
                sourceStart: end, sourceEnd: end
            )
        }
        func b(_ amount: Double, _ usd: Double, _ subject: String) -> NoteToken {
            NoteToken(
                kind: .bill, amount: amount, currency: "THB", usdEquivalent: usd,
                category: .utilities, subject: subject,
                recurrence: .monthly,
                sourceStart: end, sourceEnd: end
            )
        }
        let tokens: [NoteToken] = [
            e(320, 9.50, .takeout, "breakfast at the cafe"),
            e(250, 7.40, .transport, "scooter for the day"),
            e(1200, 35.50, .leisure, "beach club entry"),
            e(480, 14.20, .takeout, "dinner with the crew"),
            e(180, 5.30, .takeout, "one drink at home"),
            b(18000, 540, "rent"),
            b(1800, 53, "internet"),
            b(42500, 1247, "coworking annual")
        ]
        return Note(title: "today", rawText: raw, tokens: tokens)
    }()

    static let proseAndNumbers: Note = {
        let raw = "great day at the beach club. 1,200฿ for entry, plus 480฿ for dinner with the crew. "
        let end = raw.utf16.count
        let entry = NoteToken(
            kind: .expense,
            amount: 1200,
            currency: "THB",
            usdEquivalent: 35.50,
            category: .leisure,
            subject: "beach club entry",
            sourceStart: end,
            sourceEnd: end
        )
        let dinner = NoteToken(
            kind: .expense,
            amount: 480,
            currency: "THB",
            usdEquivalent: 14.20,
            category: .takeout,
            subject: "dinner",
            sourceStart: end,
            sourceEnd: end
        )
        return Note(title: "today", rawText: raw, tokens: [entry, dinner])
    }()
}
