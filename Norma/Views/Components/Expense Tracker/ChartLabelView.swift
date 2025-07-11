//
//  ChartLabelView.swift
//  Norma
//
//  Created by Claude on 7/6/25.
//

import SwiftUI

struct ChartLabelView: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    let xPosition: CGFloat
    let yPosition: CGFloat
    let dotSize: CGFloat
    let appeared: Bool
    let slideDirection: SlideDirection
    
    @State private var dotAppeared = false
    @State private var labelAppeared = false
    @State private var displayValue = ""
    @State private var valueScale: CGFloat = 0.3
    @State private var valueOpacity: Double = 0
    
    enum SlideDirection {
        case left, right
    }
    
    var body: some View {
        ZStack {
            // Dot indicator
            ZStack {
                Circle()
                    .fill(Color(UIColor.systemBackground))
                    .frame(width: dotSize + 8, height: dotSize + 8)
                
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
            }
            .scaleEffect(dotAppeared ? 1.0 : 0.0)
            .opacity(dotAppeared ? 1 : 0)
            .position(x: xPosition, y: yPosition)
            
            // Label
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color.opacity(0.8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(color.opacity(0.8))
                        .tracking(0.5)
                    
                    Text(displayValue)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(color)
                        .scaleEffect(valueScale)
                        .opacity(valueOpacity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
            .opacity(labelAppeared ? 1 : 0)
            .offset(x: labelAppeared ? 0 : (slideDirection == .left ? -30 : 30))
            .position(x: slideDirection == .left ? 80 : 240, y: yPosition)
        }
        .onChange(of: appeared) { _, newValue in
            if newValue {
                animateAppearance()
            } else {
                // Reset animation states when disappeared
                dotAppeared = false
                labelAppeared = false
                displayValue = formatAsZero(basedOn: value)
                valueScale = 0.3
                valueOpacity = 0
            }
        }
        .onChange(of: value) { _, newValue in
            // Update display value when the actual value changes
            if labelAppeared {
                displayValue = newValue
            }
        }
        .onAppear {
            // Initialize with zero in the same format as the target value
            displayValue = formatAsZero(basedOn: value)
            
            if appeared {
                animateAppearance()
            }
        }
    }
    
    private func animateAppearance() {
        // Animate dot with smooth bounce
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            dotAppeared = true
        }
        
        // Animate label with staggered delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                labelAppeared = true
            }
            
            // Start counting animation after label appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                displayValue = value
                
                // Animate the value with a soft smooth bounce
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                    valueScale = 1.0
                    valueOpacity = 1.0
                }
            }
        }
    }
    
    private func formatAsZero(basedOn originalValue: String) -> String {
        // Keep the same format as the original value but with zeros
        if originalValue.hasPrefix("$") {
            if originalValue.contains(",") {
                // Format like "$1,000" -> "$0"
                return "$0"
            } else {
                return "$0"
            }
        }
        return "0"
    }
}

#Preview {
    struct ChartLabelPreview: View {
        @State private var value = "$1,000"
        @State private var appeared = false
        
        var body: some View {
            VStack(spacing: 30) {
                ChartLabelView(
                    title: "INCOME",
                    value: value,
                    color: .green,
                    icon: "arrow.down.circle.fill",
                    xPosition: 160,
                    yPosition: 40,
                    dotSize: 16,
                    appeared: appeared,
                    slideDirection: .left
                )
                .frame(height: 100)
                
                Button("Toggle Appearance") {
                    appeared.toggle()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Animate Value") {
                    value = value == "$1,000" ? "$3,456" : "$1,000"
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
    
    return ChartLabelPreview()
}
