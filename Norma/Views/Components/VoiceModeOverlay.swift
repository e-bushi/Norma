//
//  VoiceModeOverlay.swift
//  Norma
//
//  Created by Claude on 8/6/25.
//

import SwiftUI

struct VoiceModeOverlay: View {
    @Binding var isVisible: Bool
    let cornerRadius: CGFloat
    @ObservedObject var voiceAgentViewModel: VoiceAgentViewModel
    
    private var currentStateText: String {
        switch voiceAgentViewModel.currentState {
        case .idle:
            return "Tap to start"
        case .recording:
            return "Listening..."
        case .transcribing:
            return "Processing speech..."
        case .processing:
            return "Analyzing..."
        case .generatingSpeech:
            return "Preparing response..."
        case .playingResponse:
            return "Playing response..."
        case .paused:
            return "Conversation paused"
        case .waitingForResume:
            return "Double-tap to resume"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    private var currentStateIcon: String {
        switch voiceAgentViewModel.currentState {
        case .idle:
            return "mic"
        case .recording:
            return "mic.fill"
        case .transcribing, .processing:
            return "waveform.circle"
        case .generatingSpeech:
            return "brain.head.profile"
        case .playingResponse:
            return "speaker.wave.2.fill"
        case .paused:
            return "pause.circle"
        case .waitingForResume:
            return "play.circle"
        case .error:
            return "exclamationmark.triangle"
        }
    }
    
    private var isErrorState: Bool {
        if case .error = voiceAgentViewModel.currentState {
            return true
        }
        return false
    }
    
    var body: some View {
        if isVisible {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.black.opacity(0.001))
                .background(
                    BlurView(style: .systemChromeMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
                .onTapGesture {
                    // Stop voice session if active
                    Task {
                        voiceAgentViewModel.stopRecording()
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isVisible = false
                    }
                }
                .overlay(
                    VStack(spacing: 20) {
                        // Dynamic icon based on state
                        Image(systemName: currentStateIcon)
                            .font(.system(size: 50))
                            .foregroundColor(isErrorState ? .red : .blue)
                            .scaleEffect(voiceAgentViewModel.isRecording ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: voiceAgentViewModel.isRecording)
                        
                        VStack(spacing: 8) {
                            Text(currentStateText)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            if voiceAgentViewModel.isRecording {
                                // Recording level indicator
                                RecordingLevelIndicator(level: voiceAgentViewModel.recordingLevel)
                            }
                            
                            // Show action buttons
                            HStack(spacing: 12) {
                                // Resume button when conversation is paused
                                if voiceAgentViewModel.conversationPaused || voiceAgentViewModel.currentState == .waitingForResume {
                                    Button(action: {
                                        Task {
                                            await voiceAgentViewModel.resumeConversation()
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "play.circle.fill")
                                                .font(.title2)
                                            Text("Resume")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 25)
                                                .fill(Color.blue)
                                        )
                                    }
                                }
                                
                                // End conversation button (always visible)
                                Button(action: {
                                    Task {
                                        await voiceAgentViewModel.endConversation()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            isVisible = false
                                        }
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "stop.circle.fill")
                                            .font(.title2)
                                        Text("End")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color.red.opacity(0.9))
                                    )
                                }
                            }
                            .padding(.top, 8)
                            
                            Text("Double tap to exit")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .scaleEffect(isVisible ? 1.0 : 0.5)
                    .opacity(isVisible ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: isVisible)
                )
        }
    }
}

struct RecordingLevelIndicator: View {
    let level: Float
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                let threshold = Float(index) * 0.2
                let isActive = level > threshold
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 4, height: CGFloat(8 + index * 4))
                    .opacity(isActive ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 0.1), value: level)
            }
        }
    }
}

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
