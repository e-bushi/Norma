//
//  MiniExpenseDisclosureView.swift
//  Norma
//
//  Created by Claude on 8/2/25.
//

import SwiftUI

struct MiniExpenseDisclosureView: View {
    let appeared: Bool

    @State private var itemStates: [Bool] = Array(repeating: false, count: 6)

    var body: some View {
        VStack(spacing: 16) {
            // Recent transactions
            VStack(spacing: 12) {
                HStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "cart.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Grocery Store")
                            .font(.normaInput(12))
                            .foregroundColor(.primary)
                        Text("2 hours ago")
                            .font(.normaInput(10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("$85.42")
                        .font(.normaFinancial(12))
                        .foregroundColor(.primary)
                }
                .opacity(itemStates[0] ? 1 : 0)
                .offset(x: itemStates[0] ? 0 : -20)

                
                HStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "car.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gas Station")
                            .font(.normaInput(12))
                            .foregroundColor(.primary)
                        Text("Yesterday")
                            .font(.normaInput(10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$42.18")
                        .font(.normaFinancial(12))
                        .foregroundColor(.primary)
                }
                .opacity(itemStates[1] ? 1 : 0)
                .offset(x: itemStates[1] ? 0 : -20)

                
                HStack {
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.purple)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Coffee Shop")
                            .font(.normaInput(12))
                            .foregroundColor(.primary)
                        Text("2 days ago")
                            .font(.normaInput(10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$6.50")
                        .font(.normaFinancial(12))
                        .foregroundColor(.primary)
                }
                .opacity(itemStates[2] ? 1 : 0)
                .offset(x: itemStates[2] ? 0 : -20)

                
                HStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "pills.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pharmacy")
                            .font(.normaInput(12))
                            .foregroundColor(.primary)
                        Text("4 days ago")
                            .font(.normaInput(10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$24.75")
                        .font(.normaFinancial(12))
                        .foregroundColor(.primary)
                }
                .opacity(itemStates[3] ? 1 : 0)
                .offset(x: itemStates[3] ? 0 : -20)

                
                HStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Restaurant")
                            .font(.normaInput(12))
                            .foregroundColor(.primary)
                        Text("5 days ago")
                            .font(.normaInput(10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$48.30")
                        .font(.normaFinancial(12))
                        .foregroundColor(.primary)
                }
                .opacity(itemStates[4] ? 1 : 0)
                .offset(x: itemStates[4] ? 0 : -20)

                
                HStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "tv.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.indigo)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Streaming Service")
                            .font(.normaInput(12))
                            .foregroundColor(.primary)
                        Text("6 days ago")
                            .font(.normaInput(10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$15.99")
                        .font(.normaFinancial(12))
                        .foregroundColor(.primary)
                }
                .opacity(itemStates[5] ? 1 : 0)
                .offset(x: itemStates[5] ? 0 : -20)

            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.clear)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 16))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
            )
        }
        .onChange(of: appeared) { _, isAppeared in
            if isAppeared {
                animateItemsStaggered()
            } else {
                resetAnimations()
            }
        }
    }

    private func animateItemsStaggered() {
        for i in 0..<itemStates.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    itemStates[i] = true
                }
            }
        }
    }

    private func resetAnimations() {
        itemStates = Array(repeating: false, count: 6)
    }
}

#Preview {
    MiniExpenseDisclosureView(appeared: true)
        .padding()
}
