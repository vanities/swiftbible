//
//  ChapterPullNavigation.swift
//  swiftbible
//
//  MJRefresh-based pull-to-navigate machinery for ChapterDetailView: a
//  haptic header/footer pair that only arms after the reader rests at the
//  top/bottom edge for half a second, so casual overscroll momentum doesn't
//  yank them between chapters.
//

import SwiftUI
import UIKit
import MJRefresh

private final class HapticNormalHeader: MJRefreshNormalHeader {
    private let feedback = UIImpactFeedbackGenerator(style: .medium)
    var armed = false
    private var armTimer: Timer?

    override func prepare() {
        super.prepare()
        arrowView?.isHidden = true
        arrowView?.alpha = 0
        armed = false
    }

    override func placeSubviews() {
        super.placeSubviews()
        arrowView?.isHidden = true
        arrowView?.alpha = 0
    }

    override var state: MJRefreshState {
        didSet {
            if !armed && state == .pulling {
                // Not armed yet — cancel the pull
                endRefreshing()
                return
            }
            if oldValue != .pulling && state == .pulling && armed {
                feedback.impactOccurred()
            }
        }
    }

    /// Call when the scroll view is at rest at the top
    func beginArming() {
        guard !armed else { return }
        armTimer?.invalidate()
        armTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.armed = true
        }
    }

    /// Call when the scroll view moves away from the top
    func disarm() {
        armTimer?.invalidate()
        armTimer = nil
        armed = false
    }
}

private final class HapticBackFooter: MJRefreshBackNormalFooter {
    private let feedback = UIImpactFeedbackGenerator(style: .medium)
    var armed = false
    private var armTimer: Timer?

    override func prepare() {
        super.prepare()
        arrowView?.isHidden = true
        arrowView?.alpha = 0
        armed = false
    }

    override func placeSubviews() {
        super.placeSubviews()
        arrowView?.isHidden = true
        arrowView?.alpha = 0
    }

    override var state: MJRefreshState {
        didSet {
            if !armed && state == .pulling {
                // Not armed yet — cancel the pull
                endRefreshing()
                return
            }
            if oldValue != .pulling && state == .pulling && armed {
                feedback.impactOccurred()
            }
        }
    }

    /// Call when the scroll view is at rest at the bottom
    func beginArming() {
        guard !armed else { return }
        armTimer?.invalidate()
        armTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.armed = true
        }
    }

    /// Call when the scroll view moves away from the bottom
    func disarm() {
        armTimer?.invalidate()
        armTimer = nil
        armed = false
    }
}

/// Attaches and manages the pull-to-navigate controls on the reader's
/// underlying UIScrollView.
@MainActor
enum ChapterPullNavigation {
    /// Safe to call repeatedly — already-attached controls are kept, and the
    /// armed state is reset so a chapter change doesn't carry over.
    static func configure(
        on scrollView: UIScrollView,
        hasPrevious: Bool,
        hasNext: Bool,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) {
        scrollView.alwaysBounceVertical = true
        #if DEBUG
        print("[MJRefresh] Configuring refresh. contentSize=\(scrollView.contentSize) bounds=\(scrollView.bounds.size)")
        #endif

        // Reset armed state so a chapter change doesn't carry over
        (scrollView.mj_header as? HapticNormalHeader)?.disarm()
        (scrollView.mj_footer as? HapticBackFooter)?.disarm()

        if hasPrevious {
            if scrollView.mj_header == nil {
                let header = HapticNormalHeader { [weak scrollView] in
                    defer { scrollView?.mj_header?.endRefreshing() }
                    onPrevious()
                }
                header.lastUpdatedTimeLabel?.isHidden = true
                header.arrowView?.isHidden = true
                header.setTitle("", for: .idle)
                header.setTitle("↑ Previous chapter", for: .pulling)
                header.setTitle("Loading…", for: .refreshing)
                // Higher value = requires more deliberate drag to trigger
                header.ignoredScrollViewContentInsetTop = 80
                scrollView.mj_header = header
            } else {
                #if DEBUG
                print("[MJRefresh] Header already attached")
                #endif
            }
        } else {
            scrollView.mj_header = nil
            #if DEBUG
            print("[MJRefresh] No previous chapter; header removed")
            #endif
        }

        if hasNext {
            if scrollView.mj_footer == nil {
                let footer = HapticBackFooter { [weak scrollView] in
                    defer { scrollView?.mj_footer?.endRefreshing() }
                    onNext()
                }
                footer.arrowView?.isHidden = true
                footer.setTitle("", for: .idle)
                footer.setTitle("↓ Next chapter", for: .pulling)
                footer.setTitle("Loading…", for: .refreshing)
                // Higher value = requires more deliberate drag to trigger
                footer.ignoredScrollViewContentInsetBottom = 80
                scrollView.mj_footer = footer
            } else {
                #if DEBUG
                print("[MJRefresh] Footer already attached")
                #endif
            }
        } else {
            scrollView.mj_footer = nil
            #if DEBUG
            print("[MJRefresh] No next chapter; footer removed")
            #endif
        }
    }
}

