//
//  FeatureRow.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import SwiftUI

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let includedInBase: Bool
    let includedInPro: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            iconSection
            textSection
            Spacer()
            indicatorSection
        }
    }
    
    private var iconSection: some View {
        Image(systemName: icon)
            .font(.system(size: 20))
            .foregroundColor(includedInBase ? .accentColor : .secondary)
            .frame(width: 28, height: 28)
    }
    
    private var textSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(includedInBase ? .primary : .secondary)
            
            Text(description)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    private var indicatorSection: some View {
        HStack(spacing: 12) {
            // Base tier indicator
            Image(systemName: includedInBase ? "checkmark.circle.fill" : "minus.circle")
                .font(.system(size: 16))
                .foregroundColor(includedInBase ? .green : .gray.opacity(0.4))
            
            // Pro tier indicator
            Image(systemName: includedInPro ? "checkmark.circle.fill" : "minus.circle")
                .font(.system(size: 16))
                .foregroundColor(includedInPro ? .green : .gray.opacity(0.4))
        }
    }
}