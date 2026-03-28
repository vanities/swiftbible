import SwiftUI

/// Variant E: Anchoring + Centre-Stage + Premium Framing
///
/// Behavioural principles applied:
/// - **Anchoring** (Tversky & Kahneman, 1974): The first number seen biases subsequent judgments.
///   Higher amounts [$5, $10, $25, $50] with $10 default shifts the anchor upward vs. $5 in control.
/// - **Centre-Stage Effect** (Valenzuela & Raghubir, 2009): People default to the middle option
///   in horizontal layouts. $10 is placed as the visually prominent centre recommendation.
/// - **Decoy Effect** (Huber, Payne & Puto, 1982): Asymmetric dominance makes the target option
///   more attractive. $50 makes $25 feel reasonable; $5 makes $10 feel modest.
/// - **Round Pricing Preference**: Clean round numbers ($10, $25, $50) feel more natural for
///   voluntary donations and reduce decision friction.
struct DonationPromptAnchoringView: View {
    @Binding var isPresented: Bool
    var currencyCode: String
    var onDonate: (Decimal) -> Void

    @Environment(AppViewModel.self) private var appViewModel
    @AppStorage(DonationPreferences.promptOptOutKey) private var donationPromptOptOut = false

    @State private var selectedAmount: Decimal = 10
    // OLD FLOW (Stripe): custom amount field
    // @State private var customAmount = ""
    // @State private var isCustomAmountSelected = false
    // @FocusState private var isCustomAmountFocused: Bool

    // Higher anchor amounts than control ($3/$5/$10/$25)
    private let presetAmounts: [Decimal] = [5, 10, 25, 50]
    private let recommendedAmount: Decimal = 10

    private func formattedAmount(for amount: Decimal) -> String {
        Self.currencyFormatter.currencyCode = currencyCode
        return Self.currencyFormatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$\(amount)"
    }

    var body: some View {
        VStack(spacing: 24) {
            // Hero — premium/star icon
            Image(systemName: "star.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.purple)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(appViewModel.totalPaidCents > 0
                    ? "Continue Your Investment"
                    : "Invest in Scripture")
                    .font(.title2.weight(.semibold))

                Text(appViewModel.totalPaidCents > 0
                    ? "Your contributions sustain free access for readers around the world. Thank you for investing in what matters."
                    : "swiftbible brings Scripture to thousands of readers — for free. Your investment keeps it that way.")
                    .font(.body)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                // Centre-stage grid with recommended option visually prominent
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(presetAmounts, id: \.self) { amount in
                        Button {
                            selectedAmount = amount
                        } label: {
                            VStack(spacing: 4) {
                                Text(formattedAmount(for: amount))
                                    .font(amount == recommendedAmount ? .title3.weight(.bold) : .headline)
                                if amount == recommendedAmount {
                                    Text("Recommended")
                                        .font(.caption2.weight(.bold))
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, amount == recommendedAmount ? 18 : 14)
                            .background(
                                selectedAmount == amount
                                    ? Color.purple
                                    : amount == recommendedAmount
                                        ? Color.purple.opacity(0.12)
                                        : Color.gray.opacity(0.1)
                            )
                            .foregroundColor(
                                selectedAmount == amount
                                    ? .white
                                    : .primary
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(
                                        amount == recommendedAmount && selectedAmount != amount
                                            ? Color.purple.opacity(0.4)
                                            : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .accessibilityLabel("Donate \(formattedAmount(for: amount))\(amount == recommendedAmount ? ", recommended" : "")")
                        .accessibilityAddTraits(selectedAmount == amount ? .isSelected : [])
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
                //             isCustomAmountSelected ? Color.purple : Color.gray.opacity(0.3),
                //             lineWidth: isCustomAmountSelected ? 2 : 1
                //         )
                // )
                // .onTapGesture {
                //     isCustomAmountFocused = true
                //     isCustomAmountSelected = true
                // }

                Text("Every contribution sustains free access to Scripture")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
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
                    Label("Contribute \(formattedAmount(for: selectedAmount))",
                          systemImage: "star.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.purple)
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
