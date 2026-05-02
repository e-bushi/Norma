//
//  OfflineCapsule.swift
//  Norma
//
//  Quiet "offline" pill shown at the top of the note canvas when the device
//  has no network. Distinct from NoteStatusCapsule's per-note ".queued" state
//  by colorway — uses the muted ink palette instead of lavender so it reads
//  as a passive system condition rather than active AI work the user might
//  expect to see resolve.
//
//  Render gating lives in the parent: only show this when there's no
//  per-note sync capsule already on the row, otherwise the same wifi.slash
//  signal is duplicated.
//

import SwiftUI

struct OfflineCapsule: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(NormaPalette.inkSubtle)

            Text("offline")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(NormaPalette.inkSubtle)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .glassEffect(in: Capsule())
        .overlay(
            Capsule().stroke(
                NormaPalette.inkMuted.opacity(0.6),
                style: StrokeStyle(lineWidth: 1, dash: [3, 3])
            )
        )
    }
}

#Preview {
    ZStack {
        NormaPalette.canvas.ignoresSafeArea()
        OfflineCapsule()
    }
    .preferredColorScheme(.dark)
}
