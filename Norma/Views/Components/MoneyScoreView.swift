//
//  MoneyScoreView.swift
//  Norma
//
//  Created by Claude on 1/23/25.
//

import SwiftUI

struct MoneyScoreView: View {
    let score: Int
    let trend: TrendDirection
    
    // Metric scores (0-100)
    let billManagementScore: Int
    let budgetManagementScore: Int
    let savingsRateScore: Int
    // let expenseControlScore: Int  // Commented out - needs expense categorization
    let stabilityScore: Int
    
    // Animation states
    @State private var scoreAppeared = false
    @State private var circleProgress: CGFloat = 0
    @State private var metricsAppeared = [false, false, false, false]  // 4 metrics now
    
    enum TrendDirection {
        case improving
        case declining
        case stable
    }
    
    var body: some View {
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
                // Header with overall score
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Money Score")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(1.0)
                        
                        HStack(alignment: .bottom, spacing: 8) {
                            Text("\(score)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("/ 100")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .padding(.bottom, 4)
                        }
                        
                        Text("Your overall financial health rating")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .opacity(scoreAppeared ? 1 : 0)
                    .scaleEffect(scoreAppeared ? 1 : 0.8)
                    
                    Spacer()
                    
                    // Circular score indicator
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: circleProgress)
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
                        
                        Image(systemName: trendIcon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(trendColor)
                    }
                    .opacity(scoreAppeared ? 1 : 0)
                    .scaleEffect(scoreAppeared ? 1 : 0.5)
                }
                
                // Financial Metrics
                VStack(spacing: 12) {
                    Text("FINANCIAL METRICS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(1.0)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(scoreAppeared ? 1 : 0)
                    
                    VStack(spacing: 12) {
                        // Bill Management
                        MetricCardView(
                            icon: "calendar.badge.checkmark",
                            title: "Bill Management",
                            description: "On-time payments & tracking",
                            score: billManagementScore,
                            color: .green
                        )
                        .opacity(metricsAppeared[0] ? 1 : 0)
                        .offset(y: metricsAppeared[0] ? 0 : 20)
                        
                        // Budget Management
                        MetricCardView(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Budgeting",
                            description: "Staying within budget limits",
                            score: budgetManagementScore,
                            color: .blue
                        )
                        .opacity(metricsAppeared[1] ? 1 : 0)
                        .offset(y: metricsAppeared[1] ? 0 : 20)
                        
                        // Savings Rate
                        MetricCardView(
                            icon: "banknote",
                            title: "Savings Rate",
                            description: "Monthly savings percentage",
                            score: savingsRateScore,
                            color: .purple
                        )
                        .opacity(metricsAppeared[2] ? 1 : 0)
                        .offset(y: metricsAppeared[2] ? 0 : 20)
                        
                        // Expense Control - Commented out pending categorization implementation
                        /*
                        MetricCardView(
                            icon: "creditcard",
                            title: "Expense Control",
                            description: "Spending patterns & habits",
                            score: expenseControlScore,
                            color: .orange
                        )
                        .opacity(metricsAppeared[3] ? 1 : 0)
                        .offset(y: metricsAppeared[3] ? 0 : 20)
                        */
                        
                        // Stability
                        MetricCardView(
                            icon: "gauge.medium",
                            title: "Stability",
                            description: "Income to expense ratio",
                            score: stabilityScore,
                            color: .teal
                        )
                        .opacity(metricsAppeared[3] ? 1 : 0)
                        .offset(y: metricsAppeared[3] ? 0 : 20)
                    }
                }
                .padding(.top, 8)
            }
            .padding(28)
        }
        .onAppear {
            animateElements()
        }
    }
    
    private func animateElements() {
        // Animate header and circle
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            scoreAppeared = true
        }
        
        // Animate circle progress
        withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
            circleProgress = CGFloat(score) / 100
        }
        
        // Animate metric cards with staggered delay (4 metrics)
        for index in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(index) * 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    metricsAppeared[index] = true
                }
            }
        }
    }
    
    private var trendIcon: String {
        switch trend {
        case .improving:
            return "arrow.up.right"
        case .declining:
            return "arrow.down.right"
        case .stable:
            return "minus"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .improving:
            return .green
        case .declining:
            return .red
        case .stable:
            return .gray
        }
    }
}

// Individual metric card component
struct MetricCardView: View {
    let icon: String
    let title: String
    let description: String
    let score: Int
    let color: Color
    
    private var rating: String {
        switch score {
        case 90...100:
            return "Great"
        case 80..<90:
            return "Good"
        case 70..<80:
            return "Fair"
        case 60..<70:
            return "Poor"
        default:
            return "None"
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
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
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.15),
                                    Color.gray.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
            
            HStack {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(score)%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(color)
                    
                    Text(rating)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(color)
                        .textCase(.uppercase)
                }
            }
            .padding(16)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Preview with good scores
            MoneyScoreView(
                score: 72,
                trend: .improving,
                billManagementScore: 85,
                budgetManagementScore: 72,
                savingsRateScore: 68,
                stabilityScore: 70
            )
            .padding(.horizontal, 24)
            
            // Preview with excellent scores
            MoneyScoreView(
                score: 92,
                trend: .improving,
                billManagementScore: 95,
                budgetManagementScore: 90,
                savingsRateScore: 88,
                stabilityScore: 94
            )
            .padding(.horizontal, 24)
            
            // Preview with poor scores
            MoneyScoreView(
                score: 45,
                trend: .declining,
                billManagementScore: 40,
                budgetManagementScore: 50,
                savingsRateScore: 35,
                stabilityScore: 45
            )
            .padding(.horizontal, 24)
        }
    }
}
