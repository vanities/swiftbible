import SwiftUI
import UIKit
import MJRefresh

struct RefreshableScrollView<Content: View>: UIViewRepresentable {
    let content: Content
    let onPullDown: (() -> Void)?
    let onPullUp: (() -> Void)?

    init(onPullDown: (() -> Void)? = nil, onPullUp: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.onPullDown = onPullDown
        self.onPullUp = onPullUp
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true

        let hosting = UIHostingController(rootView: content)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hosting.view.backgroundColor = .clear

        scrollView.addSubview(hosting.view)
        // Pin to contentLayoutGuide/frameLayoutGuide
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hosting.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        context.coordinator.hosting = hosting

        // Attach MJRefresh controls
        if onPullDown != nil {
            scrollView.mj_header = MJRefreshNormalHeader {
                context.coordinator.handlePullDown()
            }
        }
        if onPullUp != nil {
            scrollView.mj_footer = MJRefreshBackNormalFooter {
                context.coordinator.handlePullUp()
            }
        }

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // Update SwiftUI content
        context.coordinator.hosting?.rootView = content
        // Ensure bounce remains enabled
        uiView.alwaysBounceVertical = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onPullDown: onPullDown, onPullUp: onPullUp)
    }

    class Coordinator {
        var hosting: UIHostingController<Content>?
        let onPullDown: (() -> Void)?
        let onPullUp: (() -> Void)?

        init(onPullDown: (() -> Void)?, onPullUp: (() -> Void)?) {
            self.onPullDown = onPullDown
            self.onPullUp = onPullUp
        }

        func handlePullDown() {
            onPullDown?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.hosting?.view.superview.flatMap { $0 as? UIScrollView }?.mj_header?.endRefreshing()
            }
        }

        func handlePullUp() {
            onPullUp?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.hosting?.view.superview.flatMap { $0 as? UIScrollView }?.mj_footer?.endRefreshing()
            }
        }
    }
}
