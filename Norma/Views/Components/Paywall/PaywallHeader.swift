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
            
            Spacer()
                .frame(height: 32)

            VStack(spacing: 8) {
                Text("Start Using Norma")
                    .font(.normaTitle(28))

                Text("Unlock AI-powered financial insights")
                    .font(.custom(FontFamily.Rubik.regular, size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    PaywallHeader()
}
