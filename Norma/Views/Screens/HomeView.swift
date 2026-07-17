//
//  HomeView.swift
//  Norma
//
//  Runway-first home. Hosts ArcCountView (the runway + activity component) as
//  the primary surface and carries the bottom navigation that used to live on
//  NotesListScreen. Notes demote to a browse surface reached via the `+`.
//
//  See plans/runway-first-home.md. This is P1: the arc becomes home and notes
//  move one layer down. The runway math (freedomFund / bills → arcCount) is
//  ported from NotesListScreen; that screen keeps its own copy until the
//  later prune phase, so notes browsing stays fully functional in the interim.
//

import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var appCoordinator: AppCoordinator
    @State private var showForecast = false
    @State private var showCalendar = false
    @State private var showSettings = false
    @State private var keyboardVisible = false
    @State private var showChat = false
    /// Pre-filled chat text when the user taps "add for [day]" on the calendar.
    @State private var chatSeed: String?

    // MARK: - Runway inputs (ported from NotesListScreen)

    private var freedomFund: Double {
        sessionViewModel.currentUser?.settings.freedomFund ?? 0
    }

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private var totalMonthlyBills: Double {
        billViewModel.bills.reduce(0.0) { $0 + $1.amount }
    }

    private var arcCount: Int {
        let largestBill = billViewModel.bills.map { $0.amount }.max() ?? 0
        if freedomFund < largestBill { return 0 }
        if totalMonthlyBills > 0 {
            return Int(floor(freedomFund / totalMonthlyBills))
        }
        return 0
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                NormaPalette.canvas.ignoresSafeArea()
                NormaPalette.lavender.opacity(0.04).ignoresSafeArea()

                ArcCountView(
                    arcCount: arcCount,
                    freedomFund: freedomFund,
                    totalMonthlyBills: totalMonthlyBills,
                    currency: currency
                )
                .environmentObject(sessionViewModel)

                // The bottom nav only makes sense once there's a balance to
                // reason about — hide it on the first-time empty state.
                if !keyboardVisible && freedomFund > 0 {
                    bottomBar
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    settingsToolbarItem
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeOut(duration: 0.2)) { keyboardVisible = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.2)) { keyboardVisible = false }
        }
        .sheet(isPresented: $showForecast) {
            ForecastSheet()
                .environmentObject(sessionViewModel)
                .environmentObject(billViewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showCalendar) {
            CalendarSheet(onAddForDate: { date in
                let f = DateFormatter()
                f.dateFormat = "MMM d"
                chatSeed = "on \(f.string(from: date).lowercased()), "
                showCalendar = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.easeInOut(duration: 0.45)) { showChat = true }
                }
            })
                .environmentObject(sessionViewModel)
                .environmentObject(billViewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(sessionViewModel)
                .environmentObject(dataManager)
                .environmentObject(appCoordinator)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showChat, onDismiss: { chatSeed = nil }) {
            NormaChatView(seedText: chatSeed)
                .environmentObject(sessionViewModel)
                .environmentObject(billViewModel)
                .presentationDetents([.large])
                .presentationBackground(.clear)
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                bottomIcon(systemName: "chart.line.uptrend.xyaxis") {
                    showForecast = true
                }
                bottomIcon(systemName: "calendar") {
                    showCalendar = true
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .glassEffect(in: Capsule())
            .overlay(
                Capsule().stroke(NormaPalette.ink.opacity(0.22), lineWidth: 1)
            )

            Spacer()

            HStack(spacing: 0) {
                bottomIcon(systemName: "bubble.left.and.text.bubble.right") {
                    withAnimation(.easeInOut(duration: 0.45)) { showChat = true }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .glassEffect(in: Capsule())
            .overlay(
                Capsule().stroke(NormaPalette.ink.opacity(0.22), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func bottomIcon(systemName: String, action: (() -> Void)? = nil) -> some View {
        Group {
            if let action {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    action()
                } label: {
                    Image(systemName: systemName)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(NormaPalette.ink)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(NormaPalette.ink)
                    .frame(width: 44, height: 44)
            }
        }
    }

    private var settingsToolbarItem: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            showSettings = true
        } label: {
            Color.clear
                .frame(width: 14, height: 14)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    DitherShaderView(intensity: 1.0, dotSize: 0.8)
                        .clipShape(Capsule())
                )
                .overlay(Capsule().stroke(NormaPalette.ink.opacity(0.22), lineWidth: 1))
                .fixedSize()
        }
        .buttonStyle(.plain)
    }
}
