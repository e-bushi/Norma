//
//  ArcCountView.swift
//  Norma
//
//  Created by Claude on 12/18/25.
//

import SwiftUI
import SceneKit

struct ArcCountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    let arcCount: Int
    let freedomFund: Double
    let totalMonthlyBills: Double
    let currency: String

    // Sheet state
    @State private var showFreedomFundEdit = false
    @State private var showInfoPopover = false

    // Staggered animation states
    @State private var heroVisible = false
    @State private var arcCountVisible = false
    @State private var statsVisible = false
    @State private var reminderVisible = false
    @State private var monthsHeaderVisible = false
    @State private var coinVisibility: [Bool] = Array(repeating: false, count: 12)

    // Haptic generator
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    // Progress to next arc (0.0 to 1.0)
    private var progressToNextArc: CGFloat {
        guard totalMonthlyBills > 0 else { return 0 }
        let currentArcProgress = freedomFund.truncatingRemainder(dividingBy: totalMonthlyBills)
        return CGFloat(currentArcProgress / totalMonthlyBills)
    }

    // Amount needed for next arc
    private var amountToNextArc: Double {
        guard totalMonthlyBills > 0 else { return 0 }
        let nextArcTarget = Double(arcCount + 1) * totalMonthlyBills
        return max(0, nextArcTarget - freedomFund)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    // Get months starting from next month
    private var upcomingMonths: [(name: String, shortName: String, isCovered: Bool)] {
        let calendar = Calendar.current
        let now = Date()

        return (1...12).map { offset in
            guard let futureDate = calendar.date(byAdding: .month, value: offset, to: now) else {
                return (name: "", shortName: "", isCovered: false)
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            let fullName = formatter.string(from: futureDate)

            formatter.dateFormat = "MMM"
            let shortName = formatter.string(from: futureDate)

            // A month is covered if its position (1-indexed) <= arcCount
            let isCovered = offset <= arcCount

            return (name: fullName, shortName: shortName, isCovered: isCovered)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero coin with glow and progress ring
                    VStack(spacing: 16) {
                        ZStack {
                            // Glow effect behind coin (color matches current tier)
                            Circle()
                                .fill(CoinTierService.currentCoinTier(for: arcCount).glowColor.opacity(0.10))
                                .frame(width: 160, height: 160)
                                .blur(radius: 30)
                                .scaleEffect(heroVisible ? 1 : 0.5)
                                .opacity(heroVisible ? 1 : 0)

                            // Progress ring background
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                                .frame(width: 140, height: 140)
                                .scaleEffect(heroVisible ? 1 : 0.8)
                                .opacity(heroVisible ? 1 : 0)

                            // Progress ring foreground
                            Circle()
                                .trim(from: 0, to: heroVisible ? progressToNextArc : 0)
                                .stroke(
                                    Color("NormaPastelTeal"),
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .frame(width: 140, height: 140)
                                .rotationEffect(.degrees(-90))

                            // Spinning coin (proper SceneKit rotation)
                            HeroCoin3DView(fileName: CoinTierService.currentCoinFileName(for: arcCount))
                                .id(CoinTierService.currentCoinFileName(for: arcCount))
                                .frame(width: 100, height: 100)
                                .scaleEffect(heroVisible ? 1 : 0)
                                .opacity(heroVisible ? 1 : 0)
                        }

                        // Arc count display
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Text("x")
                                    .font(.normaHeadline(32))
                                    .foregroundColor(.secondary)
                                Text("\(arcCount)")
                                    .font(.normaHeadline(56))
                                    .foregroundColor(.primary)
                            }

                            // Progress capsule
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("NormaPastelTeal"))
                                Text("\(formatCurrency(amountToNextArc)) to next arc")
                                    .font(.normaInput(13))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.gray.opacity(0.08))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.gray.opacity(0.12), lineWidth: 0.5)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .opacity(arcCountVisible ? 1 : 0)
                    .offset(y: arcCountVisible ? 0 : 20)

                    // Stats section (row-based like ExpenseCalendarView)
                    VStack(spacing: 16) {
                        // Freedom Fund
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "banknote")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color("NormaPastelTeal"))
                                Text("Freedom Fund")
                                    .font(.normaInput(15))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(formatCurrency(freedomFund))
                                .font(.normaFinancial(16))
                                .foregroundColor(Color("NormaPastelTeal"))
                        }

                        // Monthly Bills
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color("NormaPastelPurple"))
                                Text("Monthly Bills")
                                    .font(.normaInput(15))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(formatCurrency(totalMonthlyBills))
                                .font(.normaFinancial(16))
                                .foregroundColor(.primary)
                        }

                        // Arc Count
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color("NormaPastelBeige"))
                                Text("Months Protected")
                                    .font(.normaInput(15))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(arcCount) arcs")
                                .font(.normaFinancial(16))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                    )
                    .opacity(statsVisible ? 1 : 0)
                    .offset(y: statsVisible ? 0 : 15)

                    // Remember section
                    VStack(spacing: 8) {
                        Text("Remember...")
                            .font(.custom(FontFamily.Rubik.medium, size: 14))
                            .foregroundColor(.primary)

                        Text("You'll lose 1 arc each month as bills come due. Keep adding to your Freedom Fund to stay protected.")
                            .font(.normaInput(13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("NormaPastelBeige").opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color("NormaPastelBeige").opacity(0.2), lineWidth: 1)
                            )
                    )
                    .opacity(reminderVisible ? 1 : 0)
                    .offset(y: reminderVisible ? 0 : 15)

                    // Months covered section
                    VStack(spacing: 16) {
                        Text("Months Covered")
                            .font(.custom(FontFamily.Rubik.medium, size: 16))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .opacity(monthsHeaderVisible ? 1 : 0)
                            .offset(y: monthsHeaderVisible ? 0 : 10)

                        // Month grid (3 columns x 4 rows)
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 20),
                            GridItem(.flexible(), spacing: 20),
                            GridItem(.flexible())
                        ], spacing: 24) {
                            ForEach(Array(upcomingMonths.enumerated()), id: \.offset) { index, month in
                                ArcMonthCard(
                                    monthName: month.shortName,
                                    isCovered: month.isCovered,
                                    monthNumber: index + 1,
                                    isVisible: coinVisibility[index]
                                )
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            .background(Color("NormaBackground"))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showInfoPopover = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .popover(isPresented: $showInfoPopover, arrowEdge: .top) {
                        ArcInfoPopover()
                            .presentationCompactAdaptation(.popover)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("My Arcs")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 20))
                        .foregroundColor(.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showFreedomFundEdit = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showFreedomFundEdit) {
            FreedomFundEditSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            // Prepare haptic generator
            impactGenerator.prepare()

            // Hero coin bounce in with dramatic entrance
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.15)) {
                heroVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                impactGenerator.impactOccurred(intensity: 1.0)
            }

            // Arc count text fade in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.5)) {
                arcCountVisible = true
            }

            // Stats grid fade in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.7)) {
                statsVisible = true
            }

            // Remember section fade in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.9)) {
                reminderVisible = true
            }

            // Months header
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.1)) {
                monthsHeaderVisible = true
            }

            // Staggered coin grid animations with haptics
            for index in 0..<12 {
                let delay = 1.3 + (Double(index) * 0.08)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    coinVisibility[index] = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.05) {
                    impactGenerator.impactOccurred(intensity: 0.3)
                }
            }
        }
    }
}

