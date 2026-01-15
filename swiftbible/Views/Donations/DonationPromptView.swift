import SwiftUI
import UIKit

struct DonationPromptView: View {
    @Binding var isPresented: Bool
    var currencyCode: String
    var onDonate: (Decimal) -> Void

    @Environment(AppViewModel.self) private var appViewModel
    @AppStorage(DonationPreferences.promptOptOutKey) private var donationPromptOptOut = false
    @AppStorage(DonationPreferences.donationCompletedKey) private var hasCompletedDonation = false

    @State private var animateSadFace = false
    @State private var selectedAmount = DonationPreferences.defaultDonationDollars
    @State private var customAmount = ""
    @State private var isCustomAmountSelected = false
    @FocusState private var isCustomAmountFocused: Bool

    private let presetAmounts: [Decimal] = [1, 5, 10, 25]

    private func formattedAmount(for amount: Decimal) -> String {
        DonationPromptView.currencyFormatter.currencyCode = currencyCode
        let nsAmount = NSDecimalNumber(decimal: amount)
        return DonationPromptView.currencyFormatter.string(from: nsAmount) ?? "$\(amount)"
    }

    var body: some View {
        VStack(spacing: 24) {
            if animateSadFace {
                SadFaceAnimationView(isActive: animateSadFace)
                    .frame(height: 110)
            } else {
                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 56, weight: .regular, design: .default))
                    .foregroundStyle(.yellow)
                    .rotationEffect(.degrees(-6))
            }

            VStack(spacing: 12) {
                Text(appViewModel.totalPaidCents > 0 ? "Support swiftbible Again!" : "Support swiftbible")
                    .font(.title2.weight(.semibold))

                Text(appViewModel.totalPaidCents > 0
                    ? "Welcome back! Your continued support helps keep swiftbible running and available for everyone. Thank you for being amazing! 🙏"
                    : "Your donation helps pay for server costs and the Apple developer fee. Thanks for helping keep swiftbible online.")
                    .font(.body)
                    .multilineTextAlignment(.center)
            }

            // Amount Selection
            VStack(spacing: 12) {
                Text("Choose an amount")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Preset amounts grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(presetAmounts, id: \.self) { amount in
                        Button {
                            selectedAmount = amount
                            isCustomAmountSelected = false
                            customAmount = ""
                            isCustomAmountFocused = false
                        } label: {
                            Text(formattedAmount(for: amount))
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    !isCustomAmountSelected && selectedAmount == amount
                                        ? Color.accentColor
                                        : Color.gray.opacity(0.15)
                                )
                                .foregroundColor(
                                    !isCustomAmountSelected && selectedAmount == amount
                                        ? .white
                                        : .primary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }

                // Custom amount field
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
                                // Clean and validate input
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
                            isCustomAmountSelected ? Color.accentColor : Color.gray.opacity(0.3),
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
                    let finalAmount = isCustomAmountSelected && !customAmount.isEmpty
                        ? selectedAmount
                        : selectedAmount

                    // Validate amount
                    if finalAmount >= DonationPreferences.minimumDonationDollars &&
                       finalAmount <= DonationPreferences.maximumDonationDollars {
                        onDonate(finalAmount)
                        isPresented = false
                    }
                } label: {
                    Label(appViewModel.totalPaidCents > 0
                        ? "Donate \(formattedAmount(for: selectedAmount)) Again! 🎉"
                        : "Donate \(formattedAmount(for: selectedAmount))",
                        systemImage: "heart.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
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
            .onChange(of: donationPromptOptOut) { _, newValue in
                if newValue {
                    withAnimation {
                        animateSadFace = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        animateSadFace = false
                    }
                }
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

#Preview {
    DonationPromptView(
        isPresented: .constant(true),
        currencyCode: "USD"
    ) { amount in
        print("Donate: \(amount)")
    }
    .environment(AppViewModel())
    .background(Color.gray.opacity(0.2))
}

private struct SadFaceAnimationView: View {
    var isActive: Bool

    @State private var tearOffset: CGFloat = -6
    @State private var tearOpacity: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.cyan.opacity(0.15))
                .frame(width: 110, height: 110)

            Circle()
                .strokeBorder(Color.cyan.opacity(0.5), lineWidth: 2)
                .background(
                    Circle().fill(Color.cyan.opacity(0.12))
                )
                .frame(width: 96, height: 96)

            HStack(spacing: 28) {
                Circle().frame(width: 10, height: 10)
                Circle().frame(width: 10, height: 10)
            }
            .foregroundColor(.cyan)
            .offset(y: -10)

            SadMouthShape()
                .stroke(Color.cyan, lineWidth: 3)
                .frame(width: 60, height: 24)
                .offset(y: 18)

            Circle()
                .fill(Color.cyan)
                .frame(width: 8, height: 12)
                .offset(x: 22, y: tearOffset)
                .opacity(tearOpacity)
        }
        .frame(width: 120, height: 120)
        .onAppear {
            if isActive {
                playAnimation()
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                playAnimation()
            } else {
                resetAnimation()
            }
        }
    }

    private func playAnimation() {
        resetAnimation()
        withAnimation(.easeIn(duration: 0.25)) {
            tearOpacity = 1
        }
        withAnimation(.easeIn(duration: 0.7)) {
            tearOffset = 32
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.2)) {
                tearOpacity = 0
            }
        }
    }

    private func resetAnimation() {
        tearOffset = -6
        tearOpacity = 0
    }
}

private struct SadMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        path.move(to: CGPoint(x: 0, y: height))
        path.addQuadCurve(
            to: CGPoint(x: width, y: height),
            control: CGPoint(x: width / 2, y: 0)
        )
        return path
    }
}
