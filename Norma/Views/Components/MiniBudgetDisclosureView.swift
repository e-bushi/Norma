//
//  MiniBudgetDisclosureView.swift
//  Norma
//
//  Created by Claude on 8/2/25.
//

import SwiftUI

struct MiniBudgetDisclosureView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Text("AUGUST BUDGET")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Total Budget")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("$2,500")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Remaining")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("$1,200")
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
            
            // Mini budget categories
            VStack(spacing: 12) {
                HStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("🍕")
                                .font(.system(size: 14))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Food & Dining")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Text("$450 of $600")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$150")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                }
                
                HStack {
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("🎬")
                                .font(.system(size: 14))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Entertainment")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Text("$280 of $300")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$20")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("🚗")
                                .font(.system(size: 14))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Transportation")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Text("$180 of $250")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$70")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                }
                
                HStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("🛍️")
                                .font(.system(size: 14))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Shopping")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Text("$320 of $200")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("-$120")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                }
                
                HStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("💊")
                                .font(.system(size: 14))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Healthcare")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Text("$150 of $200")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$50")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                }
                
                HStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.1))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("💡")
                                .font(.system(size: 14))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Utilities")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Text("$240 of $250")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$10")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
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
    MiniBudgetDisclosureView()
        .padding()
}