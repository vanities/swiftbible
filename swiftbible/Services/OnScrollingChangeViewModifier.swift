//
//  OnScrollingChangeViewModifier.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/29/24.
//


import SwiftUI

extension View {
    public func onScrollingChange(
        scrollingChangeThresholdUp: Double = 20.0,
        scrollingChangeThresholdDown: Double = 100.0,
        onScrollingDown: @escaping () -> Void,
        onScrollingUp: @escaping () -> Void
    ) -> some View {
        self.modifier(
            OnScrollingChangeViewModifier(
                scrollingChangeThresholdUp: scrollingChangeThresholdUp,
                scrollingChangeThresholdDown: scrollingChangeThresholdDown,
                onScrollingDown: onScrollingDown,
                onScrollingUp: onScrollingUp
            )
        )
    }
}

private struct OnScrollingChangeViewModifier: ViewModifier {
    let scrollingChangeThresholdUp: Double
    let scrollingChangeThresholdDown: Double
    let onScrollingDown: () -> Void
    let onScrollingUp: () -> Void

    @State private var offsetHolder = 0.0
    @State private var initialOffset: CGFloat?
    @State private var debounceWorkItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.frame(in: .global).minY) {
                        // Cancel any previous debounce work item
                        debounceWorkItem?.cancel()

                        // Create a new debounce work item
                        debounceWorkItem = DispatchWorkItem {
                            handleScrollChange(newValue: proxy.frame(in: .global).minY)
                        }

                        // Execute the work item after a delay (e.g., 0.01 seconds)
                        if let workItem = debounceWorkItem {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: workItem)
                        }
                    }
            }
        )
    }

    private func handleScrollChange(newValue: CGFloat) {
        // Prevent triggering callback when bouncing top edge to avoid jumpy animation
        if initialOffset == nil {
            initialOffset = newValue
            return
        } else if newValue >= initialOffset! {
            return
        }

        let absoluteNewValue = abs(newValue)

        if absoluteNewValue > offsetHolder + scrollingChangeThresholdDown {
            // Set threshold to current offset for the next iteration
            offsetHolder = absoluteNewValue

            // Scrolling down
            onScrollingDown()

        } else if absoluteNewValue < offsetHolder - scrollingChangeThresholdUp {
            // Set threshold to current offset for the next iteration
            offsetHolder = absoluteNewValue

            // Scrolling up
            onScrollingUp()
        }
    }
}
