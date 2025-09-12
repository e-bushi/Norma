//
//  NormaWidget.swift
//  NormaWidget
//
//  Created by Chris Mauldin on 8/19/25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> NormaEntry {
        NormaEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            todaysSpending: 45.67,
            monthlySpending: 1234.56,
            monthlyBills: 800.0,
            monthlyIncome: 3000.0,
            upcomingBills: [
                WidgetBill(name: "Electric", amount: 120.0, dueDate: Date(), status: .scheduled),
                WidgetBill(name: "Internet", amount: 79.99, dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!, status: .scheduled)
            ],
            aiInsight: "You're spending 15% more on dining this week."
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> NormaEntry {
        await loadWidgetData(configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<NormaEntry> {
        let entry = await loadWidgetData(configuration: configuration)
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadWidgetData(configuration: ConfigurationAppIntent) async -> NormaEntry {
        let sharedData = WidgetDataManager.shared
        
        return NormaEntry(
            date: Date(),
            configuration: configuration,
            todaysSpending: sharedData.getTodaysSpending(),
            monthlySpending: sharedData.getMonthlySpending(),
            monthlyBills: sharedData.getMonthlyBills(),
            monthlyIncome: sharedData.getMonthlyIncome(),
            upcomingBills: sharedData.getUpcomingBills(),
            aiInsight: sharedData.getLatestAIInsight()
        )
    }
}

struct NormaEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let todaysSpending: Double
    let monthlySpending: Double
    let monthlyBills: Double
    let monthlyIncome: Double
    let upcomingBills: [WidgetBill]
    let aiInsight: String?
}

struct WidgetBill {
    let name: String
    let amount: Double
    let dueDate: Date
    let status: WidgetBillStatus
}

enum WidgetBillStatus: String {
    case paid = "Paid"
    case overdue = "Overdue"
    case scheduled = "Scheduled"
}

struct NormaWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        switch family {
        case .systemSmall:
            if colorScheme == .dark {
                SmallWidgetView(entry: entry)
            } else {
                SmallWidgetLightView(entry: entry)
            }
        case .systemMedium:
            if colorScheme == .dark {
                MediumWidgetView(entry: entry)
            } else {
                MediumWidgetLightView(entry: entry)
            }
        case .systemLarge:
            if colorScheme == .dark {
                LargeWidgetView(entry: entry)
            } else {
                LargeWidgetLightView(entry: entry)
            }
        default:
            if colorScheme == .dark {
                SmallWidgetView(entry: entry)
            } else {
                SmallWidgetLightView(entry: entry)
            }
        }
    }
}

// Widget view implementations are now in separate files:
// - SmallWidgetView.swift
// - MediumWidgetView.swift  
// - LargeWidgetView.swift

struct NormaWidget: Widget {
    let kind: String = "NormaWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            NormaWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Norma Financial")
        .description("Track your spending and upcoming bills at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var spending: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        return intent
    }
}

#Preview(as: .systemSmall) {
    NormaWidget()
} timeline: {
    NormaEntry(
        date: .now,
        configuration: .spending,
        todaysSpending: 45.67,
        monthlySpending: 1234.56,
        monthlyBills: 800.0,
        monthlyIncome: 3000.0,
        upcomingBills: [
            WidgetBill(name: "Electric", amount: 120.0, dueDate: Date(), status: .scheduled)
        ],
        aiInsight: "You're spending 15% more this week."
    )
}

#Preview(as: .systemMedium) {
    NormaWidget()
} timeline: {
    NormaEntry(
        date: .now,
        configuration: .spending,
        todaysSpending: 45.67,
        monthlySpending: 1234.56,
        monthlyBills: 800.0,
        monthlyIncome: 3000.0,
        upcomingBills: [
            WidgetBill(name: "Electric", amount: 120.0, dueDate: Date(), status: .scheduled),
            WidgetBill(name: "Internet", amount: 79.99, dueDate: Date(), status: .overdue)
        ],
        aiInsight: nil
    )
}

#Preview(as: .systemLarge) {
    NormaWidget()
} timeline: {
    NormaEntry(
        date: .now,
        configuration: .spending,
        todaysSpending: 45.67,
        monthlySpending: 1234.56,
        monthlyBills: 800.0,
        monthlyIncome: 3000.0,
        upcomingBills: [
            WidgetBill(name: "Electric", amount: 120.0, dueDate: Date(), status: .scheduled),
            WidgetBill(name: "Internet", amount: 79.99, dueDate: Date(), status: .overdue),
            WidgetBill(name: "Water", amount: 65.43, dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!, status: .scheduled)
        ],
        aiInsight: "You're spending 15% more on dining this week. Consider cooking at home to stay on budget."
    )
}
