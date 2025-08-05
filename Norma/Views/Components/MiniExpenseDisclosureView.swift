//
//  MiniExpenseDisclosureView.swift
//  Norma
//
//  Created by Claude on 8/2/25.
//

import SwiftUI

struct MiniExpenseDisclosureView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Text("RECENT EXPENSES")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Total Spent")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("$1,850")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Transactions")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("24")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
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
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Text("2 hours ago")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$85.42")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
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
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Text("Yesterday")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$42.18")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
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
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Text("2 days ago")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$6.50")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
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
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Text("4 days ago")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$24.75")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
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
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Text("5 days ago")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$48.30")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
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
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Text("6 days ago")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$15.99")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
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
    MiniExpenseDisclosureView()
        .padding()
}