//
//  UserViewModel.swift
//  swiftbible
//
//  Created on 9/5/24.
//

import SwiftUI
import Supabase

@Observable
class UserViewModel {
    var user: User?
    var showSignInFlow: Bool = false
    var isAdmin: Bool = false

    func fetchAdminStatus() async {
        guard let userId = user?.id else { return }
        do {
            let profile: ProfileRow = try await SupabaseService.shared.client
                .from("profiles")
                .select("is_admin")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            await MainActor.run {
                isAdmin = profile.isAdmin
            }
        } catch {
            print("Could not fetch admin status: \(error)")
        }
    }
}

private struct ProfileRow: Decodable {
    let isAdmin: Bool

    enum CodingKeys: String, CodingKey {
        case isAdmin = "is_admin"
    }
}
