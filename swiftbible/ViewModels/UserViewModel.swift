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
}
