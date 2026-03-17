//
//  LocalDonationRecord.swift
//  swiftbible
//
//  SwiftData model for persisting StoreKit donation history locally.
//  Consumable IAP transactions are not retained by StoreKit after finish().
//

import SwiftData
import Foundation

@Model
class LocalDonationRecord {
    var transactionID: String
    var productID: String
    var amountCents: Int
    var currency: String
    var purchaseDate: Date
    var status: String

    init(transactionID: String, productID: String, amountCents: Int, currency: String, purchaseDate: Date, status: String = "completed") {
        self.transactionID = transactionID
        self.productID = productID
        self.amountCents = amountCents
        self.currency = currency
        self.purchaseDate = purchaseDate
        self.status = status
    }
}
