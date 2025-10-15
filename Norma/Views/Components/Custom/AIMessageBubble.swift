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

    @State private var revealedLines: Int = -1

    private var lines: [String] {
        content.components(separatedBy: "\n")
    }

    init(content: String, uiComponent: UIComponent? = nil, revealDirection: TextRevealDirection = .leftToRight) {
        self.content = content
        self.uiComponent = uiComponent
        self.revealDirection = revealDirection
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Text first
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: revealDirection.alignment, spacing: 4) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(.system(size: 16))
                            .lineSpacing(4)
                            .foregroundColor(Color("NormaText"))
                            .opacity(index <= revealedLines ? 1 : 0)
                            .offset(x: index <= revealedLines ? 0 : revealDirection.offset)
                            .frame(maxWidth: .infinity, alignment: revealDirection == .leftToRight ? .leading : .trailing)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onAppear {
                    startAnimation()
                }

                Spacer(minLength: 0)
                    .frame(width: UIScreen.main.bounds.width * 0.02)
            }

            // Cards second (if present)
            if let component = uiComponent {
                switch component {
                case .billCards(let bills):
                    BillCardStack(bills: bills)
                case .expenseCards(let expenses):
                    ExpenseCardStack(expenses: expenses)
                case .budgetCards(let budgets):
                    BudgetCardStack(budgets: budgets)
                }
            }
        }
    }

    private func startAnimation() {
        for i in 0..<lines.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                withAnimation(.easeOut(duration: 0.25)) {
                    revealedLines = i
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
