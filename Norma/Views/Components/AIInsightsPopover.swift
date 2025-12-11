//
//  AIInsightsPopover.swift
//  Norma
//
//  Created by Claude on 12/5/25.
//

import SwiftUI

struct AIInsightsPopover: View {
    @Binding var isPresented: Bool

    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var budgetViewModel: BudgetViewModel

    @State private var appeared = false
    @State private var isGenerating = false
    @State private var insightText: String? = nil
    @State private var generatedAt: Date? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Dismiss overlay
            Color.black.opacity(appeared ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Popover content - anchored to top right
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Financial Insights")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 20))
                        .foregroundColor(.primary)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }

                // Description
                Text("Get personalized insights based on your bills, spending, budgets, and arcs.")
                    .font(.custom(FontFamily.Rubik.regular, size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Insight display area
                VStack(alignment: .leading, spacing: 12) {
                    if isGenerating {
                        // Loading state
                        HStack(spacing: 12) {
                            ProgressView()
                                .tint(Color("NormaPastelTeal"))

                            Text("Analyzing your finances...")
                                .font(.custom(FontFamily.Rubik.regular, size: 14))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                    } else if let error = errorMessage {
                        // Error state
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 28))
                                .foregroundColor(Color("NormaPastelCoral"))

                            Text(error)
                                .font(.custom(FontFamily.Rubik.regular, size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else if let insight = insightText {
                        // Show insight
                        Text(insight)
                            .font(.custom(FontFamily.Rubik.regular, size: 15))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)

                        // Timestamp and disclaimer
                        if let date = generatedAt {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 11))
                                    Text(relativeTimeString(from: date))
                                        .font(.custom(FontFamily.Rubik.regular, size: 12))
                                }
                                .foregroundColor(.secondary)

                                // Disclaimer
                                HStack(spacing: 4) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 10))
                                    Text("Norma can make mistakes. Please double-check insights.")
                                        .font(.custom(FontFamily.Rubik.regular, size: 11))
                                }
                                .foregroundColor(.secondary.opacity(0.7))
                            }
                        }
                    } else {
                        // Empty state
                        VStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 32))
                                .foregroundColor(Color("NormaPastelTeal").opacity(0.5))

                            Text("Tap generate to get your first insight")
                                .font(.custom(FontFamily.Rubik.regular, size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.05))
                )

                // Generate button
                Button {
                    generateInsight()
                } label: {
                    HStack(spacing: 8) {
                        if isGenerating {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .medium))
                        }

                        Text(insightText == nil ? "Generate Insight" : "Refresh Insight")
                            .font(.custom(FontFamily.Rubik.medium, size: 15))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color("NormaPastelTeal"))
                    )
                }
                .disabled(isGenerating)
                .opacity(isGenerating ? 0.7 : 1)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.clear)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 24))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            )
            .padding(.top, 60)
            .padding(.horizontal, 16)
            .scaleEffect(appeared ? 1 : 0.9, anchor: .topTrailing)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private func generateInsight() {
        isGenerating = true
        errorMessage = nil

        Task {
            do {
                // Gather financial data
                let currency = sessionViewModel.currentUser?.settings.currency ?? "USD"
                let monthlyIncome = sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
                let freedomFund = sessionViewModel.currentUser?.settings.freedomFund ?? 0
                let totalBills = billViewModel.bills.reduce(0) { $0 + $1.amount }

                // Calculate upcoming bills (next 7 days)
                let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                let upcomingBills = billViewModel.bills.filter { $0.dueDate <= sevenDaysFromNow && $0.dueDate >= Date() }
                let upcomingBillsCount = upcomingBills.count
                let upcomingBillsTotal = upcomingBills.reduce(0) { $0 + $1.amount }

                // Monthly spending
                let totalMonthlySpend = expenseViewModel.totalExpenses

                // Budgets
                let budgetCount = budgetViewModel.budgets.count
                let averageBudgetUtilization: Double = {
                    guard budgetCount > 0 else { return 0 }
                    let totalUtilization = budgetViewModel.budgets.reduce(0.0) { total, budget in
                        guard budget.amount > 0 else { return total }
                        return total + (budget.currentSpent / budget.amount)
                    }
                    return totalUtilization / Double(budgetCount)
                }()

                // Arc state (simplified)
                let arcState: String = {
                    let afterBills = monthlyIncome - totalBills
                    if afterBills > totalMonthlySpend * 1.2 {
                        return "In flow (spending well under income)"
                    } else if afterBills > totalMonthlySpend {
                        return "Stable (spending close to limit)"
                    } else {
                        return "Drifting (spending exceeds available funds)"
                    }
                }()

                // Generate the prompt
                let systemPrompt = NormaSystemPrompts.insightPrompt(
                    currency: currency,
                    monthlyIncome: monthlyIncome,
                    freedomFund: freedomFund,
                    totalBills: totalBills,
                    upcomingBillsCount: upcomingBillsCount,
                    upcomingBillsTotal: upcomingBillsTotal,
                    totalMonthlySpend: totalMonthlySpend,
                    budgetCount: budgetCount,
                    averageBudgetUtilization: averageBudgetUtilization,
                    arcState: arcState
                )

                // Call API
                let messages = [AnthropicMessage(role: "user", content: .text("Generate my financial insight."))]
                let response = try await AnthropicService.shared.sendMessage(
                    messages: messages,
                    systemPrompt: systemPrompt,
                    maxTokens: 200
                )

                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        insightText = response.trimmingCharacters(in: .whitespacesAndNewlines)
                        generatedAt = Date()
                        isGenerating = false
                    }
                }

            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        errorMessage = "Failed to generate insight. Please try again."
                        isGenerating = false
                    }
                }
                print("Insight generation error: \(error)")
            }
        }
    }

    private func relativeTimeString(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "Generated just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "Generated \(minutes) min\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "Generated \(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "Generated \(days) day\(days == 1 ? "" : "s") ago"
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            appeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)

    return ZStack {
        Color("NormaBackground")
            .ignoresSafeArea()

        AIInsightsPopover(isPresented: .constant(true))
    }
    .environmentObject(sessionViewModel)
    .environmentObject(BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
    .environmentObject(ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
    .environmentObject(BudgetViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
}
