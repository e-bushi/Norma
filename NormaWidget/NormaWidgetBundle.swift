//
//  NormaWidgetBundle.swift
//  NormaWidget
//
//  Created by Chris Mauldin on 8/19/25.
//

import WidgetKit
import SwiftUI
import AppIntents

@main
struct NormaWidgetBundle: WidgetBundle {
    
    init() {
        // Register App Shortcuts when the widget bundle initializes
        NormaShortcuts.updateAppShortcutParameters()
    }
    
    var body: some Widget {
        NormaWidget()
        NormaWidgetControl()
        NormaWidgetLiveActivity()
    }
}
