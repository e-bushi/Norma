//
//  DayPickerView.swift
//  Collector
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct DayPickerView: View {
    @Binding var selectedDate: Date
    @Binding var showAllDates: Bool
    private let calendar = Calendar.current
    
    // Get all days in the current month
    private var daysInCurrentMonth: [Date] {
        let today = Date()
        
        // Get start of the current month
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
              
        // Get the range of days in the month
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }
        
        // Create array of dates for each day in the month
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
    
    // Current month and year as string
    private var currentMonthName: String {
        Date().formatted(.dateTime.month(.wide).year())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Days scrollview
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // All dates option
                    AllDaysView(isSelected: showAllDates)
                        .onTapGesture {
                            showAllDates = true
                        }
                    
                    // Divider
                    Divider()
                        .frame(height: 55)
                        .padding(.horizontal, 4)
                    
                    // Day options for current month only
                    ForEach(daysInCurrentMonth, id: \.timeIntervalSince1970) { date in
                        DayView(date: date, isSelected: calendar.isDate(date, inSameDayAs: selectedDate) && !showAllDates)
                            .onTapGesture {
                                selectedDate = date
                                showAllDates = false
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical)
            }
        }
        .frame(height: 100)
    }
}

struct DayView: View {
    let date: Date
    let isSelected: Bool
    private let calendar = Calendar.current
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var dayNumber: String {
        date.formatted(.dateTime.day())
    }
    
    private var dayName: String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }
    
    private var monthName: String {
        date.formatted(.dateTime.month(.abbreviated))
    }
    
    var body: some View {
        VStack {
            Text(dayName)
                .font(.caption)
                .foregroundColor(isSelected ? .white : .secondary)
            Text(dayNumber)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .primary)
            Text(monthName)
                .font(.caption2)
                .foregroundColor(isSelected ? .white : .secondary)
        }
        .frame(width: 50, height: 75)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
        )
    }
    
    private var backgroundFill: some ShapeStyle {
        if isSelected {
            return Color.blue
        } else if isToday {
            return Color.blue.opacity(0.1)
        } else {
            return Color(.systemBackground)
        }
    }
}

struct AllDaysView: View {
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Image(systemName: "calendar")
                .font(.title3)
                .foregroundColor(isSelected ? .white : .blue)
            Text("All")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .primary)
            Text("Dates")
                .font(.caption2)
                .foregroundColor(isSelected ? .white : .secondary)
        }
        .frame(width: 50, height: 75)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.blue : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct DayPickerView_Previews: PreviewProvider {
    static var previews: some View {
        struct PreviewWrapper: View {
            @State var selectedDate = Date()
            @State var showAllDates = false
            
            var body: some View {
                DayPickerView(selectedDate: $selectedDate, showAllDates: $showAllDates)
                    .previewLayout(.sizeThatFits)
                    .padding(.vertical)
            }
        }
        
        return PreviewWrapper()
    }
}
