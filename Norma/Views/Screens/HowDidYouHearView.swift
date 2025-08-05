//
//  HowDidYouHearView.swift
//  Norma
//
//  Created by Claude on 8/5/25.
//

import SwiftUI

struct HowDidYouHearView: View {
    @State private var selectedOption: HearAboutOption? = nil
    @State private var titleOpacity = 0.0
    @State private var titleOffset: CGFloat = 30
    @State private var descriptionOpacity = 0.0
    @State private var descriptionOffset: CGFloat = 30
    @State private var optionsOpacity = 0.0
    @State private var optionsOffset: CGFloat = 40
    @State private var buttonOpacity = 0.0
    @State private var buttonScale = 0.9
    
    let onContinue: (HearAboutOption?) -> Void
    let onSkip: () -> Void
    
    let options: [HearAboutOption] = [
        HearAboutOption(id: "appstore", title: "App Store", icon: "app.badge"),
        HearAboutOption(id: "social", title: "Social Media", icon: "heart.text.square"),
        HearAboutOption(id: "friend", title: "Friend or Family", icon: "person.2"),
        HearAboutOption(id: "search", title: "Search Engine", icon: "magnifyingglass"),
        HearAboutOption(id: "blog", title: "Blog or Article", icon: "doc.text"),
        HearAboutOption(id: "ad", title: "Advertisement", icon: "megaphone"),
        HearAboutOption(id: "other", title: "Other", icon: "ellipsis.circle")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("How did you hear about us?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)
                        .onAppear {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                                titleOffset = 0
                                titleOpacity = 1.0
                            }
                        }
                    
                    Text("Help us understand how you discovered Norma so we can improve our outreach.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .offset(y: descriptionOffset)
                        .opacity(descriptionOpacity)
                        .onAppear {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                                descriptionOffset = 0
                                descriptionOpacity = 1.0
                            }
                        }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Options List
                VStack(spacing: 12) {
                    ForEach(options, id: \.id) { option in
                        OptionToggleRow(
                            option: option,
                            isSelected: selectedOption?.id == option.id,
                            onToggle: { isSelected in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedOption = option
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .offset(y: optionsOffset)
                .opacity(optionsOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.5)) {
                        optionsOffset = 0
                        optionsOpacity = 1.0
                    }
                }
                
                // Action button
                VStack(spacing: 16) {
                    Button(action: {
                        onContinue(selectedOption)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            
                            Text("Continue")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            selectedOption != nil ? Color.purple : Color.gray,
                                            selectedOption != nil ? Color.purple.opacity(0.8) : Color.gray.opacity(0.8)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .opacity(selectedOption != nil ? 1.0 : 0.6)
                    }
                    .disabled(selectedOption == nil)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)
                }
                .padding(.vertical)
                .scaleEffect(buttonScale)
                .opacity(buttonOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7)) {
                        buttonScale = 1.0
                        buttonOpacity = 1.0
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct OptionToggleRow: View {
    let option: HearAboutOption
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            if !isSelected {
                onToggle(true)
            }
        }) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.purple : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.purple : Color.gray.opacity(0.3), lineWidth: 2)
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Option icon and info
                HStack(spacing: 12) {
                    Image(systemName: option.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .purple : .secondary)
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple.opacity(0.05) : Color.gray.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.purple.opacity(0.2) : Color.gray.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HearAboutOption {
    let id: String
    let title: String
    let icon: String
}

#Preview {
    HowDidYouHearView(
        onContinue: { option in
            print("Selected: \(option?.title ?? "None")")
        },
        onSkip: {
            print("Skipped")
        }
    )
}
