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

    init(content: String, uiComponent: UIComponent? = nil, revealDirection: TextRevealDirection = .leftToRight) {
        self.content = content
        self.uiComponent = uiComponent
        self.revealDirection = revealDirection
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Markdown text using native SwiftUI with word-by-word reveal
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(try! AttributedString(markdown: words.prefix(visibleWordCount).joined(), options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                        .font(.normaInput(16))
                        .lineSpacing(4)
                        .foregroundColor(Color("NormaText"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onAppear {
                            startWordRevealAnimation()
                        }
                }

                Spacer(minLength: 0)
                    .frame(width: UIScreen.main.bounds.width * 0.02)
            }

            // Cards second (if present)
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

                // Show cards after all words are revealed
                if index == totalWords && uiComponent != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showCards = true
                        }
                    }
                }
            }
        }
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
