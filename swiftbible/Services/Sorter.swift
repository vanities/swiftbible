//
//  Sorter.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/2/24.
//

import Foundation


func sorter(key1: String, key2: String) -> Bool {
    guard let intKey1 = Int(key1), let intKey2 = Int(key2) else {
        return key1 < key2
    }
    return intKey1 < intKey2
}

func sorter2(key1: [String: String], key2: [String: String]) -> Bool {
    guard let intKey1 = Int(key1.first!.key), let intKey2 = Int(key2.first!.key) else {
        return true
    }
    return intKey1 < intKey2
}
