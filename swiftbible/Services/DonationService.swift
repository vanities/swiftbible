import Foundation

struct DonationSessionResult {
    let sessionId: String
    let sessionURL: URL
}

struct DonationStatusResult: Decodable {
    let hasDonated: Bool
    let latestDonation: DonationRecord?
}

struct DonationHistoryResponse: Decodable {
    let totalPaidCents: Int
    let totalRefundedCents: Int
    let netDonatedCents: Int
    let donations: [DonationRecord]
}

enum DonationServiceError: LocalizedError {
    case missingAnonymousIdentifier
    case invalidAmount(minimum: Double, maximum: Double)
    case invalidCheckoutURL
    case unableToOpenURL
    case requestFailed(statusCode: Int, message: String?)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .missingAnonymousIdentifier:
            return "We couldn't create a donation session. Please try again."
        case let .invalidAmount(minimum, maximum):
            return "Donations must be between $\(String(format: "%.2f", minimum)) and $\(String(format: "%.2f", maximum))."
        case .invalidCheckoutURL:
            return "Stripe didn't return a donation link. Please try again."
        case .unableToOpenURL:
            return "We couldn't open Stripe Checkout. Please try again."
        case let .requestFailed(_, message):
            return message ?? "The donation service is unavailable right now."
        case .decodingFailed:
            return "We couldn't read the donation response. Please try again."
        }
    }
}

class DonationService {
    static let shared = DonationService()

    private init() {}

    func createDonationSession(
        amount: Decimal,
        currency: String,
        anonymousId: String,
        source: String?
    ) async throws -> DonationSessionResult {
        let sanitizedAnonymousId = anonymousId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard sanitizedAnonymousId.count >= 6 else {
            throw DonationServiceError.missingAnonymousIdentifier
        }

        let minimum = NSDecimalNumber(decimal: DonationPreferences.minimumDonationDollars).doubleValue
        let maximum = NSDecimalNumber(decimal: DonationPreferences.maximumDonationDollars).doubleValue

        let amountDouble = NSDecimalNumber(decimal: amount).doubleValue
        guard amountDouble >= minimum, amountDouble <= maximum else {
            throw DonationServiceError.invalidAmount(minimum: minimum, maximum: maximum)
        }

        guard let amountCents = amount.toCents() else {
            throw DonationServiceError.invalidAmount(minimum: minimum, maximum: maximum)
        }

        let payload = CreateDonationSessionPayload(
            amountCents: amountCents,
            currency: currency.lowercased(),
            anonymousId: sanitizedAnonymousId,
            source: source
        )

        let response: CreateDonationSessionResponse

        do {
            response = try await SupabaseService.shared.invokeFunction(
                "create-donation-session",
                payload: payload,
                responseType: CreateDonationSessionResponse.self
            )
        } catch let error as SupabaseFunctionError {
            throw DonationServiceError.requestFailed(statusCode: error.statusCode, message: error.message)
        }

        guard let url = URL(string: response.url) else {
            throw DonationServiceError.invalidCheckoutURL
        }

        return DonationSessionResult(sessionId: response.sessionId, sessionURL: url)
    }

    func fetchDonationStatus(anonymousId: String, sessionId: String? = nil) async throws -> DonationStatusResult {
        let sanitizedAnonymousId = anonymousId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard sanitizedAnonymousId.count >= 6 else {
            throw DonationServiceError.missingAnonymousIdentifier
        }

        let payload = DonationStatusPayload(
            anonymousId: sanitizedAnonymousId,
            sessionId: sessionId?.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            return try await SupabaseService.shared.invokeFunction(
                "donation-status",
                payload: payload,
                responseType: DonationStatusResult.self
            )
        } catch let error as SupabaseFunctionError {
            throw DonationServiceError.requestFailed(statusCode: error.statusCode, message: error.message)
        }
    }

    func fetchDonationHistory(anonymousId: String) async throws -> DonationHistoryResponse {
        let sanitizedAnonymousId = anonymousId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard sanitizedAnonymousId.count >= 6 else {
            throw DonationServiceError.missingAnonymousIdentifier
        }

        let payload = DonationHistoryPayload(anonymousId: sanitizedAnonymousId)

        do {
            return try await SupabaseService.shared.invokeFunction(
                "donation-history",
                payload: payload,
                responseType: DonationHistoryResponse.self
            )
        } catch let error as SupabaseFunctionError {
            throw DonationServiceError.requestFailed(statusCode: error.statusCode, message: error.message)
        }
    }
}

private extension DonationService {
    struct CreateDonationSessionPayload: Encodable {
        let amountCents: Int
        let currency: String
        let anonymousId: String
        let source: String?
    }

    struct CreateDonationSessionResponse: Decodable {
        let url: String
        let sessionId: String
    }

    struct DonationStatusPayload: Encodable {
        let anonymousId: String
        let sessionId: String?
    }

    struct DonationHistoryPayload: Encodable {
        let anonymousId: String
    }
}

private extension Decimal {
    func toCents() -> Int? {
        let cents = NSDecimalNumber(decimal: self)
            .multiplying(by: NSDecimalNumber(value: 100))
        if cents == NSDecimalNumber.notANumber {
            return nil
        }
        let rounded = cents.rounding(accordingToBehavior: NSDecimalNumberHandler(
            roundingMode: .plain,
            scale: 0,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        ))
        return rounded.intValue
    }
}

struct DonationRecord: Decodable, Identifiable, Equatable {
    let sessionId: String
    let amountCents: Int
    let currency: String
    let status: String
    let refundedAmountCents: Int
    let createdAt: Date

    var id: String { sessionId }

    var amountDecimal: Decimal {
        Decimal(amountCents) / 100
    }

    var formattedAmount: String {
        DonationRecord.currencyFormatter.currencyCode = currency.uppercased()
        let amount = NSDecimalNumber(value: amountCents).dividing(by: NSDecimalNumber(value: 100))
        return DonationRecord.currencyFormatter.string(from: amount) ?? "$\(Double(amountCents) / 100.0)"
    }

    enum CodingKeys: String, CodingKey {
        case stripe_session_id
        case amount_cents
        case currency
        case status
        case refunded_amount_cents
        case created_at
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(String.self, forKey: .stripe_session_id)
        amountCents = try container.decode(Int.self, forKey: .amount_cents)
        currency = try container.decode(String.self, forKey: .currency)
        status = try container.decode(String.self, forKey: .status)
        refundedAmountCents = try container.decodeIfPresent(Int.self, forKey: .refunded_amount_cents) ?? 0
        createdAt = try container.decode(Date.self, forKey: .created_at)
    }

    init(sessionId: String, amountCents: Int, currency: String, status: String, refundedAmountCents: Int, createdAt: Date) {
        self.sessionId = sessionId
        self.amountCents = amountCents
        self.currency = currency
        self.status = status
        self.refundedAmountCents = refundedAmountCents
        self.createdAt = createdAt
    }

    var refundedAmountDecimal: Decimal {
        Decimal(refundedAmountCents) / 100
    }

    var netAmountCents: Int {
        amountCents - refundedAmountCents
    }

    var formattedRefundedAmount: String {
        guard refundedAmountCents > 0 else { return "" }
        DonationRecord.currencyFormatter.currencyCode = currency.uppercased()
        let amount = NSDecimalNumber(value: refundedAmountCents).dividing(by: NSDecimalNumber(value: 100))
        return DonationRecord.currencyFormatter.string(from: amount) ?? "$\(Double(refundedAmountCents) / 100.0)"
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
}
