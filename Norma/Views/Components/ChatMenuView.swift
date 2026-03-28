//
//  ChatMenuView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI
import LinkKit

struct ChatMenuView: View {
    @Binding var isMenuOpen: Bool
    @Binding var mainLayerView: MainLayerViewType

    @EnvironmentObject private var conversationManager: ConversationManager
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var coinColorViewModel: CoinColorViewModel
    @EnvironmentObject private var dataManager: DataManager
    @SwiftUI.Environment(\.colorScheme) private var colorScheme

    // Delete confirmation state
    @State private var showDeleteConfirmation = false
    @State private var conversationToDelete: ChatConversation?
    @State private var showAllChats = false

    // Plaid state
    @StateObject private var plaidService = PlaidService.shared
    @State private var isLoadingLinkToken = false
    @State private var isExchangingToken = false
    @State private var plaidHandler: Handler?
    @State private var showPlaidError = false
    @State private var plaidErrorMessage = ""
    @State private var showDisconnectConfirmation = false
    @State private var isInstitutionExpanded = false

    // Display up to 4 conversations in menu
    private var displayedConversations: [ChatConversation] {
        Array(conversationManager.conversations.prefix(4))
    }

    // Check if there are more conversations than displayed
    private var hasMoreConversations: Bool {
        conversationManager.conversations.count > 4
    }

    private var additionalConversationsCount: Int {
        max(0, conversationManager.conversations.count - 4)
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
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // New Chat / Financial Overview
                    VStack(alignment: .leading, spacing: 4) {
                        compactMenuItem(icon: "plus.message", title: "New Chat", action: {
                            _ = conversationManager.createNewConversation()
                            mainLayerView = .chat
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isMenuOpen = false
                            }
                        })

                        if plaidService.isConnected {
                            compactMenuItem(icon: "building.columns", title: "Connect another bank", action: {
                                connectBank()
                            })
                        }
                    }
                    .padding(.horizontal, 12)

                    // Chats section
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Chats")
                                .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .padding(.leading, 12)

