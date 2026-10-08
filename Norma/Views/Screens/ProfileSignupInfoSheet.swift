//
//  ProfileSignupInfoSheet.swift
//  Norma
//
//  Name editor opened from the Settings profile row. Onboarding never asks
//  for a name, so this is where the user tells Norma what to call them.
//

import SwiftUI

struct ProfileSignupInfoSheet: View {
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String = ""
    @State private var lastName: String = ""

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private var accentPurple: Color { NormaPalette.lavender }

    var body: some View {
        NavigationStack {
            ZStack {
                NormaPalette.canvas.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        heroTitle

                        Text("let norma know what to call you. it stays on this iPhone.")
                            .font(.custom(FontFamily.Nunito.regular, size: 16).italic())
                            .foregroundStyle(.white.opacity(0.55))
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 18) {
                            field(label: "first name", text: $firstName)
                            field(label: "last name", text: $lastName)
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 80)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    saveButton
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: hydrate)
    }

    // MARK: - Subviews

    private var heroTitle: some View {
        (
            Text("your name").foregroundStyle(.white)
            + Text(".").foregroundStyle(NormaPalette.lavender)
        )
        .font(.system(size: 56, weight: .heavy))
        .lineLimit(1...2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func field(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.custom(FontFamily.Rubik.regular, size: 12))
                .foregroundStyle(mutedText)
            TextField("", text: text)
                .font(.custom(FontFamily.Nunito.regular, size: 18))
                .foregroundStyle(.white.opacity(0.92))
                .tint(NormaPalette.lavender)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(cream.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(cream.opacity(0.08), lineWidth: 1)
                )
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                Text("save")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(NormaPalette.ink.opacity(0.92))
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .glassEffect(in: Capsule())
            .overlay(
                Capsule().stroke(NormaPalette.ink.opacity(0.25), lineWidth: 1)
            )
            .fixedSize()
        }
        .buttonStyle(.plain)
        .disabled(!hasValidInput)
    }

    private var hasValidInput: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Actions

    private func hydrate() {
        // `.name` stores "First Last" combined, so split naively to pre-fill.
        let existing = sessionViewModel.currentUser?.name
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !existing.isEmpty else { return }
        let parts = existing.split(separator: " ", maxSplits: 1).map(String.init)
        firstName = parts.first ?? existing
        lastName = parts.count > 1 ? parts[1] : ""
    }

    private func save() {
        guard var profile = sessionViewModel.currentUser else { return }

        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = last.isEmpty ? first : "\(first) \(last)"

        profile.name = combined
        sessionViewModel.updateUserProfile(profile)
        dismiss()
    }
}
