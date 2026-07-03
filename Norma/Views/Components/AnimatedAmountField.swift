//
//  AnimatedAmountField.swift
//  Norma
//
//  A large numeric entry field where each digit "pops" in as you type and
//  pops back out on delete, with thousands separators that appear/disappear
//  at the right moments. Input is captured by an invisible system decimal-pad
//  TextField layered behind a custom-rendered, per-character animated display.
//
//  The caret always sits at the end — this is append/backspace entry, not a
//  full editor. To change the number, clear it and retype.
//
//  Identity strategy (what keeps the animation clean): integer digits are keyed
//  left-to-right (d0, d1, …) so appending/deleting only touches the tail, while
//  commas are keyed by their thousands-group-from-the-right (comma-g1 = the
//  thousands comma, comma-g2 = millions, …) so a comma keeps a stable identity
//  as the number grows. The upshot: typing 999 → 9,999 pops in ONLY the new
//  digit and the new comma; the digits already on screen don't move.
//

import SwiftUI

struct AnimatedAmountField: View {
    /// Unformatted value the field edits — digits with at most one dot
    /// (e.g. "12345" or "12345.6"). Never contains commas; formatting is
    /// purely a display concern.
    @Binding var text: String
    var focused: FocusState<Bool>.Binding

    var font: Font
    var textColor: Color
    var placeholderColor: Color
    var caretColor: Color
    var caretHeight: CGFloat = 44
    var tracking: CGFloat = 0
    var maxIntegerDigits: Int = 12
    var maxFractionDigits: Int = 2

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var caretVisible = true
    @State private var prevDigitCount = 0

    // Held in @State so the generators persist across re-renders and can be kept
    // "warm" with prepare() — that's what makes the tap land in sync with the key.
    @State private var addHaptic = UIImpactFeedbackGenerator(style: .light)
    @State private var deleteHaptic = UIImpactFeedbackGenerator(style: .rigid)

    private struct Slot: Identifiable {
        let id: String
        let char: Character
    }