                            Group {
                                if displayedConversations.isEmpty {
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

                                        if hasMoreConversations {
                                            Button {
                                                let impactLight = UIImpactFeedbackGenerator(style: .light)
                                                impactLight.impactOccurred()
                                                Task {
                                                    await conversationManager.loadAllConversations()
                                                }
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

                    // Banking section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Banking")
                            .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.leading, 12)

                        if !plaidService.connectedAccounts.isEmpty {
                            VStack(spacing: 0) {
                                // Institution header — tappable to expand
                                Button {
                                    let impactLight = UIImpactFeedbackGenerator(style: .light)
                                    impactLight.impactOccurred()
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        isInstitutionExpanded.toggle()
                                    }
                                } label: {
                                    institutionHeader
                                }
                                .buttonStyle(PlainButtonStyle())

                                // Expandable sub-accounts
                                if isInstitutionExpanded {
                                    Divider()
                                        .padding(.horizontal, 12)

                                    VStack(spacing: 4) {
                                        ForEach(plaidService.connectedAccounts) { account in
                                            accountItem(account: account)
                                                .transition(.opacity.combined(with: .move(edge: .top)))
                                        }

                                        // Disconnect button
                                        Button {
                                            showDisconnectConfirmation = true
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "link.badge.plus")
                                                    .rotationEffect(.degrees(45))
                                                    .font(.system(size: 12))
                                                Text("Disconnect")
                                                    .font(.custom(FontFamily.Rubik.regular, size: 12))
                                            }
                                            .foregroundColor(Color("NormaPastelCoral").opacity(0.7))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .transition(.opacity)
                                    }
                                    .padding(.top, 4)
                                    .padding(.bottom, 4)
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
                        } else if isExchangingToken {
                            HStack(spacing: 12) {
                                ProgressView()
                                    .tint(.primary)
                                    .frame(width: 20)

                                Text("Connecting account...")
                                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.secondary.opacity(0.03))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        } else {
                            Button {
                                let impactLight = UIImpactFeedbackGenerator(style: .light)
                                impactLight.impactOccurred()
                                connectBank()
                            } label: {
                                HStack(spacing: 12) {
                                    if isLoadingLinkToken {
                                        ProgressView()
                                            .tint(.primary)
                                            .frame(width: 20)
                                    } else {
                                        Image(systemName: "building.columns")
                                            .font(.system(size: 16))
                                            .foregroundColor(.primary)
                                            .frame(width: 20)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Connect your bank")
                                            .font(.custom(FontFamily.Rubik.medium, size: 15))
                                            .foregroundColor(.primary)

                                        Text("U.S. Only")
                                            .font(.custom(FontFamily.Rubik.regular, size: 11))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.secondary.opacity(0.03))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isLoadingLinkToken)
                        }
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.65, alignment: .leading)
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Norma")
                        .font(.normaTitle(28))
                        .foregroundColor(.primary)
                        .fixedSize()
                }
                .sharedBackgroundVisibility(.hidden)
            }
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .scrollContentBackground(.hidden)
            .background {
                CoinGradientBackground(coinColor: .gray, colorScheme: colorScheme)
                    .ignoresSafeArea()
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 8) {
                    Button {
                        let impactLight = UIImpactFeedbackGenerator(style: .light)
                        impactLight.impactOccurred()
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
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
        .alert("Connection Error", isPresented: $showPlaidError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(plaidErrorMessage)
        }
        .alert("Disconnect Bank", isPresented: $showDisconnectConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect", role: .destructive) {
                disconnectBank()
            }
        } message: {
            Text("Disconnect \(plaidService.institutionName ?? "your bank")? Your existing expenses will be kept.")
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

    private func connectBank() {
        guard let userId = sessionViewModel.currentUser?.userId else {
            plaidErrorMessage = "Please sign in to connect your bank."
            showPlaidError = true
            return
        }

        isLoadingLinkToken = true

        Task {
            do {
                let linkToken = try await PlaidService.shared.createLinkToken(userId: userId)
                await MainActor.run {
                    isLoadingLinkToken = false
                    openPlaidLink(with: linkToken)
                }
            } catch {
                await MainActor.run {
                    isLoadingLinkToken = false
                    plaidErrorMessage = error.localizedDescription
                    showPlaidError = true
                }
            }
        }
    }

    private func openPlaidLink(with linkToken: String) {
        var config = LinkTokenConfiguration(token: linkToken) { success in
            let institutionName = success.metadata.institution.name
            self.handleLinkSuccess(publicToken: success.publicToken, institutionName: institutionName)
        }

        config.onExit = { exit in
            if let error = exit.error {
                self.plaidErrorMessage = "Link exited: \(error.localizedDescription)"
                self.showPlaidError = true
            }
            self.plaidHandler = nil
        }

        let result = Plaid.create(config)
        switch result {
        case .success(let handler):
            self.plaidHandler = handler
            handler.open(presentUsing: .viewController(UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
                .first!))
        case .failure(let error):
            plaidErrorMessage = "Failed to open Plaid Link: \(error.localizedDescription)"
            showPlaidError = true
        }
    }

    private func handleLinkSuccess(publicToken: String, institutionName: String? = nil) {
        guard let userId = sessionViewModel.currentUser?.userId else { return }

        isExchangingToken = true
        plaidHandler = nil

        Task {
            do {
                // Exchange the public token
                let itemId = try await plaidService.exchangeToken(userId: userId, publicToken: publicToken, institutionName: institutionName)

                // Fetch account balances
                let accounts = try await plaidService.fetchBalances(userId: userId)

                await MainActor.run {
                    plaidService.connectedAccounts = accounts
                    plaidService.isConnected = true
                    plaidService.institutionName = institutionName
                    plaidService.itemId = itemId
                    isExchangingToken = false
                }
            } catch {
                await MainActor.run {
                    isExchangingToken = false
                    plaidErrorMessage = error.localizedDescription
                    showPlaidError = true
                }
            }
        }
    }

    private func disconnectBank() {
        guard let userId = sessionViewModel.currentUser?.userId,
              let itemId = plaidService.itemId else { return }

        Task {
            do {
                try await plaidService.disconnect(userId: userId, itemId: itemId)
            } catch {
                await MainActor.run {
                    plaidErrorMessage = error.localizedDescription
                    showPlaidError = true
                }
            }
        }
    }

    private func formatBalance(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }

    private var totalFunds: Double {
        plaidService.connectedAccounts.compactMap { $0.balances.current }.reduce(0, +)
    }

    private var institutionHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "building.columns.fill")
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(plaidService.institutionName ?? "Bank")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(formatBalance(totalFunds, currency: plaidService.connectedAccounts.first?.balances.isoCurrencyCode ?? "USD"))
                    .font(.custom(FontFamily.Rubik.regular, size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary.opacity(0.6))
                .rotationEffect(.degrees(isInstitutionExpanded ? 90 : 0))
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 4)
    }

    private func accountItem(account: PlaidService.PlaidAccount) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "building.columns")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(account.name)
                        .font(.custom(FontFamily.Rubik.regular, size: 14))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if let mask = account.mask {
                        Text("••\(mask)")
                            .font(.custom(FontFamily.Rubik.regular, size: 11))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }

                if let current = account.balances.current {
                    Text(formatBalance(current, currency: account.balances.isoCurrencyCode ?? "USD"))
                        .font(.custom(FontFamily.Rubik.regular, size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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
            .padding(.vertical, 8)
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
            HStack(alignment: .center, spacing: 12) {
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
