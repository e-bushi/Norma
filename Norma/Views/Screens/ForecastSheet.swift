//
//  ForecastSheet.swift
//  Norma
//
//  Combined income-vs-bills overview + full bills list for the selected
//  month. Reached via the chart icon in the notes-list bottom bar.
//

import SwiftUI
import SwiftData

struct ForecastSheet: View {
    enum Tab { case thisMonth, nextMonth }
    enum SelectionScope { case bills, intentions }

    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var billViewModel: BillViewModel

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \NoteToken.occurredAt) private var allTokens: [NoteToken]
    @Query(sort: \FreedomFundEntry.createdAt, order: .reverse) private var allEntries: [FreedomFundEntry]

    @State private var selectedTab: Tab = .thisMonth
    @State private var showInfoPopover = false
    @State private var showSafeInfo = false
    @State private var showWhatIfInfo = false

    // What-if a purchase — a tap-to-test amount that shows its impact on the
    // after-bills number and runway, live as you type.
    @State private var whatIfExpanded: Bool = false
    @State private var whatIfAmount: String = ""
    /// Brief dither "crunching" beat after the amount changes, before the
    /// impact rows resolve — same thinking motif as the chat.
    @State private var whatIfCalculating: Bool = false
    @State private var whatIfDebounce: Task<Void, Never>? = nil
    @FocusState private var whatIfFocused: Bool

    /// "If I committed everything" — independent toggle that subtracts the
    /// intentions total from the hero net. Styled in the tab row as a third
    /// pill, but functionally independent of the month selector so the user
    /// can stack it with either this-month or next-month.
    @State private var includeIntentions: Bool = false

    // Bulk-select state — shared between bills and intentions; the scope
    // disambiguates which kind of row is selectable in the current mode.
    @State private var isSelecting: Bool = false
    @State private var selectionScope: SelectionScope = .bills
    @State private var selectedBillIds: Set<String> = []
    @State private var selectedIntentionIds: Set<UUID> = []
    @State private var showDeleteConfirm: Bool = false
    @State private var showMarkPaidConfirm: Bool = false
    @State private var showUpgradeSheet: Bool = false
    @State private var upgradeDueDate: Date = Date()
    @State private var isDeleting: Bool = false
    @State private var isMarkingPaid: Bool = false
    @State private var isUpgrading: Bool = false
    @State private var isAdvancing: Bool = false

    /// Bill tapped for the detail/edit sheet. Non-nil drives presentation.
    @State private var selectedBillForDetail: Bill?

    /// Paid section starts collapsed as a card deck; tap toggles to a list.
    @State private var paidExpanded: Bool = false

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cardBg = Color(red: 0x1F/255, green: 0x1F/255, blue: 0x24/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private let onAccentText = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255)
    private var accentPurple: Color { NormaPalette.lavender }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroBlock
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                    if !isSelecting {
                        safeToSpendCard
                            .padding(.horizontal, 24)
                            .padding(.bottom, 12)

                        whatIfCard
                            .padding(.horizontal, 24)
                            .padding(.bottom, 22)
                    }

                    filterCapsules
                        .padding(.horizontal, 24)
                        .padding(.bottom, 22)

                    sectionsBlock
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // Tap any empty area to dismiss the decimal-pad keyboard. The
                // clear background sits behind the content, so taps on rows,
                // buttons, and the field itself are handled by them first.
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { whatIfFocused = false }
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .background(bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .animation(.easeInOut(duration: 0.18), value: isSelecting)
            .alert("delete bills?", isPresented: $showDeleteConfirm) {
                Button("cancel", role: .cancel) {}
                Button("delete", role: .destructive) { performBulkDelete() }
            } message: {
                Text("this will remove \(selectedBillIds.count) \(selectedBillIds.count == 1 ? "bill" : "bills") permanently.")
            }
            .alert("mark as paid?", isPresented: $showMarkPaidConfirm) {
                Button("cancel", role: .cancel) {}
                Button("mark paid") { performBulkMarkPaid() }
            } message: {
                Text("\(selectedBillIds.count) \(selectedBillIds.count == 1 ? "bill" : "bills") will be marked paid for this cycle.")
            }
            .sheet(isPresented: $showUpgradeSheet) {
                upgradeSheet
                    .presentationDetents([.height(360)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedBillForDetail) { bill in
                BillDetailSheet(bill: bill)
                    .environmentObject(billViewModel)
                    .environmentObject(sessionViewModel)
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                // Contextual permission prompt (decision: first bill / forecast
                // open), then re-arm so a freshly-granted user gets reminders now.
                Task {
                    if !billViewModel.bills.isEmpty {
                        await NotificationService.shared.ensurePermission()
                        await NotificationService.shared.rearmAllBillReminders(for: billViewModel.bills)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isSelecting {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    exitSelection()
                } label: {
                    Text("cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(cream.opacity(0.85))
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if selectionScope == .bills {
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            showMarkPaidConfirm = true
                        } label: {
                            Label("mark paid", systemImage: "checkmark.circle")
                        }
                        .disabled(!hasSelection || isMarkingPaid)

                        Divider()

                        Button(role: .destructive) {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            showDeleteConfirm = true
                        } label: {
                            Label("delete", systemImage: "trash")
                        }
                        .disabled(!hasSelection || isDeleting)
                    } else {
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            // Seed with end-of-displayed-month as a sensible default.
                            upgradeDueDate = defaultUpgradeDueDate()
                            showUpgradeSheet = true
                        } label: {
                            Label("upgrade to commitment", systemImage: "arrow.up.circle")
                        }
                        .disabled(!hasSelection || isUpgrading)

                        Divider()

                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            performAdvanceIntentions()
                        } label: {
                            Label("push to next month", systemImage: "calendar.badge.plus")
                        }
                        .disabled(!hasSelection || isAdvancing)
                    }
                } label: {
                    Text(hasSelection
                         ? "actions (\(selectionCount))"
                         : "actions")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(hasSelection
                                         ? accentPurple
                                         : cream.opacity(0.4))
                }
                .disabled(!hasSelection)
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    showInfoPopover = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(mutedText)
                }
                .popover(isPresented: $showInfoPopover, arrowEdge: .top) {
                    ForecastInfoPopover()
                        .presentationCompactAdaptation(.popover)
                }
            }

            if !billViewModel.bills.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(
                        item: exportText,
                        subject: Text("my bills"),
                        message: Text("here are my bills")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(cream.opacity(0.85))
                    }
                }
            }
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
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: netAfterBills)
                Text(".")
                    .font(.system(size: 72, weight: .heavy))
                    .tracking(-3.24)
                    .foregroundStyle(accentPurple)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    Text("\(formatCurrency(monthlyIncome)) income")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                        .foregroundStyle(cream)
                    Text("·")
                        .font(.custom(FontFamily.Rubik.medium, size: 15))
                        .foregroundStyle(dimText)
                    Text("\(formatCurrency(totalDeductionsForMonth)) out")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                        .foregroundStyle(cream)
                }
                if includeIntentions && !monthlyIntentions.isEmpty {
                    Text("includes \(formatCurrency(totalIntentions)) of intentions")
                        .font(.custom(FontFamily.Rubik.medium, size: 12))
                        .foregroundStyle(accentPurple.opacity(0.85))
                }
            }
        }
    }

    // MARK: - Safe to spend

    private var safeToSpendCard: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Text("SAFE TO SPEND")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 10))
                    .tracking(0.6)
                    .foregroundStyle(mutedText)
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    showSafeInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(mutedText)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showSafeInfo, arrowEdge: .top) {
                    safeToSpendInfoPopover
                        .presentationCompactAdaptation(.popover)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formatCurrency(safeToSpendPerWeek))
                    .font(.custom(FontFamily.Rubik.bold, size: 24))
                    .foregroundStyle(netAfterBills > 0 ? cream : accentPurple)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.6), value: safeToSpendPerWeek)
                Text("/ week")
                    .font(.custom(FontFamily.Rubik.medium, size: 13))
                    .foregroundStyle(mutedText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.09), Color.white.opacity(0.03)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        )
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(cream.opacity(0.08), lineWidth: 1))
    }

    private var safeToSpendInfoPopover: some View {
        let period = selectedTab == .thisMonth ? "this" : "next"
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: "wallet.bill.fill")
                    .font(.system(size: 19))
                    .foregroundColor(accentPurple)
                Text("safe to spend")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 19))
                    .foregroundColor(.primary)
            }
            Text("what you can spend each week and still cover \(period) month's bills — your income minus \(period) month's bills and commitments, split across the ~4.3 weeks in a month.")
                .font(.normaInput(16))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if netAfterBills <= 0 {
                Text("right now your bills top your income, so there's nothing extra to spend.")
                    .font(.normaInput(16))
                    .foregroundColor(NormaPalette.lavender)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(width: 300)
    }

    private var whatIfInfoPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 19))
                    .foregroundColor(accentPurple)
                Text("test a purchase")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 19))
                    .foregroundColor(.primary)
            }
            Text("type in an amount to feel the trade before you make it. norma shows your money after bills and your runway — both before and after the spend — so a purchase stops being a guess.")
                .font(.normaInput(16))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 300)
    }

    // MARK: - What-if a purchase

    private var whatIfCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accentPurple)
                Text("test a purchase")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 14))
                    .foregroundStyle(cream)
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    showWhatIfInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(mutedText)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showWhatIfInfo, arrowEdge: .top) {
                    whatIfInfoPopover
                        .presentationCompactAdaptation(.popover)
                }
                Spacer()
                Image(systemName: whatIfExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(mutedText)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) { whatIfExpanded.toggle() }
            }

            if whatIfExpanded {
                HStack(spacing: 6) {
                    Text(NormaPalette.currencySymbol(for: currency))
                        .font(.custom(FontFamily.Rubik.bold, size: 20))
                        .foregroundStyle(mutedText)
                    TextField("0", text: $whatIfAmount)
                        .keyboardType(.decimalPad)
                        .focused($whatIfFocused)
                        .font(.custom(FontFamily.Rubik.bold, size: 20))
                        .foregroundStyle(cream)
                        .tint(accentPurple)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(cream.opacity(0.06)))
                .overlay(Capsule().stroke(cream.opacity(0.10), lineWidth: 1))
                .onChange(of: whatIfAmount) { _, _ in beginWhatIfCrunch() }

                if whatIfValue > 0 {
                    ZStack {
                        if whatIfCalculating {
                            DitherShaderView(intensity: 1.0)
                                .frame(height: 66)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .transition(.opacity)
                        } else {
                            VStack(spacing: 10) {
                                whatIfImpactRow(
                                    label: "after bills",
                                    before: formatCurrency(netAfterBills),
                                    after: formatCurrency(max(0, netAfterBills - whatIfValue))
                                )
                                whatIfImpactRow(
                                    label: "runway",
                                    before: runwayLabel(runwayDays(for: freedomFund)),
                                    after: runwayLabel(runwayDays(for: freedomFund - whatIfValue))
                                )
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.4), value: whatIfCalculating)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.09), Color.white.opacity(0.03)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        )
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(cream.opacity(0.08), lineWidth: 1))
    }

    private func whatIfImpactRow(label: String, before: String, after: String) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.custom(FontFamily.Rubik.medium, size: 13))
                .foregroundStyle(mutedText)
            Spacer()
            Text(before)
                .font(.custom(FontFamily.Rubik.medium, size: 14))
                .foregroundStyle(dimText)
            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(mutedText)
            Text(after)
                .font(.custom(FontFamily.Rubik.bold, size: 15))
                .foregroundStyle(cream)
                .contentTransition(.numericText())
        }
    }

    private func runwayLabel(_ days: Int?) -> String {
        guard let days else { return "—" }
        let c = ArcCalculationService.compactRunway(days: days)
        return "\(c.value) \(c.unit)"
    }

    /// Shows the dither "crunching" beat, then resolves the impact rows a
    /// moment after the user stops typing — a considered feel instead of a
    /// jittery per-keystroke recompute.
    private func beginWhatIfCrunch() {
        whatIfDebounce?.cancel()
        guard whatIfValue > 0 else {
            withAnimation(.easeInOut(duration: 0.3)) { whatIfCalculating = false }
            return
        }
        whatIfCalculating = true
        whatIfDebounce = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.45)) { whatIfCalculating = false }
        }
    }

    // MARK: - Filter capsules

    private var filterCapsules: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                tabPill("this month", active: selectedTab == .thisMonth) { selectedTab = .thisMonth }
                tabPill("next month", active: selectedTab == .nextMonth) { selectedTab = .nextMonth }
                // Independent toggle styled as a third pill. When `monthlyIntentions`
                // is empty we keep it disabled so it can't be turned on without effect.
                togglePill(
                    "if i committed everything",
                    active: includeIntentions,
                    disabled: monthlyIntentions.isEmpty
                ) {
                    includeIntentions.toggle()
                }
            }
        }
    }

    @ViewBuilder
    private func tabPill(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                action()
            }
        } label: {
            Text(label)
                .font(.custom(active ? FontFamily.Rubik.semiBold : FontFamily.Rubik.medium, size: 13))
                .foregroundStyle(active ? onAccentText : cream)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background {
                    if active { Capsule().fill(accentPurple) }
                }
                .overlay(
                    Capsule().stroke(
                        active ? accentPurple : cream.opacity(0.32),
                        style: active ? StrokeStyle(lineWidth: 1) : StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
                )
        }
        .buttonStyle(.plain)
    }

    /// Independent toggle styled as a pill. Distinguished from `tabPill` by a
    /// small leading indicator so users register it as a switch rather than a
    /// mutually-exclusive month selection.
    @ViewBuilder
    private func togglePill(
        _ label: String,
        active: Bool,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                action()
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(active ? cream : .clear)
                    .overlay(Circle().stroke(active ? cream : cream.opacity(0.45), lineWidth: 1.2))
                    .frame(width: 9, height: 9)
                Text(label)
                    .font(.custom(active ? FontFamily.Rubik.semiBold : FontFamily.Rubik.medium, size: 13))
                    .foregroundStyle(active ? cream : cream.opacity(disabled ? 0.35 : 0.85))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background {
                if active { Capsule().fill(cream.opacity(0.12)) }
            }
            .overlay(
                Capsule().stroke(
                    active ? cream.opacity(0.55) : cream.opacity(0.22),
                    style: StrokeStyle(lineWidth: 1, dash: active ? [] : [3, 3])
                )
            )
            .opacity(disabled ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    // MARK: - Sections

    @ViewBuilder
    private var sectionsBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            if monthlyBillRows.isEmpty && monthlyIntentions.isEmpty {
                emptyState
            } else if !monthlyBillRows.isEmpty {
                if !overdueRows.isEmpty {
                    section(
                        title: "overdue",
                        titleColor: accentPurple,
                        dividerColor: accentPurple.opacity(0.25),
                        rows: overdueRows,
                        kind: .overdue
                    )
                }
                if !upcomingRows.isEmpty {
                    section(
                        title: "upcoming",
                        titleColor: cream,
                        dividerColor: cream.opacity(0.12),
                        rows: upcomingRows,
                        kind: .upcoming
                    )
                    .padding(.top, overdueRows.isEmpty ? 0 : 14)
                }
                if !paidRows.isEmpty {
                    paidSectionView
                        .padding(.top, (overdueRows.isEmpty && upcomingRows.isEmpty) ? 0 : 14)
                }
            }

            if !monthlyIntentions.isEmpty {
                intentionsSection
                    .padding(.top, monthlyBillRows.isEmpty ? 0 : 28)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("nothing \(selectedTab == .thisMonth ? "this month" : "next month")")
                .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                .foregroundStyle(cream.opacity(0.7))
            Text("bills, commitments, and intentions you add in chat show up here.")
                .font(.custom(FontFamily.Rubik.regular, size: 13))
                .foregroundStyle(mutedText)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func section(
        title: String,
        titleColor: Color,
        dividerColor: Color,
        rows: [BillRow],
        kind: RowKind
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                    .tracking(0.88)
                    .textCase(.uppercase)
                    .foregroundStyle(titleColor)
                Rectangle()
                    .fill(dividerColor)
                    .frame(height: 1)
                Text("\(rows.count)")
                    .font(.custom(FontFamily.Rubik.medium, size: 11))
                    .tracking(0.44)
                    .foregroundStyle(dimText)
            }
            .padding(.top, 6)
            .padding(.bottom, 14)

            ForEach(rows, id: \.id) { row in
                billRowView(row, kind: kind)
            }
        }
    }

    // MARK: - Paid section (collapsible card deck)

    /// Header + body for paid bills. Collapsed, the cards stack as a deck to
    /// save space; tapping the header or the deck fans them into a vertical
    /// list, and tapping again re-stacks them.
    private var paidSectionView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                    paidExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("paid")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                        .tracking(0.88)
                        .textCase(.uppercase)
                        .foregroundStyle(dimText)
                    Rectangle()
                        .fill(cream.opacity(0.08))
                        .frame(height: 1)
                    Text("\(paidRows.count)")
                        .font(.custom(FontFamily.Rubik.medium, size: 11))
                        .tracking(0.44)
                        .foregroundStyle(dimText)
                    Image(systemName: paidExpanded ? "chevron.up" : "rectangle.stack")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(dimText)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
            .padding(.bottom, 14)

            if paidExpanded {
                VStack(spacing: 10) {
                    ForEach(paidRows, id: \.id) { row in
                        paidCard(row, interactive: true)
                    }
                }
            } else {
                paidDeck
            }
        }
    }

    private var paidDeck: some View {
        let visible = Array(paidRows.prefix(4))
        let step: CGFloat = 12
        return Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                paidExpanded = true
            }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .top) {
                    ForEach(Array(Array(visible.enumerated()).reversed()), id: \.element.id) { idx, row in
                        paidCard(row, interactive: false)
                            .scaleEffect(1 - CGFloat(idx) * 0.04, anchor: .top)
                            .offset(y: CGFloat(idx) * step)
                            .opacity(1 - Double(idx) * 0.16)
                            .zIndex(Double(visible.count - idx))
                    }
                }
                .padding(.bottom, CGFloat(max(0, visible.count - 1)) * step)

                Text("tap to expand")
                    .font(.custom(FontFamily.Rubik.medium, size: 11))
                    .foregroundStyle(dimText)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func paidCard(_ row: BillRow, interactive: Bool) -> some View {
        let inner = HStack(spacing: 12) {
            statusDot(for: .paid)
            VStack(alignment: .leading, spacing: 3) {
                Text(row.name.lowercased())
                    .font(.custom(FontFamily.Rubik.medium, size: 16))
                    .tracking(-0.16)
                    .foregroundStyle(mutedText)
                    .lineLimit(1)
                Text(eyebrowText(forDate: row.dueDate, kind: .paid))
                    .font(.custom(FontFamily.Rubik.medium, size: 12))
                    .tracking(0.48)
                    .textCase(.uppercase)
                    .foregroundStyle(dimText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(formatCurrency(row.amount))
                .font(.custom(FontFamily.Rubik.medium, size: 18))
                .tracking(-0.18)
                .foregroundStyle(dimText)
                .strikethrough(true, color: dimText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(cream.opacity(0.07), lineWidth: 1))

        if interactive {
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                if case .bill(let bill) = row { selectedBillForDetail = bill }
            } label: {
                inner
            }
            .buttonStyle(.plain)
        } else {
            inner
        }
    }

    // MARK: - Intentions section

    private var intentionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("intentions")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                    .tracking(0.88)
                    .textCase(.uppercase)
                    .foregroundStyle(accentPurple)
                Rectangle()
                    .fill(accentPurple.opacity(0.25))
                    .frame(height: 1)
                Text("\(monthlyIntentions.count)")
                    .font(.custom(FontFamily.Rubik.medium, size: 11))
                    .tracking(0.44)
                    .foregroundStyle(dimText)
            }
            .padding(.top, 6)
            .padding(.bottom, 14)

            ForEach(Array(monthlyIntentions.enumerated()), id: \.element.id) { index, token in
                intentionRow(token, showTopDivider: index > 0)
            }
        }
    }

    @ViewBuilder
    private func intentionRow(_ token: NoteToken, showTopDivider: Bool) -> some View {
        let inIntentionsSelection = isSelecting && selectionScope == .intentions
        let isSelected = selectedIntentionIds.contains(token.id)
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            if inIntentionsSelection {
                toggleIntentionSelection(token)
            }
        } label: {
            HStack(spacing: 12) {
                if inIntentionsSelection {
                    selectionIndicator(selected: isSelected)
                } else {
                    Circle()
                        .stroke(accentPurple.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                        .frame(width: 8, height: 8)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text((token.subject ?? "intention").lowercased())
                        .font(.custom(FontFamily.Rubik.medium, size: 16))
                        .tracking(-0.16)
                        .foregroundStyle(cream.opacity(0.8))
                        .lineLimit(1)

                    Text("thinking · \(shortDate(token.occurredAt))")
                        .font(.custom(FontFamily.Rubik.medium, size: 12))
                        .tracking(0.48)
                        .textCase(.uppercase)
                        .foregroundStyle(accentPurple.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(formatCurrency(token.amount))
                    .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                    .tracking(-0.18)
                    .foregroundStyle(accentPurple.opacity(0.85))

                if !isSelecting {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(dimText)
                        .frame(width: 16, alignment: .trailing)
                }
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .overlay(alignment: .top) {
                if showTopDivider {
                    Rectangle()
                        .fill(cream.opacity(0.08))
                        .frame(height: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    guard !isSelecting else { return }
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    enterIntentionsSelection(with: token)
                }
        )
    }

    // MARK: - Row

    private enum RowKind { case overdue, upcoming, paid }

    @ViewBuilder
    private func billRowView(_ row: BillRow, kind: RowKind) -> some View {
        let isCommit = { if case .commitment = row { return true } else { return false } }()
        let inBillsSelection = isSelecting && selectionScope == .bills
        let isSelected = row.billId.map { selectedBillIds.contains($0) } ?? false
        let canSelect = !isCommit
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            if inBillsSelection, case .bill(let bill) = row {
                toggleSelection(bill)
            } else if case .bill(let bill) = row {
                selectedBillForDetail = bill
            }
            // Commitments have no detail sheet (they live in their source note).
        } label: {
            HStack(spacing: 12) {
                if inBillsSelection && canSelect {
                    selectionIndicator(selected: isSelected)
                } else {
                    statusDot(for: kind)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(row.name.lowercased())
                            .font(.custom(kind == .paid ? FontFamily.Rubik.medium : FontFamily.Rubik.semiBold, size: 16))
                            .tracking(-0.16)
                            .foregroundStyle(kind == .paid ? mutedText : cream)
                            .lineLimit(1)
                        if isCommit {
                            Text("commit")
                                .font(.custom(FontFamily.Rubik.semiBold, size: 9))
                                .tracking(0.66)
                                .textCase(.uppercase)
                                .foregroundStyle(accentPurple)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .overlay(
                                    Capsule().stroke(accentPurple.opacity(0.45), lineWidth: 0.8)
                                )
                        }
                    }

                    HStack(spacing: 6) {
                        Text(eyebrowText(forDate: row.dueDate, kind: kind))
                            .font(.custom(FontFamily.Rubik.medium, size: 12))
                            .tracking(0.48)
                            .textCase(.uppercase)
                            .foregroundStyle(eyebrowColor(for: kind))
                        if kind != .paid {
                            Text(shortDate(row.dueDate))
                                .font(.custom(FontFamily.Rubik.regular, size: 12).italic())
                                .foregroundStyle(dimText)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(formatCurrency(row.amount))
                    .font(.custom(kind == .paid ? FontFamily.Rubik.medium : FontFamily.Rubik.bold, size: 18))
                    .tracking(-0.18)
                    .foregroundStyle(amountColor(for: kind))
                    .strikethrough(kind == .paid, color: dimText)

                if !isSelecting {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(dimText)
                        .frame(width: 16, alignment: .trailing)
                }
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    guard !isSelecting, case .bill(let bill) = row else { return }
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    enterBillsSelection(with: bill)
                }
        )
    }

    private func selectionIndicator(selected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(selected ? accentPurple : cream.opacity(0.32), lineWidth: 1.5)
                .frame(width: 18, height: 18)
            if selected {
                Circle()
                    .fill(accentPurple)
                    .frame(width: 12, height: 12)
            }
        }
        .frame(width: 18, height: 18)
    }

    private func statusDot(for kind: RowKind) -> some View {
        Group {
            switch kind {
            case .overdue:
                Circle().fill(accentPurple)
            case .upcoming:
                Circle().fill(cream.opacity(0.65))
            case .paid:
                Circle()
                    .stroke(dimText, lineWidth: 1)
            }
        }
        .frame(width: 8, height: 8)
    }

    private func eyebrowColor(for kind: RowKind) -> Color {
        switch kind {
        case .overdue: return accentPurple
        case .upcoming: return mutedText
        case .paid: return dimText
        }
    }

    private func amountColor(for kind: RowKind) -> Color {
        switch kind {
        case .overdue: return accentPurple
        case .upcoming: return cream
        case .paid: return dimText
        }
    }

    // MARK: - Selection mode

    private func enterBillsSelection(with bill: Bill) {
        guard let id = bill.id else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            isSelecting = true
            selectionScope = .bills
            selectedBillIds.insert(id)
        }
    }

    private func enterIntentionsSelection(with token: NoteToken) {
        withAnimation(.easeInOut(duration: 0.18)) {
            isSelecting = true
            selectionScope = .intentions
            selectedIntentionIds.insert(token.id)
        }
    }

    private func toggleSelection(_ bill: Bill) {
        guard let id = bill.id else { return }
        if selectedBillIds.contains(id) {
            selectedBillIds.remove(id)
        } else {
            selectedBillIds.insert(id)
        }
    }

    private func toggleIntentionSelection(_ token: NoteToken) {
        if selectedIntentionIds.contains(token.id) {
            selectedIntentionIds.remove(token.id)
        } else {
            selectedIntentionIds.insert(token.id)
        }
    }

    private func exitSelection() {
        withAnimation(.easeInOut(duration: 0.18)) {
            isSelecting = false
            selectedBillIds.removeAll()
            selectedIntentionIds.removeAll()
            selectionScope = .bills
        }
    }

    private var hasSelection: Bool {
        switch selectionScope {
        case .bills: return !selectedBillIds.isEmpty
        case .intentions: return !selectedIntentionIds.isEmpty
        }
    }

    private var selectionCount: Int {
        switch selectionScope {
        case .bills: return selectedBillIds.count
        case .intentions: return selectedIntentionIds.count
        }
    }

    private func performBulkDelete() {
        let toDelete = billViewModel.bills.filter { bill in
            bill.id.map { selectedBillIds.contains($0) } ?? false
        }
        isDeleting = true
        Task {
            for bill in toDelete {
                await billViewModel.deleteBill(bill)
            }
            await MainActor.run {
                isDeleting = false
                exitSelection()
            }
        }
    }

    // MARK: - Upgrade sheet

    private var upgradeSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("upgrade to commitment")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 22))
                        .foregroundStyle(cream)
                    Text("\(selectedIntentionIds.count) \(selectedIntentionIds.count == 1 ? "intention" : "intentions") · \(formatCurrency(selectedIntentionsTotal))")
                        .font(.custom(FontFamily.Rubik.medium, size: 13))
                        .foregroundStyle(mutedText)
                }

                DatePicker(
                    "due date",
                    selection: $upgradeDueDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(accentPurple)

                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    performUpgradeToCommitment()
                } label: {
                    Text(isUpgrading ? "upgrading…" : "upgrade")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                        .foregroundStyle(onAccentText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(accentPurple))
                }
                .buttonStyle(.plain)
                .disabled(isUpgrading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(bg.ignoresSafeArea())
        }
        .preferredColorScheme(.dark)
    }

    private var selectedIntentionsTotal: Double {
        monthlyIntentions
            .filter { selectedIntentionIds.contains($0.id) }
            .reduce(0) { $0 + $1.amount }
    }

    private func defaultUpgradeDueDate() -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: displayedMonthDate)
        let firstOfMonth = cal.date(from: comps) ?? Date()
        return cal.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth) ?? Date()
    }

    private func performUpgradeToCommitment() {
        let targets = allTokens.filter { selectedIntentionIds.contains($0.id) && $0.kind == .intent }
        guard !targets.isEmpty else { return }
        isUpgrading = true
        let due = upgradeDueDate
        Task {
            await MainActor.run {
                let now = Date()
                for token in targets {
                    token.kindRaw = NoteToken.Kind.commit.rawValue
                    token.occurredAt = due
                    // Mark as user-adjusted so re-extraction of the source note
                    // doesn't revert this commitment back to a raw intention.
                    token.userAdjustedAt = now
                }
                try? modelContext.save()
                isUpgrading = false
                showUpgradeSheet = false
                exitSelection()
            }
        }
    }

    /// Push the selected intentions into the next month. Intentions are bucketed
    /// by `occurredAt` month, so advancing one month moves it to next month's
    /// list. Stamps `userAdjustedAt` so the move survives note re-extraction.
    private func performAdvanceIntentions() {
        let targets = allTokens.filter { selectedIntentionIds.contains($0.id) && $0.kind == .intent }
        guard !targets.isEmpty else { return }
        isAdvancing = true
        let cal = Calendar.current
        let now = Date()
        for token in targets {
            if let advanced = cal.date(byAdding: .month, value: 1, to: token.occurredAt) {
                token.occurredAt = advanced
            }
            token.userAdjustedAt = now
        }
        try? modelContext.save()
        isAdvancing = false
        exitSelection()
    }

    private func performBulkMarkPaid() {
        let toMark = billViewModel.bills.filter { bill in
            bill.id.map { selectedBillIds.contains($0) } ?? false
        }
        guard !toMark.isEmpty else { return }
        isMarkingPaid = true
        Task {
            await billViewModel.markBillsAsPaid(toMark)
            await MainActor.run {
                isMarkingPaid = false
                exitSelection()
            }
        }
    }

    /// Plain-text export of bills for sharing via iMessage / mail / etc.
    private var exportText: String {
        let amountFormatter = NumberFormatter()
        amountFormatter.numberStyle = .currency
        amountFormatter.currencyCode = currency
        amountFormatter.maximumFractionDigits = 2

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"

        let lines = billViewModel.bills
            .sorted { $0.dueDate < $1.dueDate }
            .map { bill -> String in
                let amount = amountFormatter.string(from: NSNumber(value: bill.amount))
                    ?? String(format: "$%.2f", bill.amount)
                let date = dateFormatter.string(from: bill.dueDate)
                return "\(bill.name) — \(amount) — due \(date)"
            }

        return lines.joined(separator: "\n")
    }

    // MARK: - Computed: month context

    private var displayedMonthDate: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        let firstOfThisMonth = cal.date(from: comps) ?? Date()
        if selectedTab == .nextMonth {
            return cal.date(byAdding: .month, value: 1, to: firstOfThisMonth) ?? firstOfThisMonth
        }
        return firstOfThisMonth
    }

    private var monthShortLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f.string(from: displayedMonthDate).lowercased()
    }

    // MARK: - Computed: bills

    private var monthlyIncome: Double {
        sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private var monthlyBills: [Bill] {
        let cal = Calendar.current
        return billViewModel.bills
            .filter { bill in
                cal.isDate(bill.effectiveDueDate, equalTo: displayedMonthDate, toGranularity: .month)
            }
            .sorted { $0.effectiveDueDate < $1.effectiveDueDate }
    }

    /// `.commit` tokens whose due date (`occurredAt`) falls in the displayed
    /// month. Folded into the bill sections so they read as one-time bills.
    private var monthlyCommitments: [NoteToken] {
        let cal = Calendar.current
        return allTokens.filter { token in
            token.kind == .commit
            && cal.isDate(token.occurredAt, equalTo: displayedMonthDate, toGranularity: .month)
        }
    }

    /// `.intent` tokens whose creation date falls in the displayed month.
    /// Filter by `occurredAt` since for intents that field carries the
    /// creation date (see NoteToken.Kind.intent docs).
    private var monthlyIntentions: [NoteToken] {
        let cal = Calendar.current
        return allTokens
            .filter { token in
                token.kind == .intent
                && cal.isDate(token.occurredAt, equalTo: displayedMonthDate, toGranularity: .month)
            }
            .sorted { $0.occurredAt < $1.occurredAt }
    }

    private var totalBillsForMonth: Double {
        monthlyBills.reduce(0) { $0 + $1.amount }
    }

    private var totalCommitments: Double {
        monthlyCommitments.reduce(0) { $0 + $1.amount }
    }

    private var totalIntentions: Double {
        monthlyIntentions.reduce(0) { $0 + $1.amount }
    }

    /// Total subtracted from income on the hero. Always counts bills and
    /// commitments. Counts intentions only when the toggle is on.
    private var totalDeductionsForMonth: Double {
        var sum = totalBillsForMonth + totalCommitments
        if includeIntentions { sum += totalIntentions }
        return sum
    }

    // MARK: - Computed: balance / runway (shared with the home's math)

    private var freedomFund: Double {
        sessionViewModel.currentUser?.settings.freedomFund ?? 0
    }

    /// Raw monthly bill total across all bills — matches the value the home
    /// feeds the runway engine, so the what-if runway lines up with the home.
    private var allMonthlyBills: Double {
        billViewModel.bills.reduce(0) { $0 + $1.amount }
    }

    private var userEntries: [FreedomFundEntry] {
        let uid = sessionViewModel.currentUser?.userId
        return allEntries.filter { uid == nil || $0.userId == uid }
    }

    private var dailyBurn: Double {
        let income = sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
        return ArcCalculationService.dailyBurn(entries: userEntries, monthlyBills: allMonthlyBills, monthlyIncome: income)
    }

    private func runwayDays(for balance: Double) -> Int? {
        dailyBurn > 0 ? Int(floor(max(0, balance) / dailyBurn)) : nil
    }

    /// After-bills headroom expressed as a weekly spend rate — the same monthly
    /// number the hero shows, made actionable at the cadence people budget by.
    private var safeToSpendPerWeek: Double {
        netAfterBills / 4.33
    }

    private var whatIfValue: Double {
        Double(whatIfAmount.filter { $0.isNumber || $0 == "." }) ?? 0
    }

    private var netAfterBills: Double {
        max(0, monthlyIncome - totalDeductionsForMonth)
    }

    // MARK: - Unified bill rows (Bill + commit NoteToken)
    //
    // Each row in the bills sections is either a real Bill or a `.commit`
    // token rendered to look identical. We wrap both in a single enum so
    // ordering and section bucketing read off one list.

    enum BillRow: Identifiable {
        case bill(Bill)
        case commitment(NoteToken)

        var id: String {
            switch self {
            case .bill(let b): return "bill-\(b.id ?? UUID().uuidString)"
            case .commitment(let t): return "commit-\(t.id.uuidString)"
            }
        }

        var name: String {
            switch self {
            case .bill(let b): return b.name
            case .commitment(let t): return t.subject ?? "commitment"
            }
        }

        var amount: Double {
            switch self {
            case .bill(let b): return b.amount
            case .commitment(let t): return t.amount
            }
        }

        var dueDate: Date {
            switch self {
            case .bill(let b): return b.effectiveDueDate
            case .commitment(let t): return t.occurredAt
            }
        }

        var isPaid: Bool {
            switch self {
            case .bill(let b): return b.isPaidThisCycle
            case .commitment: return false
            }
        }

        /// Underlying bill ID (used for selection). Nil for commitments —
        /// commitments aren't selectable in the bills scope.
        var billId: String? {
            if case .bill(let b) = self { return b.id }
            return nil
        }
    }

    private var monthlyBillRows: [BillRow] {
        let billRows = monthlyBills.map { BillRow.bill($0) }
        let commitRows = monthlyCommitments.map { BillRow.commitment($0) }
        return (billRows + commitRows).sorted { $0.dueDate < $1.dueDate }
    }

    private var overdueRows: [BillRow] {
        let now = Calendar.current.startOfDay(for: Date())
        return monthlyBillRows.filter { !$0.isPaid && Calendar.current.startOfDay(for: $0.dueDate) < now }
    }

    private var upcomingRows: [BillRow] {
        let now = Calendar.current.startOfDay(for: Date())
        return monthlyBillRows.filter { !$0.isPaid && Calendar.current.startOfDay(for: $0.dueDate) >= now }
    }

    private var paidRows: [BillRow] {
        monthlyBillRows.filter { $0.isPaid }
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

    private func eyebrowText(forDate dueDate: Date, kind: RowKind) -> String {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let due = cal.startOfDay(for: dueDate)
        let days = cal.dateComponents([.day], from: now, to: due).day ?? 0
        switch kind {
        case .overdue:
            let n = max(0, -days)
            return "overdue \(n)d"
        case .upcoming:
            if days == 0 { return "due today" }
            return "in \(days) \(days == 1 ? "day" : "days")"
        case .paid:
            return "paid \(shortDate(dueDate))"
        }
    }
}

// MARK: - Info Popover

struct ForecastInfoPopover: View {
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color("NormaPastelTeal"))

                    Text("your month")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 20))
                        .foregroundColor(.primary)
                }

                Text("the hero shows what's left after everything due this month — income minus bills and commitments. switch between this month and next month to plan ahead.")
                    .font(.normaInput(16))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                HStack(spacing: 10) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 20))
                        .foregroundColor(NormaPalette.lavender)

                    Text("intentions")
                        .font(.custom(FontFamily.Rubik.medium, size: 17))
                        .foregroundColor(.primary)
                }

                Text("an intention is something you're thinking about spending on — tell norma \"thinking about a $200 trip\" and it lands here. they don't count against your month unless you upgrade them.")
                    .font(.normaInput(16))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 20))
                        .foregroundColor(NormaPalette.lavender)

                    Text("commitments")
                        .font(.custom(FontFamily.Rubik.medium, size: 17))
                        .foregroundColor(.primary)
                }

                Text("when you're ready to act on an intention, long-press it and upgrade it to a commitment. commitments act like one-time bills — they get a due date and show up in the bills sections.")
                    .font(.normaInput(16))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                HStack(spacing: 10) {
                    Image(systemName: "switch.2")
                        .font(.system(size: 20))
                        .foregroundColor(NormaPalette.lavender)

                    Text("what-if toggle")
                        .font(.custom(FontFamily.Rubik.medium, size: 17))
                        .foregroundColor(.primary)
                }

                Text("flip \"if i committed everything\" to see your month with all intentions counted. handy for sanity-checking before you upgrade anything.")
                    .font(.normaInput(16))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .frame(width: 320, height: 500)
        .background(Color("NormaBackground"))
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
