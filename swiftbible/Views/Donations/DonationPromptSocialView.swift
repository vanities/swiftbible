import SwiftUI

/// Variant C: Social Proof + Community Identity
///
/// Behavioural principles applied:
/// - **Social Proof** (Cialdini, 1984): People follow the actions of others in uncertain situations.
///   "Join hundreds of supporters" and "Most popular" labels leverage descriptive norms.
/// - **Bandwagon Effect** (Leibenstein, 1950): Demand increases because others are consuming.
///   Framing tiers as community roles ("Supporter", "Champion") creates aspirational social pressure.
/// - **Authority / Halo Effect**: Star ratings and community framing build credibility and trust,
///   reducing perceived risk of the donation decision.
struct DonationPromptSocialView: View {
    @Binding var isPresented: Bool
    var currencyCode: String
    var onDonate: (Decimal) -> Void

    @Environment(AppViewModel.self) private var appViewModel
    @AppStorage(DonationPreferences.promptOptOutKey) private var donationPromptOptOut = false

    @State private var selectedAmount = DonationPreferences.defaultDonationDollars
    // OLD FLOW (Stripe): custom amount field
    // @State private var customAmount = ""
    // @State private var isCustomAmountSelected = false
    // @FocusState private var isCustomAmountFocused: Bool

    private let presetAmounts: [Decimal] = [3, 5, 10, 25]

    private let tierLabels: [Decimal: String] = [
        3: "Supporter",
        5: "Most popular",
        10: "Generous",
        25: "Champion"
    ]

    private func formattedAmount(for amount: Decimal) -> String {
        Self.currencyFormatter.currencyCode = currencyCode
        return Self.currencyFormatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$\(amount)"
    }

    var body: some View {
        VStack(spacing: 24) {
            // Hero — community/group icon
            Image(systemName: "person.3.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            VStack(spacing: 12) {
                Text(appViewModel.totalPaidCents > 0
                    ? "Welcome Back, Supporter!"
                    : "Join Hundreds of Supporters")
                    .font(.title2.weight(.semibold))

                Text(appViewModel.totalPaidCents > 0
                    ? "You're already part of the community keeping swiftbible free. Every repeat gift strengthens the mission."
                    : "Readers just like you chip in to keep swiftbible free for everyone. Join the community that makes it possible.")
                    .font(.body)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                // Social proof star rating
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                    Text("Loved by readers worldwide")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(presetAmounts, id: \.self) { amount in
                        Button {
                            selectedAmount = amount
                        } label: {
                            VStack(spacing: 4) {
                                Text(formattedAmount(for: amount))
                                    .font(.headline)
                                if let label = tierLabels[amount] {
                                    Text(label)
                                        .font(.caption2.weight(.semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedAmount == amount
                                    ? Color.blue
                                    : Color.gray.opacity(0.15)
                            )
                            .foregroundColor(
                                selectedAmount == amount
                                    ? .white
                                    : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }

                // OLD FLOW (Stripe): custom amount field — StoreKit requires fixed prices
                // HStack {
                //     Text(currencySymbol)
                //         .font(.headline)
                //         .foregroundStyle(.secondary)
                //     TextField("Other amount", text: $customAmount)
                //         .font(.headline)
                //         .keyboardType(.decimalPad)
                //         .focused($isCustomAmountFocused)
                //         .onChange(of: customAmount) { _, newValue in
                //             if !newValue.isEmpty {
                //                 isCustomAmountSelected = true
                //                 let cleaned = newValue.replacingOccurrences(of: ",", with: ".")
                //                 if let decimal = Decimal(string: cleaned), decimal > 0 {
                //                     selectedAmount = decimal
                //                 }
                //             }
                //         }
                // }
                // .padding(.horizontal, 16)
                // .padding(.vertical, 14)
                // .background(
                //     RoundedRectangle(cornerRadius: 10, style: .continuous)
                //         .stroke(
                //             isCustomAmountSelected ? Color.blue : Color.gray.opacity(0.3),
                //             lineWidth: isCustomAmountSelected ? 2 : 1
                //         )
                // )
                // .onTapGesture {
                //     isCustomAmountFocused = true
                //     isCustomAmountSelected = true
                // }
            }

            VStack(spacing: 12) {
                Button {
                    // OLD FLOW (Stripe): validated custom amounts against min/max
                    // if selectedAmount >= DonationPreferences.minimumDonationDollars &&
                    //    selectedAmount <= DonationPreferences.maximumDonationDollars {
                    //     onDonate(selectedAmount)
                    //     isPresented = false
                    // }
                    onDonate(selectedAmount)
                    isPresented = false
                } label: {
                    Label(appViewModel.totalPaidCents > 0
                        ? "Give Again — \(formattedAmount(for: selectedAmount))"
                        : "Join the Supporters — \(formattedAmount(for: selectedAmount))",
                          systemImage: "person.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button(role: .cancel) {
                    isPresented = false
                } label: {
                    Text("Not now")
                        .font(.body)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }

            Toggle(isOn: Binding(
                get: { !donationPromptOptOut },
                set: { donationPromptOptOut = !$0 }
            )) {
                Text("Show donation reminder pop up")
                    .font(.footnote)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 12)
        )
        .padding(.horizontal, 24)
    }

    // OLD FLOW (Stripe): currency symbol for custom amount field
    // private var currencySymbol: String {
    //     let formatter = NumberFormatter()
    //     formatter.numberStyle = .currency
    //     formatter.currencyCode = currencyCode
    //     return formatter.currencySymbol ?? "$"
    // }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
}
