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
    var navigationPath = NavigationPath()
    var donationFlowRequest: DonationRequest?
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

    func navigateToVerse(bookName: String, chapterNumber: Int, verseNumber: Int) {
        guard let books = allBibleData,
              let book = books.first(where: { $0.name == bookName }),
              let chapter = book.chapters.first(where: { $0.number == chapterNumber })
        else { return }
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
}
