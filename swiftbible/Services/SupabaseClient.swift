//
//  SupabaseClient.swift
//  swiftbible
//
//  Created on 9/4/24.
//

import SwiftUI
import Supabase

class SupabaseService {
    // Legacy AppStorage keys — kept for migration, new tokens go to Keychain
    @AppStorage("supabaseAccessToken") private var supabaseAccessToken: String?
    @AppStorage("supabaseRefreshToken") private var supabaseRefreshToken: String?
    @AppStorage("supabaseAccessTokenExpiration") private var supabaseAccessTokenExpiration: TimeInterval?
    static let shared = SupabaseService()

    private enum KeychainKeys {
        static let accessToken = "supabase_access_token"
        static let refreshToken = "supabase_refresh_token"
        static let userId = "supabase_user_id"
    }

    private enum ICloudKeys {
        static let accessToken = "supabase_access_token"
        static let refreshToken = "supabase_refresh_token"
        static let userId = "supabase_user_id"
    }

    private let iCloud = NSUbiquitousKeyValueStore.default

    private let supabaseURL: URL = AppConfig.supabaseURL
    private let supabaseKey: String = AppConfig.supabaseKey

    private(set) lazy var client: SupabaseClient = {
        return SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }()

    private init() {}

    var auth: AuthClient {
        return client.auth
    }

    var session: Session?

    func signIn(email: String) async {
        do {
            try await self.auth.signInWithOTP(email: email)
        } catch {
            print("Sign-in error: \(error.localizedDescription)")
            SentryService.shared.capture(error, context: ["action": "signIn", "email": email])
        }
    }

    func verifyOTP(email: String, verificationCode: String) async throws {
        do {
            /*
             {
             "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNjI3MjkxNTc3LCJzdWIiOiJmYTA2NTQ1Zi1kYmI1LTQxY2EtYjk1NC1kOGUyOTg4YzcxOTEiLCJlbWFpbCI6IiIsInBob25lIjoiNjU4NzUyMjAyOSIsImFwcF9tZXRhZGF0YSI6eyJwcm92aWRlciI6InBob25lIn0sInVzZXJfbWV0YWRhdGEiOnt9LCJyb2xlIjoiYXV0aGVudGljYXRlZCJ9.1BqRi0NbS_yr1f6hnr4q3s1ylMR3c1vkiJ4e_N55dhM",
             "token_type": "bearer",
             "expires_in": 3600,
             "refresh_token": "LSp8LglPPvf0DxGMSj-vaQ",
             "user": {...}
             }
             */
            let authResponse = try await self.auth.verifyOTP(email: email, token: verificationCode, type: .email)
            guard let session = authResponse.session else {
                print("Wrong verify")
                return
            }
            setAuthentication(
                access: session.accessToken,
                refresh: session.refreshToken,
                expiration: session.expiresIn
            )
            print("Sign-in successful. Token: \(String(describing: session.accessToken))")
        } catch {
            print("Sign-in error: \(error.localizedDescription)")
            throw error
        }
    }

    func refreshToken() async {
        do {
            if let expiration = supabaseAccessTokenExpiration {
                let refreshTime = Date.now.addingTimeInterval(expiration)
                if Date.now > refreshTime {
                    session = try await self.auth.refreshSession()
                    guard let session else {
                        print("Wrong verify")
                        return
                    }
                    setAuthentication(
                        access: session.accessToken,
                        refresh: session.refreshToken,
                        expiration: session.expiresIn
                    )
                    print("Successfully refreshed session \(supabaseRefreshToken ?? "")")
                } else {
                    print("Did not need to refresh token, next refresh at \(refreshTime)")
                }
            } else {
                print("No refresh expiration time yet")
            }
        } catch {
            print("Could not refresh session: \(error)")
        }
    }

