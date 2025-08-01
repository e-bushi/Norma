//
//  TrialTimeline.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import SwiftUI

struct TrialTimeline: View {
    @State private var appearAnimation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("HOW YOUR FREE TRIAL WORKS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
            
            VStack(spacing: 0) {
                TimelineItem(
                    icon: "play.circle.fill",
                    iconColor: .green,
                    title: "Today",
                    description: "Start your full access to Norma",
                    isLast: false
                )
                .offset(x: appearAnimation ? 0 : -20)
                .scaleEffect(appearAnimation ? 1 : 0.95)
                .opacity(appearAnimation ? 1 : 0)
                .rotation3DEffect(
                    .degrees(appearAnimation ? 0 : -5),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0.3)
                    .delay(0.08),
                    value: appearAnimation
                )
                
                TimelineItem(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "Day 5",
                    description: "Get a reminder about when your trial will end",
                    isLast: false
                )
                .offset(x: appearAnimation ? 0 : -20)
                .scaleEffect(appearAnimation ? 1 : 0.95)
                .opacity(appearAnimation ? 1 : 0)
                .rotation3DEffect(
                    .degrees(appearAnimation ? 0 : -5),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0.3)
                    .delay(0.14),
                    value: appearAnimation
                )
                
                TimelineItem(
                    icon: "creditcard.fill",
                    iconColor: .blue,
                    title: "Day 7",
                    description: "Your journey with Norma begins, cancel anytime before",
                    isLast: true
                )
                .offset(x: appearAnimation ? 0 : -20)
                .scaleEffect(appearAnimation ? 1 : 0.95)
                .opacity(appearAnimation ? 1 : 0)
                .rotation3DEffect(
                    .degrees(appearAnimation ? 0 : -5),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0.3)
                    .delay(0.20),
                    value: appearAnimation
                )
            }
        }
        .padding(20)
        .background(
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
                                    Color.gray.opacity(0.2),
                                    Color.gray.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            // Trigger initial animation when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    appearAnimation = true
                }
            }
        }
    }
}

struct TimelineItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon with line
            VStack(spacing: 0) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }
                
                // Vertical line
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 44)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.bottom, isLast ? 0 : 20)
            }
            
            Spacer()
        }
    }
}

#Preview {
    TrialTimeline()
        .padding()
}