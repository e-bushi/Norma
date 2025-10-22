//
//  ChatMenuView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct ChatMenuView: View {
    @Binding var isMenuOpen: Bool
    @Binding var mainLayerView: MainLayerViewType

    // Sample chat data - limit to 12
    private let sampleChats: [String] = []

    private var displayedChats: [String] {
        Array(sampleChats.prefix(12))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Norma")
                    .font(.normaTitle(28))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)

            // New Chat button
            VStack(alignment: .leading, spacing: 4) {
                compactMenuItem(icon: "plus.message", title: "New Chat", action: {
                    // Switch to chat view and slide it back into focus
                    mainLayerView = .chat

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isMenuOpen = false
                    }
                })
            }
            .padding(.horizontal, 12)

            // Chats section with container
            VStack(alignment: .leading, spacing: 12) {
                // Chats container
                VStack(alignment: .leading, spacing: 12) {
                    Text("Chats")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .padding(.leading, 12)

                    Group {
                        if displayedChats.isEmpty {
                            // Empty state
                            VStack(spacing: 8) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary.opacity(0.5))

                                Text("No chats yet")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)

                                Text("Start a new chat to begin")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.secondary.opacity(0.03))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        } else {
                            VStack(spacing: 8) {
                                ForEach(displayedChats, id: \.self) { chat in
                                    compactChatItem(title: chat)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.secondary.opacity(0.03))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.65, alignment: .leading)
            }
            .padding(.horizontal, 20)

            Spacer()

            // User profile at bottom
            HStack(spacing: 8) {
                Button {
                    let impactLight = UIImpactFeedbackGenerator(style: .light)
                    impactLight.impactOccurred()

                    // Switch to settings view and slide it back into focus
                    mainLayerView = .settings

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isMenuOpen = false
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 40, height: 40)

                            Text("CM")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                        }

                        Text("Chris Mauldin")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.clear)
                            .glassEffect(in: RoundedRectangle(cornerRadius: 28))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Back arrow button
                Button {
                    let impactLight = UIImpactFeedbackGenerator(style: .light)
                    impactLight.impactOccurred()

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isMenuOpen = false
                    }
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .rotationEffect(.degrees(180))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.clear)
                                .glassEffect(in: Circle())
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())

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
                    .font(.system(size: 15, weight: .medium, design: .rounded))
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
                    .font(.system(size: 14, weight: .regular, design: .rounded))
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