    /// Ensures the user has a Supabase session, creating an anonymous one if needed.
    /// Tokens are stored in Keychain so the identity survives app reinstalls.
    func ensureSession() async {
        // Migrate any existing AppStorage tokens to Keychain
        migrateTokensToKeychain()

        // Try to get existing user first
        if let user = await getUser() {
            print("Existing session found for user \(user.id)")
            await updateDeviceInfo()
            return
        }

        // Try recovering session from Keychain (survives reinstall)
        if let keychainAccess = KeychainService.get(KeychainKeys.accessToken),
           let keychainRefresh = KeychainService.get(KeychainKeys.refreshToken) {
            do {
                let session = try await self.auth.setSession(accessToken: keychainAccess, refreshToken: keychainRefresh)
                setAuthentication(
                    access: session.accessToken,
                    refresh: session.refreshToken,
                    expiration: session.expiresIn
                )
                print("Recovered session from Keychain for user \(session.user.id)")
                await updateDeviceInfo()
                return
            } catch {
                print("Keychain session recovery failed: \(error.localizedDescription)")
                SentryService.shared.capture(error, context: ["action": "keychainRecovery"])
            }
        }

        // Try recovering from iCloud (cross-device sync)
        iCloud.synchronize()
        if let iCloudAccess = iCloud.string(forKey: ICloudKeys.accessToken),
           let iCloudRefresh = iCloud.string(forKey: ICloudKeys.refreshToken) {
            do {
                let session = try await self.auth.setSession(accessToken: iCloudAccess, refreshToken: iCloudRefresh)
                setAuthentication(
                    access: session.accessToken,
                    refresh: session.refreshToken,
                    expiration: session.expiresIn
                )
                KeychainService.set(session.user.id.uuidString, forKey: KeychainKeys.userId)
                print("Recovered session from iCloud for user \(session.user.id)")
                await updateDeviceInfo()
                return
            } catch {
                print("iCloud session recovery failed: \(error.localizedDescription)")
            }
        }

        // Try refreshing via AppStorage (legacy fallback)
        await refreshToken()
        if let user = await getUser() {
            print("Refreshed session for user \(user.id)")
            await updateDeviceInfo()
            return
        }

        // No session at all — create anonymous user
        do {
            let session = try await self.auth.signInAnonymously()
            setAuthentication(
                access: session.accessToken,
                refresh: session.refreshToken,
                expiration: session.expiresIn
            )
            KeychainService.set(session.user.id.uuidString, forKey: KeychainKeys.userId)
            iCloud.set(session.user.id.uuidString, forKey: ICloudKeys.userId)
            iCloud.synchronize()
            print("Anonymous sign-in successful. User: \(session.user.id)")
            await updateDeviceInfo()
        } catch {
            print("Anonymous sign-in error: \(error.localizedDescription)")
            SentryService.shared.capture(error, context: ["action": "anonymousSignIn"])
        }
    }

    /// Saves device info to the user's profile so we can identify the Apple device.
    private func updateDeviceInfo() async {
        do {
            let deviceName = await UIDevice.current.name
            let deviceModel = await UIDevice.current.model
            let systemVersion = await UIDevice.current.systemVersion
            let vendorId = await UIDevice.current.identifierForVendor?.uuidString ?? "unknown"

            let now = ISO8601DateFormatter().string(from: Date())
            try await client.from("profiles")
                .update([
                    "device_model": "\(deviceModel)",
                    "device_os": "iOS \(systemVersion)",
                    "device_vendor_id": vendorId,
                    "device_name": deviceName,
                    "last_seen_at": now
                ])
                .eq("id", value: (try self.auth.user()).id)
                .execute()
        } catch {
            // Non-critical — don't block app launch
            print("Could not update device info: \(error.localizedDescription)")
        }
    }

    func getUser() async -> User? {
        do {
            let user = try await self.auth.user()
            print("Successfully got user")
            return user
        } catch {
            print("Could not get user: \(error)")
        }
        return nil
    }

