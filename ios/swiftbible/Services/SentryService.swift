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
        // Don't report crashes/errors from unit test runs.
        guard NSClassFromString("XCTestCase") == nil else {
            print("[Sentry] Skipping setup — running under XCTest")
            return
        }
        let dsn = AppConfig.sentryDSN
        guard !dsn.isEmpty else {
            print("[Sentry] Skipping setup — no DSN configured")
            return
        }
        SentrySDK.start { options in
            options.dsn = dsn
            options.sendDefaultPii = true
            options.enableAutoSessionTracking = true
            options.enableAutoPerformanceTracing = true
            options.enableAppHangTracking = true
            options.enableCaptureFailedRequests = true
            options.attachScreenshot = true
            options.attachViewHierarchy = true
            #if DEBUG
            options.debug = true
            options.environment = "development"
            options.tracesSampleRate = 1.0
            options.configureProfiling = {
                $0.sessionSampleRate = 1.0
                $0.lifecycle = .trace
            }
            #else
            options.environment = "production"
            options.tracesSampleRate = 0.2
            options.configureProfiling = {
                $0.sessionSampleRate = 0.2
                $0.lifecycle = .trace
            }
            #endif
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
