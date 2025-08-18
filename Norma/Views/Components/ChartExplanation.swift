//
//  ChartExplanation.swift
//  Norma
//
//  Created by Claude on 8/6/25.
//

import SwiftUI

struct ChartExplanation: View {
    @Binding var showDescription: Bool
    let incomeAmount: Double
    let billAmount: Double
    let currentExpenseAmount: Double
    let explanationButtonAppeared: Bool
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 0) {
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
                    Text("Your income (\(profileViewModel.formatCurrency(incomeAmount))) starts at the top.")
                        .font(.system(size: 12))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Text("Your bills (\(profileViewModel.formatCurrency(billAmount))) are fixed costs at the bottom.")
                        .font(.system(size: 12))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Text("The purple dot shows your total spending (\(profileViewModel.formatCurrency(currentExpenseAmount))) for the current month and combines both Bills (even if you haven't paid them yet) and random expenses.")
                        .font(.system(size: 12))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    HStack(spacing: 4) {
                        Text("You have")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text(profileViewModel.formatCurrency(max(0, incomeAmount - currentExpenseAmount)))
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
                .padding(.top, 8)
                .transition(.asymmetric(
                    insertion: .push(from: .top).combined(with: .opacity),
                    removal: .push(from: .bottom).combined(with: .opacity)
                ))
            }
        }
    }
}