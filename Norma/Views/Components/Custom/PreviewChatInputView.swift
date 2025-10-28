//
//  PreviewChatInputView.swift
//  Norma
//
//  Created by Claude on 10/25/25.
//

import SwiftUI

struct PreviewChatInputView: View {
    @Binding var text: String
    @Binding var showCapsules: Bool
    let isLoading: Bool
    let onSend: () -> Void
    let billsTotal: Double
    let budgetCount: Int
    let monthlySpend: Double
    let currencyCode: String?

    @State private var showBills = false
    @State private var showBudgets = false
    @State private var showExpenses = false
    @State private var visibleCapsules: Int = 0
    @State private var isExpanded: Bool = true
    @State private var pressedCapsule: String? = nil

    private var currentMonthAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: Date())
    }

    // Local currency formatter for preview mode
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode ?? "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
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

                // Tags rows below text field
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
                                    .font(.system(size: 11))
                                Text("Bills:")
                                    .font(.normaFinancial(15))
                                Text(formatCurrency(billsTotal))
                                    .font(.normaFinancial(15))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(Color("NormaPastelTeal"))
                            )
                            .foregroundColor(.white)
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
                                    .font(.system(size: 11))
                                Text("Budgets:")
                                    .font(.normaFinancial(15))
                                Text("\(budgetCount)")
                                    .font(.normaFinancial(15))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(Color("NormaPastelPurple"))
                            )
                            .foregroundColor(.white)
                        }
                        .buttonStyle(CapsulePressStyle())
                        .opacity(visibleCapsules > 1 ? 1 : 0)
                        .scaleEffect(visibleCapsules > 1 ? 1.0 : 0.3)
                        .offset(x: visibleCapsules > 1 ? 0 : -30)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: visibleCapsules)

                        Spacer()
                    }

                    // Second row: Monthly Spend
                    HStack(spacing: 8) {
                        // Monthly Spend tag
                        Button {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            showExpenses = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 11))
                                Text("\(currentMonthAbbreviation). Spend:")
                                    .font(.normaFinancial(15))
                                Text(formatCurrency(monthlySpend))
                                    .font(.normaFinancial(15))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(Color("NormaPastelCoral"))
                            )
                            .foregroundColor(.white)
                        }
                        .buttonStyle(CapsulePressStyle())
                        .opacity(visibleCapsules > 2 ? 1 : 0)
                        .scaleEffect(visibleCapsules > 2 ? 1.0 : 0.3)
                        .offset(x: visibleCapsules > 2 ? 0 : -30)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: visibleCapsules)

                        Spacer()

                        // Send button
                        Button(action: onSend) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "2C2C2C") ?? Color.black)
                                    .frame(width: 44, height: 44)

                                Image(systemName: "arrow.up")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                        .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.3 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
                    }
                }
                .frame(height: isExpanded ? nil : 0)
                .opacity(isExpanded ? 1 : 0)
                .clipped()
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
        .onChange(of: showCapsules) { _, newValue in
            if newValue {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.prepare()

                // Animate capsules appearing with staggered delays + haptics
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
                    visibleCapsules = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    impactFeedback.impactOccurred(intensity: 0.6)
                }

                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4)) {
                    visibleCapsules = 2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    impactFeedback.impactOccurred(intensity: 0.6)
                }

                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) {
                    visibleCapsules = 3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    impactFeedback.impactOccurred(intensity: 0.6)
                }
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
            PreviewModeBillsView()
        }
        .sheet(isPresented: $showBudgets) {
            PreviewModeBudgetsView()
        }
        .sheet(isPresented: $showExpenses) {
            PreviewModeExpensesView()
        }
    }
}

// Preview mode placeholder views
struct PreviewModeBillsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color("NormaPastelTeal"))

                Text("Bills Preview")
                    .font(.normaHeadline())

                Text("This is preview mode! In the full app, you'll see all your bills here.")
                    .normaBody()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
            .navigationTitle("My Bills")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PreviewModeBudgetsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color("NormaPastelPurple"))

                Text("Budgets Preview")
                    .font(.normaHeadline())

                Text("This is preview mode! In the full app, you'll see all your budgets here.")
                    .normaBody()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
            .navigationTitle("My Budgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PreviewModeExpensesView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color("NormaPastelCoral"))

                Text("Expenses Preview")
                    .font(.normaHeadline())

                Text("This is preview mode! In the full app, you'll see all your expenses here.")
                    .normaBody()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
            .navigationTitle("My Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    @Previewable @State var showCapsules = true

    return PreviewChatInputView(
        text: $text,
        showCapsules: $showCapsules,
        isLoading: false,
        onSend: { print("Send tapped") },
        billsTotal: 1635.99,
        budgetCount: 2,
        monthlySpend: 135.50,
        currencyCode: "USD"
    )
    .background(Color("NormaBackground"))
    .preferredColorScheme(.dark)
}
