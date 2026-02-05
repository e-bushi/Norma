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
    @ObservedObject var viewModel: PreviewModeViewModel

    @State private var showBills = false
    @State private var showExpenses = false
    @State private var visibleCapsules: Int = 0
    @State private var isExpanded: Bool = true
    @State private var pressedCapsule: String? = nil

    private var currentMonthAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: Date())
    }

    // Get the currency symbol for the user's selected currency
    private var currencySymbol: String {
        let currencyCode = viewModel.userCurrency ?? "USD"
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode

        // Get the system symbol
        let systemSymbol = formatter.currencySymbol ?? currencyCode

        // If the system returns the code itself (no symbol), use our fallback map
        if systemSymbol == currencyCode || systemSymbol.count > 3 {
            return CurrencySymbolMap.symbol(for: currencyCode)
        }

        return systemSymbol
    }

    // Local currency formatter for preview mode
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = viewModel.userCurrency ?? "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? formatter.string(from: 0) ?? "0"
    }

    // Truncated currency formatter for capsules
    private func formatCurrencyTruncated(_ amount: Double) -> String {
        let symbol = currencySymbol

        if amount < 100 {
            return "\(symbol)\(String(format: "%.2f", amount))"
        } else if amount < 1000 {
            let hasDecimals = amount.truncatingRemainder(dividingBy: 1) > 0
            return "\(symbol)\(Int(amount))" + (hasDecimals ? "+" : "")
        } else if amount < 10000 {
            return "\(symbol)\(String(format: "%.1f", amount / 1000))K"
        } else if amount < 100000 {
            return "\(symbol)\(Int(amount / 1000))K"
        } else if amount < 1000000 {
            return "\(symbol)\(Int(amount / 1000))K"
        } else {
            if amount < 10000000 {
                return "\(symbol)\(String(format: "%.1f", amount / 1000000))M"
            } else {
                return "\(symbol)\(Int(amount / 1000000))M"
            }
        }
    }

    private func animateCapsules() {
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

                // Tags rows below text field - using flow layout for wrapping
                HStack(alignment: .bottom, spacing: 8) {
                    // Capsules container with flow layout
                    CapsuleFlowLayout(spacing: 8) {
                        // Bills tag
                        Button {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            showBills = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 12))
                                Text("Bills: \(formatCurrencyTruncated(viewModel.totalBills))")
                                    .font(.normaFinancial(14))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .frame(maxWidth: 140)
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
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: visibleCapsules)

                        // Monthly Spend tag
                        Button {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            showExpenses = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 12))
                                Text("\(currentMonthAbbreviation). Spend: \(formatCurrencyTruncated(viewModel.totalExpenses))")
                                    .font(.normaFinancial(14))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .frame(maxWidth: 160)
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
                        .opacity(visibleCapsules > 1 ? 1 : 0)
                        .scaleEffect(visibleCapsules > 1 ? 1.0 : 0.3)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: visibleCapsules)
                    }

                    Spacer(minLength: 8)

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
                animateCapsules()
            } else {
                // Animate capsules disappearing
                withAnimation(.easeOut(duration: 0.3)) {
                    visibleCapsules = 0
                }
            }
        }
        .onChange(of: viewModel.triggerCapsuleAnimation) { _, newValue in
            if newValue {
                // Re-animate capsules when user adds their first bill
                animateCapsules()
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
    let viewModel = PreviewModeViewModel()

    return PreviewChatInputView(
        text: $text,
        showCapsules: $showCapsules,
        isLoading: false,
        onSend: { print("Send tapped") },
        viewModel: viewModel
    )
    .background(Color("NormaBackground"))
    .preferredColorScheme(.dark)
}

// MARK: - Capsule Flow Layout

/// A layout that arranges capsules horizontally and wraps to the next line if needed
struct CapsuleFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            // Check if we need to wrap to next line
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return (
            size: CGSize(width: totalWidth, height: currentY + lineHeight),
            positions: positions
        )
    }
}

// MARK: - Currency Symbol Fallback Map

