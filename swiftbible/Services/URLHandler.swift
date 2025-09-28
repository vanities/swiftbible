import SwiftUI

@Observable
class URLHandler: NSObject, ObservableObject {
    @MainActor
    func handle(url: URL) {
        guard url.scheme?.lowercased() == "swiftbible" else { return }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let sessionID = components?.queryItems?
            .first(where: { $0.name.lowercased() == "session_id" })?
            .value

        switch url.host?.lowercased() {
        case "donation-success":
            NotificationCenter.default.post(
                name: .donationCompleted,
                object: nil,
                userInfo: ["session_id": sessionID as Any]
            )
            NotificationCenter.default.post(name: .donationStatusShouldRefresh, object: nil, userInfo: ["session_id": sessionID as Any])
        case "donation-cancel":
            NotificationCenter.default.post(name: .donationCancelled, object: nil)
            NotificationCenter.default.post(name: .donationStatusShouldRefresh, object: nil)
        default:
            break
        }
    }
}

extension Notification.Name {
    static let donationCompleted = Notification.Name("DonationCompletedNotification")
    static let donationCancelled = Notification.Name("DonationCancelledNotification")
    static let donationStatusShouldRefresh = Notification.Name("DonationStatusShouldRefresh")
}
