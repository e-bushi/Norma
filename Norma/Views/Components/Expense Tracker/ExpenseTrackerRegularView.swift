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
        VStack(spacing: 24) {
            // Enhanced header with status
            VStack(spacing: 12) {
                // Progress badge
                Text("\(month.uppercased())'S PROGRESS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                    .opacity(headerAppeared ? 1 : 0)
                    .offset(y: headerAppeared ? 0 : -10)
                
                // Smart insights
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Remaining")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.2f", max(0, incomeAmount - currentExpenseAmount)))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Daily Budget")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.2f", (incomeAmount - billAmount) / 30))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                )
                .scaleEffect(insightsAppeared ? 1 : 0.7)
                .opacity(insightsAppeared ? 1 : 0)
                .offset(y: insightsAppeared ? 0 : 20)
            }

            // Main chart
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
                        value: "$\(String(format: "%.2f", incomeAmount))",
                        color: .green,
                        icon: "arrow.down.circle.fill",
                        xPosition: centerX,
                        yPosition: 40,
                        dotSize: dotSize,
                        appeared: incomeLabelAppeared,
                        slideDirection: .left
                    )
                    
                    // Bills indicator
                    ChartLabelView(
                        title: "BILLS",
                        value: "$\(String(format: "%.2f", billAmount))",
                        color: .red,
                        icon: "calendar.badge.minus",
                        xPosition: centerX,
                        yPosition: lineHeight - 40,
                        dotSize: dotSize,
                        appeared: billsLabelAppeared,
                        slideDirection: .left
                    )
                    
                    // Current expense indicator (animated position)
                    ChartLabelView(
                        title: "CURRENT",
                        value: "$\(String(format: "%.2f", currentExpenseAmount))",
                        color: .purple,
                        icon: "creditcard.fill",
                        xPosition: centerX,
                        yPosition: expensePosition,
                        dotSize: dotSize,
                        appeared: currentLabelAppeared,
                        slideDirection: .right
                    )
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: currentExpenseAmount)
                }
                .frame(width: chartWidth, height: lineHeight)
                .padding(.vertical, 60)
                .padding(.horizontal, 20)
            }
            .padding(.horizontal)
            .padding(.horizontal)
            
            // Toggle button for explanation
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showDescription.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: showDescription ? "info.circle.fill" : "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    
                    Text(showDescription ? "Hide explanation" : "How to read this chart")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Image(systemName: showDescription ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            .padding(.horizontal)
            .scaleEffect(explanationButtonAppeared ? 1 : 0.9)
            .opacity(explanationButtonAppeared ? 1 : 0)
            .offset(y: explanationButtonAppeared ? 0 : 10)
            
            // Animated explanation content
            if showDescription {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your income ($\(String(format: "%.2f", incomeAmount))) starts at the top.")
                        .font(.system(size: 12))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Text("Your bills ($\(String(format: "%.2f", billAmount))) are fixed costs at the bottom.")
                        .font(.system(size: 12))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Text("The purple dot shows your total spending ($\(String(format: "%.2f", currentExpenseAmount))) for the current month and combines both Bills (even if you haven't paid them yet) and random expenses.")
                        .font(.system(size: 12))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    HStack(spacing: 4) {
                        Text("You have")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("$\(String(format: "%.2f", max(0, incomeAmount - currentExpenseAmount)))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(currentExpenseAmount > incomeAmount ? .red : .green)
                        
                        Text(currentExpenseAmount > incomeAmount ? "over budget" : "left to spend")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
                .padding(.horizontal)
                .padding(.top, -8)
                .transition(.asymmetric(
                    insertion: .push(from: .top).combined(with: .opacity),
                    removal: .push(from: .bottom).combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            animateElements()
        }
        .onChange(of: dotsAppeared) { _, newValue in
            if newValue {
                // Stagger the chart label animations
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    incomeLabelAppeared = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        billsLabelAppeared = true
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        currentLabelAppeared = true
                    }
                }
            } else {
                // Reset when dotsAppeared becomes false
                incomeLabelAppeared = false
                billsLabelAppeared = false
                currentLabelAppeared = false
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
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    ExpenseTrackerRegularView(
        billAmount: 1500,
        currentExpenseAmount: 2800,
        incomeAmount: 3000,
        month: "December",
        chartAppeared: true,
        dotsAppeared: true,
        insightsAppeared: true
    )
}
