//
//  ChatInputView.swift
//  Norma
//
//  Created by Claude on 5/10/25.
//

import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    let onVoiceInput: () -> Void
    var glowColor: Color? = nil

    @State private var isKeyboardVisible: Bool = false

    private var isSendButtonActive: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    var body: some View {
        VStack(spacing: 0) {
            // Floating input container
            HStack(alignment: .center, spacing: 12) {
                // Text field
                TextField("Chat with Norma", text: $text, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.normaInput())
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .onSubmit {
                        if !text.isEmpty {
                            onSend()
                        }
                    }
                    .padding(.vertical, 8)

                // Dual-purpose voice/send button
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        if isSendButtonActive {
                            onSend()
                        } else {
                            onVoiceInput()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isSendButtonActive ? Color.black : Color.gray.opacity(0.15))
                                .frame(width: 44, height: 44)

                            // Waveform icon when empty
                            Image(systemName: "waveform")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                                .opacity(isSendButtonActive ? 0 : 1)
                                .scaleEffect(isSendButtonActive ? 0.5 : 1)

                            // Send arrow when has text
                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .opacity(isSendButtonActive ? 1 : 0)
                                .scaleEffect(isSendButtonActive ? 1 : 0.5)
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: isSendButtonActive)
                    }
                    .buttonStyle(SendButtonStyle())
                    .disabled(isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.clear)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 28))
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(glowColor?.opacity(0.6) ?? Color.gray.opacity(0.22), lineWidth: glowColor != nil ? 1.5 : 1)
                    .shadow(color: glowColor?.opacity(0.5) ?? .clear, radius: 8)
                    .shadow(color: glowColor?.opacity(0.3) ?? .clear, radius: 16)
                    .animation(.easeInOut(duration: 0.4), value: glowColor)
            )
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, isKeyboardVisible ? 12 : 16)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isKeyboardVisible)
        }
        .padding(.top, 12)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isKeyboardVisible = false
            }
        }
    }
}

// Custom button style for capsule press animation
struct CapsulePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Custom button style for send button press animation
struct SendButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    @Previewable @State var text = ""

    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)

    return ChatInputView(
        text: $text,
        isLoading: false,
        onSend: { print("Send tapped") },
        onVoiceInput: { print("Voice input tapped") }
    )
    .environmentObject(ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
    .environmentObject(BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
    .environmentObject(ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
    .background(Color("NormaBackground"))
}
