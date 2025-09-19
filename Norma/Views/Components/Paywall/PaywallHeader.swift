//
//  PaywallHeader.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import SwiftUI

struct PaywallHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            // Icon with background
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundColor(.accentColor)
                .frame(width: 80, height: 80)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(spacing: 8) {
                Text("Start Using Norma")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Unlock AI-powered financial insights")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    PaywallHeader()
}