    func signOut() async throws {
        do {
            try await self.auth.signOut()
            supabaseAccessToken = ""
            supabaseRefreshToken = ""
            KeychainService.delete(KeychainKeys.accessToken)
            KeychainService.delete(KeychainKeys.refreshToken)
            KeychainService.delete(KeychainKeys.userId)
            iCloud.removeObject(forKey: ICloudKeys.accessToken)
            iCloud.removeObject(forKey: ICloudKeys.refreshToken)
            iCloud.removeObject(forKey: ICloudKeys.userId)
            iCloud.synchronize()
            print("Sign-out successful.")
        } catch {
            print("Sign-out error: \(error.localizedDescription)")
            throw error
        }
    }

    func setAuthentication(access: String, refresh: String, expiration: TimeInterval) {
        // Write to Keychain (persists across reinstall)
        KeychainService.set(access, forKey: KeychainKeys.accessToken)
        KeychainService.set(refresh, forKey: KeychainKeys.refreshToken)
        // Sync tokens to iCloud (cross-device)
        iCloud.set(access, forKey: ICloudKeys.accessToken)
        iCloud.set(refresh, forKey: ICloudKeys.refreshToken)
        iCloud.synchronize()
        // Legacy AppStorage
        supabaseAccessToken = access
        supabaseRefreshToken = refresh
        supabaseAccessTokenExpiration = expiration
    }

    /// Migrate tokens from AppStorage to Keychain if Keychain is empty
    private func migrateTokensToKeychain() {
        if KeychainService.get(KeychainKeys.accessToken) == nil,
           let token = supabaseAccessToken, !token.isEmpty {
            KeychainService.set(token, forKey: KeychainKeys.accessToken)
            if let refresh = supabaseRefreshToken, !refresh.isEmpty {
                KeychainService.set(refresh, forKey: KeychainKeys.refreshToken)
            }
            print("Migrated tokens from AppStorage to Keychain")
        }
    }
}

struct SupabaseFunctionError: LocalizedError {
    let statusCode: Int
    let message: String?

    var errorDescription: String? {
        if let message, !message.isEmpty {
            return message
        }
        return "Supabase function failed with status code \(statusCode)."
    }
}

extension SupabaseService {
    func invokeFunction<Response: Decodable, Payload: Encodable>(
        _ name: String,
        payload: Payload,
        responseType: Response.Type = Response.self,
        method: String = "POST"
    ) async throws -> Response {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(payload)

        let data = try await invokeFunction(
            name,
            httpBody: body,
            responseType: responseType,
            method: method
        )
        return data
    }

    func invokeFunction<Response: Decodable>(
        _ name: String,
        responseType: Response.Type = Response.self
    ) async throws -> Response {
        try await invokeFunction(name, httpBody: nil, responseType: responseType, method: "GET")
    }

    private func invokeFunction<Response: Decodable>(
        _ name: String,
        httpBody: Data?,
        responseType: Response.Type,
        method: String
    ) async throws -> Response {
        let functionURL = supabaseURL.appendingPathComponent("functions/v1/\(name)")
        var request = URLRequest(url: functionURL)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        if let token = supabaseAccessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = httpBody

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseFunctionError(statusCode: -1, message: "Invalid server response.")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = parseErrorMessage(from: data)
            let error = SupabaseFunctionError(statusCode: httpResponse.statusCode, message: message)
            SentryService.shared.capture(error, context: ["function": name, "statusCode": "\(httpResponse.statusCode)"])
            throw error
        }

        if data.isEmpty {
            throw SupabaseFunctionError(statusCode: httpResponse.statusCode, message: "Empty response body.")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw SupabaseFunctionError(statusCode: httpResponse.statusCode, message: "Unable to decode response: \(error.localizedDescription)")
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let message = json["message"] as? String {
                return message
            }
            if let error = json["error"] as? String {
                return error
            }
            if let description = json["description"] as? String {
                return description
            }
        }
        return String(data: data, encoding: .utf8)
    }
}
