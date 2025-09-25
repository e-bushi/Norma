//
//  MoneyRemainingChartView.swift
//  Norma
//
//  Created by Claude on 1/24/25.
//

import SwiftUI

struct MoneyRemainingChartView: View {
    let incomeAmount: Double
    let billAmount: Double
    let currentExpenseAmount: Double
    
    // Animation states
    let chartAppeared: Bool
    @Binding var incomeLabelAppeared: Bool
    @Binding var billsLabelAppeared: Bool
    @Binding var currentLabelAppeared: Bool
    @Binding var showDescription: Bool
    let explanationButtonAppeared: Bool
    
    // Voice mode
    @Binding var showVoiceMode: Bool
    @Binding var voiceAgentViewModel: VoiceAgentViewModel?
    @Binding var lastTapTime: Date
    @Binding var isPressed: Bool
    @Binding var showPaywall: Bool
    @Binding var showingIncomeDetail: Bool
    
    // Environment
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var billViewModel: BillViewModel
    @EnvironmentObject var incomeViewModel: IncomeViewModel
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // Chart constants
    private let lineHeight: CGFloat = 400
    private let dotSize: CGFloat = 16
    private let chartWidth: CGFloat = 320
    
    private var expensePosition: CGFloat {
        // Calculate position based on expense amount relative to income
        let incomePosition: CGFloat = 40
        let billsPosition: CGFloat = lineHeight - 40
        
        // If no income, place at bills position
        guard incomeAmount > 0 else { return billsPosition }
        
        // If current expense is at or below bills, place at bills position
        if currentExpenseAmount <= billAmount {
            return billsPosition
        }
        
        // If current expense exceeds income, place at income position
        if currentExpenseAmount >= incomeAmount {
            return incomePosition
        }
        
        // Calculate position between bills and income based on current expense
        let totalRange = incomeAmount - billAmount
        let currentRange = currentExpenseAmount - billAmount
        let progress = currentRange / totalRange
        
        // Interpolate between bills position and income position
        let position = billsPosition - (progress * (billsPosition - incomePosition))
        
        return position
    }
    
    var body: some View {
        ZStack {
            // Chart content layer
            ZStack {
                // Elegant background with grid
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(UIColor.systemBackground),
                                Color.gray.opacity(0.02)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.2),
                                        Color.gray.opacity(0.05)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .animatedBorder(
                        cornerRadius: 20,
                        lineWidth: 2,
                        useRainbow: true,
                        isVoiceModeActive: showVoiceMode
                    )
                    .scaleEffect(chartAppeared ? 1 : 0.9)
                    .opacity(chartAppeared ? 1 : 0)
                
                // Chart content
                ZStack(alignment: .center) {
                    let centerX: CGFloat = chartWidth / 2
                    
                    // Subtle grid lines
                    VStack(spacing: lineHeight / 4) {
                        ForEach(0..<4) { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.05))
                                .frame(height: 0.5)
                        }
                    }
                    .frame(width: chartWidth * 0.8)
                    .opacity(chartAppeared ? 1 : 0)
                    .scaleEffect(chartAppeared ? 1 : 0.8)
                    
                    // Vertical reference line
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.15),
                                    Color.gray.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: chartAppeared ? lineHeight : 0)
                        .position(x: centerX, y: lineHeight / 2)
                    
                    // Income indicator
                    ChartLabelView(
                        title: "INCOME",
                        value: profileViewModel.formatCurrencyTruncated(incomeAmount),
                        color: .green,
                        icon: "arrow.down.circle.fill",
                        xPosition: centerX,
                        yPosition: 40,
                        dotSize: dotSize,
                        appeared: incomeLabelAppeared,
                        slideDirection: .left,
                        onTap: {
                            showingIncomeDetail = true
                        }
                    )
                    
                    // Bills indicator
                    ChartLabelView(
                        title: "BILLS",
                        value: profileViewModel.formatCurrencyTruncated(billAmount),
                        color: .red,
                        icon: "calendar.badge.minus",
                        xPosition: centerX,
                        yPosition: lineHeight - 40,
                        dotSize: dotSize,
                        appeared: billsLabelAppeared,
                        slideDirection: .left
                    )
                    
                    // Current expense indicator (animated position)
                    ChartLabelView(
                        title: "CURRENT",
                        value: profileViewModel.formatCurrencyTruncated(currentExpenseAmount),
                        color: .purple,
                        icon: "creditcard.fill",
                        xPosition: centerX,
                        yPosition: expensePosition,
                        dotSize: dotSize,
                        appeared: currentLabelAppeared,
                        slideDirection: .right,
                        animateFromBottom: true,
                        chartHeight: lineHeight
                    )
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: currentExpenseAmount)
                }
                .frame(width: chartWidth, height: lineHeight)
                .padding(.vertical, 60)
                .padding(.horizontal, 20)
            }
            
            // Voice mode overlay
            if let voiceAgent = voiceAgentViewModel {
                VoiceModeOverlay(
                    isVisible: $showVoiceMode,
                    cornerRadius: 20,
                    voiceAgentViewModel: voiceAgent
                )
            }
        }
        .padding(.horizontal)
        .padding(.horizontal)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            // Record tap time for double-tap detection
            lastTapTime = Date()
            print("ExpenseTracker: Single tap detected at \(lastTapTime)")
        }
        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: .infinity) {
            // Long press completed
            print("ExpenseTracker: Long press completed")
        } onPressingChanged: { pressing in
            handlePressChange(pressing)
        }
    }
    
    private func handlePressChange(_ pressing: Bool) {
        print("ExpenseTracker: Press changed - pressing: \(pressing)")
        // Visual feedback during press
        if pressing {
            let timeSinceLastTap = Date().timeIntervalSince(lastTapTime)
            print("ExpenseTracker: Press started. Time since last tap: \(timeSinceLastTap) seconds")
            if timeSinceLastTap < 0.5 {
                print("ExpenseTracker: Double-tap and hold detected!")
                
                // Check if user has active subscription or is in trial
                if subscriptionManager.isInFreeTrial || subscriptionManager.hasActiveSubscription {
                    print("ExpenseTracker: User has access (trial or subscription) - activating voice mode...")
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
                        let userName = sessionViewModel.currentUser?.name
                        
                        if let voiceAgent = voiceAgentViewModel {
                            // Check if there's a paused conversation to resume
                            if voiceAgent.conversationPaused {
                                print("Resuming paused voice conversation...")
                                await voiceAgent.resumeConversation()
                            } else {
                                print("Starting new voice interaction...")
                                // Request permissions if needed
                                if !voiceAgent.hasPermissions {
                                    print("Requesting permissions...")
                                    let granted = await voiceAgent.requestPermissions()
                                    if !granted {
                                        print("Permissions not granted")
                                        return
                                    }
                                }
                                await voiceAgent.startVoiceInteraction(userName: userName)
                            }
                        } else {
                            print("VoiceAgentViewModel is nil - initializing now")
                            if let userId = sessionViewModel.currentUser?.userId {
                                voiceAgentViewModel = VoiceAgentViewModel(
                                    userId: userId,
                                    billViewModel: billViewModel,
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
                                    await voiceAgent.startVoiceInteraction(userName: userName)
                                }
                            } else {
                                print("No user ID available")
                            }
                        }
                    }
                } else {
                    print("ExpenseTracker: User has no access (no trial, no subscription) - showing paywall")
                    // User doesn't have access - show paywall
                    showPaywall = true
                    
                    // Light haptic feedback for denied access
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            }
        } else {
            print("ExpenseTracker: Press ended")
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
    }
}