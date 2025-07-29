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
    let animateFromBottom: Bool
    let chartHeight: CGFloat
    let onTap: (() -> Void)?
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @State private var dotAppeared = false
    @State private var labelAppeared = false
    @State private var displayValue = ""
    @State private var valueScale: CGFloat = 0.3
    @State private var valueOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.8
    @State private var shouldBlur: Bool = false
    @State private var animatedYPosition: CGFloat = 0
    
    enum SlideDirection {
        case left, right
    }
    
    // Default initializer to make the new parameters optional
    init(
        title: String,
        value: String,
        color: Color,
        icon: String,
        xPosition: CGFloat,
        yPosition: CGFloat,
        dotSize: CGFloat,
        appeared: Bool,
        slideDirection: SlideDirection,
        animateFromBottom: Bool = false,
        chartHeight: CGFloat = 400,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.color = color
        self.icon = icon
        self.xPosition = xPosition
        self.yPosition = yPosition
        self.dotSize = dotSize
        self.appeared = appeared
        self.slideDirection = slideDirection
        self.animateFromBottom = animateFromBottom
        self.chartHeight = chartHeight
        self.onTap = onTap
    }
    
    private var labelContent: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(color.opacity(0.8))
                    .tracking(0.5)
                
                ZStack {
                    // Hidden text to maintain consistent size using final value
                    Text(value)
                        .font(.system(size: 18, weight: .bold))
                        .opacity(0)
                    
                    // Also reserve space for the formatted zero to ensure it's at least that wide
                    Text(formatAsZero(basedOn: value))
                        .font(.system(size: 18, weight: .bold))
                        .opacity(0)
                    
                    // Visible animated text
                    Text(displayValue)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(color)
                        .scaleEffect(valueScale)
                        .opacity(valueOpacity)
                }
            }
        }
        .fluidBlur(isActive: shouldBlur)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            // Base background
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    var body: some View {
        ZStack {
            // Dot indicator
            ZStack {
                // Pulsing ring for CURRENT label only
                if title == "CURRENT" && dotAppeared {
                    Circle()
                        .stroke(color, lineWidth: 2)
                        .frame(width: dotSize, height: dotSize)
                        .scaleEffect(pulseScale)
                        .opacity(pulseOpacity)
                }
                
                Circle()
                    .fill(Color(UIColor.systemBackground))
                    .frame(width: dotSize + 8, height: dotSize + 8)
                
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
            }
            .scaleEffect(dotAppeared ? 1.0 : 0.0)
            .opacity(dotAppeared ? 1 : 0)
            .position(x: xPosition, y: animatedYPosition)
            
            // Label
            Group {
                if let onTap = onTap {
                    Button(action: onTap) {
                        labelContent
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    labelContent
                }
            }
            .opacity(labelAppeared ? 1 : 0)
            .offset(x: labelAppeared ? 0 : (slideDirection == .left ? -30 : 30))
            .position(x: slideDirection == .left ? 80 : 240, y: animatedYPosition)
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
                pulseScale = 1.0
                pulseOpacity = 0.8
                shouldBlur = false
                animatedYPosition = animateFromBottom ? (chartHeight - 40) : yPosition
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
            
            // Reset all animation states to starting positions
            dotAppeared = false
            labelAppeared = false
            valueScale = 0.3
            valueOpacity = 0
            pulseScale = 1.0
            pulseOpacity = 0.8
            shouldBlur = false
            animatedYPosition = animateFromBottom ? (chartHeight - 40) : yPosition
            
            // Always run the full appearance animation on every appearance
            if appeared {
                animateAppearance()
            }
        }
    }
    
    private func animateAppearance() {
        // Start blur animation immediately (like original timing)
        shouldBlur = true
        
        // Animate position from bottom to final position (for CURRENT label)
        if animateFromBottom {
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedYPosition = yPosition
            }
        }
        
        // Animate dot with smooth bounce
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            dotAppeared = true
        }
        
        // Animate label with longer delay to sync with position animation
        let labelDelay = animateFromBottom ? 0.8 : 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + labelDelay) {
            withAnimation(.easeOut(duration: 0.4)) {
                labelAppeared = true
            }
            
            // Start counting animation after label appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                displayValue = value
                
                // Animate the value with a soft smooth bounce
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                    valueScale = 1.0
                    valueOpacity = 1.0
                }
                
                // Start pulsating animation for CURRENT label
                if title == "CURRENT" {
                    startPulsingAnimation()
                }
            }
        }
    }
    
    private func startPulsingAnimation() {
        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
            pulseScale = 2.5
            pulseOpacity = 0.0
        }
    }
    
    
    private func formatAsZero(basedOn originalValue: String) -> String {
        // Return formatted zero using the current currency
        return profileViewModel.formatCurrency(0)
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
        .preferredColorScheme(.light)
        .environmentObject({
            let dataManager = DataManager()
            let sessionViewModel = SessionViewModel(dataManager: dataManager)
            return ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
        }())
}
