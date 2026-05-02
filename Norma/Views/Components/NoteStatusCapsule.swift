//
//  NoteStatusCapsule.swift
//  Norma
//
//  Created by Claude on 4/27/26.
//
//  Compact pill that surfaces the current sync/processing state of a note —
//  the user's signal that the AI is thinking, that the request is queued
//  while offline, or that the last extraction succeeded or failed.
//
//  Lives next to the date label at the top of the canvas: it's metadata
//  about processing, not content, so it doesn't compete with the hero title.
//

import SwiftUI

struct NoteStatusCapsule: View {
    let state: NoteSyncQueue.SyncState
    var onTapRetry: (() -> Void)? = nil

    @State private var pulse: Bool = false

    var body: some View {
        let content = HStack(spacing: 6) {
            indicator
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .glassEffect(in: Capsule())
        .overlay(border)

        if state == .error {
            Button(action: { onTapRetry?() }) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }

    @ViewBuilder
    private var indicator: some View {
        switch state {
        case .pending, .syncing:
            Circle()
                .fill(NormaPalette.lavender)
                .frame(width: 6, height: 6)
                .opacity(pulse ? 0.35 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                }
        case .queued:
            Image(systemName: "wifi.slash")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(NormaPalette.lavender.opacity(0.75))
        case .synced:
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(NormaPalette.lavender)
        case .error:
            Image(systemName: "exclamationmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.red.opacity(0.85))
        }
    }

    @ViewBuilder
    private var border: some View {
        switch state {
        case .queued:
            Capsule().stroke(
                NormaPalette.lavender.opacity(0.4),
                style: StrokeStyle(lineWidth: 1, dash: [3, 3])
            )
        case .error:
            Capsule().stroke(Color.red.opacity(0.5), lineWidth: 1)
        default:
            Capsule().stroke(NormaPalette.lavender.opacity(0.5), lineWidth: 1)
        }
    }

    private var label: String {
        switch state {
        case .pending:  return "thinking"
        case .syncing:  return "thinking"
        case .queued:   return "queued · offline"
        case .synced:   return "synced"
        case .error:    return "tap to retry"
        }
    }

    private var textColor: Color {
        switch state {
        case .error: return .red.opacity(0.85)
        default:     return NormaPalette.lavender
        }
    }
}

#Preview {
    ZStack {
        NormaPalette.canvas.ignoresSafeArea()
        VStack(alignment: .leading, spacing: 16) {
            NoteStatusCapsule(state: .pending)
            NoteStatusCapsule(state: .syncing)
            NoteStatusCapsule(state: .queued)
            NoteStatusCapsule(state: .synced)
            NoteStatusCapsule(state: .error)
        }
        .padding(24)
    }
    .preferredColorScheme(.dark)
}
