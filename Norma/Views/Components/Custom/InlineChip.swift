//
//  InlineChip.swift
//  Norma
//
//  Created by Claude on 12/5/25.
//

import SwiftUI

struct InlineChip: View {
    var icon: String? = nil
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10))
            }
            Text(text)
                .font(.custom(FontFamily.Rubik.medium, size: 12))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        InlineChip(icon: "dollarsign.circle.fill", text: "$1,200", color: Color("NormaPastelTeal"))
        InlineChip(icon: "info.circle.fill", text: "Your savings", color: Color("NormaPastelPurple"))
        InlineChip(text: "45% of arc", color: Color("NormaPastelCoral"))
    }
    .padding()
}
