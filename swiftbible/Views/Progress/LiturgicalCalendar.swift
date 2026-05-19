//
//  LiturgicalCalendar.swift
//  swiftbible
//

import Foundation

/// Computes liturgical dates needed by hidden badges. Easter uses the
/// Anonymous Gregorian (Meeus/Jones/Butcher) algorithm; Pentecost is
/// 49 days after Easter; Christmas is fixed.
enum LiturgicalCalendar {
    /// Western (Gregorian) Easter Sunday for a given year.
    static func easterSunday(year: Int) -> Date? {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components).map(Calendar.current.startOfDay(for:))
    }

    /// Pentecost Sunday — 49 days after Easter.
    static func pentecost(year: Int) -> Date? {
        guard let easter = easterSunday(year: year) else { return nil }
        return Calendar.current.date(byAdding: .day, value: 49, to: easter)
    }

    static func christmas(year: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = 12
        components.day = 25
        return Calendar.current.date(from: components).map(Calendar.current.startOfDay(for:))
    }

    static func isEaster(_ date: Date) -> Bool {
        let year = Calendar.current.component(.year, from: date)
        guard let easter = easterSunday(year: year) else { return false }
        return Calendar.current.isDate(date, inSameDayAs: easter)
    }

    static func isPentecost(_ date: Date) -> Bool {
        let year = Calendar.current.component(.year, from: date)
        guard let pent = pentecost(year: year) else { return false }
        return Calendar.current.isDate(date, inSameDayAs: pent)
    }

    static func isChristmas(_ date: Date) -> Bool {
        let comps = Calendar.current.dateComponents([.month, .day], from: date)
        return comps.month == 12 && comps.day == 25
    }
}
