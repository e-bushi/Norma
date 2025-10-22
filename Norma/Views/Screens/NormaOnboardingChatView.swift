//
//  NormaOnboardingChatView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct NormaOnboardingChatView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Error message
                if onboardingViewModel.showError {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
                            )
                        
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                            
                            Text(onboardingViewModel.errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }
                
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(onboardingViewModel.messages) { message in
                                ChatBubbleView(message: message)
                                    .id(message.id)
                            }
                            
                            if onboardingViewModel.isTyping {
                                ThinkingIndicator()
                                    .id("typing")
                            }
                            
                            // Spacer to ensure last message appears above input
                            Color.clear
                                .frame(height: 24)
                                .id("bottom-spacer")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onChange(of: onboardingViewModel.messages.count) { _, _ in
                        // Delay slightly to ensure the view has updated
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo("bottom-spacer", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: onboardingViewModel.isTyping) { _, _ in
                        if onboardingViewModel.isTyping {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo("bottom-spacer", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                // Input field
                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Type your message...", text: $onboardingViewModel.userInput)
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.gray.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .disabled(onboardingViewModel.isTyping)
                        .focused($isInputFocused)
                        .onSubmit {
                            sendMessage()
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                
                                Button("Done") {
                                    isInputFocused = false
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            }
                        }
                    
                    Button(action: {
                        sendMessage()
                    }) {
                        ZStack {
                            Circle()
                                .fill(onboardingViewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || onboardingViewModel.isTyping ? Color.gray.opacity(0.2) : Color.primary)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(onboardingViewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || onboardingViewModel.isTyping ? .secondary : Color(UIColor.systemBackground))
                        }
                    }
                    .disabled(onboardingViewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || onboardingViewModel.isTyping)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("🤗")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                startConversation()
            }
        }
    }
    
    private func startConversation() {
        Task {
            await onboardingViewModel.startConversation()
        }
    }
    
    private func sendMessage() {
        let messageText = onboardingViewModel.userInput
        Task {
            await onboardingViewModel.sendMessage(messageText)
            
            // Keep keyboard focused after sending message
            await MainActor.run {
                isInputFocused = true
            }
        }
    }
    
}

#Preview {
    NormaOnboardingChatView()
        .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
        .preferredColorScheme(.light)
}
