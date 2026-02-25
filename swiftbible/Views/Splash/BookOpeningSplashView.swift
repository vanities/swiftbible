//
//  BookOpeningSplashView.swift
//  swiftbible
//

import SwiftUI

struct BookOpeningSplashView: View {
    var onFinished: () -> Void

    // Cover
    @State private var coverAngle: Double = 0
    @State private var showCoverFront = true

    // Pages
    @State private var page1Angle: Double = 0
    @State private var page2Angle: Double = 0
    @State private var page3Angle: Double = 0

    // Global
    @State private var bookScale: CGFloat = 1.0
    @State private var contentOpacity: Double = 1.0
    @State private var backgroundOpacity: Double = 1.0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20

    private let gradient = LinearGradient(
        colors: [
            Color(red: 0.75, green: 0.85, blue: 0.0),
            Color(red: 0.2, green: 0.8, blue: 0.4),
            Color(red: 0.0, green: 0.75, blue: 0.85)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let bookW: CGFloat = 120
    private let bookH: CGFloat = 160

    var body: some View {
        ZStack {
            gradient
                .ignoresSafeArea()
                .opacity(backgroundOpacity)

            VStack(spacing: 28) {
                ZStack {
                    // Back cover (always flat)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(white: 0.20))
                        .frame(width: bookW, height: bookH)

                    // Pages (smaller than cover, fan from leading edge)
                    pageFan(angle: page3Angle, shade: 0.85, lineWidths: [70, 55, 65, 40, 60])
                    pageFan(angle: page2Angle, shade: 0.90, lineWidths: [50, 65, 45, 70, 55])
                    pageFan(angle: page1Angle, shade: 0.96, lineWidths: [60, 45, 70, 50, 65])

                    // Front cover - two faces swapped at 90 degrees
                    ZStack {
                        // Inside of cover (visible after 90)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.18))
                            .frame(width: bookW, height: bookH)
                            .opacity(showCoverFront ? 0 : 1)

                        // Outside of cover with cross (visible before 90)
                        coverFront
                            .opacity(showCoverFront ? 1 : 0)
                    }
                    .rotation3DEffect(
                        .degrees(-coverAngle),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .leading,
                        perspective: 0.3
                    )
                }
                .frame(width: bookW * 2, height: bookH + 10)
                .scaleEffect(bookScale)
                .opacity(contentOpacity)

                Text("SwiftBible")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
            }
        }
        .onAppear {
            animate()
        }
    }

    // MARK: - Cover Front Face

    private var coverFront: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.15))
                .frame(width: bookW, height: bookH)

            // Cross - vertical top
            Rectangle()
                .fill(gradient)
                .frame(width: 4, height: 35)
                .offset(y: -12)

            // Cross - horizontal bar
            Rectangle()
                .fill(gradient)
                .frame(width: 26, height: 4)
                .offset(y: -5)

            // Cross - vertical bottom (longer)
            Rectangle()
                .fill(gradient)
                .frame(width: 4, height: 22)
                .offset(y: 12)

            // Bookmark tab at bottom
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 14))
                path.addLine(to: CGPoint(x: 7, y: 9))
                path.addLine(to: CGPoint(x: 14, y: 14))
                path.addLine(to: CGPoint(x: 14, y: 0))
            }
            .fill(Color(white: 0.15))
            .frame(width: 14, height: 14)
            .offset(x: -20, y: bookH / 2 + 4)

            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(white: 0.25), lineWidth: 1.5)
                .frame(width: bookW, height: bookH)
        }
    }

    // MARK: - Page

    private func pageFan(angle: Double, shade: CGFloat, lineWidths: [CGFloat]) -> some View {
        let pageW = bookW - 14
        let pageH = bookH - 14

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(white: shade))
                .frame(width: pageW, height: pageH)

            // Text lines
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(lineWidths.enumerated()), id: \.offset) { _, w in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(white: shade - 0.12))
                        .frame(width: w, height: 1.5)
                }
            }
            .padding(.top, 14)
            .padding(.leading, 12)
            .opacity(angle > 5 ? 1 : 0)

            // Page edge shadow
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color(white: shade - 0.06), lineWidth: 0.5)
                .frame(width: pageW, height: pageH)
        }
        .rotation3DEffect(
            .degrees(-angle),
            axis: (x: 0, y: 1, z: 0),
            anchor: .leading,
            perspective: 0.3
        )
    }

    // MARK: - Animation

    private func animate() {
        // Title
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            titleOpacity = 1
            titleOffset = 0
        }

        // Cover opens fully
        withAnimation(.spring(response: 0.9, dampingFraction: 0.78).delay(0.5)) {
            coverAngle = 180
        }

        // Swap front/back face at ~90 degrees
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.88) {
            showCoverFront = false
        }

        // Pages fan out from spine
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.7)) {
            page1Angle = 60
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.85)) {
            page2Angle = 42
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(1.0)) {
            page3Angle = 24
        }

        // Fade out
        withAnimation(.easeIn(duration: 0.5).delay(1.7)) {
            bookScale = 1.3
            contentOpacity = 0
            titleOpacity = 0
            backgroundOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            onFinished()
        }
    }
}
