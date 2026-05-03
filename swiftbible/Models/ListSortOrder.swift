//
//  ListSortOrder.swift
//  swiftbible
//

import Foundation

enum ListSortOrder: String, CaseIterable, Identifiable {
    case newest
    case oldest

    var id: String { rawValue }

    var label: String {
        switch self {
        case .newest: return "Newest First"
        case .oldest: return "Oldest First"
        }
    }

    var systemImage: String {
        switch self {
        case .newest: return "arrow.down"
        case .oldest: return "arrow.up"
        }
    }
}
