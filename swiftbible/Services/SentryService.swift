//
//  SentryService.swift
//  swiftbible
//

import Foundation
import Sentry

final class SentryService {
    static let shared = SentryService()

    private init() {}

    func configure() {
        let dsn = AppConfig.sentryDSN
        guard !dsn.isEmpty else {
            print("[Sentry] Skipping setup — no DSN configured")
            return
        }
        SentrySDK.start { options in
            options.dsn = dsn
            options.enableAutoSessionTracking = true
            options.enableAutoPerformanceTracing = true
            options.enableAppHangTracking = true
            #if DEBUG
            options.debug = true
            options.environment = "development"
            #else
            options.environment = "production"
            #endif
            options.enableCaptureFailedRequests = true
            options.tracesSampleRate = 0.2
        }
    }

    func capture(_ error: Error, context: [String: Any]? = nil) {
        SentrySDK.capture(error: error) { scope in
            if let context {
                for (key, value) in context {
                    scope.setExtra(value: value, key: key)
                }
            }
        }
    }

    func addBreadcrumb(category: String, message: String, level: SentryLevel = .info) {
        let crumb = Breadcrumb(level: level, category: category)
        crumb.message = message
        SentrySDK.addBreadcrumb(crumb)
    }
}
