//
//  SupabaseClient.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/4/24.
//

import SwiftUI
import Supabase

class SupabaseService {
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
}
