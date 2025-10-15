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
    let billsTotal: Double
    let budgetCount: Int
    let monthlySpend: Double

    @State private var showBills = false
    @State private var showBudgets = false
    @State private var showExpenses = false

    private var currentMonthAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            // Floating input container
            VStack(alignment: .leading, spacing: 12) {
                // Text field
                TextField("Chat with Norma", text: $text, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16))
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .onSubmit {
                        if !text.isEmpty {
                            onSend()
                        }
                    }
                    .padding(.top, 4)

                // Tags rows below text field
                VStack(alignment: .leading, spacing: 8) {
                    // First row: Bills and Budgets
                    HStack(spacing: 8) {
                        // Bills tag
                        Button {
                            showBills = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 11))
                                Text("Bills:")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                Text("$\(String(format: "%.2f", billsTotal))")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.85, green: 0.82, blue: 0.92),
                                                Color(red: 0.88, green: 0.85, blue: 0.94)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color(red: 0.75, green: 0.70, blue: 0.85).opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(Color(red: 0.50, green: 0.45, blue: 0.65))
                        }

                        // Budgets tag
                        Button {
                            showBudgets = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.pie.fill")
                                    .font(.system(size: 11))
                                Text("Budgets:")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                Text("\(budgetCount)")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.80, green: 0.90, blue: 0.88),
                                                Color(red: 0.82, green: 0.92, blue: 0.90)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color(red: 0.65, green: 0.80, blue: 0.78).opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(Color(red: 0.40, green: 0.60, blue: 0.58))
                        }

                        Spacer()
                    }

                    // Second row: Monthly Spend
                    HStack(spacing: 8) {
                        // Monthly Spend tag
                        Button {
                            showExpenses = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 11))
                                Text("\(currentMonthAbbreviation). Spend:")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                Text("$\(String(format: "%.2f", monthlySpend))")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.96, green: 0.88, blue: 0.85),
                                                Color(red: 0.98, green: 0.90, blue: 0.87)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color(red: 0.88, green: 0.75, blue: 0.70).opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(Color(red: 0.70, green: 0.50, blue: 0.45))
                        }

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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color("NormaInputField"))
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

#Preview {
    @Previewable @State var text = ""

    return ChatInputView(
        text: $text,
        isLoading: false,
        onSend: { print("Send tapped") },
        billsTotal: 1234.56,
        budgetCount: 3,
        monthlySpend: 2567.89
    )
    .background(Color("NormaBackground"))
}
