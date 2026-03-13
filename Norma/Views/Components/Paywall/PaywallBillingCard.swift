//
//  PaywallBillingCard.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import SwiftUI

struct PaywallPlanCard: View {
    let title: String
    let price: String
    var badge: String? = nil
    var strikethroughPrice: String? = nil
    let isSelected: Bool
    let action: () -> Void

    @State private var stripesVisible = false

    private let accentColor = Color("NormaPastelPurple")

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? accentColor : Color("NormaText").opacity(0.2), lineWidth: 2)
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 10, height: 10)
                    }
                }

                // Title + price
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                            .foregroundColor(Color("NormaText"))

                        if let badge = badge {
                            Text(badge)
                                .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(accentColor)
                                )
                        }
                    }

                    HStack(spacing: 6) {
                        Text(price)
                            .font(.custom(FontFamily.Rubik.regular, size: 14))
                            .foregroundColor(Color("NormaText").opacity(0.5))

                        if let strikethrough = strikethroughPrice {
                            Text(strikethrough)
                                .font(.custom(FontFamily.Rubik.regular, size: 13))
                                .foregroundColor(Color("NormaText").opacity(0.3))
                                .strikethrough(color: Color("NormaText").opacity(0.3))
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? accentColor.opacity(0.08) : Color.clear)

                    if isSelected {
                        DiagonalStripesPattern(
                            lineColor: accentColor.opacity(0.07),
                            spacing: 10,
                            lineWidth: 0.8
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .opacity(stripesVisible ? 1 : 0)
                        .mask(
                            GeometryReader { geo in
                                Rectangle()
                                    .frame(width: stripesVisible ? geo.size.width : 0)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? accentColor.opacity(0.5) : Color("NormaText").opacity(0.08),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(PlanCardButtonStyle())
        .onChange(of: isSelected) { _, selected in
            if selected {
                stripesVisible = false
                withAnimation(.easeOut(duration: 0.45).delay(0.05)) {
                    stripesVisible = true
                }
            } else {
                stripesVisible = false
            }
        }
        .onAppear {
            if isSelected {
                // Slight delay so initial load also animates
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.45)) {
                        stripesVisible = true
                    }
                }
            }
        }
    }
}

// MARK: - Diagonal Stripes Pattern

private struct DiagonalStripesPattern: View {
    var lineColor: Color = .gray
    var spacing: CGFloat = 10
    var lineWidth: CGFloat = 0.8

    var body: some View {
        Canvas { context, size in
            let totalLines = Int((size.width + size.height) / spacing) + 1

            for i in 0..<totalLines {
                let offset = CGFloat(i) * spacing

                var path = Path()
                let startX = offset
                let startY: CGFloat = 0
                let endX = offset - size.height
                let endY = size.height

                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))

                context.stroke(
                    path,
                    with: .color(lineColor),
                    lineWidth: lineWidth
                )
            }
        }
    }
}

// MARK: - Button Style

struct PlanCardButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
