import SwiftUI
import Charts

struct OverviewChartView: View {
    let chartData: [ExpenseChartDataPoint]
    let billAmount: Double
    let incomeAmount: Double
    let daysInMonth: Int
    
    var body: some View {
        Chart {
            // Bill line (horizontal)
            RuleMark(y: .value("Amount", billAmount))
                .foregroundStyle(Color.red.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .annotation(position: .topLeading, alignment: .leading) {
                    Text("Bills")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            
            // Income line (horizontal)
            RuleMark(y: .value("Amount", incomeAmount))
                .foregroundStyle(Color.green.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .annotation(position: .topLeading, alignment: .leading) {
                    Text("Income")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            
            // Expense line
            ForEach(chartData) { dataPoint in
                LineMark(
                    x: .value("Day", dataPoint.day),
                    y: .value("Amount", dataPoint.highAmount)
                )
                .foregroundStyle(Color.blue)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            
            // Area under the expense line
            ForEach(chartData) { dataPoint in
                AreaMark(
                    x: .value("Day", dataPoint.day),
                    y: .value("Amount", dataPoint.highAmount)
                )
                .foregroundStyle(Color.blue.opacity(0.1))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYScale(domain: (billAmount * 0.95)...(incomeAmount * 1.05))
        .chartXScale(domain: 1...daysInMonth)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel {
                    if let day = value.as(Int.self) {
                        Text("\(day)")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text("$\(Int(amount))")
                            .font(.caption2)
                    }
                }
            }
        }
        .frame(height: 250)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

struct ExpenseChartDataPoint: Identifiable {
    let id = UUID()
    let day: Int
    let highAmount: Double
    let lowAmount: Double
    let dailyExpense: Double
}

// Preview
struct OverviewChartView_Previews: PreviewProvider {
    static var previews: some View {
        OverviewChartView(
            chartData: generateSampleData(),
            billAmount: 450,
            incomeAmount: 750,
            daysInMonth: 15
        )
        .padding()
    }
    
    static func generateSampleData() -> [ExpenseChartDataPoint] {
        // Only show days with expenses (simulate random days with activity)
        let activeDays = [5, 7, 8, 10, 12, 15, 18, 20, 22]
        let billAmount: Double = 450
        let incomeAmount: Double = 750
        
        var runningTotal = billAmount
        
        return activeDays.map { day in
            // Daily expense amount (length of candlestick)
            let dailyExpense = Double.random(in: 50...100)
            
            // Low is where we started (previous day's high)
            let lowAmount = runningTotal
            // High is low + daily expenses
            let highAmount = runningTotal + dailyExpense
            
            // Update running total for next day
            runningTotal = highAmount
            
            return ExpenseChartDataPoint(
                day: day,
                highAmount: highAmount,
                lowAmount: lowAmount,
                dailyExpense: dailyExpense
            )
        }
    }
}
