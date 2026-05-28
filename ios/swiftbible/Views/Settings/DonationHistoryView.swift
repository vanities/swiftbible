import SwiftUI

struct DonationHistoryView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        List {
            if appViewModel.donationHistory.isEmpty {
                Text("No donations yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Section(header: summaryHeader) {
                    ForEach(appViewModel.donationHistory, id: \.sessionId) { donation in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(donation.formattedAmount)
                                    .font(.headline)
                                Spacer()
                                StatusBadge(status: donation.status)
                            }
                            Text(formattedDate(for: donation))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            if donation.refundedAmountCents > 0 {
                                Text("Refunded \(donation.formattedRefundedAmount)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Donation History")
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Total Donated")
                .font(.subheadline.weight(.semibold))
            Text(appViewModel.formattedNetDonation)
                .font(.title3.weight(.semibold))
            if appViewModel.totalRefundedCents > 0 {
                Text("Refunded \(appViewModel.formattedTotalRefunded)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formattedDate(for donation: DonationRecord) -> String {
        DonationHistoryView.dateFormatter.string(from: donation.createdAt)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

private struct StatusBadge: View {
    let status: String

    var body: some View {
        let (label, color) = badgeStyle(for: status)
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color, in: Capsule())
    }

    private func badgeStyle(for status: String) -> (String, Color) {
        switch status.lowercased() {
        case "paid":
            return ("Paid", .green)
        case "partially_refunded":
            return ("Partially Refunded", .orange)
        case "refunded":
            return ("Refunded", .red)
        default:
            return (status.capitalized, .gray)
        }
    }
}

#Preview {
    let vm = AppViewModel()
    vm.donationHistory = [
        DonationRecord(sessionId: "session1", amountCents: 1000, currency: "usd", status: "paid", refundedAmountCents: 0, createdAt: Date()),
        DonationRecord(sessionId: "session2", amountCents: 2000, currency: "usd", status: "partially_refunded", refundedAmountCents: 500, createdAt: Date().addingTimeInterval(-86400))
    ]
    vm.totalPaidCents = 3000
    vm.totalRefundedCents = 500
    return DonationHistoryView()
        .environment(vm)
}
