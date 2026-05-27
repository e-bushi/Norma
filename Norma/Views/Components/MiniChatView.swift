//
//  MiniChatView.swift
//  Norma
//
//  Created by Claude on 5/26/26.
//
//  Contextual AI overlay on the note canvas. Shows only Norma's response
//  as bold typographic text — same register as the onboarding interstitial.
//  The user types a question, Norma answers, the response replaces any
//  previous one. Tap the backdrop to dismiss.
//

import SwiftUI
import SwiftData

struct MiniChatView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    let note: Note
    var onDismiss: (() -> Void)? = nil
    var initialMessage: String? = nil

    @State private var history: [MiniChatMessage] = []
    @State private var profile: UserProfile?
    @State private var responseText: String = ""
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var didLoadInitial: Bool = false
    @FocusState private var inputFocused: Bool

    private let chatService = MiniChatService()
    private let maxResponseLength = 120

    var body: some View {
        ZStack {
            DitherShaderView(intensity: 1.0)
                .blur(radius: 20)
                .opacity(isLoading ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: isLoading)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    if !responseText.isEmpty && !isLoading {
                        responseArea
                            .transition(.opacity.combined(with: .offset(y: 12)))
                            .padding(.top, 40)
                    }
                }

                Spacer(minLength: 12)

                inputBar
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            inputFocused = true
            loadProfile()
            loadInitialMessage()
        }
    }

    // MARK: - Response

    private var responseArea: some View {
        WaveTextView(
            text: responseText,
            font: .system(size: 32, weight: .bold),
            color: NormaPalette.ink,
            isAnimating: true,
            alignment: .leading,
            tracking: -0.8,
            wordSpacing: 8,
            lineSpacing: 4,
            onWordAppear: { _ in
                UIImpactFeedbackGenerator(style: .soft)
                    .impactOccurred(intensity: 0.4)
            }
        )
        .id(responseText)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("ask norma anything…", text: $inputText)
                .font(.system(size: 14))
                .foregroundStyle(NormaPalette.ink)
                .tint(NormaPalette.lavender)
                .focused($inputFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(NormaPalette.ink.opacity(0.15), lineWidth: 1)
                )
                .onSubmit { sendMessage() }

            Button(action: sendMessage) {
                Circle()
                    .fill(NormaPalette.lavender)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(NormaPalette.canvas)
                            .rotationEffect(.degrees(45))
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            .opacity(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
        .padding(.bottom, 36)
    }

    // MARK: - Actions

    private func loadProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try? modelContext.fetch(descriptor).first {
            profile = existing
        } else {
            let newProfile = UserProfile()
            modelContext.insert(newProfile)
            try? modelContext.save()
            profile = newProfile
        }
    }

    private func loadInitialMessage() {
        guard !didLoadInitial else { return }
        didLoadInitial = true

        if let message = initialMessage {
            responseText = String(message.prefix(maxResponseLength))
            history.append(MiniChatMessage(role: .assistant, text: responseText))
        } else {
            isLoading = true
            Task {
                do {
                    let context = buildNoteContext()
                    let response = try await chatService.send(
                        userText: "The user just opened the chat on this note. Give a brief, helpful opening line based on what's in the note — a quick observation, a calculation you noticed, or ask if they need help with something specific.",
                        noteContext: context,
                        profileContext: profileContextString,
                        history: [],
                        toolContext: toolContext
                    )
                    let trimmed = String(response.prefix(maxResponseLength))
                    history.append(MiniChatMessage(role: .assistant, text: trimmed))
                    withAnimation(.easeOut(duration: 0.3)) {
                        responseText = trimmed
                        isLoading = false
                    }
                } catch {
                    withAnimation(.easeOut(duration: 0.3)) {
                        responseText = "what can i help with?"
                        isLoading = false
                    }
                }
            }
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        history.append(MiniChatMessage(role: .user, text: text))
        inputText = ""
        withAnimation(.easeOut(duration: 0.2)) { isLoading = true }

        Task {
            do {
                let context = buildNoteContext()
                let response = try await chatService.send(
                    userText: text,
                    noteContext: context,
                    profileContext: profileContextString,
                    history: history,
                    toolContext: toolContext
                )
                let trimmed = String(response.prefix(maxResponseLength))
                history.append(MiniChatMessage(role: .assistant, text: trimmed))
                withAnimation(.easeOut(duration: 0.3)) {
                    responseText = trimmed
                    isLoading = false
                }
            } catch {
                withAnimation(.easeOut(duration: 0.3)) {
                    responseText = "something went wrong — try again."
                    isLoading = false
                }
            }
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
            totalMonthlyBills: totalMonthlyBills,
            note: note
        )
    }

    private var profileContextString: String {
        var lines: [String] = []
        if let settings = sessionViewModel.currentUser?.settings {
            lines.append("currency: \(settings.currency)")
            if settings.monthlyIncome > 0 { lines.append("monthly income: \(settings.monthlyIncome)") }
            if settings.freedomFund > 0 { lines.append("freedom fund: \(settings.freedomFund)") }
        }
        if let p = profile {
            if let day = p.payday { lines.append("payday: day \(day)") }
            if let freq = p.incomeFrequency { lines.append("income frequency: \(freq)") }
            if let floor = p.runwayFloor { lines.append("runway floor: \(floor) months") }
            for fact in p.facts { lines.append("- \(fact.fact)") }
        }
        return lines.joined(separator: "\n")
    }

    private func buildNoteContext() -> String {
        let title = note.title ?? "untitled"
        let tokens = note.tokens.map { token in
            "\(token.kind.rawValue): \(token.subject ?? "") \(token.amount) \(token.currency ?? "")"
        }.joined(separator: "\n")
        let tokenBlock = tokens.isEmpty ? "no chips extracted" : tokens

        return """
        Note: \(title)
        Content: \(note.rawText)
        Chips:
        \(tokenBlock)
        """
    }
}
