//
//  SupabaseClient.swift
//  swiftbible
//
//  Created on 9/4/24.
//

import SwiftUI
import Supabase

class SupabaseService {
    @AppStorage("supabaseAccessToken") private var supabaseAccessToken: String?
    @AppStorage("supabaseRefreshToken") private var supabaseRefreshToken: String?
    @AppStorage("supabaseAccessTokenExpiration") private var supabaseAccessTokenExpiration: TimeInterval?
    static let shared = SupabaseService()

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
            print("Sign-out successful.")
        } catch {
            print("Sign-out error: \(error.localizedDescription)")
            throw error
        }
    }

    func setAuthentication(access: String, refresh: String, expiration: TimeInterval) {
        supabaseAccessToken = access
        supabaseRefreshToken = refresh
        supabaseAccessTokenExpiration = expiration
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
            throw SupabaseFunctionError(statusCode: httpResponse.statusCode, message: message)
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
