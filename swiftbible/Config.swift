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
}
