//
//  BillCardStack.swift
//  Norma
//
//  Created by Claude on 10/11/25.
//

import SwiftUI

struct BillCardStack: View {
    let bills: [Bill]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(bills) { bill in
                BillRowView(bill: bill)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("NormaCard"))
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
            }
        }
    }
}
