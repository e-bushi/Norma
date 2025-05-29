//
//  BillListView.swift
//  Collector
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

// Filter options enum
enum BillFilter: String, CaseIterable {
    case all = "All"
    case paid = "Paid"
    case scheduled = "Scheduled"
    case overdue = "Overdue"
}

struct BillListView: View {
    // Bills and filters
    let bills: [Bill]
    @Binding var selectedFilter: BillFilter
    @Binding var selectedDate: Date
    @Binding var showAllDates: Bool
    
    // Animation state
    @Namespace private var animation
    @State private var appearAnimation = false
    
    // Computed properties for filtered bills
    private var filteredBills: [Bill] {
        switch selectedFilter {
        case .all:
            return bills
        case .paid:
            return bills.filter { $0.status == .paid }
        case .scheduled:
            return bills.filter { $0.status == .scheduled }
        case .overdue:
            return bills.filter { $0.status == .overdue }
        }
    }
    
    private var filteredAndDateFilteredBills: [Bill] {
        if showAllDates {
            return filteredBills
        } else {
            let calendar = Calendar.current
            return filteredBills.filter { bill in
                calendar.isDate(bill.date, inSameDayAs: selectedDate)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Filter selector with enhanced animation
            VStack(spacing: 4) {
                // Picker with custom transitions
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(BillFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue)
                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                            .matchedGeometryEffect(id: "filter_\(filter.rawValue)", in: animation, isSource: selectedFilter == filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .scaleEffect(x: appearAnimation ? 1 : 0.98, y: appearAnimation ? 1 : 0.98)
                .animation(.spring(response: 0.3), value: appearAnimation)
            }
            .onChange(of: selectedFilter) {
                // Create a smooth transition effect
                withAnimation(.easeOut(duration: 0.2)) {
                    appearAnimation = false
                }
                
                // Use a slightly longer delay for more visual separation between states
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        appearAnimation = true
                    }
                }
            }
            
            // Bills content
            if filteredAndDateFilteredBills.isEmpty {
                emptyStateView
            } else {
                billListView
            }
        }
        .onAppear {
            // Trigger initial animation when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    appearAnimation = true
                }
            }
        }
        .onChange(of: selectedDate) {
            refreshAnimation()
        }
        .onChange(of: showAllDates) {
            refreshAnimation()
        }
    }
    
    // Empty state view when no bills match the current filter/date
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.top, 60)
                .scaleEffect(appearAnimation ? 1 : 0.8)
                .opacity(appearAnimation ? 1 : 0)
            
            Text("No bills found")
                .font(.title3)
                .foregroundColor(.secondary)
                .scaleEffect(appearAnimation ? 1 : 0.9)
                .opacity(appearAnimation ? 1 : 0)
            
            Text(showAllDates ? "Try changing the filter" : "Try selecting a different date")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .scaleEffect(appearAnimation ? 1 : 0.9)
                .opacity(appearAnimation ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1), value: appearAnimation)
    }
    
    // Bill list view when there are bills to show
    private var billListView: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(filteredAndDateFilteredBills.enumerated()), id: \.element.id) { index, bill in
                Button(action: {
                    // Handle bill tap action - show bill details, etc.
                }) {
                    BillCardView(
                        name: bill.name,
                        date: bill.date,
                        amount: bill.amount,
                        status: bill.status,
                        frequency: bill.frequency
                    )
                }
                .padding(.horizontal)
                // Apply multiple transformations for a more interesting animation
                .offset(x: appearAnimation ? 0 : -20)
                .scaleEffect(appearAnimation ? 1 : 0.95)
                .opacity(appearAnimation ? 1 : 0)
                // Add slight rotation for a more dynamic effect
                .rotation3DEffect(
                    .degrees(appearAnimation ? 0 : -5),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
                // Use a spring animation with staggered delay based on index
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0.3)
                    .delay(0.08 + Double(index) * 0.06),
                    value: appearAnimation
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
                .id("\(bill.id)-\(selectedFilter)-\(selectedDate)-\(showAllDates)")
                .buttonStyle(TapToBounceStyle())
            }
        }
        .padding(.vertical)
    }
    
    // Helper method to refresh animation state
    private func refreshAnimation() {
        withAnimation {
            appearAnimation = false
        }
        
        // Delay the animation slightly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation {
                appearAnimation = true
            }
        }
    }
}

// Custom button style that adds a bounce animation when tapped
struct TapToBounceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// Preview
struct BillListView_Previews: PreviewProvider {
    static var previews: some View {
        struct PreviewWrapper: View {
            let sampleBills = [
                Bill(
                    name: "Electricity Bill",
                    date: Date(),
                    amount: 87.50,
                    status: .paid,
                    frequency: .monthly
                ),
                Bill(
                    name: "Internet Service",
                    date: Date().addingTimeInterval(-86400 * 5),
                    amount: 65.99,
                    status: .overdue,
                    frequency: .monthly
                ),
                Bill(
                    name: "Rent Payment",
                    date: Date().addingTimeInterval(86400 * 3),
                    amount: 1200.00,
                    status: .scheduled,
                    frequency: .monthly
                )
            ]
            
            @State private var selectedFilter: BillFilter = .all
            @State private var selectedDate: Date = Date()
            @State private var showAllDates: Bool = true
            
            var body: some View {
                BillListView(
                    bills: sampleBills,
                    selectedFilter: $selectedFilter,
                    selectedDate: $selectedDate,
                    showAllDates: $showAllDates
                )
                .padding(.vertical)
            }
        }
        
        return NavigationStack {
            PreviewWrapper()
        }
    }
}
