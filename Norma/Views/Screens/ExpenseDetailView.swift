//
//  ExpenseDetailView.swift
//  Norma
//
//  Created by Claude on 7/12/25.
//

import SwiftUI

struct ExpenseDetailView: View {
    let expense: Expense
    
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var billViewModel: BillViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showEditExpenseSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showDuplicateSuccess = false
    @State private var showLinkToBillSheet = false
    
    private var expenseDate: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: expense.expenseDate) ?? Date()
    }
    
    private var linkedBill: Bill? {
        guard let billId = expense.billId else { return nil }
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
                    // Expense details section
                    expenseDetailsView
                    
                    // Payment information
                    paymentInfoView
                    
                    // Linked bill information
                    if linkedBill != nil {
                        linkedBillView
                    }
                    
                    // Additional details
                    if expense.isRecurring || expense.merchant != nil || expense.location != nil {
                        additionalDetailsView
                    }
                    
                    // Tags
                    if !expense.tags.isEmpty {
                        tagsView
                    }
                    
                    // Notes
                    if let notes = expense.notes, !notes.isEmpty {
                        notesView(notes: notes)
                    }
                    
                    // Actions
                    actionButtonsView
                }
                .padding()
            }
            .navigationTitle("Expense Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showEditExpenseSheet = true
                    }) {
                        Text("Edit")
                            .fontWeight(.medium)
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
        .alert("Expense Duplicated", isPresented: $showDuplicateSuccess) {
            Button("OK") { }
        } message: {
            Text("A copy of this expense has been created.")
        }
    }
    
    @ViewBuilder
    private var expenseDetailsView: some View {
        VStack(spacing: 16) {
            // Header with amount and name
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if let merchant = expense.merchant {
                        Text(merchant)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(expense.amount, specifier: "%.2f")")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: paymentMethodIcon)
                            .font(.system(size: 12))
                        Text(expense.paymentMethod.rawValue)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(paymentMethodColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            // Date and recurring info
            HStack {
                Label {
                    Text(expenseDate, format: .dateTime.weekday(.wide).month(.wide).day().year())
                        .font(.system(size: 14))
                } icon: {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                if expense.isRecurring {
                    Label {
                        Text(expense.recurringFrequency?.rawValue ?? "Recurring")
                            .font(.system(size: 14))
                    } icon: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.purple)
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var paymentInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Details")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 0) {
                // Payment method
                HStack {
                    Text("Method")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: paymentMethodIcon)
                            .font(.system(size: 12))
                        Text(expense.paymentMethod.rawValue)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(paymentMethodColor)
                }
                .padding(.vertical, 12)
                
                if let location = expense.location {
                    Divider()
                    HStack {
                        Text("Location")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(location)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.vertical, 12)
                }
            }
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    @ViewBuilder
    private var linkedBillView: some View {
        if let bill = linkedBill {
            VStack(alignment: .leading, spacing: 12) {
                Text("Linked to Bill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bill.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        Text("Due \(bill.dueDate, format: .dateTime.month().day())")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "link")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )
            }
        }
    }
    
    private var additionalDetailsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional Information")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 0) {
                if let merchant = expense.merchant, expense.location == nil {
                    HStack {
                        Text("Merchant")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(merchant)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 12)
                }
                
                if expense.isRecurring, let frequency = expense.recurringFrequency {
                    if expense.merchant != nil && expense.location == nil {
                        Divider()
                    }
                    HStack {
                        Text("Frequency")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12))
                            Text(frequency.rawValue)
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.purple)
                    }
                    .padding(.vertical, 12)
                }
            }
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    private var tagsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            FlowLayout(spacing: 8) {
                ForEach(expense.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 13))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.purple.opacity(0.15))
                        )
                        .foregroundColor(.purple)
                }
            }
        }
    }
    
    private func notesView(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(notes)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // Primary actions
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await duplicateExpense()
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 20))
                        Text("Duplicate")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .foregroundColor(.blue)
                }
                
                if expense.billId == nil {
                    Button(action: {
                        showLinkToBillSheet = true
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "link")
                                .font(.system(size: 20))
                            Text("Link to Bill")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple.opacity(0.1))
                        )
                        .foregroundColor(.purple)
                    }
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
                        .font(.system(size: 16, weight: .medium))
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
    
    private func duplicateExpense() async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())
        
        let success = await expenseViewModel.addExpense(
            name: expense.name,
            amount: expense.amount,
            expenseDate: todayString,
            categoryId: expense.categoryId,
            billId: expense.billId,
            paymentMethod: expense.paymentMethod,
            isRecurring: expense.isRecurring,
            recurringFrequency: expense.recurringFrequency,
            merchant: expense.merchant,
            location: expense.location,
            tags: expense.tags,
            notes: expense.notes,
            attachmentUrls: expense.attachmentUrls
        )
        
        if success {
            showDuplicateSuccess = true
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

// Placeholder for LinkToBillView
struct LinkToBillView: View {
    let expense: Expense
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Link to Bill")
                    .font(.title)
                Text("Select a bill to link this expense to")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Link to Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
}