// MARK: - Freedom Fund Edit Sheet
struct FreedomFundEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var billViewModel: BillViewModel

    @State private var freedomFundText: String = ""
    @State private var isSaving = false
    @FocusState private var isTextFieldFocused: Bool

    private var currentFreedomFund: Double {
        sessionViewModel.currentUser?.settings.freedomFund ?? 0
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private var currencySymbol: String {
        CurrencyData.getSymbol(for: currency)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color("NormaPastelTeal"))

                    Text("Update Freedom Fund")
                        .font(.custom(FontFamily.Rubik.medium, size: 18))
                        .foregroundColor(.primary)

                    Text("Enter the total amount you have saved for bills")
                        .font(.normaInput(14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                // Amount input
                HStack(spacing: 8) {
                    Text(currencySymbol)
                        .font(.custom(FontFamily.Rubik.medium, size: 24))
                        .foregroundColor(.primary)

                    TextField("0", text: $freedomFundText)
                        .font(.custom(FontFamily.Rubik.regular, size: 24))
                        .keyboardType(.decimalPad)
                        .focused($isTextFieldFocused)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isTextFieldFocused ? Color("NormaPastelTeal") : Color.clear,
                            lineWidth: 2
                        )
                )
                .padding(.horizontal, 24)

                Spacer()

                // Save button
                Button {
                    saveChanges()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                                .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("NormaPastelTeal"))
                    )
                    .foregroundColor(.white)
                }
                .disabled(isSaving)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color("NormaBackground"))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Freedom Fund")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            // Pre-populate with current value
            if currentFreedomFund > 0 {
                freedomFundText = formatNumberWithoutCurrency(currentFreedomFund)
            }

            // Auto-focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
    }

    private func formatNumberWithoutCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private func parseNumber(_ text: String) -> Double {
        let cleanedText = text.replacingOccurrences(of: ",", with: "")
        return Double(cleanedText) ?? 0
    }

    private func saveChanges() {
        guard let currentUser = sessionViewModel.currentUser else { return }

        isSaving = true

        let newFreedomFund = parseNumber(freedomFundText)

        // Create updated settings
        var updatedSettings = currentUser.settings
        updatedSettings.freedomFund = newFreedomFund

        // Create updated profile - update BOTH settings and direct column
        var updatedProfile = currentUser
        updatedProfile.settings = updatedSettings
        updatedProfile.freedomFund = newFreedomFund  // Also update direct column for Edge Function

        Task {
            // Use arc check version to trigger rewards when arcs increase
            await sessionViewModel.updateUserProfileWithArcCheck(updatedProfile, bills: billViewModel.bills)

            await MainActor.run {
                isSaving = false

                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

                dismiss()
            }
        }
    }
}

