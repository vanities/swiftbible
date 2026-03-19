//
//  AppViewModel.swift
//  swiftbible
//
//  Created on 9/11/24.
//

import SwiftUI
import Foundation

struct SelectedVerse {
    var book: Book
    var chapter: Chapter
    var verse: Int
}

struct DonationSummary: Equatable {
    var sessionId: String
    var amountCents: Int
    var currency: String
    var createdAt: Date

    var formattedAmount: String {
        DonationSummary.currencyFormatter.currencyCode = currency.uppercased()
        let amount = NSDecimalNumber(value: amountCents).dividing(by: NSDecimalNumber(value: 100))
        return DonationSummary.currencyFormatter.string(from: amount) ?? "$\(Double(amountCents) / 100.0)"
    }

    var formattedDate: String {
        DonationSummary.dateFormatter.string(from: createdAt)
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

struct DonationRequest: Equatable {
    var amount: Decimal
    var currency: String
    var source: String
}

@Observable
class AppViewModel {
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    var showSelectedVerse: Bool = false
    var selectedVerse: SelectedVerse?
    var allBibleData: [Book]?

    // Selected Bible version - synced with UserDefaults for persistence
    var selectedVersion: Version {
        didSet {
            UserDefaults.standard.set(selectedVersion.rawValue, forKey: "selectedVersion")
        }
    }
    var navigationPath = NavigationPath()
    var donationFlowRequest: DonationRequest?
    var donationVariant: DonationPromptVariant = .control
    var latestDonation: DonationSummary?
    var donationHistory: [DonationRecord] = []
    var totalPaidCents: Int = 0
    var totalRefundedCents: Int = 0
    var shouldTriggerConfetti: Bool = false

    var netDonatedCents: Int {
        max(totalPaidCents - totalRefundedCents, 0)
    }

    var formattedNetDonation: String {
        formatCurrency(cents: netDonatedCents)
    }

    var formattedTotalPaid: String {
        formatCurrency(cents: totalPaidCents)
    }

    var formattedTotalRefunded: String {
        formatCurrency(cents: totalRefundedCents)
    }

    private func formatCurrency(cents: Int) -> String {
        let formatter = AppViewModel.currencyFormatter
        let currency = latestDonation?.currency.uppercased() ?? donationHistory.first?.currency.uppercased() ?? Locale.current.currency?.identifier.uppercased() ?? "USD"
        formatter.currencyCode = currency
        return formatter.string(from: NSDecimalNumber(value: cents).dividing(by: NSDecimalNumber(value: 100))) ?? "$0"
    }

    func ensureBibleDataLoadedIfNeeded() {
        guard allBibleData == nil || allBibleData?.isEmpty == true else { return }

        let bible = BibleService.shared.fetchBibleData()
        var combinedBooks = bible.oldTestament + bible.newTestament

        let apocrypha = BibleService.shared.fetchApocryphaData()
        let enoch = BibleService.shared.fetchEnochData()
        let jubilees = BibleService.shared.fetchJubileesData()
        let testaments = BibleService.shared.fetchTestamentsData()
        let secondEnoch = BibleService.shared.fetchSecondEnochData()
        let didache = BibleService.shared.fetchDidacheData()
        let firstClement = BibleService.shared.fetchFirstClementData()
        if !apocrypha.isEmpty { combinedBooks.append(contentsOf: apocrypha) }
        if !enoch.isEmpty { combinedBooks.append(contentsOf: enoch) }
        if !jubilees.isEmpty { combinedBooks.append(contentsOf: jubilees) }
        if !testaments.isEmpty { combinedBooks.append(contentsOf: testaments) }
        if !secondEnoch.isEmpty { combinedBooks.append(contentsOf: secondEnoch) }
        if !didache.isEmpty { combinedBooks.append(contentsOf: didache) }
        if !firstClement.isEmpty { combinedBooks.append(contentsOf: firstClement) }

        allBibleData = combinedBooks
    }

    func navigateToVerse(bookName: String, chapterNumber: Int, verseNumber: Int, version: Version? = nil) {
        // Switch to the specified version if provided
        if let version = version, selectedVersion != version {
            selectedVersion = version
        }

        // Load data for the current version
        let bible = BibleService.shared.fetchBibleData(version: selectedVersion)
        var books = bible.oldTestament + bible.newTestament

        // Also check extra-canonical texts for the book
        let apocrypha = BibleService.shared.fetchApocryphaData()
        let enoch = BibleService.shared.fetchEnochData()
        let jubilees = BibleService.shared.fetchJubileesData()
        let testaments = BibleService.shared.fetchTestamentsData()
        let secondEnoch = BibleService.shared.fetchSecondEnochData()
        let didache = BibleService.shared.fetchDidacheData()
        let firstClement = BibleService.shared.fetchFirstClementData()
        books.append(contentsOf: apocrypha)
        books.append(contentsOf: enoch)
        books.append(contentsOf: jubilees)
        books.append(contentsOf: testaments)
        books.append(contentsOf: secondEnoch)
        books.append(contentsOf: didache)
        books.append(contentsOf: firstClement)

        guard let book = books.first(where: { $0.name == bookName }),
              let chapter = book.chapters.first(where: { $0.number == chapterNumber })
        else { return }

        if showSelectedVerse {
            showSelectedVerse = false
        }

        selectedVerse = SelectedVerse(
            book: book,
            chapter: chapter,
            verse: verseNumber
        )
        showSelectedVerse = true
    }

    func requestDonationFlow(amount: Decimal, currency: String, source: String) {
        donationFlowRequest = DonationRequest(amount: amount, currency: currency, source: source)
    }

    func testConfetti() {
        print("🎊 TEST: Triggering confetti from debug button")
        shouldTriggerConfetti = true
    }

    init() {
        // Load saved version from UserDefaults
        let savedVersion = UserDefaults.standard.string(forKey: "selectedVersion") ?? Version.kjv.rawValue
        self.selectedVersion = Version(rawValue: savedVersion) ?? .kjv
    }
}
