//
//  RootView.swift
//  Collector
//
//  Created by Chris Mauldin on 5/8/25.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            BillHomeView()
                .tabItem {
                    Label("My Bills", systemImage: "doc.text.fill")
                }
                
            
            IncomeAndExpenseView()
                .tabItem {
                    Label("Expenses", systemImage: "chart.bar.fill")
                }
                
            
            Text("Settings")
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                
        }
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
