//
//  Version.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/11/24.
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

enum Version: String, Codable {
    case kjv
    case niv
    case nkjv
    case ntl
    case esv
    case ntl1995
    case ntl2009
    case ntl2011
    case ntl2016
    case ntl2017
}
