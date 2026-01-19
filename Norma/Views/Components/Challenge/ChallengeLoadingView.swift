//
//  ChallengeLoadingView.swift
//  Norma
//
//  Created by Claude on 1/17/26.
//

import SwiftUI

/// Loading state view for challenges
struct ChallengeLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading challenge...")
                .font(.normaInput(16))
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// MARK: - Previews

#Preview("Loading State") {
    ChallengeLoadingView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("NormaBackground"))
}
