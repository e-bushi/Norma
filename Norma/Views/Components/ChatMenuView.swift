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

    @EnvironmentObject private var conversationManager: ConversationManager
    @EnvironmentObject private var sessionViewModel: SessionViewModel

    // Delete confirmation state
    @State private var showDeleteConfirmation = false
    @State private var conversationToDelete: ChatConversation?
    @State private var showAllChats = false

    // Display up to 6 conversations in menu
    private var displayedConversations: [ChatConversation] {
        Array(conversationManager.conversations.prefix(6))
    }

    // Check if there are more conversations than displayed
    private var hasMoreConversations: Bool {
        conversationManager.conversations.count > 6
    }

    private var additionalConversationsCount: Int {
        max(0, conversationManager.conversations.count - 6)
    }

    // Get user initials from name
    private var userInitials: String {
        guard let name = sessionViewModel.currentUser?.name else { return "?" }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
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
                    // Create new conversation
                    _ = conversationManager.createNewConversation()

                    // Navigate to chat view
                    mainLayerView = .chat
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isMenuOpen = false
                    }
                })

                compactMenuItem(icon: "chart.pie", title: "Overview", action: {
                    // Navigate to financial overview
                    mainLayerView = .overview
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isMenuOpen = false
                    }
                })

                compactMenuItem(icon: "coloncurrencysign.arrow.trianglehead.counterclockwise.rotate.90", title: "Purchasing Power", action: {
                    // Navigate to currency converter
                    mainLayerView = .currencyConverter
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
                        if displayedConversations.isEmpty {
                            // Empty state
                            VStack(spacing: 8) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary.opacity(0.5))

                                Text("No chats yet")
                                    .font(.custom(FontFamily.Rubik.medium, size: 14))
                                    .foregroundColor(.secondary)

                                Text("Start a new chat to begin")
                                    .font(.custom(FontFamily.Rubik.regular, size: 12))
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
                                ForEach(displayedConversations) { conversation in
                                    conversationItem(conversation: conversation)
                                }

                                // "See All" button when there are more conversations
                                if hasMoreConversations {
                                    Button {
                                        let impactLight = UIImpactFeedbackGenerator(style: .light)
                                        impactLight.impactOccurred()
                                        showAllChats = true
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "ellipsis")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)

                                            Text("See All (\(additionalConversationsCount) more)")
                                                .font(.custom(FontFamily.Rubik.medium, size: 13))
                                                .foregroundColor(.secondary)

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.secondary.opacity(0.6))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                    }
                                    .buttonStyle(PlainButtonStyle())
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

                    // Navigate to settings view
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

                            Text(userInitials)
                                .font(.custom(FontFamily.Rubik.medium, size: 15))
                                .foregroundColor(.primary)
                        }

                        Text(sessionViewModel.currentUser?.name ?? "User")
                            .font(.custom(FontFamily.Rubik.medium, size: 16))
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

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color("NormaBackground"))
        .alert("Delete Conversation", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                conversationToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let conversation = conversationToDelete {
                    Task {
                        await conversationManager.deleteConversation(conversation)
                    }
                }
                conversationToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this conversation? This cannot be undone.")
        }
        .sheet(isPresented: $showAllChats) {
            AllChatsView(
                isMenuOpen: $isMenuOpen,
                mainLayerView: $mainLayerView,
                showAllChats: $showAllChats,
                conversationToDelete: $conversationToDelete,
                showDeleteConfirmation: $showDeleteConfirmation
            )
            .environmentObject(conversationManager)
        }
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
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .frame(width: 20)

                Text(title)
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
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

    private func conversationItem(conversation: ChatConversation) -> some View {
        Button {
            // Quick slide feeling
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()

            // Pulse feeling immediately after
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
                impactRigid.impactOccurred()
            }

            // Select this conversation
            conversationManager.selectConversation(conversation)

            // Navigate to chat view
            mainLayerView = .chat
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isMenuOpen = false
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(conversationManager.displayTitle(for: conversation))
                        .font(.custom(FontFamily.Rubik.regular, size: 14))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(conversationManager.relativeTimestamp(for: conversation))
                        .font(.custom(FontFamily.Rubik.regular, size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                // Highlight if this is the current conversation
                RoundedRectangle(cornerRadius: 8)
                    .fill(conversationManager.currentConversation?.id == conversation.id ?
                          Color.secondary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                conversationToDelete = conversation
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - All Chats View
struct AllChatsView: View {
    @Binding var isMenuOpen: Bool
    @Binding var mainLayerView: MainLayerViewType
    @Binding var showAllChats: Bool
    @Binding var conversationToDelete: ChatConversation?
    @Binding var showDeleteConfirmation: Bool

    @EnvironmentObject private var conversationManager: ConversationManager

    var body: some View {
        NavigationStack {
            List {
                ForEach(conversationManager.conversations) { conversation in
                    Button {
                        // Select this conversation
                        conversationManager.selectConversation(conversation)

                        // Dismiss sheet and navigate to chat
                        showAllChats = false
                        mainLayerView = .chat
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isMenuOpen = false
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(conversationManager.displayTitle(for: conversation))
                                    .font(.custom(FontFamily.Rubik.medium, size: 16))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                Text(conversationManager.relativeTimestamp(for: conversation))
                                    .font(.custom(FontFamily.Rubik.regular, size: 13))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if conversationManager.currentConversation?.id == conversation.id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            conversationToDelete = conversation
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("All Chats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        showAllChats = false
                    }
                    .font(.custom(FontFamily.Rubik.medium, size: 16))
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
