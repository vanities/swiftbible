import SwiftUI

/// Variant D: Reciprocity + Concrete Impact
///
/// Behavioural principles applied:
/// - **Reciprocity** (Gouldner, 1960; Cialdini, 1984): People feel obligated to return favours.
///   "You've been reading for free" triggers the reciprocity norm — giving back for value received.
/// - **Identifiable Victim / Concrete Impact**: Specific cost breakdowns ("$5 = 1 month of uptime")
///   make abstract donations feel tangible. People give more when they see exactly where money goes.
/// - **Endowed Progress Effect** (Nunes & Dreze, 2006): Showing value already received ("free Scripture access")
///   creates a sense of progress toward reciprocation, increasing follow-through.
struct DonationPromptReciprocityView: View {
    @Binding var isPresented: Bool
    var currencyCode: String
    var onDonate: (Decimal) -> Void

    @Environment(AppViewModel.self) private var appViewModel
    @AppStorage(DonationPreferences.promptOptOutKey) private var donationPromptOptOut = false

    @State private var selectedAmount = DonationPreferences.defaultDonationDollars
    @State private var customAmount = ""
    @State private var isCustomAmountSelected = false
    @FocusState private var isCustomAmountFocused: Bool

    private let presetAmounts: [Decimal] = [3, 5, 10, 25]

    private let impactLabels: [Decimal: String] = [
        3: "1 week of hosting",
        5: "1 month of uptime",
        10: "App Store fees",
        25: "A month of development"
    ]

    private func formattedAmount(for amount: Decimal) -> String {
        Self.currencyFormatter.currencyCode = currencyCode
        return Self.currencyFormatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$\(amount)"
    }

    var body: some View {
        VStack(spacing: 24) {
            // Hero — gift icon to prime reciprocity
            Image(systemName: "gift.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            VStack(spacing: 12) {
                Text(appViewModel.totalPaidCents > 0
                    ? "Your Impact Continues"
                    : "A Small Gift Goes a Long Way")
                    .font(.title2.weight(.semibold))

                Text(appViewModel.totalPaidCents > 0
                    ? "Your past generosity kept swiftbible running. Here's how another gift makes a direct impact:"
                    : "You've been reading Scripture for free — a small gift back helps keep swiftbible running for everyone.")
                    .font(.body)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Text("See your impact")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Amount buttons with concrete impact labels
                ForEach(presetAmounts, id: \.self) { amount in
                    Button {
                        selectedAmount = amount
                        isCustomAmountSelected = false
                        customAmount = ""
                        isCustomAmountFocused = false
                    } label: {
                        HStack {
                            Text(formattedAmount(for: amount))
                                .font(.headline)
                                .frame(width: 60, alignment: .leading)

                            if let impact = impactLabels[amount] {
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(impact)
                                    .font(.subheadline)
                            }

                            Spacer()

                            if !isCustomAmountSelected && selectedAmount == amount {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            !isCustomAmountSelected && selectedAmount == amount
                                ? Color.green.opacity(0.12)
                                : Color.gray.opacity(0.08)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    !isCustomAmountSelected && selectedAmount == amount
                                        ? Color.green
                                        : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .foregroundColor(.primary)
                }

                HStack {
                    Text(currencySymbol)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    TextField("Other amount", text: $customAmount)
                        .font(.headline)
                        .keyboardType(.decimalPad)
                        .focused($isCustomAmountFocused)
                        .onChange(of: customAmount) { _, newValue in
                            if !newValue.isEmpty {
                                isCustomAmountSelected = true
                                let cleaned = newValue.replacingOccurrences(of: ",", with: ".")
                                if let decimal = Decimal(string: cleaned), decimal > 0 {
                                    selectedAmount = decimal
                                }
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            isCustomAmountSelected ? Color.green : Color.gray.opacity(0.3),
                            lineWidth: isCustomAmountSelected ? 2 : 1
                        )
                )
                .onTapGesture {
                    isCustomAmountFocused = true
                    isCustomAmountSelected = true
                }
            }

            VStack(spacing: 12) {
                Button {
                    if selectedAmount >= DonationPreferences.minimumDonationDollars &&
                       selectedAmount <= DonationPreferences.maximumDonationDollars {
                        onDonate(selectedAmount)
                        isPresented = false
                    }
                } label: {
                    Label("Give Back — \(formattedAmount(for: selectedAmount))",
                          systemImage: "arrow.uturn.backward.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
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

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.currencySymbol ?? "$"
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
}