/// Provides native currency symbols for currencies where NumberFormatter
/// may return the currency code instead of the actual symbol
enum CurrencySymbolMap {
    // Map of currency codes to their native symbols
    private static let symbols: [String: String] = [
        // Middle East
        "KWD": "د.ك",  // Kuwaiti Dinar
        "BHD": "د.ب",  // Bahraini Dinar
        "OMR": "ر.ع",  // Omani Rial
        "QAR": "ر.ق",  // Qatari Riyal
        "SAR": "ر.س",  // Saudi Riyal
        "AED": "د.إ",  // UAE Dirham
        "JOD": "د.ا",  // Jordanian Dinar
        "IQD": "ع.د",  // Iraqi Dinar
        "LBP": "ل.ل",  // Lebanese Pound
        "SYP": "ل.س",  // Syrian Pound
        "YER": "ر.ي",  // Yemeni Rial
        "EGP": "ج.م",  // Egyptian Pound
        "MAD": "د.م",  // Moroccan Dirham
        "TND": "د.ت",  // Tunisian Dinar
        "DZD": "د.ج",  // Algerian Dinar
        "LYD": "د.ل",  // Libyan Dinar
        "ILS": "₪",    // Israeli Shekel
        "IRR": "﷼",    // Iranian Rial

        // Asia
        "AFN": "؋",    // Afghan Afghani
        "PKR": "₨",    // Pakistani Rupee
        "LKR": "₨",    // Sri Lankan Rupee
        "NPR": "₨",    // Nepalese Rupee
        "BDT": "৳",    // Bangladeshi Taka
        "MMK": "K",    // Myanmar Kyat
        "KHR": "៛",    // Cambodian Riel
        "LAK": "₭",    // Lao Kip
        "MNT": "₮",    // Mongolian Tugrik
        "KZT": "₸",    // Kazakhstani Tenge
        "UZS": "сўм",  // Uzbekistani Som
        "AZN": "₼",    // Azerbaijani Manat
        "GEL": "₾",    // Georgian Lari
        "AMD": "֏",    // Armenian Dram

        // Africa
        "GHS": "₵",    // Ghanaian Cedi
        "NGN": "₦",    // Nigerian Naira
        "KES": "KSh",  // Kenyan Shilling
        "UGX": "USh",  // Ugandan Shilling
        "TZS": "TSh",  // Tanzanian Shilling
        "ZMW": "ZK",   // Zambian Kwacha
        "MWK": "MK",   // Malawian Kwacha
        "BWP": "P",    // Botswana Pula
        "SZL": "E",    // Swazi Lilangeni
        "LSL": "L",    // Lesotho Loti
        "NAD": "N$",   // Namibian Dollar
        "MUR": "₨",    // Mauritian Rupee
        "SCR": "₨",    // Seychellois Rupee
        "ETB": "Br",   // Ethiopian Birr
        "RWF": "FRw",  // Rwandan Franc
        "XOF": "CFA",  // West African CFA Franc
        "XAF": "FCFA", // Central African CFA Franc

        // Europe (non-Euro)
        "UAH": "₴",    // Ukrainian Hryvnia
        "BYN": "Br",   // Belarusian Ruble
        "MDL": "L",    // Moldovan Leu
        "MKD": "ден",  // Macedonian Denar
        "RSD": "дин",  // Serbian Dinar
        "BAM": "KM",   // Bosnia Mark
        "ALL": "L",    // Albanian Lek

        // Americas
        "PYG": "₲",    // Paraguayan Guarani
        "CRC": "₡",    // Costa Rican Colón
        "NIO": "C$",   // Nicaraguan Córdoba
        "HNL": "L",    // Honduran Lempira
        "GTQ": "Q",    // Guatemalan Quetzal
        "HTG": "G",    // Haitian Gourde
        "PAB": "B/.",  // Panamanian Balboa
        "VES": "Bs",   // Venezuelan Bolívar
        "BOB": "Bs",   // Bolivian Boliviano
        "PEN": "S/",   // Peruvian Sol
        "UYU": "$U",   // Uruguayan Peso
        "ARS": "$",    // Argentine Peso
        "CLP": "$",    // Chilean Peso
        "COP": "$",    // Colombian Peso

        // Caribbean
        "JMD": "J$",   // Jamaican Dollar
        "TTD": "TT$",  // Trinidad Dollar
        "BBD": "Bds$", // Barbadian Dollar
        "BSD": "B$",   // Bahamian Dollar
        "XCD": "EC$",  // East Caribbean Dollar

        // Oceania
        "FJD": "FJ$",  // Fijian Dollar
        "PGK": "K",    // Papua New Guinean Kina
        "WST": "WS$",  // Samoan Tala
        "TOP": "T$",   // Tongan Paʻanga
        "VUV": "VT",   // Vanuatu Vatu
    ]

    /// Returns the native symbol for a currency code, falling back to the code if not found
    static func symbol(for currencyCode: String) -> String {
        return symbols[currencyCode.uppercased()] ?? currencyCode
    }
}
