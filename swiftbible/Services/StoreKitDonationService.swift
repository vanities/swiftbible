//
//  StoreKitDonationService.swift
//  swiftbible
//
//  StoreKit 2 service for in-app purchase donations.
//

import StoreKit
import SwiftUI

@Observable
class StoreKitDonationService {
    static let shared = StoreKitDonationService()

    private(set) var products: [Product] = []
    private(set) var purchaseInProgress = false

    private init() {}

    /// Load donation products from App Store Connect.
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: DonationPreferences.productIDs)
            await MainActor.run {
                products = storeProducts.sorted { $0.price < $1.price }
            }
        } catch {
            print("Failed to load StoreKit products: \(error)")
        }
    }

    /// Purchase a donation by dollar amount. Returns the verified transaction.
    func purchase(amount: Decimal) async throws -> StoreKit.Transaction {
        guard let productID = DonationPreferences.productID(for: amount),
              let product = products.first(where: { $0.id == productID }) else {
            AnalyticsService.shared.capture(.donationFailed, properties: [
                "amount": "\(amount)",
                "reason": "product_not_found"
            ])
            throw StoreKitDonationError.productNotFound
        }

        await MainActor.run { purchaseInProgress = true }
        defer { Task { @MainActor in purchaseInProgress = false } }

        AnalyticsService.shared.capture(.donationPaymentSheetShown, properties: [
            "amount": "\(amount)",
            "product_id": productID
        ])

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return transaction

        case .userCancelled:
            AnalyticsService.shared.capture(.donationCancelled, properties: [
                "amount": "\(amount)",
                "product_id": productID,
                "reason": "user_cancelled"
            ])
            throw StoreKitDonationError.userCancelled

        case .pending:
            throw StoreKitDonationError.pending

        @unknown default:
            AnalyticsService.shared.capture(.donationFailed, properties: [
                "amount": "\(amount)",
                "product_id": productID,
                "reason": "unknown"
            ])
            throw StoreKitDonationError.unknown
        }
    }

    /// Purchase a specific StoreKit product directly.
    func purchase(product: Product) async throws -> StoreKit.Transaction {
        await MainActor.run { purchaseInProgress = true }
        defer { Task { @MainActor in purchaseInProgress = false } }

        AnalyticsService.shared.capture(.donationPaymentSheetShown, properties: [
            "product_id": product.id
        ])

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return transaction

        case .userCancelled:
            AnalyticsService.shared.capture(.donationCancelled, properties: [
                "product_id": product.id,
                "reason": "user_cancelled"
            ])
            throw StoreKitDonationError.userCancelled

        case .pending:
            throw StoreKitDonationError.pending

        @unknown default:
            AnalyticsService.shared.capture(.donationFailed, properties: [
                "product_id": product.id,
                "reason": "unknown"
            ])
            throw StoreKitDonationError.unknown
        }
    }

    /// Listen for unfinished transactions (e.g., interrupted purchases).
    /// Call from ContentView.onAppear and keep the task alive.
    func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    // Post notification so ContentView can record the donation
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .storeKitDonationCompleted,
                            object: nil,
                            userInfo: [
                                "transactionID": String(transaction.id),
                                "productID": transaction.productID,
                                "amountCents": self.amountCents(for: transaction.productID),
                                "purchaseDate": transaction.purchaseDate
                            ]
                        )
                    }
                } catch {
                    print("StoreKit transaction verification failed: \(error)")
                }
            }
        }
    }

    /// Extract cents from a product ID (e.g., "com.swiftbible.donation.5" → 499).
    func amountCents(for productID: String) -> Int {
        guard let last = productID.split(separator: ".").last,
              let dollars = Int(last) else { return 0 }
        // Map to App Store tier pricing
        switch dollars {
        case 3: return 299
        case 5: return 499
        case 10: return 999
        case 25: return 2499
        case 50: return 4999
        default: return dollars * 100
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitDonationError.verificationFailed
        case .verified(let value):
            return value
        }
    }
}

enum StoreKitDonationError: LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case verificationFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Donation product not available. Please try again later."
        case .userCancelled:
            return nil // Silent — user chose to cancel
        case .pending:
            return "Your donation is pending approval."
        case .verificationFailed:
            return "Could not verify the transaction. Please contact support."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}

extension Notification.Name {
    static let storeKitDonationCompleted = Notification.Name("storeKitDonationCompleted")
}
