//
//  WidgetTheme.swift
//  NormaWidget
//
//  Created by Claude on 8/19/25.
//

import SwiftUI

struct WidgetTheme {
    // MARK: - Colors that adapt to light/dark mode
    
    static var primaryBackground: Color {
        Color(.systemBackground)
    }
    
    static var secondaryBackground: Color {
        Color(.secondarySystemBackground)
    }
    
    static var cardBackground: Color {
        Color(.tertiarySystemBackground)
    }
    
    static var primaryText: Color {
        Color(.label)
    }
    
    static var secondaryText: Color {
        Color(.secondaryLabel)
    }
    
    static var accentColor: Color {
        Color(.systemBlue)
    }
    
    // MARK: - Custom colors for specific contexts
    
    static var spendingGreen: Color {
        Color(.systemGreen)
    }
    
    static var warningOrange: Color {
        Color(.systemOrange)
    }
    
    static var overdueRed: Color {
        Color(.systemRed)
    }
    
    // MARK: - Gradients that work in both modes
    
    static var spendingGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(.systemBlue).opacity(0.1),
                Color(.systemBlue).opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var billsGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(.systemPurple).opacity(0.1),
                Color(.systemPurple).opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Environment-based theme modifier

struct ThemedCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(WidgetTheme.cardBackground)
                    .shadow(
                        color: colorScheme == .dark ? .clear : .black.opacity(0.1),
                        radius: colorScheme == .dark ? 0 : 2,
                        x: 0,
                        y: 1
                    )
            )
    }
}

extension View {
    func themedCard() -> some View {
        modifier(ThemedCard())
    }
}