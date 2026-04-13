//
//  Config.swift
//  swiftbible
//

import Foundation

enum AppEnvironment: String {
    case local
    case production

    var supabaseURL: URL {
        switch self {
        case .local:
            if let urlString = Bundle.main.infoDictionary?["SUPABASE_URL_DEBUG"] as? String,
               let url = URL(string: urlString),
               !urlString.isEmpty {
                return url
            }
            return URL(string: "http://127.0.0.1:54321")!
        case .production:
            guard let urlString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
                  let url = URL(string: urlString) else {
                fatalError("Missing SUPABASE_URL in Info.plist")
            }
            return url
        }
    }

    var supabaseKey: String {
        switch self {
        case .local:
            if let key = Bundle.main.infoDictionary?["SUPABASE_KEY_DEBUG"] as? String {
                let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
            // Default Supabase local dev anon key
            return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
        case .production:
            guard let key = Bundle.main.infoDictionary?["SUPABASE_KEY"] as? String else {
                fatalError("Missing SUPABASE_KEY in Info.plist")
            }
            return key.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

enum AppConfig {
    // Toggle this to switch between local and production Supabase
    static let environment: AppEnvironment = .production

    static var supabaseURL: URL { environment.supabaseURL }
    static var supabaseKey: String { environment.supabaseKey }

    static var sentryDSN: String {
        guard let dsn = Bundle.main.infoDictionary?["SENTRY_DSN"] as? String,
              !dsn.isEmpty else {
            #if DEBUG
            return ""
            #else
            fatalError("Missing SENTRY_DSN in Info.plist")
            #endif
        }
        return dsn
    }

    static var posthogAPIKey: String {
        guard let key = Bundle.main.infoDictionary?["POSTHOG_API_KEY"] as? String,
              !key.isEmpty else {
            #if DEBUG
            return ""
            #else
            fatalError("Missing POSTHOG_API_KEY in Info.plist")
            #endif
        }
        return key
    }

    // MARK: - App Update

    static let appleAppID: String = "6670373108"

    static var appStoreURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appleAppID)")!
    }

    static var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
    }

    // Cooldown so we don't nag the user. The update prompt is shown at most
    // once per week regardless of how many times the app is launched.
    static let updatePromptLastShownKey = "updatePromptLastShown"
    private static let updatePromptCooldown: TimeInterval = 7 * 24 * 60 * 60 // 1 week

    static func recordUpdatePromptShown() {
        UserDefaults.standard.set(Date(), forKey: updatePromptLastShownKey)
    }

    static var isWithinUpdateCooldown: Bool {
        guard let last = UserDefaults.standard.object(forKey: updatePromptLastShownKey) as? Date else { return false }
        return Date().timeIntervalSince(last) < updatePromptCooldown
    }

    static func resetUpdateCooldown() {
        UserDefaults.standard.removeObject(forKey: updatePromptLastShownKey)
    }

    /// Builds the iTunes lookup URL used by the in-app update checker.
    ///
    /// IMPORTANT: always uses the `bundleId=` variant, never `id=`. Apple's
    /// CDN keys on URL, and the two parameter styles are independent cache
    /// entries that can diverge by hours after a release — using a single
    /// variant consistently avoids the two-endpoints-disagree bug.
    ///
    /// `cacheBuster` is appended as `&_=<value>` to defeat any cooperative
    /// cache that keys on the full URL. Apple's CDN itself ignores unknown
    /// query params, but combined with `URLRequest.cachePolicy =
    /// .reloadIgnoringLocalAndRemoteCacheData` and no-cache headers, we get
    /// fresh data from the nearest non-stale layer.
    static func iTunesLookupURL(bundleId: String, cacheBuster: Int) -> URL? {
        return URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)&_=\(cacheBuster)")
    }

    /// Parses the iTunes lookup API response and returns the app store version
    /// string, or nil if parsing fails.
    static func parseAppStoreVersion(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]],
              let appStoreVersion = results.first?["version"] as? String else { return nil }
        return appStoreVersion
    }

    /// Returns true if `storeVersion` is strictly newer than `currentVersion`
    /// using numeric dotted comparison (e.g. `1.9 < 1.10`).
    static func isUpdateAvailable(currentVersion: String, storeVersion: String) -> Bool {
        return currentVersion.compare(storeVersion, options: .numeric) == .orderedAscending
    }

    /// Fetches the App Store version and returns true if an update is available
    /// AND the weekly cooldown has elapsed. Silently fails to `false` on any
    /// network/parse error so the user never sees a spurious alert.
    ///
    /// The response is NEVER cached locally — cache-busting timestamp + reload
    /// policy + no-cache headers defeat both `URLCache` (which persists across
    /// app kills) and any cooperative intermediaries.
    static func checkForUpdate() async -> Bool {
        guard !isWithinUpdateCooldown else { return false }
        guard let bundleId = Bundle.main.bundleIdentifier else { return false }
        let cacheBuster = Int(Date().timeIntervalSince1970)
        guard let url = iTunesLookupURL(bundleId: bundleId, cacheBuster: cacheBuster) else { return false }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let storeVersion = parseAppStoreVersion(from: data) else { return false }
            return isUpdateAvailable(currentVersion: currentAppVersion, storeVersion: storeVersion)
        } catch {
            return false
        }
    }
}
