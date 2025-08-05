//
//  MiniChatView.swift
//  Norma
//
//  Created by Claude on 8/2/25.
//

import SwiftUI

struct MiniChatView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Text("AI ASSISTANT")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Smart Insights")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("Always On")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.purple)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Personalized")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("100%")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            
            // Chat messages
            VStack(spacing: 12) {
                // User message
                HStack {
                    Spacer()
                    Text("Help me budget for vacation")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.purple)
                        )
                }
                
                // AI response
                HStack {
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("🤖")
                                .font(.system(size: 10))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Based on your spending, I suggest saving $200/month for 6 months. You can reduce dining out by $50/month.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.1))
                    )
                    
                    Spacer()
                }
                
                // Another user message
                HStack {
                    Spacer()
                    Text("Show me my top expenses")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.purple)
                        )
                }
                
                // AI response with suggestions
                HStack {
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("🤖")
                                .font(.system(size: 10))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your top 3: Food ($450), Entertainment ($280), Shopping ($320). Try cooking more meals at home!")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.1))
                    )
                    
                    Spacer()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    MiniChatView()
        .padding()
}