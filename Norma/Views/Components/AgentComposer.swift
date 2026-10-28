//
//  AgentComposer.swift
//  Norma
//
//  The agent composer from the Agents board. Not wired into a screen.
//  Empty send stays the coral token and drops in opacity. No disabled color.
//

import SwiftUI

enum AgentComposerMetrics {
    static let paddingTop: CGFloat = 10
    static let paddingBottom: CGFloat = 34
    static let paddingInline: CGFloat = 16
    static let rowGap: CGFloat = 10

    static let addButtonSize: CGFloat = 36
    static let addButtonRadius: CGFloat = 18
    static let plusSize: CGFloat = 18
    static let plusStroke: CGFloat = 2

    static let fieldHeight: CGFloat = 38
    static let fieldRadius: CGFloat = 19
    static let fieldPaddingLeading: CGFloat = 14
    static let fieldPaddingTrailing: CGFloat = 4
    static let fieldStrokeWidth: CGFloat = 1
    static let textLineHeight: CGFloat = 20

    static let sendButtonSize: CGFloat = 30
    static let sendButtonRadius: CGFloat = 15
    static let arrowSize: CGFloat = 16
    static let arrowStroke: CGFloat = 2.4

    static let addFill = NormaTheme.addFill
    static let plusColor = NormaTheme.slate
    static let fieldFill = NormaTheme.fieldFill
    static let fieldStroke = NormaTheme.fieldStroke
    static let placeholderColor = NormaTheme.placeholder
    static let textStyle = NormaTheme.message
    static let typedText = NormaTheme.ink
    static let sendFill = NormaTheme.coral
    static let arrowColor = NormaTheme.white
}

struct AgentComposer: View {
    static let placeholder = "Message everyone, or @ one"
    static let addAccessibilityLabel = "Add"
    static let sendAccessibilityLabel = "Send"
    /// Empty send uses this opacity on the same coral. It is not a new color.
    static let disabledOpacity: CGFloat = 0.4

    static func canSend(_ text: String) -> Bool {
        !text.isEmpty
    }

    static func sendOpacity(for text: String) -> CGFloat {
        canSend(text) ? 1 : disabledOpacity
    }

    @Binding var text: String
    let onAdd: () -> Void
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: AgentComposerMetrics.rowGap) {
            addButton
            field
        }
        .padding(.top, AgentComposerMetrics.paddingTop)
        .padding(.bottom, AgentComposerMetrics.paddingBottom)
        .padding(.horizontal, AgentComposerMetrics.paddingInline)
    }

    private var addButton: some View {
        Button(action: onAdd) {
            PlusIcon()
                .frame(width: AgentComposerMetrics.addButtonSize, height: AgentComposerMetrics.addButtonSize)
                .background(
                    AgentComposerMetrics.addFill.color,
                    in: NormaTheme.shape(AgentComposerMetrics.addButtonRadius)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Self.addAccessibilityLabel)
    }

    private var field: some View {
        HStack(spacing: 0) {
            TextField(
                "",
                text: $text,
                prompt: Text(Self.placeholder)
                    .font(AgentComposerMetrics.textStyle.font)
                    .foregroundStyle(AgentComposerMetrics.placeholderColor.color)
            )
            .font(AgentComposerMetrics.textStyle.font)
            .foregroundStyle(AgentComposerMetrics.typedText.color)
            .textFieldStyle(.plain)
            .frame(minHeight: AgentComposerMetrics.textLineHeight)
            .submitLabel(.send)
            .onSubmit(send)

            sendButton
        }
        .padding(.leading, AgentComposerMetrics.fieldPaddingLeading)
        .padding(.trailing, AgentComposerMetrics.fieldPaddingTrailing)
        .frame(maxWidth: .infinity)
        .frame(minHeight: AgentComposerMetrics.fieldHeight)
        .background(
            AgentComposerMetrics.fieldFill.color,
            in: NormaTheme.shape(AgentComposerMetrics.fieldRadius)
        )
        .overlay {
            NormaTheme.shape(AgentComposerMetrics.fieldRadius)
                .strokeBorder(
                    AgentComposerMetrics.fieldStroke.color,
                    lineWidth: AgentComposerMetrics.fieldStrokeWidth
                )
        }
    }

    private var sendButton: some View {
        Button(action: send) {
            UpArrowIcon()
                .frame(width: AgentComposerMetrics.sendButtonSize, height: AgentComposerMetrics.sendButtonSize)
                .background(
                    AgentComposerMetrics.sendFill.color,
                    in: NormaTheme.shape(AgentComposerMetrics.sendButtonRadius)
                )
        }
        .buttonStyle(.plain)
        .opacity(Self.sendOpacity(for: text))
        .disabled(!Self.canSend(text))
        .accessibilityLabel(Self.sendAccessibilityLabel)
    }

    private func send() {
        guard Self.canSend(text) else { return }
        onSend()
    }
}

private struct PlusIcon: View {
    var body: some View {
        PlusIconShape()
            .stroke(
                AgentComposerMetrics.plusColor.color,
                style: StrokeStyle(
                    lineWidth: AgentComposerMetrics.plusStroke,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .frame(width: AgentComposerMetrics.plusSize, height: AgentComposerMetrics.plusSize)
    }
}

private struct PlusIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = AgentComposerMetrics.plusStroke / 2
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.midY))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - inset))
        return path
    }
}

private struct UpArrowIcon: View {
    var body: some View {
        UpArrowShape()
            .stroke(
                AgentComposerMetrics.arrowColor.color,
                style: StrokeStyle(
                    lineWidth: AgentComposerMetrics.arrowStroke,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .frame(width: AgentComposerMetrics.arrowSize, height: AgentComposerMetrics.arrowSize)
    }
}

private struct UpArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = AgentComposerMetrics.arrowStroke / 2
        let midX = rect.midX
        let top = rect.minY + inset
        let bottom = rect.maxY - inset
        let left = rect.minX + inset
        let right = rect.maxX - inset
        let headY = top + (rect.height * 0.36)
        var path = Path()
        path.move(to: CGPoint(x: midX, y: bottom))
        path.addLine(to: CGPoint(x: midX, y: top))
        path.move(to: CGPoint(x: left, y: headY))
        path.addLine(to: CGPoint(x: midX, y: top))
        path.addLine(to: CGPoint(x: right, y: headY))
        return path
    }
}

#Preview("Composer empty") {
    AgentComposerEmptyPreview()
}

#Preview("Composer typed") {
    AgentComposerTypedPreview()
}

private struct AgentComposerEmptyPreview: View {
    @State private var text = ""

    var body: some View {
        AgentComposer(text: $text, onAdd: {}, onSend: {})
            .background(NormaTheme.silver.color)
    }
}

private struct AgentComposerTypedPreview: View {
    @State private var text = "On my way"

    var body: some View {
        AgentComposer(text: $text, onAdd: {}, onSend: {})
            .background(NormaTheme.silver.color)
    }
}
