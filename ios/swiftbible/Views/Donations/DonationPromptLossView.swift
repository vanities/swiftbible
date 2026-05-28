import SwiftUI

/// Variant B: Loss Aversion + Urgency
///
/// Behavioural principles applied:
/// - **Loss Aversion** (Kahneman & Tversky, 1979): Losses loom larger than equivalent gains.
///   Copy frames inaction as losing free access rather than gaining supporter status.
/// - **Status Quo Bias** (Samuelson & Zeckhauser, 1988): People prefer the current state.
///   "Don't let free access disappear" frames donation as preserving what they already have.
/// - **Scarcity Framing** (Cialdini, 2001): Perceived scarcity increases perceived value.
///   "At risk" language creates urgency without fabricating deadlines.
struct DonationPromptLossView: View {
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
    private let recommendedAmount: Decimal = 5

    private func formattedAmount(for amount: Decimal) -> String {
        Self.currencyFormatter.currencyCode = currencyCode
        return Self.currencyFormatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$\(amount)"
    }

    var body: some View {
        VStack(spacing: 24) {
            // Hero — warning/shield icon to trigger protective instinct
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(appViewModel.totalPaidCents > 0
                    ? "swiftbible Still Needs You"
                    : "swiftbible Needs Your Help")
                    .font(.title2.weight(.semibold))

                Text(appViewModel.totalPaidCents > 0
                    ? "Your past support made a difference. But servers run every day, and without continued help, free access to Scripture is at risk."
                    : "Without reader support, swiftbible's servers and future updates are at risk. Don't let free access to Scripture disappear.")
                    .font(.body)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Text("Choose an amount to protect access")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(presetAmounts, id: \.self) { amount in
                        Button {
                            selectedAmount = amount
                        } label: {
                            VStack(spacing: 4) {
                                Text(formattedAmount(for: amount))
                                    .font(.headline)
                                if amount == recommendedAmount {
                                    Text("Keeps the lights on")
                                        .font(.caption2.weight(.semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedAmount == amount
                                    ? Color.orange
                                    : Color.gray.opacity(0.15)
                            )
                            .foregroundColor(
                                selectedAmount == amount
                                    ? .white
                                    : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .accessibilityLabel("Donate \(formattedAmount(for: amount))\(amount == recommendedAmount ? ", keeps the lights on" : "")")
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
                //             isCustomAmountSelected ? Color.orange : Color.gray.opacity(0.3),
                //             lineWidth: isCustomAmountSelected ? 2 : 1
                //         )
                // )
                // .onTapGesture {
                //     isCustomAmountFocused = true
                //     isCustomAmountSelected = true
                // }

                Text("Once it's gone, it's gone — help today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            VStack(spacing: 12) {
                Button {
                    // OLD FLOW (Stripe): validated custom amounts against min/max
                    onDonate(selectedAmount)
                    isPresented = false
                } label: {
                    Label("Protect Free Access — \(formattedAmount(for: selectedAmount))",
                          systemImage: "shield.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange)
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
