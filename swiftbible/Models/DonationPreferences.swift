import Foundation

enum DonationPreferences {
    static let promptOptOutKey = "donationPromptOptOut"
    static let donationCompletedKey = "hasCompletedDonation"
    static let anonIdentifierKey = "donationAnonymousIdentifier"
    static let preferredAmountKey = "preferredDonationAmount"
    static let defaultDonationDollars: Decimal = 5
    static let minimumDonationDollars: Decimal = 1
    static let maximumDonationDollars: Decimal = 500
}
