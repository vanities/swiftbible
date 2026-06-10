//
//  ReadTrackerDebugBadge.swift
//  swiftbible
//

#if DEBUG
import SwiftUI

/// DEBUG-only floating badge that shows the live read-tracking timer for the
/// current chapter: which session is tracked, accumulated foreground seconds,
/// and whether it has crossed the 5s threshold that lets `stopReading` persist.
struct ReadTrackerDebugBadge: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { _ in
            let service = ReadingStatsService.shared
            let elapsed = Int(service.debugElapsedSeconds.rounded())
            let needSecs = Int(ReadingStatsService.readSecondsThreshold)
            HStack(spacing: 6) {
                Image(systemName: service.debugIsTracking ? "record.circle.fill" : "pause.circle")
                    .foregroundStyle(service.debugIsTracking ? .red : .secondary)
                if let label = service.debugTrackingLabel {
                    Text(label)
                        .lineLimit(1)
                    Text("·").foregroundStyle(.secondary)
                    // seconds — green once past the 30s read threshold
                    Text("\(elapsed)s")
                        .monospacedDigit()
                        .foregroundStyle(elapsed >= needSecs ? .green : .orange)
                    // scrolled to last verse?
                    Text(service.debugReachedEnd ? "end✓" : "end✗")
                        .foregroundStyle(service.debugReachedEnd ? .green : .orange)
                    // both met → chapter counts as read
                    if service.debugMeetsReadThreshold {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                } else {
                    Text("not tracking").foregroundStyle(.secondary)
                }
            }
            .font(.caption2.monospaced())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
            .padding(.bottom, 8)
            .allowsHitTesting(false)
        }
    }
}
#endif
