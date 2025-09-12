import SwiftUI

struct ExpenseTrackerChartView: View {
    let billAmount: Double
    let currentExpenseAmount: Double
    let incomeAmount: Double
    let month: String
    let isOnboardingMode: Bool
    @Binding var showNormaChat: Bool
    var isScrolling: Bool = false
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @State private var chartAppeared = false
    @State private var dotsAppeared = false
    @State private var insightsAppeared = false
    @State private var hasTriggeredFallback = false
    
    init(billAmount: Double = 0, currentExpenseAmount: Double = 0, incomeAmount: Double, month: String = "Monthly", isOnboardingMode: Bool = false, showNormaChat: Binding<Bool> = .constant(false)) {
        self.billAmount = billAmount
        self.currentExpenseAmount = currentExpenseAmount
        self.incomeAmount = incomeAmount
        self.month = month
        self.isOnboardingMode = isOnboardingMode
        self._showNormaChat = showNormaChat
    }
    
    var body: some View {
        VStack(spacing: 24) {
            if isOnboardingMode {
                ExpenseTrackerOnboardingView(
                    incomeAmount: incomeAmount,
                    showNormaChat: $showNormaChat
                )
            } else {
                ExpenseTrackerRegularView(
                    billAmount: billAmount,
                    currentExpenseAmount: currentExpenseAmount,
                    incomeAmount: incomeAmount,
                    month: month,
                    isScrolling: isScrolling,
                    chartAppeared: chartAppeared,
                    dotsAppeared: dotsAppeared,
                    insightsAppeared: insightsAppeared
                )
            }
        }
        .onAppear {
            triggerAnimationsIfDataReady()
            
            // Fallback: Always trigger animations after a delay if they haven't triggered yet
            if !hasTriggeredFallback {
                hasTriggeredFallback = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if !chartAppeared {
                        // Force trigger animations even without data
                        withAnimation(.easeOut(duration: 0.8)) {
                            chartAppeared = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                                insightsAppeared = true
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                dotsAppeared = true
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: incomeAmount) { _, _ in
            triggerAnimationsIfDataReady()
        }
        .onChange(of: billAmount) { _, _ in
            triggerAnimationsIfDataReady()
        }
        .onChange(of: currentExpenseAmount) { _, _ in
            triggerAnimationsIfDataReady()
        }
    }
    
    private func triggerAnimationsIfDataReady() {
        // Check if we have meaningful data
        let hasData = incomeAmount > 0 || billAmount > 0 || currentExpenseAmount > 0
        
        print("📊 ExpenseTrackerChartView: triggerAnimationsIfDataReady - hasData: \(hasData), chartAppeared: \(chartAppeared), dotsAppeared: \(dotsAppeared)")
        print("   💰 Data values - income: \(incomeAmount), bills: \(billAmount), current: \(currentExpenseAmount)")
        
        if !chartAppeared && hasData {
            print("   ✅ Triggering chart animations")
            // Trigger all animations immediately when data is ready
            withAnimation(.easeOut(duration: 0.8)) {
                chartAppeared = true
            }
            
            // Use DispatchQueue for reliable timing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    insightsAppeared = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    dotsAppeared = true
                    print("   🎯 dotsAppeared set to true")
                }
            }
        } else if chartAppeared && !dotsAppeared {
            // If chart appeared but dots haven't (edge case), trigger dots
            print("   ⚠️ Edge case: chart appeared but dots haven't, triggering dots now")
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                dotsAppeared = true
            }
        }
    }
}

struct ExpenseTrackerChartView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Onboarding mode preview
                ExpenseTrackerChartView(
                    incomeAmount: 3000,
                    month: "December",
                    isOnboardingMode: true,
                    showNormaChat: .constant(false)
                )
                
                // Regular mode previews
                ExpenseTrackerChartView(
                    billAmount: 0,
                    currentExpenseAmount: 0,
                    incomeAmount: 0,
                    month: "December",
                    showNormaChat: .constant(false)
                )
                
                ExpenseTrackerChartView(
                    billAmount: 1500,
                    currentExpenseAmount: 2800,
                    incomeAmount: 3000,
                    month: "December",
                    showNormaChat: .constant(false)
                )
                
                ExpenseTrackerChartView(
                    billAmount: 1500,
                    currentExpenseAmount: 3200,
                    incomeAmount: 3000,
                    month: "December",
                    showNormaChat: .constant(false)
                )
            }
        }
        .preferredColorScheme(.light)
    }
}