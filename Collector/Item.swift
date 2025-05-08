//
//  Item.swift
//  Collector
//
//  Created by Chris Mauldin on 5/8/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
