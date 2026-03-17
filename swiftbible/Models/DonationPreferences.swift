import Foundation

enum DonationPreferences {
    static let promptOptOutKey = "donationPromptOptOut"
    static let donationCompletedKey = "hasCompletedDonation"
    static let anonIdentifierKey = "donationAnonymousIdentifier"
    static let preferredAmountKey = "preferredDonationAmount"
    static let defaultDonationDollars: Decimal = 5
    static let minimumDonationDollars: Decimal = 1
    static let maximumDonationDollars: Decimal = 500

    /// Set to `false` to use StoreKit IAP instead of Stripe.
    /// Flip back to `true` if Apple allows external payments in the future.
    static let useStripePayments = false

    /// StoreKit consumable product IDs for donation tiers.
    static let productIDs: [String] = [
        "com.swiftbible.donation.3",
        "com.swiftbible.donation.5",
        "com.swiftbible.donation.10",
        "com.swiftbible.donation.25",
        "com.swiftbible.donation.50"
    ]

    /// Map a dollar amount to the nearest StoreKit product ID.
    static func productID(for amount: Decimal) -> String? {
        let tiers: [(Decimal, String)] = [
            (3, "com.swiftbible.donation.3"),
            (5, "com.swiftbible.donation.5"),
            (10, "com.swiftbible.donation.10"),
            (25, "com.swiftbible.donation.25"),
            (50, "com.swiftbible.donation.50")
        ]
        // Exact match first
        if let match = tiers.first(where: { $0.0 == amount }) {
            return match.1
        }
        // Nearest tier
        let sorted = tiers.sorted { abs($0.0 - amount) < abs($1.0 - amount) }
        return sorted.first?.1
    }
}
