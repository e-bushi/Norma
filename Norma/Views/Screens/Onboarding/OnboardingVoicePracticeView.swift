//
//  OnboardingVoicePracticeView.swift
//  Norma
//
//  Practice screen wedged between the card questions and the auth tail.
//  Lets the user feel the product before signing up: tap the waveform,
//  speak a money-shaped thought, watch Deepgram transcribe it, then watch
//  the LLM extractor surface chips. Nothing is persisted — this is an
//  ephemeral demo.
//

import SwiftUI
import AVFoundation

struct OnboardingVoicePracticeView: View {
    let onContinue: () -> Void

    @StateObject private var deepgram = DeepgramService.shared

    @State private var isRecording: Bool = false
    @State private var transcript: String = ""
    @State private var audioEngine: AVAudioEngine?

    @State private var isExtracting: Bool = false
    @State private var extractedTokens: [NoteToken] = []
    @State private var hasTried: Bool = false
    @State private var extractionError: String?

    /// Tracks which primitive kinds the user has successfully created at
    /// least once across the session. Drives the per-card check marks and
    /// the status line beneath the mic.
    @State private var seenKinds: Set<NoteToken.Kind> = []

    /// Drives the dither shader's circular mask. 0 = collapsed (shader
    /// invisible), 1 = full coverage. Mirrors the NoteCanvasView pattern
    /// where the shader radiates out from the top of the screen while
    /// the AI is active and collapses back when it's done.
    @State private var waveScale: CGFloat = 0

    // Entrance choreography — every text/component fades in with the
    // shared spring curve, staggered down the page.
    @State private var titleAppeared = false
    @State private var examplesHeaderAppeared = false
    @State private var examplesAppeared = false
    @State private var micAppeared = false
    @State private var ctaAppeared = false

    /// Spring used for every entrance/exit on the page. Matches the
    /// design-system spring used by the question screens.
    private static let pageSpring: Animation = .interpolatingSpring(
        mass: 1,
        stiffness: 350,
        damping: 50,
        initialVelocity: 30
    )

    var body: some View {
        ZStack {
            NormaPalette.canvas.ignoresSafeArea()

            // Same pattern as NoteCanvasView: shader is invisible until the
            // mask scales out from the top of the screen. We drive that mask
            // off `waveScale`, which animates to 1 while recording/extracting
            // and back to 0 when the demo is idle.
            DitherShaderView(intensity: 1.0)
                .ignoresSafeArea()
                .allowsHitTesting(false)
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

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerBlock
                    transcriptBlock
                    chipsBlock
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 240)
                .frame(maxWidth: .infinity, alignment: .leading)
                // Conditional blocks (transcript + chips) animate in/out
                // with the shared spring as their state flips.
                .animation(Self.pageSpring, value: isRecording)
                .animation(Self.pageSpring, value: transcript.isEmpty)
                .animation(Self.pageSpring, value: isExtracting)
                .animation(Self.pageSpring, value: extractedTokens.count)
                .animation(Self.pageSpring, value: hasTried)
                .animation(Self.pageSpring, value: extractionError)
            }

