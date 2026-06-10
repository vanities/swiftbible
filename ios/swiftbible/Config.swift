//
//  Config.swift
//  swiftbible
//

import Foundation

enum AppEnvironment: String {
    case local
    case production

    private static let localSupabaseURL: URL = {
        guard let url = URL(string: "http://127.0.0.1:54321") else {
            preconditionFailure("Hardcoded local Supabase URL must parse")
        }
        return url
    }()

    var supabaseURL: URL {
        switch self {
        case .local:
            if let urlString = AppConfig.infoPlistString("SUPABASE_URL_DEBUG"),
               let url = URL(string: urlString) {
                return url
            }
            return Self.localSupabaseURL
        case .production:
            if let urlString = AppConfig.infoPlistString("SUPABASE_URL"),
               let url = URL(string: urlString) {
                return url
            }
            #if DEBUG
            return Self.localSupabaseURL
            #else
            fatalError("Missing SUPABASE_URL in Info.plist")
            #endif
        }
    }

    var supabaseKey: String {
        switch self {
        case .local:
            if let key = AppConfig.infoPlistString("SUPABASE_KEY_DEBUG") {
                return key
            }
            // Default Supabase local dev anon key.
            return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
        case .production:
            if let key = AppConfig.infoPlistString("SUPABASE_KEY") {
                return key
            }
            #if DEBUG
            return AppEnvironment.local.supabaseKey
            #else
            fatalError("Missing SUPABASE_KEY in Info.plist")
            #endif
        }
    }
}

enum AppConfig {
    static func infoPlistString(_ key: String) -> String? {
        guard let rawValue = Bundle.main.infoDictionary?[key] as? String else { return nil }
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.hasPrefix("$(") else { return nil }
        return value
    }

    #if DEBUG
    static func debugLogClientConfiguration(context: String) {
        let keys = [
            "SUPABASE_URL",
            "SUPABASE_KEY",
            "SUPABASE_URL_DEBUG",
            "SUPABASE_KEY_DEBUG",
            "POSTHOG_API_KEY",
            "SENTRY_DSN",
            "DEVOTIONAL_READ_SECRET"
        ]

        print("[Config] \(context): resolved environment=\(environment.rawValue)")
        print("[Config] \(context): resolved SUPABASE_URL=\(supabaseURL.absoluteString)")
        print("[Config] \(context): resolved SUPABASE_KEY=\(redacted(supabaseKey))")
        for key in keys {
            let rawValue = Bundle.main.infoDictionary?[key] as? String
            let resolvedValue = infoPlistString(key)
            print("[Config] \(context): Info.plist \(key) raw=\(debugDescription(rawValue)) resolved=\(debugDescription(resolvedValue))")
        }
    }

    private static func debugDescription(_ value: String?) -> String {
        guard let value else { return "<missing>" }
        if value.hasPrefix("$(") { return "<unresolved:\(value)>" }
        return redacted(value)
    }

    private static func redacted(_ value: String) -> String {
        guard !value.isEmpty else { return "<empty>" }
        if value.hasPrefix("http://") || value.hasPrefix("https://") {
            return value
        }
        if value.count <= 10 {
            return "<set:length=\(value.count)>"
        }
        return "\(value.prefix(6))…\(value.suffix(4)) (length=\(value.count))"
    }
    #endif

    // Toggle this to switch between local and production Supabase
    static let environment: AppEnvironment = .production

    static var supabaseURL: URL { environment.supabaseURL }
    static var supabaseKey: String { environment.supabaseKey }

    static var sentryDSN: String {
        guard let dsn = infoPlistString("SENTRY_DSN") else {
            #if DEBUG
            return ""
            #else
            fatalError("Missing SENTRY_DSN in Info.plist")
            #endif
        }
        return dsn
    }

    static var posthogAPIKey: String {
        guard let key = infoPlistString("POSTHOG_API_KEY") else {
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
        guard let url = URL(string: "https://apps.apple.com/app/id\(appleAppID)") else {
            preconditionFailure("App Store URL must parse")
        }
        return url
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
