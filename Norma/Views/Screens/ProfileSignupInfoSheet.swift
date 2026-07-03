//
//  ProfileSignupInfoSheet.swift
//  Norma
//
//  Sheet shown when the user's profile is missing the basic signup info
//  Norma needs — primarily their name. Apple Sign In only returns the
//  display name on the *very first* authorization for an app, so users who
//  revoke + re-grant (or who hide their email and skip the name prompt)
//  end up with an empty name field. This sheet lets them fix it from
//  settings; saving updates the encrypted profile on the backend.
//

import SwiftUI

struct ProfileSignupInfoSheet: View {
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var isSaving = false

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

                        Text("apple didn't share your name with us. let norma know what to call you.")
                            .font(.custom(FontFamily.Nunito.regular, size: 16).italic())
                            .foregroundStyle(.white.opacity(0.55))
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 18) {
                            field(label: "first name", text: $firstName)
                            field(label: "last name", text: $lastName)

                            if let email = sessionViewModel.currentUser?.email {
                                readOnlyField(label: "email", value: email)
                            }
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

    @ViewBuilder
    private func readOnlyField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.custom(FontFamily.Rubik.regular, size: 12))
                .foregroundStyle(mutedText)
            Text(value)
                .font(.custom(FontFamily.Nunito.regular, size: 18))
                .foregroundStyle(dimText)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(cream.opacity(0.02))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(cream.opacity(0.05), lineWidth: 1)
                )
        }
    }

    private var saveButton: some View {
        Button(action: { Task { await save() } }) {
            HStack(spacing: 6) {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(NormaPalette.ink.opacity(0.92))
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(isSaving ? "saving…" : "save")
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
        .disabled(isSaving || !hasValidInput)
    }

    private var hasValidInput: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Actions

    private func hydrate() {
        // Pre-fill from any existing partial name. Apple's split may give us
        // "First Last" combined in `.name`, so try a naive split.
        let existing = sessionViewModel.currentUser?.name
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !existing.isEmpty else { return }
        let parts = existing.split(separator: " ", maxSplits: 1).map(String.init)
        firstName = parts.first ?? existing
        lastName = parts.count > 1 ? parts[1] : ""
    }

    private func save() async {
        guard var profile = sessionViewModel.currentUser else { return }
        isSaving = true
        defer { isSaving = false }

        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = last.isEmpty ? first : "\(first) \(last)"

        profile.name = combined

        // `updateUserProfile` encrypts + writes to Supabase via the edge
        // function, and updates `sessionViewModel.currentUser` on success.
        // Any failure surfaces a toast already wired in the view model.
        await sessionViewModel.updateUserProfile(profile)
        dismiss()
    }
}
