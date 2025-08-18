//
//  NormaOnboardingStoryView.swift
//  Norma
//
//  Created by Claude on 8/4/25.
//

import SwiftUI

struct NormaOnboardingStoryView: View {
    @State private var currentPage = 0
    @State private var progress: [CGFloat] = [1, 0, 0, 0]  // First story starts as viewed
    @State private var isPaused = false
    
    let stories = [
        StoryContent(
            imageName: "chart.line.uptrend.xyaxis",
            title: "Track Your Finances",
            description: "Keep all your bills, expenses, and income organized in one place with smart tracking and insights.",
            miniViewType: .expense
        ),
        StoryContent(
            imageName: "bell.badge",
            title: "Never Miss a Payment",
            description: "Get timely reminders for upcoming bills and stay on top of your financial obligations effortlessly.",
            miniViewType: .calendar
        ),
        StoryContent(
            imageName: "chart.pie",
            title: "Smart Budgeting",
            description: "Set budgets, track spending patterns, and achieve your financial goals with detailed analytics.",
            miniViewType: .budget
        ),
        StoryContent(
            imageName: "sparkles",
            title: "AI Assistant",
            description: "Get personalized financial advice and insights powered by artificial intelligence.",
            miniViewType: .chat
        )
    ]
    
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress bars at the top
                    HStack(spacing: 4) {
                        ForEach(0..<stories.count, id: \.self) { index in
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    // Background bar
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 3)
                                    
                                    // Progress bar
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.purple)
                                        .frame(width: geo.size.width * progress[index], height: 3)
                                        .animation(.linear(duration: 0.1), value: progress[index])
                                }
                            }
                            .frame(height: 3)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    
                    // Story content
                    TabView(selection: $currentPage) {
                        ForEach(0..<stories.count, id: \.self) { index in
                            StoryPageView(story: stories[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .onChange(of: currentPage) { newValue in
                        resetProgress(for: newValue)
                    }
                    
                    // Bottom controls
                    HStack(spacing: 20) {
                        // Skip button
                        Button(action: {
                            onSkip()
                        }) {
                            Text("Skip")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                        }
                        
                        // Continue button
                        Button(action: {
                            if currentPage < stories.count - 1 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                onComplete()
                            }
                        }) {
                            HStack {
                                Text(currentPage < stories.count - 1 ? "Continue" : "Get Started")
                                    .font(.system(size: 16, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.purple)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
                
                // Tap areas for navigation
                HStack(spacing: 0) {
                    // Left tap area - go back
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if currentPage > 0 {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }
                        }
                    
                    // Right tap area - go forward
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if currentPage < stories.count - 1 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                onComplete()
                            }
                        }
                }
                .padding(.top, 100)
                .padding(.bottom, 150)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 50 {
                        // Swipe right - go back
                        if currentPage > 0 {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                    } else if value.translation.width < -50 {
                        // Swipe left - go forward
                        if currentPage < stories.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            onComplete()
                        }
                    }
                }
        )
        .onTapGesture(count: 1) { location in
            handleLongPress(at: location)
        }
    }
    
    
    private func resetProgress(for page: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            // Fill all previous pages
            for i in 0..<page {
                progress[i] = 1
            }
            
            // Fill current page
            progress[page] = 1
            
            // Reset future pages
            for i in (page + 1)..<stories.count {
                progress[i] = 0
            }
        }
    }
    
    private func handleLongPress(at location: CGPoint) {
        // This would be for pause functionality if needed
    }
}

struct StoryPageView: View {
    let story: StoryContent
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity = 0.0
    @State private var descriptionOffset: CGFloat = 30
    @State private var descriptionOpacity = 0.0
    @State private var miniViewScale = 0.8
    @State private var miniViewOpacity = 0.0
    @State private var miniViewOffset: CGFloat = 50
    
    var body: some View {
        VStack(spacing: 12) {
            // Title with stagger animation
            Text(story.title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .offset(y: titleOffset)
                .opacity(titleOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                        titleOffset = 0
                        titleOpacity = 1.0
                    }
                }
                .padding(.top, 20)
            
            // Description with stagger animation
            Text(story.description)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 24)
                .fixedSize(horizontal: false, vertical: true)
                .offset(y: descriptionOffset)
                .opacity(descriptionOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                        descriptionOffset = 0
                        descriptionOpacity = 1.0
                    }
                }
            
            // Mini view with stagger animation
            Group {
                switch story.miniViewType {
                case .expense:
                    MiniExpenseDisclosureView()
                        .scaleEffect(0.75)
                case .calendar:
                    MiniExpenseCalendarView()
                        .scaleEffect(0.75)
                case .budget:
                    MiniBudgetDisclosureView()
                        .scaleEffect(0.75)
                case .chat:
                    MiniChatView()
                        .scaleEffect(0.75)
                }
            }
            .padding(.horizontal, 20)
            .scaleEffect(miniViewScale)
            .opacity(miniViewOpacity)
            .offset(y: miniViewOffset)
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.5)) {
                    miniViewScale = 1.0
                    miniViewOpacity = 1.0
                    miniViewOffset = 0
                }
            }
            
            Spacer(minLength: 10)
        }
        .onDisappear {
            // Reset animations when disappearing
            titleOffset = 30
            titleOpacity = 0
            descriptionOffset = 30
            descriptionOpacity = 0
            miniViewScale = 0.8
            miniViewOpacity = 0
            miniViewOffset = 50
        }
    }
}

enum MiniViewType {
    case expense
    case calendar
    case budget
    case chat
}

struct StoryContent {
    let imageName: String
    let title: String
    let description: String
    let miniViewType: MiniViewType
}

#Preview {
    NormaOnboardingStoryView(
        onComplete: { print("Completed") },
        onSkip: { print("Skipped") }
    )
    .preferredColorScheme(.light)
}
