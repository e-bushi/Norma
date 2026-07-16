//
//  NormaChatView.swift
//  Norma
//
//  Full-screen conversational surface — the way you add bills, reminders,
//  intentions, and commitments, and ask "how long does my money last?".
//  Replaces prose notes + background extraction. Decoupled from any Note:
//  the chat is a standalone token producer (see MiniChatTools create-tools).
//
//  Transparent .glassEffect layer over the live home; the salvaged notes
//  dither is the loading state while a response resolves.
//

import SwiftUI
import SwiftData

struct NormaChatView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var sessionViewModel: SessionViewModel

    var seedText: String? = nil

    /// A transcript entry — either a chat message or an inline confirmation
    /// chip for a create/mutate tool Norma just ran.
    private enum ChatEntry: Identifiable {
        case message(MiniChatMessage)
        case chip(id: UUID, summary: String)

        var id: UUID {
            switch self {
            case .message(let m): return m.id
            case .chip(let id, _): return id
            }
        }
    }

    @State private var entries: [ChatEntry] = [
        .message(MiniChatMessage(role: .assistant, text: "hey — tell me what's coming up, or ask how long your money lasts."))
    ]
    @State private var profile: UserProfile?
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var appeared: Bool = false
    @State private var hapticTask: Task<Void, Never>?
    @FocusState private var inputFocused: Bool

    private let chatService = MiniChatService()

    var body: some View {
        ZStack {
            // Solid dark backing — no glass.
            NormaPalette.canvas
                .ignoresSafeArea()

            // Loading state: the salvaged notes dither.
            DitherShaderView(intensity: 1.0)
                .blur(radius: 20)
                .opacity(isLoading ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: isLoading)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                transcript
                inputBar
            }
        }
        .preferredColorScheme(.dark)
        // Fog-in: the whole surface materializes out of a blur, like breath on glass.
        .opacity(appeared ? 1 : 0)
        .blur(radius: appeared ? 0 : 24)
        .onAppear {
            loadProfile()
            if let seedText, !seedText.isEmpty, inputText.isEmpty { inputText = seedText }
            withAnimation(.easeOut(duration: 0.55)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { inputFocused = true }
        }
        .onDisappear { stopThinkingHaptics() }
        // Gentle recurring pulse while the dither is thinking.
        .onChange(of: isLoading) { _, loading in
            if loading { startThinkingHaptics() } else { stopThinkingHaptics() }
        }
    }

    // MARK: - Thinking haptics

    private func startThinkingHaptics() {
        hapticTask?.cancel()
        hapticTask = Task { @MainActor in
            let generator = UIImpactFeedbackGenerator(style: .light)
            while !Task.isCancelled {
                generator.impactOccurred(intensity: 0.5)
                try? await Task.sleep(nanoseconds: 480_000_000)
            }
        }
    }

    private func stopThinkingHaptics() {
        hapticTask?.cancel()
        hapticTask = nil
    }

    // MARK: - Transcript

    /// Only Norma's latest reply is shown — no user echoes, no scrollback. The
    /// full exchange still lives in `entries` for API context; the surface just
    /// stays a single, calm response.
    private var transcript: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                if isLoading {
                    typingIndicator
                } else {
                    ForEach(lastTurnChips, id: \.id) { chip in
                        confirmationChip(chip.summary)
                    }
                    if let reply = latestReply {
                        bubble(reply)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Norma's most recent assistant message.
    private var latestReply: MiniChatMessage? {
        for entry in entries.reversed() {
            if case .message(let m) = entry, m.role == .assistant { return m }
        }
        return nil
    }

    /// Confirmation chips produced since the last thing the user said.
    private var lastTurnChips: [(id: UUID, summary: String)] {
        let lastUserIdx = entries.lastIndex {
            if case .message(let m) = $0 { return m.role == .user } else { return false }
        }
        let tail = lastUserIdx.map { entries[entries.index(after: $0)...] } ?? entries[...]
        return tail.compactMap {
            if case .chip(let id, let s) = $0 { return (id: id, summary: s) } else { return nil }
        }
    }

    /// Inline confirmation that a create/mutate tool ran — e.g. "✓ added
    /// rent · $1,400 · monthly". Renders before Norma's text reply.
    private func confirmationChip(_ summary: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
            Text(summary)
                .font(.system(size: 13, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(NormaPalette.lavender)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule(style: .continuous).fill(NormaPalette.lavender.opacity(0.14)))
        .overlay(Capsule(style: .continuous).stroke(NormaPalette.lavender.opacity(0.45), lineWidth: 1))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func bubble(_ message: MiniChatMessage) -> some View {
        if message.role == .user {
            HStack {
                Spacer(minLength: 40)
                Text(message.text)
                    .font(.system(size: 16))
                    .foregroundStyle(NormaPalette.canvas)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Capsule(style: .continuous).fill(NormaPalette.lavender))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            // Norma speaks as large white wave text — no bubble, no border.
            WaveTextView(
                text: message.text,
                font: .system(size: 32, weight: .semibold),
                color: .white,
                isAnimating: true,
                alignment: .leading,
                tracking: -0.5,
                wordSpacing: 9,
                lineSpacing: 6,
                onWordAppear: { _ in
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.35)
                }
            )
            .id(message.id)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(NormaPalette.inkSubtle)
                    .frame(width: 6, height: 6)
                    .opacity(0.6)
                    .scaleEffect(isLoading ? 1 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.15),
                        value: isLoading
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("tell norma…", text: $inputText, axis: .vertical)
                .font(.system(size: 15))
                .foregroundStyle(NormaPalette.ink)
                .tint(NormaPalette.lavender)
                .lineLimit(1...4)
                .focused($inputFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(NormaPalette.ink.opacity(0.15), lineWidth: 1)
                )
                .onSubmit { sendMessage() }

            Button(action: sendMessage) {
                Circle()
                    .fill(NormaPalette.lavender)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(NormaPalette.canvas)
                    )
            }
            .disabled(sendDisabled)
            .opacity(sendDisabled ? 0.5 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var sendDisabled: Bool {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
    }

    // MARK: - Actions

    /// Prior messages only (chips excluded) — the API history. Captured before
    /// the new user turn is appended so `send` doesn't double-count it.
    private var messageHistory: [MiniChatMessage] {
        entries.compactMap { if case .message(let m) = $0 { return m } else { return nil } }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let priorHistory = messageHistory
        entries.append(.message(MiniChatMessage(role: .user, text: text)))
        inputText = ""
        withAnimation(.easeOut(duration: 0.2)) { isLoading = true }

        Task {
            do {
                let response = try await chatService.send(
                    userText: text,
                    noteContext: "",
                    profileContext: profileContextString,
                    history: priorHistory,
                    toolContext: toolContext
                )
                withAnimation(.easeOut(duration: 0.3)) {
                    for outcome in response.outcomes {
                        entries.append(.chip(id: outcome.id, summary: chipLabel(outcome.summary)))
                    }
                    entries.append(.message(MiniChatMessage(role: .assistant, text: response.text)))
                    isLoading = false
                }
            } catch {
                entries.append(.message(MiniChatMessage(role: .assistant, text: "something went wrong — try again.")))
                withAnimation(.easeOut(duration: 0.3)) { isLoading = false }
            }
        }
    }

    /// Tidies a tool summary for the chip — drops the "added bill:" style verb
    /// prefix so the pill reads as a clean fact ("rent · $1,400 · monthly").
    private func chipLabel(_ summary: String) -> String {
        if let colon = summary.firstIndex(of: ":") {
            let tail = summary[summary.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            if !tail.isEmpty { return tail }
        }
        return summary
    }

    private func loadProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try? modelContext.fetch(descriptor).first {
            profile = existing
        }
    }

    private var freedomFund: Double {
        sessionViewModel.currentUser?.settings.freedomFund ?? 0
    }

    private var totalMonthlyBills: Double {
        billViewModel.bills.reduce(0.0) { $0 + $1.amount }
    }

    private var toolContext: MiniChatService.ToolContext {
        MiniChatService.ToolContext(
            modelContext: modelContext,
            bills: billViewModel.bills,
            billViewModel: billViewModel,
            sessionViewModel: sessionViewModel,
            freedomFund: freedomFund,
            totalMonthlyBills: totalMonthlyBills
        )
    }

    private var profileContextString: String {
        var lines: [String] = []
        if let settings = sessionViewModel.currentUser?.settings {
            lines.append("currency: \(settings.currency)")
            if settings.monthlyIncome > 0 { lines.append("monthly income: \(settings.monthlyIncome)") }
            if settings.freedomFund > 0 { lines.append("balance: \(settings.freedomFund)") }
        }
        if let p = profile {
            if let day = p.payday { lines.append("payday: day \(day)") }
            if let freq = p.incomeFrequency { lines.append("income frequency: \(freq)") }
            if let floor = p.runwayFloor { lines.append("runway floor: \(floor) months") }
            for fact in p.facts { lines.append("- \(fact.fact)") }
        }
        return lines.joined(separator: "\n")
    }
}
