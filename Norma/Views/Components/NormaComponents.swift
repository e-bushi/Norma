//
//  NormaComponents.swift
//  Norma
//
//  The small pieces every screen is built from: the hero headline with its
//  accent period, uppercase field labels, choice pills, and a wrapping
//  layout for rows of pills.
//

import SwiftUI
import UIKit

/// Big lowercase headline ending in the accent-colored period.
struct HeroTitle: View {
    let text: String
    var size: CGFloat = 56

    var body: some View {
        (Text(text).foregroundStyle(NormaPalette.ink)
            + Text(".").foregroundStyle(NormaPalette.lavender))
            .font(.system(size: size, weight: .heavy, relativeTo: .largeTitle))
            .tracking(-size * 0.04)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Small uppercase label above a field or section.
struct FieldLabel: View {
    let text: String
    var color: Color = NormaPalette.inkSubtle

    init(_ text: String, color: Color = NormaPalette.inkSubtle) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .rubik(FontFamily.Rubik.semiBold, size: 11, relativeTo: .caption2)
            .tracking(0.88)
            .textCase(.uppercase)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Selectable capsule: solid accent when active, dashed outline otherwise.
struct ChoicePill: View {
    let label: String
    let isActive: Bool
    var fillsWidth = false
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { action() }
        } label: {
            Text(label)
                .rubik(
                    isActive ? FontFamily.Rubik.semiBold : FontFamily.Rubik.medium,
                    size: 14,
                    relativeTo: .subheadline
                )
                .foregroundStyle(isActive ? NormaPalette.onAccent : NormaPalette.ink)
                .padding(.horizontal, 15)
                .padding(.vertical, 9)
                .frame(maxWidth: fillsWidth ? .infinity : nil)
                .background { if isActive { Capsule().fill(NormaPalette.lavender) } }
                .overlay(
                    Capsule().strokeBorder(
                        isActive ? NormaPalette.lavender : NormaPalette.ink.opacity(0.28),
                        style: isActive ? StrokeStyle(lineWidth: 1) : StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Solid accent capsule for the one primary action on a screen.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, relativeTo: .headline))
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .semibold, relativeTo: .headline))
                }
            }
            .foregroundStyle(NormaPalette.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Capsule().fill(NormaPalette.lavender.opacity(isEnabled ? 1 : 0.4)))
            .shadow(color: NormaPalette.lavender.opacity(isEnabled ? 0.4 : 0), radius: 18, y: 10)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isEnabled)
    }
}

/// Slight shrink-and-dim on press.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Entrance for one item in a staggered sequence: rises a few points, fades
/// in, and sharpens from a slight blur. With Reduce Motion it only fades.
struct StaggeredAppear: ViewModifier {
    let isVisible: Bool
    let delay: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let isMoving = !isVisible && !reduceMotion
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isMoving ? 14 : 0)
            .blur(radius: isMoving ? 6 : 0)
            .animation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.6).delay(delay), value: isVisible)
    }
}

extension View {
    /// Stagger position `index` in a sequence that starts after `baseDelay`.
    func staggeredAppear(_ isVisible: Bool, index: Int, baseDelay: Double = 0, step: Double = 0.07) -> some View {
        modifier(StaggeredAppear(isVisible: isVisible, delay: baseDelay + Double(index) * step))
    }
}

/// Intro and celebration copy when VoiceOver is on: the phrase stays on
/// screen, is announced, and advances only from the continue button.
struct VoiceOverPhrasePrompt: View {
    let phrase: String
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text(phrase)
                    .font(.system(size: 40, weight: .bold, relativeTo: .largeTitle))
                    .foregroundStyle(NormaPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                PrimaryButton(title: "continue", systemImage: "arrow.right", action: onContinue)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 32)
        }
        .onAppear { announce(phrase) }
        .onChange(of: phrase) { _, newValue in announce(newValue) }
    }

    private func announce(_ phrase: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            UIAccessibility.post(notification: .announcement, argument: phrase)
        }
    }
}

/// Lays children out left to right, wrapping onto new lines as needed.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, maxWidth: proposal.width ?? .infinity)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
        }
    }

    private struct Row {
        var indices: [Int] = []
        var y: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(_ subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let proposedWidth = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if proposedWidth > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row(y: current.y + current.height + lineSpacing)
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
