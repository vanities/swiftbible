//
//  BlessingBurstView.swift
//  swiftbible
//
//  Created by Adam Mischke on 4/6/25.
//


import SwiftUI

struct BlessingBurstView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<6) { i in
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: animate ? 180 : 0, height: animate ? 180 : 0)
                    .scaleEffect(animate ? 1 : 0.5)
                    .opacity(animate ? 0 : 0.6)
                    .animation(
                        .easeOut(duration: 1.2)
                            .delay(Double(i) * 0.1),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}
