import SwiftUI

struct ExpenseTrackerChartView: View {
    let billAmount: Double
    let currentExpenseAmount: Double
    let incomeAmount: Double
    
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
                Text("MONTHLY PROGRESS")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
                
                // Smart insights
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Remaining")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        Text("$\(Int(max(0, incomeAmount - currentExpenseAmount)))")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Daily Budget")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        Text("$\(Int((incomeAmount - billAmount) / 30))")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
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
                
                HStack(spacing: 8) {
                    Text("\(Int(expensePercentage))% used")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    
                    Text("•")
                        .font(.system(size: 16))
                        .foregroundColor(budgetStatus.color.opacity(0.5))
                    
                    Text(budgetStatus.text)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                }
                .foregroundColor(budgetStatus.color)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(budgetStatus.color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(budgetStatus.color.opacity(0.2), lineWidth: 1)
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
                    
                    // Horizontal expense line (right side only)
                    if currentExpenseAmount > 0 {
                        let lineWidth = (chartWidth * 0.45) - (dotSize / 2) - 10
                        
                        // Subtle shadow for depth
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.black.opacity(0.08))
                            .frame(width: lineWidth, height: 2)
                            .offset(y: 2)
                            .position(x: centerX + (lineWidth / 2) + (dotSize / 2), y: expensePosition)
                        
                        // Main gradient line
                        RoundedRectangle(cornerRadius: 1)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.purple,
                                        Color.blue
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: lineWidth, height: 2)
                            .position(x: centerX + (lineWidth / 2) + (dotSize / 2), y: expensePosition)
                        
                        // End dot
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                            .position(x: centerX + lineWidth + (dotSize / 2), y: expensePosition)
                    }
                    
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
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.green.opacity(0.8))
                                .tracking(0.5)
                            
                            Text("$\(Int(incomeAmount))")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
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
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.red.opacity(0.8))
                                .tracking(0.5)
                            
                            Text("$\(Int(billAmount))")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
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
                            .stroke(Color.purple.opacity(0.3), lineWidth: 2)
                            .frame(width: dotSize + 16, height: dotSize + 16)
                        
                        Circle()
                            .fill(Color(UIColor.systemBackground))
                            .frame(width: dotSize + 8, height: dotSize + 8)
                        
                        Circle()
                            .fill(Color.purple)
                            .frame(width: dotSize, height: dotSize)
                    }
                    .position(x: centerX, y: expensePosition)
                    
                    // Current expense label (right side, below line)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CURRENT")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.purple.opacity(0.7))
                            .tracking(0.5)
                        
                        Text("$\(Int(currentExpenseAmount))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.purple.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.purple.opacity(0.15), lineWidth: 1)
                            )
                    )
                    .position(x: chartWidth - 50, y: expensePosition + 40)
                }
                .frame(width: chartWidth, height: lineHeight)
                .padding(.vertical, 60)
                .padding(.horizontal, 20)
            }
            .padding(.horizontal)
            .padding(.horizontal)
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
                    incomeAmount: 3000
                )
                
                ExpenseTrackerChartView(
                    billAmount: 1500,
                    currentExpenseAmount: 2800,
                    incomeAmount: 3000
                )
                
                ExpenseTrackerChartView(
                    billAmount: 1500,
                    currentExpenseAmount: 3200,
                    incomeAmount: 3000
                )
            }
        }
        .preferredColorScheme(.light)
    }
}
