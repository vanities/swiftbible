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

    /// Good Friday — two days before Easter Sunday.
    static func goodFriday(year: Int) -> Date? {
        guard let easter = easterSunday(year: year) else { return nil }
        return Calendar.current.date(byAdding: .day, value: -2, to: easter)
    }

    static func isGoodFriday(_ date: Date) -> Bool {
        let year = Calendar.current.component(.year, from: date)
        guard let gf = goodFriday(year: year) else { return false }
        return Calendar.current.isDate(date, inSameDayAs: gf)
    }

    /// Ash Wednesday — 46 days before Easter (40 fasting days plus six Sundays).
    static func ashWednesday(year: Int) -> Date? {
        guard let easter = easterSunday(year: year) else { return nil }
        return Calendar.current.date(byAdding: .day, value: -46, to: easter)
    }

    static func isAshWednesday(_ date: Date) -> Bool {
        let year = Calendar.current.component(.year, from: date)
        guard let aw = ashWednesday(year: year) else { return false }
        return Calendar.current.isDate(date, inSameDayAs: aw)
    }

    /// The four Sundays of Advent, earliest first. The fourth (last) Advent
    /// Sunday is the Sunday falling in Dec 18–24; the rest are the preceding
    /// Sundays at one-week intervals.
    static func adventSundays(year: Int) -> [Date] {
        let cal = Calendar.current
        for day in 18...24 {
            var comps = DateComponents()
            comps.year = year
            comps.month = 12
            comps.day = day
            guard let date = cal.date(from: comps) else { continue }
            guard cal.component(.weekday, from: date) == 1 else { continue } // Sunday == 1
            let fourth = cal.startOfDay(for: date)
            return [3, 2, 1, 0].compactMap { cal.date(byAdding: .day, value: -7 * $0, to: fourth) }
        }
        return []
    }

    /// The hours straddling midnight on New Year's — late on Dec 31 or the
    /// small hours of Jan 1, mirroring a watchnight service.
    static func isWatchnight(_ date: Date) -> Bool {
        let comps = Calendar.current.dateComponents([.month, .day, .hour], from: date)
        guard let month = comps.month, let day = comps.day, let hour = comps.hour else { return false }
        return (month == 12 && day == 31 && hour >= 22) || (month == 1 && day == 1 && hour < 4)
    }
}
