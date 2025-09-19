//
//  ExpenseCalendarVoiceMode.swift
//  Norma
//
//  Created by Claude on 8/15/25.
//

import SwiftUI

struct ExpenseCalendarVoiceMode: ViewModifier {
    @Binding var showVoiceMode: Bool
    @Binding var voiceAgentViewModel: VoiceAgentViewModel?
    @Binding var lastTapTime: Date
    @Binding var isPressed: Bool
    
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var billViewModel: BillViewModel
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var incomeViewModel: IncomeViewModel
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .onTapGesture {
                    // Record tap time for double-tap detection
                    lastTapTime = Date()
                    print("ExpenseCalendar: Single tap detected at \(lastTapTime)")
                }
                .onLongPressGesture(minimumDuration: 0.5, maximumDistance: .infinity) {
                    // Long press completed
                    print("ExpenseCalendar: Long press completed")
                } onPressingChanged: { pressing in
                    print("ExpenseCalendar: Press changed - pressing: \(pressing)")
                    // Visual feedback during press
                    if pressing {
                        let timeSinceLastTap = Date().timeIntervalSince(lastTapTime)
                        print("ExpenseCalendar: Press started. Time since last tap: \(timeSinceLastTap) seconds")
                        if timeSinceLastTap < 0.5 {
                            print("ExpenseCalendar: Double-tap and hold detected!")
                            
                            // Check if user has active subscription or is in trial
                            if subscriptionManager.isInFreeTrial {
                                print("ExpenseCalendar: User is in free trial - activating voice mode...")
                                // This is a double-tap and hold!
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showVoiceMode = true
                                }
                                
                                // Visual press effect
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isPressed = true
                                }
                                
                                // Strong haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                impactFeedback.impactOccurred()
                                
                                // Start voice recording or resume paused conversation
                                Task {
                                    await startVoiceInteraction()
                                }
                            } else {
                                print("ExpenseCalendar: User not in trial - showing paywall")
                                // User doesn't have access - show paywall
                                showPaywall = true
                                
                                // Light haptic feedback for denied access
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        }
                    } else {
                        print("ExpenseCalendar: Press ended")
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isPressed = false
                        }
                    }
                }
            
            // Voice mode overlay
            if let voiceAgent = voiceAgentViewModel {
                VoiceModeOverlay(
                    isVisible: $showVoiceMode,
                    cornerRadius: cornerRadius,
                    voiceAgentViewModel: voiceAgent
                )
            }
        }
        .onAppear {
            initializeVoiceAgent()
        }
        .onChange(of: voiceAgentViewModel?.currentState) { _, newState in
            handleStateChange(newState)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
    
    private func startVoiceInteraction() async {
        let userName = sessionViewModel.currentUser?.name
        
        if let voiceAgent = voiceAgentViewModel {
            // Check if there's a paused conversation to resume
            if voiceAgent.conversationPaused {
                print("Resuming paused voice conversation...")
                await voiceAgent.resumeConversation()
            } else {
                print("Starting new voice interaction for expenses...")
                // Request permissions if needed
                if !voiceAgent.hasPermissions {
                    print("Requesting permissions...")
                    let granted = await voiceAgent.requestPermissions()
                    if !granted {
                        print("Permissions not granted")
                        return
                    }
                }
                await voiceAgent.startExpenseVoiceInteraction(userName: userName)
            }
        } else {
            print("VoiceAgentViewModel is nil - initializing now")
            if let userId = sessionViewModel.currentUser?.userId {
                voiceAgentViewModel = VoiceAgentViewModel(
                    userId: userId,
                    billViewModel: billViewModel,
                    expenseViewModel: expenseViewModel,
                    incomeViewModel: incomeViewModel,
                    sessionViewModel: sessionViewModel
                )
                // Request permissions if needed
                if let voiceAgent = voiceAgentViewModel {
                    if !voiceAgent.hasPermissions {
                        print("Requesting permissions...")
                        let granted = await voiceAgent.requestPermissions()
                        if !granted {
                            print("Permissions not granted")
                            return
                        }
                    }
                    await voiceAgent.startExpenseVoiceInteraction(userName: userName)
                }
            } else {
                print("No user ID available")
            }
        }
    }
    
    private func initializeVoiceAgent() {
        // Initialize voice agent with user ID, BillViewModel, and ExpenseViewModel
        if voiceAgentViewModel == nil, let userId = sessionViewModel.currentUser?.userId {
            voiceAgentViewModel = VoiceAgentViewModel(
                userId: userId,
                billViewModel: billViewModel,
                expenseViewModel: expenseViewModel,
                incomeViewModel: incomeViewModel,
                sessionViewModel: sessionViewModel
            )
        }
    }
    
    private func handleStateChange(_ newState: VoiceAgentViewModel.VoiceAgentState?) {
        guard let newState = newState else { return }
        
        // Hide voice mode overlay when session completes or errors, but keep it visible when paused
        switch newState {
        case .idle, .error:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showVoiceMode = false
            }
        case .paused, .waitingForResume:
            // Keep overlay visible for paused states
            break
        default:
            break
        }
    }
}

extension View {
    func expenseCalendarVoiceMode(
        showVoiceMode: Binding<Bool>,
        voiceAgentViewModel: Binding<VoiceAgentViewModel?>,
        lastTapTime: Binding<Date>,
        isPressed: Binding<Bool>,
        cornerRadius: CGFloat = 20
    ) -> some View {
        self.modifier(
            ExpenseCalendarVoiceMode(
                showVoiceMode: showVoiceMode,
                voiceAgentViewModel: voiceAgentViewModel,
                lastTapTime: lastTapTime,
                isPressed: isPressed,
                cornerRadius: cornerRadius
            )
        )
    }
}