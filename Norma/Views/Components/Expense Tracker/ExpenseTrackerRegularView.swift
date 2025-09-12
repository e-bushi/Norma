//
//  ExpenseTrackerRegularView.swift
//  Norma
//
//  Created by Claude on 7/6/25.
//

import SwiftUI

struct ExpenseTrackerRegularView: View {
    let billAmount: Double
    let currentExpenseAmount: Double
    let incomeAmount: Double
    let month: String
    let isScrolling: Bool
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var billViewModel: BillViewModel
    @EnvironmentObject var incomeViewModel: IncomeViewModel
    @State private var showingIncomeDetail = false
    
    // Animation states
    let chartAppeared: Bool
    let dotsAppeared: Bool
    let insightsAppeared: Bool
    
    @State private var showDescription = false
    @State private var headerAppeared = false
    @State private var explanationButtonAppeared = false
    @State private var incomeLabelAppeared = false
    @State private var billsLabelAppeared = false
    @State private var currentLabelAppeared = false
    
    @State private var showVoiceMode = false
    @State private var voiceAgentViewModel: VoiceAgentViewModel?
    @State private var lastTapTime: Date = Date()
    @State private var isPressed = false
    
    // Chart constants
    private let lineHeight: CGFloat = 400
    private let dotSize: CGFloat = 16
    private let chartWidth: CGFloat = 320
    
    private var expensePosition: CGFloat {
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
            VStack(spacing: 24) {
            // Enhanced header with status
            ExpenseInsightsHeader(
                month: month,
                incomeAmount: incomeAmount,
                currentExpenseAmount: currentExpenseAmount,
                billAmount: billAmount,
                headerAppeared: headerAppeared,
                insightsAppeared: insightsAppeared
            )
            
            // Voice mode instruction
            VoiceModeInstruction(
                explanationButtonAppeared: explanationButtonAppeared
            )

            // Main chart
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
                        slideDirection: .left,
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
                        chartHeight: lineHeight,
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
                print("ExpenseTracker: Press changed - pressing: \(pressing)")
                // Visual feedback during press
                if pressing {
                    let timeSinceLastTap = Date().timeIntervalSince(lastTapTime)
                    print("ExpenseTracker: Press started. Time since last tap: \(timeSinceLastTap) seconds")
                    if timeSinceLastTap < 0.5 {
                        print("ExpenseTracker: Double-tap and hold detected! Activating voice mode...")
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
                    }
                } else {
                    print("ExpenseTracker: Press ended")
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
            }
            
            // Chart explanation section
            ChartExplanation(
                showDescription: $showDescription,
                incomeAmount: incomeAmount,
                billAmount: billAmount,
                currentExpenseAmount: currentExpenseAmount,
                explanationButtonAppeared: explanationButtonAppeared
            )
            }
            .onAppear {
                animateElements()
                // Initialize voice agent with user ID and BillViewModel
                if voiceAgentViewModel == nil, let userId = sessionViewModel.currentUser?.userId {
                    voiceAgentViewModel = VoiceAgentViewModel(
                        userId: userId, 
                        billViewModel: billViewModel,
                        incomeViewModel: incomeViewModel,
                        sessionViewModel: sessionViewModel
                    )
                }
                
                // IMPORTANT: Check if dotsAppeared is already true on appear
                // This handles the race condition where dotsAppeared is true before the view appears
                if dotsAppeared && !incomeLabelAppeared {
                    print("📊 ExpenseTrackerRegularView: dotsAppeared is already true on appear, triggering labels immediately")
                    // Small delay to ensure view is properly laid out
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        triggerLabelAnimations()
                    }
                }
            }
            .onChange(of: voiceAgentViewModel?.currentState) { _, newState in
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
            .sheet(isPresented: $showingIncomeDetail) {
                IncomeDetailView()
                    .environmentObject(profileViewModel)
            }
            .onChange(of: dotsAppeared) { _, newValue in
                print("📊 ExpenseTrackerRegularView: dotsAppeared changed to \(newValue)")
                if newValue {
                    triggerLabelAnimations()
                } else {
                    // Reset when dotsAppeared becomes false
                    print("   🔄 Resetting label states")
                    incomeLabelAppeared = false
                    billsLabelAppeared = false
                    currentLabelAppeared = false
                }
            }
        }
    }
    
    private func animateElements() {
        withAnimation(.easeOut(duration: 0.4)) {
            headerAppeared = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                explanationButtonAppeared = true
            }
        }
    }
    
    private func triggerLabelAnimations() {
        print("   🎯 Triggering label animations!")
        
        // Stagger the chart label animations with reliable timing
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            incomeLabelAppeared = true
            print("   💰 incomeLabelAppeared = true")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                billsLabelAppeared = true
                print("   📄 billsLabelAppeared = true")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                currentLabelAppeared = true
                print("   💳 currentLabelAppeared = true")
            }
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let profileViewModel = ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    
    ExpenseTrackerRegularView(
        billAmount: 1500,
        currentExpenseAmount: 2800,
        incomeAmount: 3000,
        month: "December",
        isScrolling: false, chartAppeared: true,
        dotsAppeared: true,
        insightsAppeared: true
    )
    .environmentObject(profileViewModel)
    .environmentObject(sessionViewModel)
    .preferredColorScheme(.light)
}
