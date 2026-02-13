//
//  TimezoneSelectionView.swift
//  Norma
//
//  Sheet for selecting timezones to track
//

import SwiftUI

struct TimezoneSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var timezoneManager = TimezoneManager.shared

    @State private var searchText = ""

    private var filteredTimezones: [TimezoneInfo] {
        if searchText.isEmpty {
            return TimezoneManager.popularTimezones
        }
        let lowercased = searchText.lowercased()
        return TimezoneManager.popularTimezones.filter { timezone in
            timezone.city.lowercased().contains(lowercased) ||
            timezone.country.lowercased().contains(lowercased)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Selected timezones section
                if !timezoneManager.selectedTimezones.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected Timezones")
                            .font(.custom(FontFamily.Rubik.medium, size: 14))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(timezoneManager.selectedTimezones) { timezone in
                                    SelectedTimezoneChip(timezone: timezone) {
                                        timezoneManager.removeTimezone(timezone)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                    Divider()
                        .padding(.horizontal, 20)
                }

                // Available timezones list
                List {
                    ForEach(filteredTimezones) { timezone in
                        TimezoneRow(
                            timezone: timezone,
                            isSelected: timezoneManager.selectedTimezones.contains(where: { $0.id == timezone.id }),
                            canAdd: timezoneManager.canAddMore
                        ) {
                            toggleTimezone(timezone)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(Color("NormaBackground"))
            .navigationTitle("Timezones")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search cities...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom(FontFamily.Rubik.medium, size: 16))
                    .foregroundColor(Color("NormaPastelTeal"))
                }
            }
        }
    }

    private func toggleTimezone(_ timezone: TimezoneInfo) {
        if timezoneManager.selectedTimezones.contains(where: { $0.id == timezone.id }) {
            timezoneManager.removeTimezone(timezone)
        } else if timezoneManager.canAddMore {
            timezoneManager.addTimezone(timezone)
        }
    }
}

// MARK: - Supporting Views

struct SelectedTimezoneChip: View {
    let timezone: TimezoneInfo
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(timezone.city)
                .font(.custom(FontFamily.Rubik.medium, size: 13))

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .foregroundColor(Color("NormaPastelTeal"))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color("NormaPastelTeal").opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(Color("NormaPastelTeal").opacity(0.3), lineWidth: 0.5)
        )
    }
}

struct TimezoneRow: View {
    let timezone: TimezoneInfo
    let isSelected: Bool
    let canAdd: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(timezone.city)
                        .font(.custom(FontFamily.Rubik.medium, size: 16))
                        .foregroundColor(.primary)

                    Text(timezone.country)
                        .font(.custom(FontFamily.Rubik.regular, size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(timezone.abbreviation)
                    .font(.custom(FontFamily.Rubik.regular, size: 13))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 8)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color("NormaPastelTeal"))
                } else if canAdd {
                    Image(systemName: "circle")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary.opacity(0.3))
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary.opacity(0.15))
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .disabled(!isSelected && !canAdd)
        .opacity(!isSelected && !canAdd ? 0.5 : 1)
        .listRowBackground(Color.clear)
    }
}

#Preview {
    TimezoneSelectionView()
}
