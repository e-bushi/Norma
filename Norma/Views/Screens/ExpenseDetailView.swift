//
//  ExpenseDetailView.swift
//  Norma
//
//  Created by Claude on 7/12/25.
//

import SwiftUI

struct ExpenseDetailView: View {
    let expense: Expense
    var expenseBinding: Binding<Expense>?
    
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var showEditExpenseSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showLinkToBillSheet = false
    @State private var showLinkedBillCard = false
    
    private var expenseDate: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: expense.expenseDate) ?? Date()
    }
    
    // Use binding if provided, otherwise fall back to looking up from view model
    private var currentExpense: Expense {
        if let binding = expenseBinding {
            return binding.wrappedValue
        }
        guard let expenseId = expense.id else { return expense }
        return expenseViewModel.expenses.first { $0.id == expenseId } ?? expense
    }

    private var linkedBill: Bill? {
        guard let billId = currentExpense.billId else { return nil }
        return billViewModel.bills.first { $0.id == billId }
    }
    
    private var paymentMethodIcon: String {
        switch expense.paymentMethod {
        case .cash:
            return "banknote.fill"
        case .creditCard:
            return "creditcard.fill"
        case .debitCard:
            return "creditcard"
        case .bankTransfer:
            return "building.columns.fill"
        case .digitalWallet:
            return "wallet.pass.fill"
        case .check:
            return "checkmark.rectangle.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
    
    private var paymentMethodColor: Color {
        switch expense.paymentMethod {
        case .cash:
            return .green
        case .creditCard, .debitCard:
            return .blue
        case .bankTransfer:
            return .purple
        case .digitalWallet:
            return .orange
        case .check:
            return .gray
        case .other:
            return .secondary
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with centered icon and name
                    headerView

                    // Expense details card
                    expenseDetailsCard

                    // Linked items
                    linkedItemsView

                    // Actions
                    actionButtonsView
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Expense Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Set initial state for linked items
                showLinkedBillCard = linkedBill != nil
            }
            .onChange(of: currentExpense.billId) { oldValue, newValue in
                // Animate when bill gets linked (from nil to having a value)
                if oldValue == nil && newValue != nil {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showLinkedBillCard = true
                    }
                }
            }
        }
        .sheet(isPresented: $showEditExpenseSheet) {
            EditExpenseView(expense: expense)
                .environmentObject(expenseViewModel)
                .environmentObject(billViewModel)
        }
        .sheet(isPresented: $showLinkToBillSheet) {
            LinkToBillView(expense: expense)
                .environmentObject(expenseViewModel)
                .environmentObject(billViewModel)
        }
        .alert("Delete Expense", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteExpense()
                }
            }
        } message: {
            Text("Are you sure you want to delete this expense? This action cannot be undone.")
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 12) {
            // Payment method icon
            Circle()
                .fill(paymentMethodColor.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: paymentMethodIcon)
                        .font(.system(size: 26))
                        .foregroundColor(paymentMethodColor)
                )

            // Expense name and amount
            VStack(spacing: 4) {
                Text(expense.name)
                    .font(.normaTitle(24))
                    .foregroundColor(.primary)

                Text(profileViewModel.formatCurrency(expense.amount))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)

                if let merchant = expense.merchant {
                    Text(merchant)
                        .font(.normaHeadline(14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var expenseDetailsCard: some View {
        VStack(spacing: 12) {
            // Payment method
            DetailRowView(
                label: "Payment Method",
                value: expense.paymentMethod.rawValue,
                icon: paymentMethodIcon,
                iconColor: paymentMethodColor
            )

            if !expense.tags.isEmpty {
                Divider()
                HStack {
                    Text("Date")
                        .font(.normaHeadline(14))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(expenseDate, format: .dateTime.month().day().year())
                        .font(.normaHeadline(14))
                        .foregroundColor(.primary)
                }
            }

            if expense.isRecurring, let frequency = expense.recurringFrequency {
                Divider()
                DetailRowView(
                    label: "Frequency",
                    value: frequency.rawValue,
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: .purple
                )
            }

            if let location = expense.location {
                Divider()
                HStack {
                    Text("Location")
                        .font(.normaHeadline(14))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(location)
                        .font(.normaHeadline(14))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.trailing)
                }
            }

            if !expense.tags.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.normaHeadline(14))
                        .foregroundColor(.secondary)

                    FlowLayout(spacing: 6) {
                        ForEach(expense.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.normaHeadline(11))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.purple.opacity(0.15))
                                )
                                .foregroundColor(.purple)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let notes = expense.notes, !notes.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.normaHeadline(14))
                        .foregroundColor(.secondary)

                    Text(notes)
                        .font(.normaHeadline(13))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private var linkedItemsView: some View {
        if linkedBill != nil {
            VStack(spacing: 12) {
                if let bill = linkedBill, showLinkedBillCard {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Linked to Bill")
                                .font(.normaHeadline(10))
                                .foregroundColor(.secondary)
                            Text(bill.name)
                                .font(.normaHeadline(12))
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        Text("Due \(bill.dueDate, format: .dateTime.month().day())")
                            .font(.normaHeadline(10))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .scaleEffect(showLinkedBillCard ? 1.0 : 0.8)
                    .opacity(showLinkedBillCard ? 1.0 : 0.0)
                }
            }
        }
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // Link to Bill button
            if linkedBill == nil {
                Button(action: {
                    showLinkToBillSheet = true
                }) {
                    HStack {
                        Image(systemName: "link")
                            .font(.system(size: 16))
                        Text("Link to Bill")
                            .font(.normaHeadline(16))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .foregroundColor(.blue)
                }
            }

            // Delete button
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                    Text("Delete Expense")
                        .font(.normaHeadline(16))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                )
                .foregroundColor(.red)
            }
        }
        .padding(.top, 8)
    }
    
    private func deleteExpense() async {
        await expenseViewModel.deleteExpense(expense)
        dismiss()
    }
    
}