    var body: some View {
        ZStack(alignment: .leading) {
            display
                .allowsHitTesting(false)

            // Invisible, on top so it reliably captures taps. Clear text + clear
            // tint means the system caret and raw string never show — the custom
            // display is the only thing the user sees.
            TextField("", text: $text)
                .keyboardType(.decimalPad)
                .focused(focused)
                .foregroundColor(.clear)
                .tint(.clear)
                .accentColor(.clear)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: text) { _, newValue in
                    let cleaned = sanitize(newValue)
                    if cleaned != newValue {
                        text = cleaned
                        return
                    }
                    let count = cleaned.filter(\.isNumber).count
                    if count > prevDigitCount {
                        fireHaptic(added: true)
                    } else if count < prevDigitCount {
                        fireHaptic(added: false)
                    }
                    prevDigitCount = count
                }
        }
        .onAppear {
            // Sync the baseline so hydrating an existing value never fires a
            // phantom haptic, and warm up the generators.
            prevDigitCount = text.filter(\.isNumber).count
            addHaptic.prepare()
            deleteHaptic.prepare()
        }
    }

    /// Subtle, differentiated feedback: a light tap when a digit lands, a crisper
    /// one when it's removed. Re-prepare after each fire to stay low-latency for
    /// rapid typing.
    private func fireHaptic(added: Bool) {
        if added {
            addHaptic.impactOccurred(intensity: 0.7)
            addHaptic.prepare()
        } else {
            deleteHaptic.impactOccurred(intensity: 0.9)
            deleteHaptic.prepare()
        }
    }

    // MARK: - Display

    private var display: some View {
        let slots = makeSlots(from: text)
        return FittedRow {
            HStack(spacing: 0) {
                if slots.isEmpty {
                    Text("0")
                        .font(font)
                        .tracking(tracking)
                        .foregroundColor(placeholderColor)
                } else {
                    ForEach(slots) { slot in
                        Text(String(slot.char))
                            .font(font)
                            .tracking(tracking)
                            .foregroundColor(textColor)
                            .transition(popTransition)
                    }
                }
                caret
            }
            .animation(popAnimation, value: text)
        }
    }

    private var caret: some View {
        Capsule(style: .continuous)
            .fill(caretColor)
            .frame(width: 3, height: caretHeight)
            .shadow(color: caretColor.opacity(0.55), radius: 6)
            .padding(.leading, 5)
            // Breathe between full and dim rather than hard on/off — reads
            // calmer and more deliberate, fitting a hero number. Reduced motion
            // pins it solid (no pulsing) but still present.
            .opacity(focused.wrappedValue ? (reduceMotion ? 1 : (caretVisible ? 1 : 0.18)) : 0)
            .animation(.easeInOut(duration: 0.5), value: caretVisible)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    caretVisible = false
                }
            }
    }

    // MARK: - Animation spec
    //
    // Digits pop in from 0.5 scale (clearly "small", never from nothing) with a
    // gentle spring overshoot. Removal starts from 0.7 — less travel reads as a
    // quicker exit under the same spring, the asymmetry the design guidance asks
    // for without juggling two curves. Reduced motion drops all movement.

    private var popTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .scale(scale: 0.5, anchor: .bottom).combined(with: .opacity),
            removal: .scale(scale: 0.7, anchor: .bottom).combined(with: .opacity)
        )
    }

    private var popAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.12) : .spring(response: 0.26, dampingFraction: 0.64)
    }

    // MARK: - Formatting

    /// Builds the ordered, identity-stable list of digit/comma slots from the
    /// raw value. See the file header for the keying scheme.
    private func makeSlots(from raw: String) -> [Slot] {
        guard !raw.isEmpty else { return [] }

        let hasDot = raw.contains(".")
        let pieces = raw.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let intPart = pieces.indices.contains(0) ? String(pieces[0]) : ""
        let decPart = pieces.indices.contains(1) ? String(pieces[1]) : ""

        var slots: [Slot] = []
        let intChars = Array(intPart)
        let n = intChars.count

        for (i, ch) in intChars.enumerated() {
            let fromRight = n - i
            // A comma precedes this digit at every thousands boundary (but never
            // before the first digit). The group number counts from the right so
            // the thousands comma is always "comma-g1" regardless of length.
            if i != 0, fromRight % 3 == 0 {
                slots.append(Slot(id: "comma-g\(fromRight / 3)", char: ","))
            }
            slots.append(Slot(id: "d\(i)", char: ch))
        }

        if hasDot {
            slots.append(Slot(id: "dot", char: "."))
            for (j, ch) in decPart.enumerated() {
                slots.append(Slot(id: "dec\(j)", char: ch))
            }
        }

        return slots
    }

    /// Keeps the raw string to digits + a single dot, clamped to the configured
    /// integer/fraction lengths. Runs on every keystroke (and on paste).
    private func sanitize(_ input: String) -> String {
        var sawDot = false
        var intCount = 0
        var fracCount = 0
        var result = ""

        for ch in input {
            if ch.isNumber {
                if sawDot {
                    guard fracCount < maxFractionDigits else { continue }
                    fracCount += 1
                } else {
                    guard intCount < maxIntegerDigits else { continue }
                    intCount += 1
                }
                result.append(ch)
            } else if (ch == "." || ch == ",") && !sawDot && maxFractionDigits > 0 {
                // Accept either separator as the decimal point (decimal pads in
                // comma-locales emit ","), but only one, and only if it isn't the
                // leading character.
                guard !result.isEmpty else { continue }
                sawDot = true
                result.append(".")
            }
        }

        return result
    }
}

// MARK: - FittedRow
//
// Scales its content down (never up) to fit the available width, anchored left,
// preserving the leading edge. Replaces the per-Text `minimumScaleFactor` the
// old single-TextField used, which can't coordinate across separate Texts.

private struct FittedRow<Content: View>: View {
    @ViewBuilder var content: Content

    @State private var contentWidth: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let available = proxy.size.width
            let scale = (contentWidth > available && contentWidth > 0)
                ? max(0.4, available / contentWidth)
                : 1

            content
                .fixedSize()
                .background(
                    GeometryReader { inner in
                        Color.clear
                            .onAppear { contentWidth = inner.size.width }
                            .onChange(of: inner.size.width) { _, w in contentWidth = w }
                    }
                )
                .scaleEffect(scale, anchor: .leading)
                .frame(width: available, alignment: .leading)
                .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: rowHeight)
    }

    // Tall enough for the 64pt hero numerals used by the freedom-fund sheet.
    private var rowHeight: CGFloat { 76 }
}

// MARK: - Preview

private struct AnimatedAmountFieldPreview: View {
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        let bg = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255)
        let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
        let accent = NormaPalette.lavender

        ZStack {
            bg.ignoresSafeArea()
            HStack(alignment: .center, spacing: 4) {
                Text("$")
                    .font(.system(size: 64, weight: .bold))
                    .tracking(-2.56)
                    .foregroundColor(cream.opacity(0.55))
                AnimatedAmountField(
                    text: $text,
                    focused: $focused,
                    font: .system(size: 64, weight: .bold),
                    textColor: cream,
                    placeholderColor: cream.opacity(0.3),
                    caretColor: accent,
                    caretHeight: 46,
                    tracking: -2.56
                )
            }
            .padding(.horizontal, 24)
        }
        .onAppear { focused = true }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    AnimatedAmountFieldPreview()
}
