//
//  DigitReel.swift
//  Norma
//
//  Created by Claude on 7/6/25.
//

import SwiftUI

struct DigitReel: View {
    let targetDigit: String
    let font: Font
    let color: Color
    
    @State private var currentDigit: String = "0"
    @State private var verticalOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var animationQueue: [String] = []
    
    // All possible digits for the reel
    private let digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Create the full reel of digits
                ForEach(Array(allReelDigits.enumerated()), id: \.offset) { index, digit in
                    Text(digit)
                        .font(font)
                        .foregroundColor(color)
                        .monospacedDigit()
                        .frame(height: 24)
                        .opacity(opacityForDigit(at: index))
                        .blur(radius: blurForDigit(at: index))
                }
            }
            .offset(y: verticalOffset) // Offset to center the middle digit
            .clipped()
        }
        .frame(height: 24)
        .onChange(of: targetDigit) { _, newDigit in
            animateToDigit(newDigit)
        }
        .onAppear {
            currentDigit = targetDigit
        }
    }
    
    // Generate just the digits we need: previous, current, and next
    private var allReelDigits: [String] {
        guard let currentIndex = digits.firstIndex(of: currentDigit) else {
            return [currentDigit]
        }
        
        let prevIndex = (currentIndex - 1 + digits.count) % digits.count
        let nextIndex = (currentIndex + 1) % digits.count
        
        return [
            digits[prevIndex],  // Previous digit (above)
            currentDigit,       // Current digit (center)
            digits[nextIndex]   // Next digit (below)
        ]
    }
    
    // Calculate opacity for each digit based on position and animation progress
    private func opacityForDigit(at index: Int) -> Double {
        let progress = abs(verticalOffset) / 24.0 // Progress from 0 to 1
        
        switch index {
        case 0: // Top digit
            if verticalOffset > 0 { // Scrolling down, top digit coming in
                return min(1.0, progress * 2) // Fade in
            } else {
                return max(0, 0.05 - progress * 0.05) // Stay faint
            }
        case 1: // Middle digit (current)
            return max(0, 1.0 - progress) // Fade out as it leaves
        case 2: // Bottom digit
            if verticalOffset < 0 { // Scrolling up, bottom digit coming in
                return min(1.0, progress * 2) // Fade in
            } else {
                return max(0, 0.05 - progress * 0.05) // Stay faint
            }
        default:
            return 0
        }
    }
    
    // Calculate blur for each digit based on position and animation progress
    private func blurForDigit(at index: Int) -> CGFloat {
        let progress = abs(verticalOffset) / 24.0 // Progress from 0 to 1
        
        switch index {
        case 0: // Top digit
            if verticalOffset > 0 { // Coming in
                return max(0, 2 - progress * 2) // Reduce blur as it comes in
            } else {
                return 2 // Stay blurred
            }
        case 1: // Middle digit
            return min(2, progress * 2) // Increase blur as it leaves
        case 2: // Bottom digit
            if verticalOffset < 0 { // Coming in
                return max(0, 2 - progress * 2) // Reduce blur as it comes in
            } else {
                return 2 // Stay blurred
            }
        default:
            return 0
        }
    }
    
    private func animateToDigit(_ newDigit: String) {
        guard currentDigit != newDigit else { return }
        guard let currentIndex = digits.firstIndex(of: currentDigit),
              let targetIndex = digits.firstIndex(of: newDigit) else { return }
        
        // If already animating, just update the target
        if isAnimating {
            // Clear the queue and recalculate path to new target
            animationQueue.removeAll()
        }
        
        // Calculate the shortest path (forward or backward)
        let forwardDistance = (targetIndex - currentIndex + digits.count) % digits.count
        let backwardDistance = (currentIndex - targetIndex + digits.count) % digits.count
        
        let shouldGoForward = forwardDistance <= backwardDistance
        
        // Build the queue of digits to animate through
        animationQueue.removeAll()
        
        if shouldGoForward {
            for i in 1...forwardDistance {
                let index = (currentIndex + i) % digits.count
                animationQueue.append(digits[index])
            }
        } else {
            for i in 1...backwardDistance {
                let index = (currentIndex - i + digits.count) % digits.count
                animationQueue.append(digits[index])
            }
        }
        
        // Start animating if not already
        if !isAnimating {
            isAnimating = true
            animateNextInQueue()
        }
    }
    
    private func animateNextInQueue() {
        guard !animationQueue.isEmpty else {
            isAnimating = false
            return
        }
        
        let nextDigit = animationQueue.removeFirst()
        let shouldGoUp = shouldAnimateUp(to: nextDigit)
        
        // Calculate the offset for animation
        let lineHeight: CGFloat = 24
        let targetOffset = shouldGoUp ? -lineHeight : lineHeight
        
        // Calculate animation timing based on position in queue
        let totalSteps = animationQueue.count + 1
        let remainingSteps = animationQueue.count
        
        // Speed up in the middle, slow down at the end
        let duration: Double
        if totalSteps == 1 {
            // Single digit change - slightly slower for visibility
            duration = 0.5
        } else if remainingSteps == 0 {
            // Last digit - slow down with bounce
            duration = 0.3
        } else if remainingSteps > totalSteps / 2 {
            // Accelerating phase
            duration = 0.12
        } else {
            // Middle phase - fastest
            duration = 0.08
        }
        
        // Use different animation for the last digit
        if remainingSteps == 0 {
            // Final digit gets a gentle bounce
            withAnimation(.spring(response: duration, dampingFraction: 0.5)) {
                verticalOffset = targetOffset
            }
        } else {
            // Other digits use smooth easing
            withAnimation(.easeInOut(duration: duration)) {
                verticalOffset = targetOffset
            }
        }
        
        // After this step completes, update and continue
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            currentDigit = nextDigit
            verticalOffset = 0
            
            // Continue with the next digit in queue
            animateNextInQueue()
        }
    }
    
    private func shouldAnimateUp(to nextDigit: String) -> Bool {
        guard let currentIndex = digits.firstIndex(of: currentDigit),
              let nextIndex = digits.firstIndex(of: nextDigit) else { return true }
        
        // Check if next digit is the one after current (going up)
        return (currentIndex + 1) % digits.count == nextIndex
    }
}

#Preview {
    struct DigitReelPreview: View {
        @State private var digit = "0"
        
        var body: some View {
            VStack(spacing: 20) {
                DigitReel(
                    targetDigit: digit,
                    font: .system(size: 18, weight: .bold),
                    color: .primary
                )
                
                Button("Next Digit") {
                    let currentIndex = Int(digit) ?? 0
                    digit = String((currentIndex + 2) % 10)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
    
    return DigitReelPreview()
}
