//
//  View.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/6/24.
//

import SwiftUI

extension View {
    public func onScrollingChange(
        scrollingChangeThreshold: Double = 100.0,
        scrollingStopThreshold: TimeInterval = 0.5,
        onScrollingDown: @escaping () -> Void,
        onScrollingUp: @escaping () -> Void,
        onScrollingStopped: @escaping () -> Void) -> some View {
            self.modifier(OnScrollingChangeViewModifier(scrollingChangeThreshold: scrollingChangeThreshold, scrollingStopThreshold: scrollingStopThreshold, onScrollingDown: onScrollingDown, onScrollingUp: onScrollingUp, onScrollingStopped: onScrollingStopped))
        }
}
