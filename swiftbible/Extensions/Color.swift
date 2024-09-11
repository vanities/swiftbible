//
//  Color.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/10/24.
//

import SwiftUI


extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let rgbValue = UInt32(hex, radix: 16)
        let r = Double((rgbValue! & 0xFF0000) >> 16) / 255
        let g = Double((rgbValue! & 0x00FF00) >> 8) / 255
        let b = Double(rgbValue! & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
    
    var hexValue: String {
        let uiColor = UIColor(self)
        let components = uiColor.cgColor.components

        let red = components?[0] ?? 0
        let green = components?[1] ?? 0
        let blue = components?[2] ?? 0

        let hexString = String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))

        return hexString
    }
}
