//
//  Version.swift
//  swiftbible
//
//  Created on 9/11/24.
//

import Foundation

/*
 https://support.biblegateway.com/hc/en-us/articles/360001403507-What-Bibles-on-Bible-Gateway-are-in-the-public-domain?mobile_site=true
 American Standard Version (ASV)
 Darby Translation (DARBY)
 Douay-Rheims 1899 American Edition (DRA)
 King James Version (KJV)
 World English Bible (WEB)
 Young's Literal Translation (YLT)
 Reina-Valera Antigua (RVA)
 Biblia Sacra Vulgata (VULGATE)
 */

enum Version: String, Codable, CaseIterable {
    case kjv
    case asv
    case web
    case original

    var displayName: String {
        switch self {
        case .kjv:
            return "King James Version (KJV)"
        case .asv:
            return "American Standard Version (ASV)"
        case .web:
            return "World English Bible (WEB)"
        case .original:
            return "Original (Hebrew OT / Greek NT)"
        }
    }

    var shortName: String {
        switch self {
        case .kjv:
            return "KJV"
        case .asv:
            return "ASV"
        case .web:
            return "WEB"
        case .original:
            return "Original"
        }
    }

    var filename: String {
        switch self {
        case .kjv:
            return "bible"
        case .asv:
            return "asv"
        case .web:
            return "web"
        case .original:
            return "hebrew" // Special: BibleService loads both hebrew.json and greek.json
        }
    }

    var isRTL: Bool {
        self == .original
    }
}
