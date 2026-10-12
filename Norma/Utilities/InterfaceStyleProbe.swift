//
//  InterfaceStyleProbe.swift
//  Norma
//
//  UI tests read this view's UIKit interface style. It is installed only for
//  `--ui-testing` launches, and it does not change the color scheme.
//

import SwiftUI
import UIKit

struct InterfaceStyleProbe: UIViewRepresentable {
    func makeUIView(context: Context) -> ProbeView {
        ProbeView()
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {
        uiView.refresh()
    }

    final class ProbeView: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            isAccessibilityElement = true
            backgroundColor = .clear
            isUserInteractionEnabled = false
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ProbeView, _) in
                view.refresh()
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            refresh()
        }

        func refresh() {
            let dark = traitCollection.userInterfaceStyle == .dark
            accessibilityIdentifier = dark ? "interface-style-dark" : "interface-style-light"
        }
    }
}