            VStack(spacing: 14) {
                Spacer()
                micButton
                    .opacity(micAppeared ? 1 : 0)
                    .offset(y: micAppeared ? 0 : 14)
                    .animation(Self.pageSpring, value: micAppeared)
                primitiveStatusLine
                    .opacity(micAppeared ? 1 : 0)
                    .animation(Self.pageSpring, value: micAppeared)
                    .animation(Self.pageSpring, value: seenKinds)
                ZStack {
                    continueButton
                        .opacity(ctaAppeared && hasTried ? 1 : 0)
                        .offset(y: ctaAppeared && hasTried ? 0 : 14)
                    skipButton
                        .opacity(ctaAppeared && !hasTried ? 1 : 0)
                        .offset(y: ctaAppeared && !hasTried ? 0 : 14)
                }
                .animation(Self.pageSpring, value: ctaAppeared)
                .animation(Self.pageSpring, value: hasTried)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.dark)
        .onAppear { runEntranceAnimation() }
        .onDisappear { teardownIfNeeded() }
    }

    // MARK: - Subviews

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("try saying a money thought.")
                .font(.system(size: 44, weight: .heavy))
                .tracking(-1.3)
                .lineSpacing(2)
                .foregroundStyle(NormaPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(titleAppeared ? 1 : 0)
                .offset(y: titleAppeared ? 0 : 14)
                .animation(Self.pageSpring, value: titleAppeared)

            VStack(alignment: .leading, spacing: 10) {
                Text("three things norma can catch:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(NormaPalette.inkSubtle)
                    .opacity(examplesHeaderAppeared ? 1 : 0)
                    .offset(y: examplesHeaderAppeared ? 0 : 10)
                    .animation(Self.pageSpring, value: examplesHeaderAppeared)

                primitiveCard(
                    label: "BILL",
                    description: "a recurring thing you have to pay",
                    example: "\"rent is 1800, due the first\"",
                    isSeen: seenKinds.contains(.bill),
                    index: 0
                )
                primitiveCard(
                    label: "REMINDER",
                    description: "a task you don't want to forget",
                    example: "\"remind me to pay verizon friday\"",
                    isSeen: seenKinds.contains(.reminder),
                    index: 1
                )
                primitiveCard(
                    label: "INTENTION",
                    description: "something you're considering",
                    example: "\"thinking about a 200 dollar trip to chiang mai\"",
                    isSeen: seenKinds.contains(.intent),
                    index: 2
                )
            }
        }
    }

    @ViewBuilder
    private func primitiveCard(
        label: String,
        description: String,
        example: String,
        isSeen: Bool,
        index: Int
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(label)
                        .font(.custom(FontFamily.Rubik.semiBold, size: 10))
                        .tracking(1.0)
                        .foregroundStyle(NormaPalette.lavender)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .overlay(
                            Capsule().stroke(
                                NormaPalette.lavender.opacity(isSeen ? 1 : 0.45),
                                lineWidth: 1
                            )
                        )

                    if isSeen {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(NormaPalette.lavender)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Spacer(minLength: 0)
                }

                Text(description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(NormaPalette.ink.opacity(0.78))

                Text(example)
                    .font(.custom(FontFamily.Rubik.regular, size: 14).italic())
                    .foregroundStyle(NormaPalette.ink.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(NormaPalette.ink.opacity(isSeen ? 0.07 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isSeen ? NormaPalette.lavender.opacity(0.6) : NormaPalette.ink.opacity(0.14),
                    lineWidth: 1
                )
        )
        .opacity(examplesAppeared ? 1 : 0)
        .offset(y: examplesAppeared ? 0 : 10)
        .animation(
            Self.pageSpring.delay(Double(index) * 0.06),
            value: examplesAppeared
        )
        .animation(Self.pageSpring, value: isSeen)
    }

    @ViewBuilder
    private var transcriptBlock: some View {
        if isRecording || !transcript.isEmpty {
            transcriptCard
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
        }
    }

    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("what we heard")
                .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                .tracking(0.88)
                .textCase(.uppercase)
                .foregroundStyle(NormaPalette.inkSubtle)
            Text(transcript.isEmpty ? "listening…" : transcript)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(NormaPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(NormaPalette.ink.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(NormaPalette.ink.opacity(0.18), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var chipsBlock: some View {
        Group {
            if isExtracting {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(NormaPalette.lavender)
                    Text("norma is reading it…")
                        .font(.custom(FontFamily.Rubik.medium, size: 13))
                        .foregroundStyle(NormaPalette.inkSubtle)
                }
            } else if !extractedTokens.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("what norma pulled out")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                        .tracking(0.88)
                        .textCase(.uppercase)
                        .foregroundStyle(NormaPalette.lavender)
                    FlowStack(spacing: 8) {
                        ForEach(Array(extractedTokens.enumerated()), id: \.element.id) { index, token in
                            ChipView(token: token, style: .inline)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.85).combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .animation(
                                    Self.pageSpring.delay(Double(index) * 0.06),
                                    value: extractedTokens.count
                                )
                        }
                    }
                }
            } else if hasTried, let extractionError {
                Text(extractionError)
                    .font(.custom(FontFamily.Rubik.medium, size: 13))
                    .foregroundStyle(NormaPalette.inkSubtle)
            } else if hasTried {
                Text("norma didn't find anything to pull out. try one of the examples above.")
                    .font(.custom(FontFamily.Rubik.medium, size: 13))
                    .foregroundStyle(NormaPalette.inkSubtle)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity
        ))
    }

    /// Small footer showing which of the three primitives the user has
    /// created at least once. Each item is dim until its kind shows up in
    /// `seenKinds`, at which point it brightens and gets a check.
    private var primitiveStatusLine: some View {
        HStack(spacing: 12) {
            statusPill("bill", isSeen: seenKinds.contains(.bill))
            statusPill("reminder", isSeen: seenKinds.contains(.reminder))
            statusPill("intention", isSeen: seenKinds.contains(.intent))
        }
    }

    @ViewBuilder
    private func statusPill(_ label: String, isSeen: Bool) -> some View {
        HStack(spacing: 5) {
            if isSeen {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(NormaPalette.lavender)
            } else {
                Circle()
                    .stroke(NormaPalette.ink.opacity(0.25), lineWidth: 1)
                    .frame(width: 8, height: 8)
            }
            Text(label)
                .font(.custom(FontFamily.Rubik.medium, size: 11))
                .foregroundStyle(isSeen ? NormaPalette.ink : NormaPalette.ink.opacity(0.35))
        }
    }

    private var micButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isRecording ? NormaPalette.lavender : NormaPalette.ink.opacity(0.08))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle().stroke(
                            isRecording ? NormaPalette.lavender : NormaPalette.ink.opacity(0.32),
                            lineWidth: 1
                        )
                    )

                if isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(NormaPalette.canvas)
                        .frame(width: 18, height: 18)
                } else {
                    Image(systemName: "waveform")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(NormaPalette.ink)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var continueButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            teardownIfNeeded()
            onContinue()
        } label: {
            HStack(spacing: 8) {
                Text("continue")
                    .font(.system(size: 15, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(NormaPalette.canvas)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(Capsule().fill(NormaPalette.lavender))
        }
        .buttonStyle(.plain)
    }

    private var skipButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            teardownIfNeeded()
            onContinue()
        } label: {
            Text("skip")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(NormaPalette.ink.opacity(0.5))
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recording

    private func startRecording() {
        transcript = ""
        // Don't wipe extractedTokens — chips accumulate across recordings so
        // the user watches their vocabulary build up. We only clear the
        // transient transcript + any prior error.
        extractionError = nil

        withAnimation(.easeOut(duration: 0.55)) {
            waveScale = 1.0
        }

        Task { @MainActor in
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.record, mode: .measurement, options: .duckOthers)
                try session.setActive(true, options: .notifyOthersOnDeactivation)

                let engine = AVAudioEngine()
                audioEngine = engine

                try await deepgram.startLiveTranscription(
                    audioEngine: engine,
                    onPartialResult: { text in
                        self.transcript = text
                    },
                    onFinalResult: { text in
                        self.transcript = text
                    },
                    onError: { error in
                        print("OnboardingVoicePracticeView: deepgram error: \(error)")
                        self.stopRecording()
                    }
                )
                isRecording = true
            } catch {
                print("OnboardingVoicePracticeView: failed to start: \(error)")
                isRecording = false
            }
        }
    }

    private func stopRecording() {
        guard isRecording else { return }
        deepgram.stopTranscription()
        isRecording = false
        audioEngine = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("OnboardingVoicePracticeView: failed to deactivate audio session: \(error)")
        }

        let captured = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !captured.isEmpty else {
            collapseWaveAfterPause()
            return
        }
        hasTried = true
        runExtraction(on: captured)
    }

    private func runExtraction(on text: String) {
        isExtracting = true
        Task {
            do {
                let tokens = try await NoteExtractionService.shared.extract(text: text)
                await MainActor.run {
                    extractedTokens.append(contentsOf: tokens)
                    seenKinds.formUnion(tokens.map { $0.kind })
                    isExtracting = false
                    collapseWaveAfterPause()
                }
            } catch {
                await MainActor.run {
                    extractionError = "couldn't reach the extractor. try again."
                    isExtracting = false
                    collapseWaveAfterPause()
                }
            }
        }
    }

    /// Holds the shader open briefly after extraction lands so the user can
    /// register the chips against the lavender field, then collapses it back
    /// to idle — same beat as NoteCanvasView's extraction wave.
    private func collapseWaveAfterPause() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeIn(duration: 0.6)) {
                waveScale = 0
            }
        }
    }

    private func teardownIfNeeded() {
        if isRecording { stopRecording() }
    }

    // MARK: - Entrance

    private func runEntranceAnimation() {
        // The page-spring is applied via `.animation()` modifiers on each
        // element, so here we just flip the booleans on cue and the spring
        // handles the rest.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { titleAppeared = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { examplesHeaderAppeared = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) { examplesAppeared = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) { micAppeared = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) { ctaAppeared = true }
    }
}

// MARK: - Flow layout for chips

/// Minimal wrap-around layout so extracted chips wrap onto multiple lines.
private struct FlowStack<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        _FlowLayout(spacing: spacing) { content() }
    }
}

private struct _FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if lineWidth + size.width > maxWidth {
                totalHeight += lineHeight + spacing
                totalWidth = max(totalWidth, lineWidth - spacing)
                lineWidth = size.width + spacing
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
        totalHeight += lineHeight
        totalWidth = max(totalWidth, lineWidth - spacing)
        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