// Detail row component
struct DetailRowView: View {
    let label: String
    let value: String
    let icon: String
    let iconColor: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.normaHeadline(14))
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(value)
                    .font(.normaHeadline(14))
            }
            .foregroundColor(iconColor)
        }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: ProposedViewSize(frame.size))
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var frames: [CGRect]
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var frames: [CGRect] = []
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxX: CGFloat = 0
            
            for subview in subviews {
                let viewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + viewSize.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: viewSize))
                lineHeight = max(lineHeight, viewSize.height)
                currentX += viewSize.width + spacing
                maxX = max(maxX, currentX)
            }
            
            self.size = CGSize(width: maxX - spacing, height: currentY + lineHeight)
            self.frames = frames
        }
    }
}

// Placeholder for EditExpenseView
struct EditExpenseView: View {
    let expense: Expense
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Edit Expense")
                    .font(.title)
                Text("Edit functionality coming soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}



#Preview {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    let sampleExpense = Expense(
        id: "1",
        userId: "preview-user-123",
        name: "Groceries",
        amount: 142.75,
        expenseDate: dateFormatter.string(from: Date()),
        paymentMethod: .creditCard,
        isRecurring: false,
        recurringFrequency: nil,
        merchant: "Whole Foods Market",
        location: "123 Main St, San Francisco, CA",
        tags: ["food", "groceries", "weekly shopping"],
        notes: "Weekly grocery shopping. Bought extra items for the dinner party this weekend.",
        attachmentUrls: []
    )
    
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let expenseViewModel = ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    let billViewModel = BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
    
    return ExpenseDetailView(expense: sampleExpense)
        .environmentObject(expenseViewModel)
        .environmentObject(billViewModel)
        .environmentObject(dataManager)
        .environmentObject(ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
}

