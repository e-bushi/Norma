//
//  ChatMenuView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct ChatMenuView: View {
    @Binding var isMenuOpen: Bool

    // Sample chat data - limit to 12
    private let sampleChats = [
        "Chat One",
        "Chat Two",
        "Chat Three",
        "Chat Four",
        "Chat Five"
    ]

    private var displayedChats: [String] {
        Array(sampleChats.prefix(12))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Norma")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)

            // New Chat button
            VStack(alignment: .leading, spacing: 4) {
                compactMenuItem(icon: "plus.message", title: "New Chat", action: {})
            }
            .padding(.horizontal, 12)

            // Chats section with container
            VStack(alignment: .leading, spacing: 12) {
                // Chats container
                VStack(alignment: .leading, spacing: 12) {
                    Text("Chats")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .padding(.leading, 12)

                    VStack(spacing: 8) {
                        ForEach(displayedChats, id: \.self) { chat in
                            compactChatItem(title: chat)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.65, alignment: .leading)
            }
            .padding(.horizontal, 20)

            Spacer()

            // User profile at bottom
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Text("CM")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Text("Chris Mauldin")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color("NormaBackground"))
    }

    private func compactMenuItem(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            // Quick slide feeling
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()

            // Pulse feeling immediately after
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
                impactRigid.impactOccurred()
            }

            action()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isMenuOpen = false
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func compactChatItem(title: String) -> some View {
        Button {
            // Quick slide feeling
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()

            // Pulse feeling immediately after
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
                impactRigid.impactOccurred()
            }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isMenuOpen = false
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
