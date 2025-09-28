import SwiftUI

struct DonationCelebrationView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.pink)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)

                Text("Preparing donation...")
                    .font(.title2)
                    .fontWeight(.semibold)

                ProgressView()
                    .scaleEffect(1.5)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(uiColor: .systemBackground))
            )
            .shadow(radius: 20)
        }
        .onAppear {
            isAnimating = true
        }
    }
}
