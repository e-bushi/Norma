//
//  TranscriptionView.swift
//  Norma
//
//  Created by Claude on 12/8/25.
//

import SwiftUI
import Speech

struct TranscriptionView: View {
    @Binding var transcribedText: String
    @Binding var isRecording: Bool
    let onInsert: (String) -> Void

    @State private var appeared = false
    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: 12) {
            // Recording indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                    .opacity(pulseAnimation ? 1 : 0.6)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)

                Text("Listening...")
                    .font(.custom(FontFamily.Rubik.medium, size: 14))
                    .foregroundColor(.secondary)

                Spacer()

                // Cancel button
                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    isRecording = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }

            // Transcribed text area - tappable to insert
            Button {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                if !transcribedText.isEmpty {
                    onInsert(transcribedText)
                }
            } label: {
                HStack {
                    if transcribedText.isEmpty {
                        Text("Speak now...")
                            .font(.custom(FontFamily.Rubik.regular, size: 16))
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        Text(transcribedText)
                            .font(.custom(FontFamily.Rubik.regular, size: 16))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()

                    if !transcribedText.isEmpty {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color("NormaPastelTeal"))
                    }
                }
                .frame(minHeight: 44)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(transcribedText.isEmpty)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.clear)
                .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                appeared = true
            }
            pulseAnimation = true
        }
    }
}

#Preview {
    ZStack {
        Color("NormaBackground")
            .ignoresSafeArea()

        VStack {
            Spacer()
            TranscriptionView(
                transcribedText: .constant("Hello, I want to check my bills"),
                isRecording: .constant(true),
                onInsert: { text in print("Insert: \(text)") }
            )
        }
    }
}
