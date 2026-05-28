import SwiftUI
import PostHog

enum DonationPromptVariant: String, CaseIterable {
    case control
    case lossAversion = "loss_aversion"
    case socialProof = "social_proof"
    case reciprocity
    case anchoring

    static let featureFlagKey = "donation_prompt_variant"

    static func fromPostHog() -> DonationPromptVariant {
        guard let value = PostHogSDK.shared.getFeatureFlag(featureFlagKey) as? String,
              let variant = DonationPromptVariant(rawValue: value) else {
            return .control
        }
        return variant
    }
}

struct DonationPromptContainer: View {
    @Binding var isPresented: Bool
    var currencyCode: String
    var variant: DonationPromptVariant
    var onDonate: (Decimal) -> Void

    var body: some View {
        switch variant {
        case .control:
            DonationPromptView(isPresented: $isPresented, currencyCode: currencyCode, onDonate: onDonate)
        case .lossAversion:
            DonationPromptLossView(isPresented: $isPresented, currencyCode: currencyCode, onDonate: onDonate)
        case .socialProof:
            DonationPromptSocialView(isPresented: $isPresented, currencyCode: currencyCode, onDonate: onDonate)
        case .reciprocity:
            DonationPromptReciprocityView(isPresented: $isPresented, currencyCode: currencyCode, onDonate: onDonate)
        case .anchoring:
            DonationPromptAnchoringView(isPresented: $isPresented, currencyCode: currencyCode, onDonate: onDonate)
        }
    }
}