// Helper to resolve the UIScrollView used by SwiftUI ScrollView
struct ScrollViewResolver: UIViewRepresentable {
    let onResolve: (UIScrollView) -> Void
    func makeUIView(context: Context) -> UIView { UIView() }
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let scroll = findScrollView(from: uiView) {
                #if DEBUG
                print("[MJRefresh] Resolver found UIScrollView contentSize=\(scroll.contentSize) bounds=\(scroll.bounds.size)")
                #endif
                onResolve(scroll)
                // Attach dead-zone delegate if not already set
                let delegate: DeadZoneScrollDelegate
                if let existing = scroll.delegate as? DeadZoneScrollDelegate {
                    delegate = existing
                } else {
                    delegate = DeadZoneScrollDelegate()
                    // Keep a strong reference via associated object
                    objc_setAssociatedObject(scroll, &DeadZoneScrollDelegate.associatedKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    scroll.delegate = delegate
                }
                // Arm immediately if content doesn't need scrolling
                delegate.armIfContentFits(scroll)
            } else {
                #if DEBUG
                print("[MJRefresh] Resolver could not find UIScrollView yet")
                #endif
            }
        }
    }
    private func findScrollView(from view: UIView?) -> UIScrollView? {
        // Walk up to a common ancestor, then search down for UIScrollView
        var ancestor = view
        while let current = ancestor {
            if let scroll = current as? UIScrollView { return scroll }
            if let found = searchDescendants(forScrollIn: current) { return found }
            ancestor = current.superview
        }
        return nil
    }
    private func searchDescendants(forScrollIn view: UIView) -> UIScrollView? {
        for sub in view.subviews {
            if let s = sub as? UIScrollView { return s }
            if let found = searchDescendants(forScrollIn: sub) { return found }
        }
        return nil
    }
}

/// Monitors scroll position to arm/disarm the dead-zone on header and footer.
/// The refresh controls only become active after the user has been at rest
/// at the top/bottom edge for 0.5 seconds.
/// If content fits on screen (no scrolling needed), arms immediately.
private class DeadZoneScrollDelegate: NSObject, UIScrollViewDelegate {
    static var associatedKey: UInt8 = 0
    private let edgeThreshold: CGFloat = 10

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateArmState(for: scrollView)
    }

    /// Called after layout to handle non-scrollable content
    func armIfContentFits(_ scrollView: UIScrollView) {
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.bounds.height

        guard contentHeight > 0 && contentHeight <= frameHeight else { return }

        // Content fits on screen — no scroll momentum possible, arm immediately
        (scrollView.mj_header as? HapticNormalHeader)?.armed = true
        (scrollView.mj_footer as? HapticBackFooter)?.armed = true
    }

    private func updateArmState(for scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.bounds.height

        // Top edge check
        if let header = scrollView.mj_header as? HapticNormalHeader {
            if offsetY <= edgeThreshold {
                header.beginArming()
            } else {
                header.disarm()
            }
        }

        // Bottom edge check
        if let footer = scrollView.mj_footer as? HapticBackFooter {
            let distanceFromBottom = contentHeight - (offsetY + frameHeight)
            if distanceFromBottom <= edgeThreshold {
                footer.beginArming()
            } else {
                footer.disarm()
            }
        }
    }
}
