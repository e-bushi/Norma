import SwiftUI

struct ExpenseTrackerChartView: View {
    let billAmount: Double
    let currentExpenseAmount: Double
    let incomeAmount: Double
    let month: String
    
    @State private var showDescription = false
    
    init(billAmount: Double, currentExpenseAmount: Double, incomeAmount: Double, month: String = "Monthly") {
        self.billAmount = billAmount
        self.currentExpenseAmount = currentExpenseAmount
        self.incomeAmount = incomeAmount
        self.month = month
    }
    
    private let lineHeight: CGFloat = 400
    private let dotSize: CGFloat = 16
    private let chartWidth: CGFloat = 320
    
    private var expensePosition: CGFloat {
        let range = incomeAmount - billAmount
        let progress = (currentExpenseAmount - billAmount) / range
        return CGFloat(1 - progress.clamped(to: 0...1)) * lineHeight
    }
    
    private var expensePercentage: Double {
        let range = incomeAmount - billAmount
        let progress = (currentExpenseAmount - billAmount) / range
        return progress.clamped(to: 0...1) * 100
    }
    
    private var isOverBudget: Bool {
        currentExpenseAmount > incomeAmount
    }
    
    private var budgetStatus: (text: String, color: Color) {
        if currentExpenseAmount < billAmount * 1.1 {
            return ("Great start", .green)
        } else if currentExpenseAmount < incomeAmount * 0.7 {
            return ("On track", .blue)
        } else if currentExpenseAmount < incomeAmount * 0.9 {
            return ("Watch spending", .yellow)
        } else if currentExpenseAmount <= incomeAmount {
            return ("Near limit", .orange)
        } else {
            return ("Over budget", .red)
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Enhanced header with status
            VStack(spacing: 12) {
                // Progress badge
                Text("\(month.uppercased())'S PROGRESS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                
                // Smart insights
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Remaining")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("$\(Int(max(0, incomeAmount - currentExpenseAmount)))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Daily Budget")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("$\(Int((incomeAmount - billAmount) / 30))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                )
            }

            // Main chart
            ZStack {
                // Elegant background with grid
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(UIColor.systemBackground),
                                Color.gray.opacity(0.02)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.2),
                                        Color.gray.opacity(0.05)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Chart content
                ZStack(alignment: .center) {
                    let centerX: CGFloat = chartWidth / 2
                    
                    // Subtle grid lines
                    VStack(spacing: lineHeight / 4) {
                        ForEach(0..<4) { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.05))
                                .frame(height: 0.5)
                        }
                    }
                    .frame(width: chartWidth * 0.8)
                    
                    
                    // Vertical reference line
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.15),
                                    Color.gray.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: lineHeight)
                        .position(x: centerX, y: lineHeight / 2)
                    
                    // Income indicator dot
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.systemBackground))
                            .frame(width: dotSize + 8, height: dotSize + 8)
                        
                        Circle()
                            .fill(Color.green)
                            .frame(width: dotSize, height: dotSize)
                    }
                    .position(x: centerX, y: 40)
                    
                    // Income label (left side)
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("INCOME")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.green.opacity(0.8))
                                .tracking(0.5)
                            
                            Text("$\(Int(incomeAmount))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .position(x: 80, y: 40)
                    
                    // Bills indicator dot
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.systemBackground))
                            .frame(width: dotSize + 8, height: dotSize + 8)
                        
                        Circle()
                            .fill(Color.red)
                            .frame(width: dotSize, height: dotSize)
                    }
                    .position(x: centerX, y: lineHeight - 40)
                    
                    // Bills label (left side)
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.badge.minus")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("BILLS")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.red.opacity(0.8))
                                .tracking(0.5)
                            
                            Text("$\(Int(billAmount))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .position(x: 80, y: lineHeight - 40)
                    
                    // Current expense indicator dot
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.systemBackground))
                            .frame(width: dotSize + 8, height: dotSize + 8)
                        
                        Circle()
                            .fill(Color.purple)
                            .frame(width: dotSize, height: dotSize)
                    }
                    .position(x: centerX, y: expensePosition)
                    
                    // Current expense label (right side)
                    HStack(spacing: 12) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.purple.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CURRENT")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.purple.opacity(0.8))
                                .tracking(0.5)
                            
                            Text("$\(Int(currentExpenseAmount))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .position(x: chartWidth - 80, y: expensePosition)
                }
                .frame(width: chartWidth, height: lineHeight)
                .padding(.vertical, 60)
                .padding(.horizontal, 20)
            }
            .padding(.horizontal)
            .padding(.horizontal)
            
            // Toggle button for explanation
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showDescription.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: showDescription ? "info.circle.fill" : "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    
                    Text(showDescription ? "Hide explanation" : "How to read this chart")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Image(systemName: showDescription ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            .padding(.horizontal)
            
            // Animated explanation content
            if showDescription {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your income ($\(Int(incomeAmount))) starts at the top.")
                        .font(.system(size: 12))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Text("Your bills ($\(Int(billAmount))) are fixed costs at the bottom.")
                        .font(.system(size: 12))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Text("The purple dot shows your total spending ($\(Int(currentExpenseAmount))) so far.")
                        .font(.system(size: 12))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    HStack(spacing: 4) {
                        Text("You have")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("$\(Int(max(0, incomeAmount - currentExpenseAmount)))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(currentExpenseAmount > incomeAmount ? .red : .green)
                        
                        Text(currentExpenseAmount > incomeAmount ? "over budget" : "left to spend")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
                .padding(.top, -8)
                .transition(.asymmetric(
                    insertion: .push(from: .top).combined(with: .opacity),
                    removal: .push(from: .bottom).combined(with: .opacity)
                ))
            }
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

struct ExpenseTrackerChartView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 30) {
                ExpenseTrackerChartView(
                    billAmount: 1500,
                    currentExpenseAmount: 2500,
                    incomeAmount: 3000,
                    month: "December"
                )
                
                ExpenseTrackerChartView(
                    billAmount: 1500,
                    currentExpenseAmount: 2800,
                    incomeAmount: 3000,
                    month: "December"
                )
                
                ExpenseTrackerChartView(
                    billAmount: 1500,
                    currentExpenseAmount: 3200,
                    incomeAmount: 3000,
                    month: "December"
                )
            }
        }
        .preferredColorScheme(.light)
    }
}
