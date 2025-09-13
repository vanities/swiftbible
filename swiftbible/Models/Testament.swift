//
//  Testament.swift
//  swiftbible
//
//  Created on 9/1/24.
//

import Foundation

enum Testament: Codable {
    case old
    case new
    case apocrypha
    case enoch

    static let oldNames = [
           "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
           "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel",
           "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra",
           "Nehemiah", "Esther", "Job", "Psalms", "Proverbs",
           "Ecclesiastes", "Song of Solomon", "Isaiah", "Jeremiah",
           "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel",
           "Amos", "Obadiah", "Jonah", "Micah", "Nahum",
           "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi"
       ]

    static let newNames = [
        "Matthew", "Mark", "Luke", "John", "Acts", "Romans",
        "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians", "Philippians",
        "Colossians", "1 Thessalonians", "2 Thessalonians", "1 Timothy",
        "2 Timothy", "Titus", "Philemon", "Hebrews", "James", "1 Peter",
        "2 Peter", "1 John", "2 John", "3 John", "Jude", "Revelation",
    ]

    static let apocryphaNames = [
        "1 Esdras",
        "2 Esdras",
        "Tobit",
        "Judith",
        "Additions to Esther",
        "Wisdom of Solomon",
        "Ecclesiasticus",
        "Baruch",
        "Letter of Jeremiah",
        "Prayer of Azariah",
        "Susanna",
        "Bel and the Dragon",
        "Prayer of Manasseh",
        "1 Maccabees",
        "2 Maccabees",
    ]

    static let enochNames = [
        "The Book of the Watchers",
        "The Book of Parables",
        "The Astronomical Book",
        "The Book of Dream Visions",
        "The Epistle of Enoch",
    ]
}
