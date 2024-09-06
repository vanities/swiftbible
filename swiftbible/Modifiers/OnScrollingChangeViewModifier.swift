//
//  OnScrollingChangeViewModifier.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/6/24.
//

import SwiftUI

struct OnScrollingChangeViewModifier: ViewModifier {
    let scrollingChangeThreshold: Double
    let scrollingStopThreshold: TimeInterval
    let onScrollingDown: () -> Void
    let onScrollingUp: () -> Void
    let onScrollingStopped: () -> Void

    @State private var scrollingStopTimer: Timer?
    @State private var offsetHolder = 0.0
    @State private var initialOffset: CGFloat?

    func body(content: Content) -> some View {
        content.background {
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.frame(in: .global).minY, initial: true) { oldValue, newValue in

                        // prevent triggering callback when boucing top edge to avoid jumpy animation
                        if initialOffset == nil {
                            initialOffset = oldValue
                        } else if newValue >= initialOffset! {
                            return
                        }

                        let newValue = abs(newValue)

                        if newValue > offsetHolder + scrollingChangeThreshold {
                            // We set thresh hold to current offset so we can remember on next iterations.
                            offsetHolder = newValue

                            // is scrolling down
                            onScrollingDown()

                        } else if newValue < offsetHolder - scrollingChangeThreshold {

                            // Save current offset to threshold
                            offsetHolder = newValue
                            // is scrolling up
                            onScrollingUp()
                        }

                        scrollingStopTimer?.invalidate()
                        scrollingStopTimer = Timer.scheduledTimer(withTimeInterval: scrollingStopThreshold, repeats: false, block: { _ in
                            onScrollingStopped()
                        })
                    }
            }
        }
    }
}

