//
//  ForecastSheet.swift
//  Norma
//
//  Income vs bills overview. Reached via the chart icon in the notes-list
//  bottom bar.
//

import SwiftUI

struct ForecastSheet: View {
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var billViewModel: BillViewModel

    @State private var showBills = false

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private let accentPurple = Color(red: 0x96/255, green: 0x76/255, blue: 0xD9/255)

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroBlock
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                    nextBillSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showBills) {
            BillsView()
                .environmentObject(sessionViewModel)
                .environmentObject(billViewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(monthShortLabel.uppercased()) AFTER BILLS")
                .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                .tracking(0.66)
                .foregroundStyle(mutedText)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(formatCurrency(netAfterBills))
                    .font(.system(size: 72, weight: .heavy))
                    .tracking(-3.24)
                    .foregroundStyle(cream)
                Text(".")
                    .font(.system(size: 72, weight: .heavy))
                    .tracking(-3.24)
                    .foregroundStyle(accentPurple)
            }

            HStack(spacing: 12) {
                Text("\(formatCurrency(monthlyIncome)) income")
                    .font(.custom(FontFamily.Rubik.medium, size: 12))
                    .foregroundStyle(mutedText)
                Text("·")
                    .font(.custom(FontFamily.Rubik.medium, size: 12))
                    .foregroundStyle(dimText)
                Text("\(formatCurrency(totalBillsForMonth)) bills")
                    .font(.custom(FontFamily.Rubik.medium, size: 12))
                    .foregroundStyle(mutedText)
            }
        }
    }

    // MARK: - Next Bill

    @ViewBuilder
    private var nextBillSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("next bill up")
                .font(.custom(FontFamily.Rubik.medium, size: 18))
                .foregroundStyle(mutedText)

            if let bill = nextBill {
                nextBillCard(bill)
            } else {
                noBillsCard
            }

            if !monthlyBills.isEmpty {
                viewAllPill
                    .padding(.top, 8)
            }
        }
    }

    @ViewBuilder
    private func nextBillCard(_ bill: Bill) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accentPurple)
                    .frame(width: 6, height: 6)
                Text(dueLabel(for: bill))
                    .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                    .tracking(0.88)
                    .textCase(.uppercase)
                    .foregroundStyle(accentPurple)
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(formatCurrency(bill.amount))
                    .font(.system(size: 32, weight: .bold))
                    .tracking(-0.64)
                    .foregroundStyle(accentPurple)
                Text(bill.name.lowercased())
                    .font(.custom(FontFamily.Rubik.medium, size: 14))
                    .foregroundStyle(cream)
                Text(shortDate(bill.effectiveDueDate))
                    .font(.custom(FontFamily.Rubik.regular, size: 13).italic())
                    .foregroundStyle(dimText)
            }
            .padding(.top, 2)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(accentPurple.opacity(0.08)))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accentPurple.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        )
    }

    private var noBillsCard: some View {
        Text("nothing due this month")
            .font(.custom(FontFamily.Rubik.medium, size: 13))
            .foregroundStyle(dimText)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18).fill(cream.opacity(0.04)))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(cream.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
    }

    private var viewAllPill: some View {
        HStack {
            Spacer()
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                showBills = true
            } label: {
                HStack(spacing: 10) {
                    Text("view all \(monthlyBills.count) \(monthlyBills.count == 1 ? "bill" : "bills")")
                        .font(.custom(FontFamily.Rubik.medium, size: 13))
                        .foregroundStyle(cream)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(cream)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .overlay(
                    Capsule().stroke(cream.opacity(0.32), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                )
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: - Computed

    private var displayedMonthDate: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        return cal.date(from: comps) ?? Date()
    }

    private var monthShortLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f.string(from: displayedMonthDate).lowercased()
    }

    private var monthlyIncome: Double {
        sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private var monthlyBills: [Bill] {
        let cal = Calendar.current
        return billViewModel.bills.filter { bill in
            cal.isDate(bill.effectiveDueDate, equalTo: displayedMonthDate, toGranularity: .month)
        }
    }

    private var totalBillsForMonth: Double {
        monthlyBills.reduce(0) { $0 + $1.amount }
    }

    private var netAfterBills: Double {
        max(0, monthlyIncome - totalBillsForMonth)
    }

    private var nextBill: Bill? {
        monthlyBills
            .filter { $0.status != .paid }
            .min(by: { $0.effectiveDueDate < $1.effectiveDueDate })
    }

    // MARK: - Formatting

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(Int(amount))"
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date).lowercased()
    }

    private func dueLabel(for bill: Bill) -> String {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let due = cal.startOfDay(for: bill.effectiveDueDate)
        let days = cal.dateComponents([.day], from: now, to: due).day ?? 0
        if days < 0 { return "overdue \(-days) \(-days == 1 ? "day" : "days")" }
        if days == 0 { return "due today" }
        return "due in \(days) \(days == 1 ? "day" : "days")"
    }
}

#Preview {
    Color.black
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ForecastSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
}
