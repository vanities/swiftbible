//
//  BadgeEarnedToast.swift
//  swiftbible
//

import SwiftUI
import UIKit

/// Banner shown at the top of the screen when a new badge is earned.
/// Auto-dismisses after 3 seconds, or on tap. Fires a success haptic
/// on appear. Confetti is triggered separately by ContentView so it
/// uses the same canon the donation flow does.
struct BadgeEarnedToast: View {
    let badge: BadgeDefinition
    let onDismiss: () -> Void

    @State private var bounce = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(badge.tint.opacity(0.85))
                    .frame(width: 48, height: 48)
                Image(systemName: badge.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(bounce ? 1.1 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: bounce)

            VStack(alignment: .leading, spacing: 2) {
                Text("Badge earned")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(badge.tint)
                Text(badge.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(badge.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        )
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            onDismiss()
        }
        .onAppear {
            bounce = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                onDismiss()
            }
        }
    }
}