// MARK: - Income Edit Sheet
struct IncomeEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionViewModel: SessionViewModel

    @State private var incomeText: String = ""
    @State private var isSaving = false
    @FocusState private var isTextFieldFocused: Bool

    private var currentIncome: Double {
        sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private var currencySymbol: String {
        CurrencyData.getSymbol(for: currency)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color("NormaPastelTeal"))

                    Text("Update Monthly Income")
                        .font(.custom(FontFamily.Rubik.medium, size: 18))
                        .foregroundColor(.primary)

                    Text("Enter your monthly income after taxes")
                        .font(.normaInput(14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                // Amount input
                HStack(spacing: 8) {
                    Text(currencySymbol)
                        .font(.custom(FontFamily.Rubik.medium, size: 24))
                        .foregroundColor(.primary)

                    TextField("0", text: $incomeText)
                        .font(.custom(FontFamily.Rubik.regular, size: 24))
                        .keyboardType(.decimalPad)
                        .focused($isTextFieldFocused)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isTextFieldFocused ? Color("NormaPastelTeal") : Color.clear,
                            lineWidth: 2
                        )
                )
                .padding(.horizontal, 24)

                Spacer()

                // Save button
                Button {
                    saveChanges()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                                .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("NormaPastelTeal"))
                    )
                    .foregroundColor(.white)
                }
                .disabled(isSaving)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color("NormaBackground"))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Monthly Income")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            // Pre-populate with current value
            if currentIncome > 0 {
                incomeText = formatNumberWithoutCurrency(currentIncome)
            }

            // Auto-focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
    }

    private func formatNumberWithoutCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private func parseNumber(_ text: String) -> Double {
        let cleanedText = text.replacingOccurrences(of: ",", with: "")
        return Double(cleanedText) ?? 0
    }

    private func saveChanges() {
        guard let currentUser = sessionViewModel.currentUser else { return }

        isSaving = true

        let newIncome = parseNumber(incomeText)

        // Create updated settings
        var updatedSettings = currentUser.settings
        updatedSettings.monthlyIncome = newIncome

        // Create updated profile - encryption handled by Edge Function via updateUserProfile
        var updatedProfile = currentUser
        updatedProfile.settings = updatedSettings

        Task {
            await sessionViewModel.updateUserProfile(updatedProfile)

            await MainActor.run {
                isSaving = false

                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

                dismiss()
            }
        }
    }
}

