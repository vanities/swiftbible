//
//  AppUpdateService.swift
//  swiftbible
//
//  In-app update checker. Queries Apple's iTunes lookup API and exposes
//  observable state for the Settings "About" row. ContentView separately
//  drives the launch-time modal alert via `AppConfig.checkForUpdate()` —
//  both code paths use the same URL builder in `AppConfig` so the Settings
//  row and the modal never disagree.
//

import Foundation
import UIKit

enum AppUpdateStatus: Equatable {
    case upToDate
    case updateAvailable(version: String)
    case unknown
}

@MainActor
@Observable
final class AppUpdateService {
    var updateStatus: AppUpdateStatus = .unknown
    var isChecking: Bool = false

    /// Always fetches fresh — no in-memory throttle, no URLCache, no CDN
    /// cache. Silently falls back to `.unknown` on any error so the UI
    /// never shows a misleading state.
    func checkForUpdate() async {
        isChecking = true
        defer { isChecking = false }

        guard let bundleId = Bundle.main.bundleIdentifier else {
            updateStatus = .unknown
            return
        }

        let cacheBuster = Int(Date().timeIntervalSince1970)
        guard let url = AppConfig.iTunesLookupURL(bundleId: bundleId, cacheBuster: cacheBuster) else {
            updateStatus = .unknown
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let storeVersion = AppConfig.parseAppStoreVersion(from: data) else {
                updateStatus = .unknown
                return
            }
            if AppConfig.isUpdateAvailable(currentVersion: AppConfig.currentAppVersion, storeVersion: storeVersion) {
                updateStatus = .updateAvailable(version: storeVersion)
            } else {
                updateStatus = .upToDate
            }
        } catch {
            updateStatus = .unknown
        }
    }

    func openAppStore() {
        UIApplication.shared.open(AppConfig.appStoreURL)
    }
}
