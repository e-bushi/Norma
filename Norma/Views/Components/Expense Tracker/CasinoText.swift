//
//  CasinoText.swift
//  Norma
//
//  Created by Claude on 7/6/25.
//

import SwiftUI

struct CasinoText: View {
    let value: String
    let font: Font
    let color: Color
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(parsedValueComponents.enumerated()), id: \.offset) { index, component in
                if component.isNumber {
                    DigitReel(
                        targetDigit: String(component),
                        font: font,
                        color: color
                    )
                    .frame(height: 24) // Ensure consistent height
                } else {
                    // Non-digit characters (like $, comma, etc.)
                    Text(String(component))
                        .font(font)
                        .foregroundColor(color)
                        .monospacedDigit()
                        .frame(height: 24) // Match the digit reel height
                        .offset(y: -1) // Fine-tune vertical alignment if needed
                }
            }
        }
        .fixedSize() // Prevent layout shifts during animation
    }
    
    // Parse the value string into individual components
    private var parsedValueComponents: [Character] {
        return Array(value)
    }
}

#Preview {
    struct CasinoTextPreview: View {
        @State private var value1 = "$1,234"
        @State private var value2 = "$5"
        
        var body: some View {
            VStack(spacing: 20) {
                
                CasinoText(
                    value: value2,
                    font: .system(size: 18, weight: .semibold),
                    color: .green
                )
                
                Button("Animate Values") {
                    value1 = value1 == "$1,234" ? "$1,456" : "$1,234"
                    value2 = value2 == "$5" ? "$91" : "$104"
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
    
    return CasinoTextPreview()
}
