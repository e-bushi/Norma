//
//  OnboardingCashCardMixView.swift
//  Norma
//
//  O4a — "how do you mostly pay?". Three-segment draggable bar
//  (card / cash / transfers) with live percentages summing to 100.
//  Lavender dither shader background, dark card legend.
//

import SwiftUI
import UIKit

struct OnboardingCashCardMixView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    let onContinue: () -> Void
    let onBack: () -> Void

    // Two split positions in 0...1. Card occupies [0, splitA], cash [splitA, splitB],
    // transfers [splitB, 1]. Defaults from artboard: 60/30/10.
    @State private var splitA: CGFloat = 0.60
    @State private var splitB: CGFloat = 0.90

    @State private var subtitleAppeared = false
    @State private var cardAppeared = false
    @State private var ctaAppeared = false

    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let minSegment: CGFloat = 0.05

    private var cardPercent: Int { Int((splitA * 100).rounded()) }
    private var cashPercent: Int { Int(((splitB - splitA) * 100).rounded()) }
    private var transfersPercent: Int { max(0, 100 - cardPercent - cashPercent) }

    var body: some View {
        ZStack {
            NormaPalette.canvas.ignoresSafeArea()

            DitherShaderView(intensity: 1.0)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            LinearGradient(
                stops: [
                    .init(color: NormaPalette.canvas.opacity(0),    location: 0.00),
                    .init(color: NormaPalette.canvas.opacity(0),    location: 0.18),
                    .init(color: NormaPalette.canvas.opacity(0.55), location: 0.40),
                    .init(color: NormaPalette.canvas.opacity(0.85), location: 0.62),
                    .init(color: NormaPalette.canvas,               location: 0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                backButton
                    .padding(.top, 8)

                Spacer()

                titleView
                    .padding(.bottom, 12)

                Text("drag the segments to set your mix.")
                    .font(.system(size: 14))
                    .foregroundStyle(NormaPalette.inkSubtle)
                    .opacity(subtitleAppeared ? 1 : 0)
                    .offset(y: subtitleAppeared ? 0 : 8)
                    .padding(.bottom, 22)

                cardView
                    .opacity(cardAppeared ? 1 : 0)
                    .offset(y: cardAppeared ? 0 : 12)

                Spacer().frame(height: 22)

                continueButton
                    .opacity(ctaAppeared ? 1 : 0)
                    .offset(y: ctaAppeared ? 0 : 12)

                Spacer().frame(height: 36)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            impactGenerator.prepare()
            // Restore from view model if user navigated back.
            let card = CGFloat(onboardingViewModel.cardPercent / 100.0)
            let cash = CGFloat(onboardingViewModel.cashPercent / 100.0)
            if card > 0 || cash > 0 {
                splitA = max(minSegment, min(CGFloat(1) - 2 * minSegment, card))
                splitB = max(splitA + minSegment, min(CGFloat(1) - minSegment, splitA + cash))
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.50)) { subtitleAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.65)) { cardAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.80)) { ctaAppeared = true }
        }
    }

    // MARK: - Subviews

    private var backButton: some View {
        Button(action: {
            impactGenerator.impactOccurred()
            onBack()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(NormaPalette.ink)
                .frame(width: 36, height: 36)
                .background(Circle().fill(NormaPalette.ink.opacity(0.05)))
                .overlay(Circle().strokeBorder(NormaPalette.ink.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var titleView: some View {
        WaveTextView(
            text: "how do you mostly pay?",
            font: .system(size: 56, weight: .bold),
            color: NormaPalette.ink,
            isAnimating: true,
            alignment: .leading,
            tracking: -1.5,
            wordSpacing: 12,
            lineSpacing: 0
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cardView: some View {
        VStack(spacing: 22) {
            segmentBar
            legend
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 26)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.125))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(NormaPalette.ink.opacity(0.06), lineWidth: 1)
        )
    }

    private var segmentBar: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let aPx = splitA * w
            let bPx = splitB * w

            ZStack(alignment: .leading) {
                HStack(spacing: 4) {
                    segmentCell(
                        width: max(0, aPx - 2),
                        bg: NormaPalette.lavender,
                        textColor: NormaPalette.canvas,
                        percent: cardPercent
                    )
                    segmentCell(
                        width: max(0, (bPx - aPx) - 4),
                        bg: NormaPalette.lavender.opacity(0.40),
                        textColor: NormaPalette.ink,
                        percent: cashPercent
                    )
                    segmentCell(
                        width: max(0, (w - bPx) - 2),
                        bg: NormaPalette.lavender.opacity(0.20),
                        textColor: NormaPalette.ink,
                        percent: transfersPercent
                    )
                }

                handle()
                    .position(x: aPx, y: 28)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let raw = value.location.x / w
                                let clamped = max(minSegment, min(splitB - minSegment, raw))
                                if abs(clamped - splitA) > 0.001 {
                                    splitA = clamped
                                }
                            }
                            .onEnded { _ in impactGenerator.impactOccurred() }
                    )

                handle()
                    .position(x: bPx, y: 28)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let raw = value.location.x / w
                                let clamped = max(splitA + minSegment, min(1 - minSegment, raw))
                                if abs(clamped - splitB) > 0.001 {
                                    splitB = clamped
                                }
                            }
                            .onEnded { _ in impactGenerator.impactOccurred() }
                    )
            }
        }
        .frame(height: 56)
    }

    private func segmentCell(width: CGFloat, bg: Color, textColor: Color, percent: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(bg)
            Text("\(percent)%")
                .font(.system(size: percent < 12 ? 11 : 14, weight: .bold))
                .foregroundStyle(textColor)
        }
        .frame(width: width, height: 56)
    }

    private func handle() -> some View {
        // Visible bar plus an oversized invisible hit area for easy dragging.
        ZStack {
            Color.clear
                .frame(width: 36, height: 64)
                .contentShape(Rectangle())
            RoundedRectangle(cornerRadius: 1.5)
                .fill(NormaPalette.ink.opacity(0.85))
                .frame(width: 3, height: 32)
                .shadow(color: NormaPalette.canvas.opacity(0.5), radius: 4, x: 0, y: 0)
        }
    }

    private var legend: some View {
        VStack(spacing: 14) {
            legendRow(
                color: NormaPalette.lavender,
                label: "card",
                description: "credit, debit, apple pay"
            )
            legendRow(
                color: NormaPalette.lavender.opacity(0.40),
                label: "cash",
                description: "bills in your wallet"
            )
            legendRow(
                color: NormaPalette.lavender.opacity(0.20),
                label: "transfers",
                description: "venmo, zelle, wise"
            )
        }
    }

    private func legendRow(color: Color, label: String, description: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(NormaPalette.ink)
            Spacer(minLength: 8)
            Text(description)
                .font(.system(size: 12))
                .foregroundStyle(NormaPalette.inkSubtle)
        }
    }

    private var continueButton: some View {
        Button(action: {
            impactGenerator.impactOccurred()
            persist()
            onContinue()
        }) {
            HStack(spacing: 8) {
                Text("continue")
                    .font(.system(size: 15, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(NormaPalette.canvas)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(Capsule().fill(NormaPalette.lavender))
            .shadow(color: NormaPalette.lavender.opacity(0.40), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    private func persist() {
        onboardingViewModel.cardPercent = Double(cardPercent)
        onboardingViewModel.cashPercent = Double(cashPercent)
        onboardingViewModel.transfersPercent = Double(transfersPercent)
    }
}

#Preview {
    OnboardingCashCardMixView(onContinue: {}, onBack: {})
        .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
}
