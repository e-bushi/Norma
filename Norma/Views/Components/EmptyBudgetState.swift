//
//  EmptyBudgetState.swift
//  Norma
//
//  Created by Claude on 7/24/25.
//

import SwiftUI

struct EmptyBudgetState: View {
    let onCategorySelected: ((Category) -> Void)?
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Enhanced empty state with category grid
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.1),
                                    Color.blue.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "target")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 8) {
                    Text("Ready to set budgets?")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Tap the target button above to create spending limits for different categories")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Divider()
                .frame(maxWidth: 200)
            
            // Quick budget suggestions
            VStack(spacing: 12) {
                Text("Popular budget categories")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                // Get the first 4 expense categories
                let popularCategories = Array(dataManager.getCategories(ofType: .expense).prefix(4))
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(popularCategories, id: \.id) { category in
                        Button(action: {
                            onCategorySelected?(category)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(category.color)
                                
                                Text(category.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(category.color.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(category.color.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
    }
}