//
//  AIMessageBubble.swift
//  Norma
//
//  Created by Claude on 10/11/25.
//

import SwiftUI

enum TextRevealDirection {
    case leftToRight
    case rightToLeft

    var offset: CGFloat {
        switch self {
        case .leftToRight: return -20
        case .rightToLeft: return 20
        }
    }

    var alignment: HorizontalAlignment {
        switch self {
        case .leftToRight: return .leading
        case .rightToLeft: return .trailing
        }
    }
}

struct AIMessageBubble: View {
    let content: String
    let uiComponent: UIComponent?
    let revealDirection: TextRevealDirection

    @State private var visibleWordCount = 0
    @State private var showCards = false
    @State private var hasAnimated = false

    private var words: [String] {
        // Split by whitespace but preserve the spaces
        var result: [String] = []
        var currentWord = ""

        for char in content {
            currentWord.append(char)
            if char.isWhitespace {
                result.append(currentWord)
                currentWord = ""
            }
        }
        if !currentWord.isEmpty {
            result.append(currentWord)
        }
        return result
    }

    private var displayText: String {
        // Show the animated portion as it reveals
        return words.prefix(visibleWordCount).joined()
    }

    private var isToolActivityMessage: Bool {
        if case .toolActivity = uiComponent {
            return true
        }
        return false
    }

    init(content: String, uiComponent: UIComponent? = nil, revealDirection: TextRevealDirection = .leftToRight) {
        self.content = content
        self.uiComponent = uiComponent
        self.revealDirection = revealDirection
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Cards first (if present) - shown before text
            if let component = uiComponent, showCards {
                switch component {
                case .billCards(let bills):
                    BillCardStack(bills: bills)
                        .transition(.opacity.combined(with: .scale))
                case .expenseCards(let expenses):
                    ExpenseCardStack(expenses: expenses)
                        .transition(.opacity.combined(with: .scale))
                case .budgetCards(let budgets):
                    BudgetCardStack(budgets: budgets)
                        .transition(.opacity.combined(with: .scale))
                case .actionConfirmation(let icon, let message, let colorName):
                    ActionConfirmationCard(icon: icon, message: message, colorName: colorName)
                        .transition(.opacity.combined(with: .scale))
                case .toolActivity(let message):
                    ToolActivityView(message: message)
                        .transition(.opacity.combined(with: .scale))
                case .arcDisplay(let arcCount):
                    ArcDisplayView(arcCount: arcCount)
                        .transition(.opacity.combined(with: .scale))
                case .flowStateCapsule:
                    // Flow state is displayed in nav bar, not in message bubble
                    EmptyView()
                }
            }

            // Markdown text using native SwiftUI with word-by-word reveal
            // Don't show text content for tool activity messages (content is already in the ToolActivityView)
            if !isToolActivityMessage {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(try! AttributedString(markdown: displayText, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                            .font(.normaInput(16))
                            .lineSpacing(4)
                            .foregroundColor(Color("NormaText"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onAppear {
                                // Only animate once per message
                                if !hasAnimated {
                                    hasAnimated = true

                                    // Show cards immediately if present
                                    if uiComponent != nil {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            showCards = true
                                        }
                                        // Start text animation after a brief delay
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            startWordRevealAnimation()
                                        }
                                    } else {
                                        // No UI component, start text animation immediately
                                        startWordRevealAnimation()
                                    }
                                } else {
                                    // If already animated, show full text and cards immediately
                                    visibleWordCount = words.count
                                    showCards = true
                                }
                            }
                    }

                    Spacer(minLength: 0)
                        .frame(width: UIScreen.main.bounds.width * 0.02)
                }
            } else {
                // For tool activity messages, just show the cards immediately
                EmptyView()
                    .onAppear {
                        if !hasAnimated {
                            hasAnimated = true
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showCards = true
                            }
                        } else {
                            showCards = true
                        }
                    }
            }
        }
    }

    private func startWordRevealAnimation() {
        let totalWords = words.count

        for index in 0...totalWords {
            let delay = Double(index) * 0.05 // 50ms per word
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.15)) {
                    visibleWordCount = index
                }
            }
        }
    }
}

struct ActionConfirmationCard: View {
    let icon: String
    let message: String
    let colorName: String

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color(colorName))
                )

            // Message
            Text(message)
                .font(.normaInput(13))
                .foregroundColor(Color("NormaText"))
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(colorName).opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(colorName).opacity(0.3), lineWidth: 1)
        )
    }
}

struct ToolActivityView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            // Activity indicator
            ProgressView()
                .scaleEffect(0.7)
                .frame(width: 20, height: 20)

            // Message
            Text(message)
                .font(.normaInput(13))
                .foregroundColor(Color("NormaText").opacity(0.6))
                .italic()

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color("NormaText").opacity(0.04))
        )
    }
}

#Preview {
    VStack(spacing: 24) {
        AIMessageBubble(
            content: "Based on your spending last month, you spent $450 on groceries.\n\nThis is about 15% higher than your average.\n\nWould you like me to help you create a grocery budget?",
            revealDirection: .leftToRight
        )

        Divider()

        AIMessageBubble(
            content: "أنفقت 450 دولارًا على البقالة الشهر الماضي.\n\nهذا أعلى بنسبة 15٪ من المتوسط.\n\nهل تريد مني مساعدتك في إنشاء ميزانية البقالة؟",
            revealDirection: .rightToLeft
        )
    }
    .padding()
    .background(Color("NormaBackground"))
}
