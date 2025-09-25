//
//  MoneyViewPicker.swift
//  Norma
//
//  Created by Claude on 1/24/25.
//

import SwiftUI

struct MoneyViewPicker: View {
    @Binding var selectedView: Int // 0 for Money Chart, 1 for Money Score
    let chartAppeared: Bool
    
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
                                    Color.gray.opacity(0.2),
                                    Color.gray.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
            
            HStack(spacing: 0) {
                // Money Chart button
                Button(action: {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedView = 0
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedView == 0 ? .purple : .secondary)
                        
                        Text("Money Chart")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedView == 0 ? .purple : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            if selectedView == 0 {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.purple.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                    )
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            }
                        }
                    )
                    .padding(.horizontal, 4)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Money Score button
                Button(action: {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedView = 1
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedView == 1 ? .green : .secondary)
                        
                        Text("Money Score")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedView == 1 ? .green : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            if selectedView == 1 {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                                    )
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            }
                        }
                    )
                    .padding(.horizontal, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(4)
        }
        .frame(height: 48)
        .padding(.horizontal)
        .padding(.horizontal)
        .scaleEffect(chartAppeared ? 1 : 0.9)
        .opacity(chartAppeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedView)
    }
}

#Preview {
    @State var selectedView = 0
    
    return MoneyViewPicker(selectedView: $selectedView, chartAppeared: true)
        .padding()
        .background(Color.gray.opacity(0.1))
}