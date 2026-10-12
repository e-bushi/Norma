//
//  RootView.swift
//  Norma
//
//  Onboarding until a profile exists, home after. Resetting data deletes the
//  profile, which lands the user back on the landing screen.
//

import SwiftData
import SwiftUI

struct RootView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        ZStack {
            if let profile = profiles.first {
                HomeView(profile: profile)
                    .transition(.opacity)
            } else {
                OnboardingFlowView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: profiles.isEmpty)
    }
}
