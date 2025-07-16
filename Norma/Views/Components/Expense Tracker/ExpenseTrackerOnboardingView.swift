//
//  ExpenseTrackerOnboardingView.swift
//  Norma
//
//  Created by Claude on 7/6/25.
//

import SwiftUI

struct ExpenseTrackerOnboardingView: View {
    let incomeAmount: Double
    @Binding var showNormaChat: Bool
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @State private var headerAppeared = false
    @State private var cardAppeared = false
    @State private var iconAppeared = false
    @State private var contentAppeared = false
    @State private var stepsAppeared = false
    @State private var buttonAppeared = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header for onboarding mode
            VStack(spacing: 8) {
                Text("YOUR FINANCIAL TRACKER")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                
                Text("Ready to track your spending")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .opacity(headerAppeared ? 1 : 0)
            .offset(y: headerAppeared ? 0 : -20)
            
            // Main onboarding card - matching ProfileView style
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
                    // Income icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.green.opacity(0.1),
                                        Color.green.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                    }
                    .scaleEffect(iconAppeared ? 1 : 0.5)
                    .opacity(iconAppeared ? 1 : 0)
                    
                    // Main content
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text("Monthly Income")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text(profileViewModel.formatCurrency(incomeAmount))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                            
                            Text("Let's start tracking where your money goes")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 20)
                        
                        Divider()
                            .frame(maxWidth: 280)
                            .opacity(contentAppeared ? 1 : 0)
                            .scaleEffect(x: contentAppeared ? 1 : 0, y: 1)
                        
                        // How it works
                        VStack(spacing: 16) {
                            Text("How your tracker works")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .opacity(stepsAppeared ? 1 : 0)
                            
                            VStack(spacing: 12) {
                                // Step 1
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 28, height: 28)
                                        
                                        Text("1")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Text("Add your recurring bills (rent, utilities, subscriptions)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Spacer()
                                }
                                .opacity(stepsAppeared ? 1 : 0)
                                .offset(x: stepsAppeared ? 0 : -30)
                                
                                // Step 2
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.purple.opacity(0.1))
                                            .frame(width: 28, height: 28)
                                        
                                        Text("2")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.purple)
                                    }
                                    
                                    Text("Track daily expenses as they happen")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Spacer()
                                }
                                .opacity(stepsAppeared ? 1 : 0)
                                .offset(x: stepsAppeared ? 0 : -30)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: stepsAppeared)
                                
                                // Step 3
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.green.opacity(0.1))
                                            .frame(width: 28, height: 28)
                                        
                                        Text("3")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                    
                                    Text("See how much you have left to spend")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Spacer()
                                }
                                .opacity(stepsAppeared ? 1 : 0)
                                .offset(x: stepsAppeared ? 0 : -30)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: stepsAppeared)
                            }
                        }
                    }
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 32)
            }
            .padding(.horizontal)
            .padding(.horizontal)
            .scaleEffect(cardAppeared ? 1 : 0.95)
            .opacity(cardAppeared ? 1 : 0)
            
            // Call to action
            Button(action: {
                showNormaChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                    
                    Text("Add your first bill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
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
            .scaleEffect(buttonAppeared ? 1 : 0.8)
            .opacity(buttonAppeared ? 1 : 0)
        }
        .onAppear {
            animateViews()
        }
    }
    
    private func animateViews() {
        withAnimation(.easeOut(duration: 0.6)) {
            headerAppeared = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                cardAppeared = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                iconAppeared = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.5)) {
                contentAppeared = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                stepsAppeared = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                buttonAppeared = true
            }
        }
    }
}

#Preview {
    ExpenseTrackerOnboardingView(
        incomeAmount: 3000,
        showNormaChat: .constant(false)
    )
}