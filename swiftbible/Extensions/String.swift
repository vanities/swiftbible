//
//  String.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/11/24.
//

import Foundation


extension String {
    func fixToBrowserString() -> String {
        self.replacingOccurrences(of: ";", with: "%3B")
            .replacingOccurrences(of: "\n", with: "%0D%0A")
            .replacingOccurrences(of: " ", with: "+")
            .replacingOccurrences(of: "!", with: "%21")
            .replacingOccurrences(of: "\"", with: "%22")
            .replacingOccurrences(of: "\\", with: "%5C")
            .replacingOccurrences(of: "/", with: "%2F")
            .replacingOccurrences(of: "‘", with: "%91")
            .replacingOccurrences(of: ",", with: "%2C")
            .replacingOccurrences(of: "-", with: "%2D")
            .replacingOccurrences(of: "@", with: "%40")
            //more symbols fixes here: https://mykindred.com/htmlspecialchars.php
    }
}
