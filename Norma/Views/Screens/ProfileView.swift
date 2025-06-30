//
//  ProfileView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct ProfileView: View {
    let hasProfileData: Bool
    
    // Sample data - would come from analysis
    @State private var moneyPersonality = MoneyPersonality(
        userId: "sample-user-id",
        category: "The Anxious Saver",
        primaryTrait: "Security-Driven",
        subconscious: "Money equals safety, but never enough",
        patterns: [
            "Consistently underspending on self-care",
            "Avoiding investment opportunities",
            "Feeling guilty about necessary purchases"
        ],
        strengths: [
            "Excellent at building emergency funds",
            "Rarely makes impulsive purchases",
            "Strong financial discipline"
        ],
        growthAreas: [
            "Learning to invest for growth",
            "Balancing saving with enjoying life",
            "Releasing scarcity mindset"
        ],
        psychologicalBarriers: [
            "Fear of financial abundance",
            "Childhood money trauma patterns",
            "Self-worth tied to bank balance"
        ]
    )
    
    @State private var financialHealth = FinancialHealthInsight(
        userId: "sample-user-id",
        score: 72,
        trend: .improving,
        psychologicalBarriers: [
            "Fear of financial abundance",
            "Childhood money trauma patterns",
            "Self-worth tied to bank balance"
        ],
        assessmentData: FinancialHealthInsight.AssessmentData(
            totalQuestions: 15,
            questionsAnswered: 15,
            conversationLength: 12,
            dataQualityScore: 0.85,
            lastAssessmentDate: "2025-06-26"
        )
    )
    
    init(hasProfileData: Bool = true) {
        self.hasProfileData = hasProfileData
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if hasProfileData {
                    profileContent
                } else {
                    emptyStateContent
                }
            }
        }
        .background(Color(UIColor.systemBackground))
    }
    
    @ViewBuilder
    private var emptyStateContent: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("YOUR MONEY PSYCHOLOGY")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                
                Text("Discover Your Financial Mind")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.top, 24)
            
            // Main empty state card
            ZStack {
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
                
                VStack(spacing: 32) {
                    // Brain icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.purple.opacity(0.1),
                                        Color.purple.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundColor(.purple)
                    }
                    
                    // Main content
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text("Ready to understand your money mindset?")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            Text("Chat with Norma to uncover your psychological relationship with money")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Divider()
                            .frame(maxWidth: 280)
                        
                        // Process explanation
                        VStack(spacing: 16) {
                            Text("How it works")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 12) {
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 28, height: 28)
                                        
                                        Text("1")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Text("Norma asks personalized questions about your money habits")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Spacer()
                                }
                                
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.green.opacity(0.1))
                                            .frame(width: 28, height: 28)
                                        
                                        Text("2")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                    
                                    Text("AI analyzes your responses and spending patterns")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Spacer()
                                }
                                
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.orange.opacity(0.1))
                                            .frame(width: 28, height: 28)
                                        
                                        Text("3")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.orange)
                                    }
                                    
                                    Text("Receive insights into your subconscious money beliefs")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 32)
            }
            .padding(.horizontal, 24)
            
            // Important note card
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        
                        Text("Pro Tip")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                    
                    Text("The more actively you track expenses and financial data, the better your psychological summaries will reflect your progress and growth patterns.")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                .padding(20)
            }
            .padding(.horizontal, 24)
            
            // Start evaluation button
            Button(action: {
                // Open Norma chat for psychological evaluation
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                    
                    Text("Start Chat with Norma")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color(UIColor.systemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple,
                                    Color.purple.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
    
    @ViewBuilder
    private var profileContent: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("YOUR MONEY PSYCHOLOGY")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                
                Text("Understanding Your Financial Mind")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.top, 24)
                
                // Personality Category Card
                ZStack {
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
                    
                    VStack(spacing: 20) {
                        // Category Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.primary.opacity(0.1),
                                            Color.primary.opacity(0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 36))
                                .foregroundColor(.primary)
                        }
                        
                        VStack(spacing: 8) {
                            Text(moneyPersonality.category.uppercased())
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                                .tracking(1.0)
                            
                            Text(moneyPersonality.primaryTrait)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.vertical, 32)
                    .padding(.horizontal, 24)
                }
                .padding(.horizontal, 24)
                
                // Subconscious Mantra Card
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.primary.opacity(0.05),
                                    Color.primary.opacity(0.02)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.primary.opacity(0.2),
                                            Color.primary.opacity(0.1)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "quote.opening")
                                .font(.system(size: 20))
                                .foregroundColor(.primary.opacity(0.5))
                            Spacer()
                        }
                        
                        Text(moneyPersonality.subconscious)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .italic()
                        
                        Text("YOUR SUBCONSCIOUS MANTRA")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(1.0)
                    }
                    .padding(24)
                }
                .padding(.horizontal, 24)
                
                // Behavioral Patterns
                VStack(alignment: .leading, spacing: 16) {
                    Text("OBSERVED PATTERNS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                    
                    VStack(spacing: 12) {
                        ForEach(moneyPersonality.patterns, id: \.self) { pattern in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.red.opacity(0.2))
                                    .frame(width: 8, height: 8)
                                
                                Text(pattern)
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.red.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 24)
                
                // Strengths & Growth Areas
                HStack(spacing: 16) {
                    // Strengths
                    VStack(alignment: .leading, spacing: 12) {
                        Label("STRENGTHS", systemImage: "sparkles")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.green)
                            .tracking(1.0)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(moneyPersonality.strengths, id: \.self) { strength in
                                Text("• \(strength)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
                            )
                    )
                    
                    // Growth Areas
                    VStack(alignment: .leading, spacing: 12) {
                        Label("GROWTH", systemImage: "arrow.up.circle")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.orange)
                            .tracking(1.0)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(moneyPersonality.growthAreas, id: \.self) { area in
                                Text("• \(area)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.orange.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 24)
                
                // Financial Health Score
                ZStack {
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
                    
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Money Relationship Score")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .tracking(1.0)
                                
                                HStack(alignment: .bottom, spacing: 8) {
                                    Text("\(financialHealth.score)")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Text("/ 100")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 4)
                                }
                            }
                            
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(financialHealth.score) / 100)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.primary,
                                                Color.primary.opacity(0.6)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: financialHealth.trend == .improving ? "arrow.up.right" : "arrow.down.right")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(financialHealth.trend == .improving ? .green : .red)
                            }
                        }
                        
                        // Psychological Barriers
                        VStack(alignment: .leading, spacing: 8) {
                            Text("KEY PSYCHOLOGICAL BARRIERS")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                                .tracking(1.0)
                            
                            ForEach(financialHealth.psychologicalBarriers, id: \.self) { barrier in
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.orange)
                                    
                                    Text(barrier)
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                }
                .padding(.horizontal, 24)
                
                // Action Button
                Button(action: {
                    // Navigate to detailed insights or coaching
                }) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 16))
                        
                        Text("Get Personalized Breakthrough Plan")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Color(UIColor.systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.primary,
                                        Color.primary.opacity(0.8)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 30) {
            // Empty state preview
            ProfileView(hasProfileData: false)
            
            // With data preview
            ProfileView(hasProfileData: true)
        }
    }
}