// MARK: - Arc Info Popover
struct ArcInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color("NormaPastelTeal"))

                Text("What are Arcs?")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                    .foregroundColor(.primary)
            }

            // Explanation
            VStack(alignment: .leading, spacing: 12) {
                Text("An arc represents one month of bills covered by your Freedom Fund.")
                    .font(.normaInput(14))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("For example, if your monthly bills are $1,500 and you have $4,500 saved, you have 3 arcs — meaning you're covered for 3 months.")
                    .font(.normaInput(14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            // Coin reward section
            HStack(spacing: 10) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color("NormaPastelPurple"))

                Text("Coin Rewards")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundColor(.primary)
            }

            Text("Each time you earn a new arc, you unlock a new coin. As you save more, your coins evolve — celebrating your progress toward financial freedom.")
                .font(.normaInput(14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 300)
        .background(Color("NormaBackground"))
    }
}

// MARK: - Arc Month Card
struct ArcMonthCard: View {
    let monthName: String
    let isCovered: Bool
    let monthNumber: Int
    var isVisible: Bool = true

    // Get the coin tier for this specific month/arc number
    private var coinTier: CoinTier {
        CoinTierService.currentCoinTier(for: monthNumber)
    }

    // Get the coin file name for this specific month/arc number
    private var coinFileName: String {
        coinTier.fileName
    }

    // Unique state name for each month (progression from urgency to freedom)
    private var stateDescription: String {
        if isCovered {
            switch monthNumber {
            case 1: return "urgency"
            case 2: return "caution"
            case 3: return "stable"
            case 4: return "calm"
            case 5: return "steady"
            case 6: return "secure"
            case 7: return "balanced"
            case 8: return "thriving"
            case 9: return "flourishing"
            case 10: return "abundant"
            case 11: return "liberated"
            case 12: return "free"
            default: return "covered"
            }
        } else {
            return "locked"
        }
    }

    private var stateColor: Color {
        if isCovered {
            switch monthNumber {
            case 1: return Color("NormaPastelCoral")
            case 2: return Color(red: 1.0, green: 0.7, blue: 0.3) // Orange
            case 3: return Color(red: 0.9, green: 0.75, blue: 0.4) // Light orange
            case 4: return Color(red: 0.8, green: 0.8, blue: 0.45) // Yellow
            case 5: return Color(red: 0.65, green: 0.8, blue: 0.5) // Yellow-green
            case 6: return Color("NormaPastelTeal")
            case 7: return Color(red: 0.4, green: 0.75, blue: 0.8) // Teal-blue
            case 8: return Color(red: 0.4, green: 0.7, blue: 0.9) // Blue
            case 9: return Color(red: 0.5, green: 0.6, blue: 0.9) // Blue-purple
            case 10: return Color(red: 0.6, green: 0.5, blue: 0.85) // Light purple
            case 11: return Color(red: 0.65, green: 0.4, blue: 0.8) // Purple
            case 12: return Color(red: 0.7, green: 0.35, blue: 0.75) // Deep purple
            default: return Color("NormaPastelTeal")
            }
        } else {
            return Color.secondary
        }
    }

    // Spring animation for coin appearance
    private var coinAnimation: Animation {
        .spring(response: 0.7, dampingFraction: 0.6)
    }

    var body: some View {
        VStack(spacing: 4) {
            if isCovered {
                // Static 3D coin with halo effect
                ZStack {
                    // Glow effect behind coin (color matches tier)
                    Circle()
                        .fill(coinTier.glowColor.opacity(0.10))
                        .frame(width: 80, height: 80)
                        .blur(radius: 15)
                        .scaleEffect(isVisible ? 1 : 0.3)
                        .opacity(isVisible ? 1 : 0)
                        .animation(coinAnimation, value: isVisible)

                    // Static 3D coin showing the tier for this specific arc number
                    StaticCoin3DView(fileName: coinFileName)
                        .id(coinFileName)
                        .frame(width: 64, height: 64)
                        .scaleEffect(isVisible ? 1 : 0)
                        .opacity(isVisible ? 1 : 0)
                        .animation(coinAnimation, value: isVisible)
                }
            } else {
                // Uncovered month shows grayed out coin with lock
                ZStack {
                    // Grayed out coin
                    StaticCoin3DView(fileName: coinFileName)
                        .id("\(coinFileName)-locked")
                        .frame(width: 64, height: 64)
                        .saturation(0)
                        .opacity(isVisible ? 0.4 : 0)
                        .scaleEffect(isVisible ? 1 : 0)
                        .animation(coinAnimation, value: isVisible)

                    // Lock overlay
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 64, height: 64)
                        .scaleEffect(isVisible ? 1 : 0)
                        .opacity(isVisible ? 1 : 0)
                        .animation(coinAnimation, value: isVisible)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .scaleEffect(isVisible ? 1 : 0)
                        .opacity(isVisible ? 1 : 0)
                        .animation(coinAnimation, value: isVisible)
                }
            }

            // Month name and state
            VStack(spacing: 2) {
                Text(monthName)
                    .font(.custom(FontFamily.Rubik.medium, size: 14))
                    .foregroundColor(isCovered ? .primary : .secondary)

                Text(stateDescription)
                    .font(.custom(FontFamily.Rubik.regular, size: 11))
                    .foregroundColor(stateColor)
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 5)
            .animation(coinAnimation, value: isVisible)
        }
    }
}

