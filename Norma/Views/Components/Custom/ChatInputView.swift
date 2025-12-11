//
//  ChatInputView.swift
//  Norma
//
//  Created by Claude on 5/10/25.
//

import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    let onVoiceInput: () -> Void
    let billsTotal: Double
    let budgetCount: Int
    let monthlySpend: Double

    @State private var showBills = false
    @State private var showBudgets = false
    @State private var showExpenses = false
    @State private var visibleCapsules: Int = 0
    @State private var isExpanded: Bool = true
    @State private var pressedCapsule: String? = nil
    @EnvironmentObject var profileViewModel: ProfileViewModel

    private var currentMonthAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: Date())
    }

    private var isSendButtonActive: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    var body: some View {
        VStack(spacing: 0) {
            // Floating input container
            VStack(alignment: .leading, spacing: 12) {
                // Text field
                TextField("Chat with Norma", text: $text, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.normaInput())
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .onSubmit {
                        if !text.isEmpty {
                            onSend()
                        }
                    }
                    .padding(.vertical, 8)

                // Tags and buttons row
                HStack(alignment: .bottom, spacing: 12) {
                    // Tags on the left
                    VStack(alignment: .leading, spacing: 8) {
                        // First row: Bills and Budgets
                        HStack(spacing: 8) {
                            // Bills tag
                            Button {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                showBills = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 12))
                                    Text("Bills: \(profileViewModel.formatCurrency(billsTotal))")
                                        .font(.normaFinancial(14))
                                        .lineLimit(1)
                                        .fixedSize()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color("NormaPastelTeal").opacity(0.15))
                                        .glassEffect(in: Capsule())
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color("NormaPastelTeal").opacity(0.3), lineWidth: 0.5)
                                )
                                .foregroundColor(Color("NormaPastelTeal"))
                            }
                            .buttonStyle(CapsulePressStyle())
                            .opacity(visibleCapsules > 0 ? 1 : 0)
                            .scaleEffect(visibleCapsules > 0 ? 1.0 : 0.3)
                            .offset(x: visibleCapsules > 0 ? 0 : -30)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: visibleCapsules)

                            // Budgets tag
                            Button {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                showBudgets = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chart.pie.fill")
                                        .font(.system(size: 12))
                                    Text("Budgets: \(budgetCount)")
                                        .font(.normaFinancial(14))
                                        .lineLimit(1)
                                        .fixedSize()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color("NormaPastelPurple").opacity(0.15))
                                        .glassEffect(in: Capsule())
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color("NormaPastelPurple").opacity(0.3), lineWidth: 0.5)
                                )
                                .foregroundColor(Color("NormaPastelPurple"))
                            }
                            .buttonStyle(CapsulePressStyle())
                            .opacity(visibleCapsules > 1 ? 1 : 0)
                            .scaleEffect(visibleCapsules > 1 ? 1.0 : 0.3)
                            .offset(x: visibleCapsules > 1 ? 0 : -30)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: visibleCapsules)
                        }

                        // Second row: Monthly Spend
                        Button {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            showExpenses = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 12))
                                Text("\(currentMonthAbbreviation). Spend: \(profileViewModel.formatCurrency(monthlySpend))")
                                    .font(.normaFinancial(14))
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color("NormaPastelCoral").opacity(0.15))
                                    .glassEffect(in: Capsule())
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color("NormaPastelCoral").opacity(0.3), lineWidth: 0.5)
                            )
                            .foregroundColor(Color("NormaPastelCoral"))
                        }
                        .buttonStyle(CapsulePressStyle())
                        .opacity(visibleCapsules > 2 ? 1 : 0)
                        .scaleEffect(visibleCapsules > 2 ? 1.0 : 0.3)
                        .offset(x: visibleCapsules > 2 ? 0 : -30)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: visibleCapsules)
                    }

                    Spacer()

                    // Dual-purpose voice/send button
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        if isSendButtonActive {
                            onSend()
                        } else {
                            onVoiceInput()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isSendButtonActive ? Color.black : Color.gray.opacity(0.15))
                                .frame(width: 44, height: 44)

                            // Waveform icon when empty
                            Image(systemName: "waveform")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                                .opacity(isSendButtonActive ? 0 : 1)
                                .scaleEffect(isSendButtonActive ? 0.5 : 1)

                            // Send arrow when has text
                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .opacity(isSendButtonActive ? 1 : 0)
                                .scaleEffect(isSendButtonActive ? 1 : 0.5)
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: isSendButtonActive)
                    }
                    .buttonStyle(SendButtonStyle())
                    .disabled(isLoading)
                }
                .frame(height: isExpanded ? nil : 0)
                .opacity(isExpanded ? 1 : 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.clear)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 28))
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.gray.opacity(0.22), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .padding(.top, 16)
        .onAppear {
            // Animate capsules appearing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                visibleCapsules = 3
            }
        }
        .background(
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color("NormaBackground"))
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(0.6), location: 0.5),
                                .init(color: .white.opacity(0.9), location: 0.7),
                                .init(color: .white, location: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Solid extension below
                Rectangle()
                    .fill(Color("NormaBackground"))
                    .frame(height: 20)
            }
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showBills) {
            BillHomeView()
        }
        .sheet(isPresented: $showBudgets) {
            MyBudgetView()
        }
        .sheet(isPresented: $showExpenses) {
            IncomeAndExpenseView()
        }
    }
}

// Custom button style for capsule press animation
struct CapsulePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Custom button style for send button press animation
struct SendButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    @Previewable @State var text = ""

    return ChatInputView(
        text: $text,
        isLoading: false,
        onSend: { print("Send tapped") },
        onVoiceInput: { print("Voice input tapped") },
        billsTotal: 1234.56,
        budgetCount: 3,
        monthlySpend: 2567.89
    )
    .background(Color("NormaBackground"))
}
