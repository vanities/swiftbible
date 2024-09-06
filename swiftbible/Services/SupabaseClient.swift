//
//  SupabaseClient.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/4/24.
//

import SwiftUI
import Supabase

class SupabaseService {
    @AppStorage("supabaseAccessToken") private var supabaseAccessToken: String?
    @AppStorage("supabaseRefreshToken") private var supabaseRefreshToken: String?
    @AppStorage("supabaseAccessTokenExpiration") private var supabaseAccessTokenExpiration: TimeInterval?
    static let shared = SupabaseService()

    private let supabaseURL: URL = {
        guard let supabaseURL = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              let url = URL(string: supabaseURL) else {
            fatalError("Missing SUPABASE_URL environment variable.")
        }
        return url
    }()

    private let supabaseKey: String = {
        guard let key = Bundle.main.infoDictionary?["SUPABASE_KEY"] as? String else {
            fatalError("Missing SUPABASE_KEY environment variable.")
        }
        return key
    }()

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
        }
        catch {
            print("Could not refresh session: \(error)")
        }
    }

    func getUser() async -> User? {
        do {
            let user = try await self.auth.user()
            print("Successfully got user")
            return user
        }
        catch {
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