// MARK: - Hero Coin 3D View (Spinning)
/// Large spinning 3D coin for hero display
struct HeroCoin3DView: UIViewRepresentable {
    var fileName: String = "norma-coin"

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = false
        scnView.isUserInteractionEnabled = false
        scnView.antialiasingMode = .multisampling4X

        if !loadScene(into: scnView) {
            createFallbackScene(into: scnView)
        }

        scnView.isPlaying = true

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // No updates needed
    }

    private func loadScene(into scnView: SCNView) -> Bool {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "usdz") else {
            print("HeroCoin3DView: Could not find \(fileName).usdz")
            return false
        }

        guard let scene = try? SCNScene(url: url, options: [.checkConsistency: true]) else {
            print("HeroCoin3DView: Failed to load scene from URL")
            return false
        }

        scene.background.contents = UIColor.clear

        // Create container for the model
        let containerNode = SCNNode()

        // Clone all child nodes from the loaded scene
        for childNode in scene.rootNode.childNodes {
            containerNode.addChildNode(childNode.clone())
        }

        // Remove original nodes to prevent static coin overlay
        scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }

        // Calculate bounding box and center the model
        let (minBound, maxBound) = containerNode.boundingBox
        let centerX = (minBound.x + maxBound.x) / 2
        let centerY = (minBound.y + maxBound.y) / 2
        let centerZ = (minBound.z + maxBound.z) / 2
        containerNode.position = SCNVector3(-centerX, -centerY, -centerZ)

        // Calculate model dimensions
        let width = maxBound.x - minBound.x
        let height = maxBound.y - minBound.y
        let depth = maxBound.z - minBound.z
        let maxDimension = max(width, max(height, depth))

        scene.rootNode.addChildNode(containerNode)

        // Setup camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = Double(maxDimension * 0.6)
        cameraNode.position = SCNVector3(0, 0, maxDimension * 2)
        scene.rootNode.addChildNode(cameraNode)

        // Slow rotation for hero coin (10 seconds for full rotation)
        let rotation = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 10)
        let repeatRotation = SCNAction.repeatForever(rotation)
        containerNode.runAction(repeatRotation)

        scnView.scene = scene
        return true
    }

    private func createFallbackScene(into scnView: SCNView) {
        let fallbackScene = SCNScene()
        fallbackScene.background.contents = UIColor.clear

        let torus = SCNTorus(ringRadius: 0.4, pipeRadius: 0.15)
        torus.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0)
        torus.firstMaterial?.specular.contents = UIColor.white
        let torusNode = SCNNode(geometry: torus)
        torusNode.eulerAngles.x = .pi / 4

        fallbackScene.rootNode.addChildNode(torusNode)

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 1.0
        camera.position = SCNVector3(0, 0, 3)
        fallbackScene.rootNode.addChildNode(camera)

        let rotation = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 10)
        torusNode.runAction(SCNAction.repeatForever(rotation))

        scnView.scene = fallbackScene
    }
}

#Preview {
    ArcCountView(
        arcCount: 3,
        freedomFund: 4500,
        totalMonthlyBills: 1500,
        currency: "USD"
    )
    .environmentObject(SessionViewModel(dataManager: DataManager()))
}
