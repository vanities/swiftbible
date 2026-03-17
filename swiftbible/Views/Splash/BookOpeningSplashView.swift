//
//  BookOpeningSplashView.swift
//  swiftbible
//

import SwiftUI

struct BookOpeningSplashView: View {
    var onFinished: () -> Void

    // Book entrance
    @State private var bookOpacity: Double = 0
    @State private var bookScale: CGFloat = 0.88

    // Cover opening
    @State private var coverAngle: Double = 0
    @State private var showCoverInside = false

    // Pages fanning
    @State private var page1Angle: Double = 0
    @State private var page2Angle: Double = 0
    @State private var page3Angle: Double = 0

    // Golden glow from pages
    @State private var glowIntensity: Double = 0
    @State private var glowScale: CGFloat = 0.6

    // Text
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 14
    @State private var verseOpacity: Double = 0

    // Exit
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0
    @State private var bgOpacity: Double = 1.0

    // MARK: - Colors

    private let deepNavy = Color.brandDeepNavy
    private let warmGold = Color.brandGold
    private let lightGold = Color.brandLightGold
    private let coverDark = Color.brandCoverDark
    private let coverLight = Color.brandCoverLight
    private let ribbonRed = Color.brandRibbonRed

    private let bookW: CGFloat = 140
    private let bookH: CGFloat = 185

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background: matches launch screen
            deepNavy
                .ignoresSafeArea()
                .opacity(bgOpacity)

            // Ambient golden glow behind book
            RadialGradient(
                colors: [
                    warmGold.opacity(0.5),
                    warmGold.opacity(0.12),
                    .clear
                ],
                center: .center,
                startRadius: 30,
                endRadius: 220
            )
            .scaleEffect(glowScale)
            .opacity(glowIntensity * bgOpacity)

            // Main content
            VStack(spacing: 0) {
                bookAssembly
                    .padding(.bottom, 20)
                titleSection
                    .padding(.top, 30)
            }
            .scaleEffect(exitScale)
            .opacity(exitOpacity)
        }
        .ignoresSafeArea()
        .onAppear { animate() }
    }

    // MARK: - Book Assembly

    private var bookAssembly: some View {
        ZStack {
            backCover

            // Stacked pages that fan out from spine
            pageSheet(angle: page3Angle, brightness: 0.86,
                      lineWidths: [58, 42, 65, 38, 55, 48])
            pageSheet(angle: page2Angle, brightness: 0.92,
                      lineWidths: [45, 60, 35, 55, 48, 62])
            pageSheet(angle: page1Angle, brightness: 0.98,
                      lineWidths: [52, 40, 65, 45, 58, 50])

            // Golden light spilling from between pages
            pageGlow

            // Front cover with gold cross
            frontCover
                .rotation3DEffect(
                    .degrees(-coverAngle),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .leading,
                    perspective: 0.35
                )
        }
        .frame(width: bookW * 1.8, height: bookH + 40)
        .scaleEffect(bookScale)
        .opacity(bookOpacity)
    }

    // MARK: - Back Cover

    private var backCover: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(coverDark)
                .frame(width: bookW, height: bookH)
                .shadow(color: .black.opacity(0.6), radius: 10, x: 3, y: 5)

            // Spine line
            RoundedRectangle(cornerRadius: 1)
                .fill(coverLight.opacity(0.4))
                .frame(width: 2, height: bookH - 20)
                .offset(x: -bookW / 2 + 8)
        }
    }

    // MARK: - Front Cover

    private var frontCover: some View {
        ZStack {
            // Cover inside (visible after 90°)
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(red: 0.14, green: 0.09, blue: 0.06))
                .frame(width: bookW, height: bookH)
                .scaleEffect(x: -1)
                .opacity(showCoverInside ? 1 : 0)

            // Cover outside (visible before 90°)
            coverOutside
                .opacity(showCoverInside ? 0 : 1)
        }
        .shadow(color: .black.opacity(0.4), radius: 6, x: -3, y: 3)
    }

    private var coverOutside: some View {
        ZStack {
            // Main cover surface
            RoundedRectangle(cornerRadius: 7)
                .fill(
                    LinearGradient(
                        colors: [coverLight, coverDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: bookW, height: bookH)

            // Inner gold trim border
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(
                    LinearGradient(
                        colors: [warmGold.opacity(0.5), warmGold.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: bookW - 14, height: bookH - 14)

            // Gold embossed cross
            VStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [lightGold, warmGold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 6, height: 26)

                Rectangle()
                    .fill(warmGold)
                    .frame(width: 30, height: 6)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [warmGold, warmGold.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 6, height: 40)
            }
            .offset(y: -6)
            .shadow(color: warmGold.opacity(0.4), radius: 6)

            // Red bookmark ribbon
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 20))
                path.addLine(to: CGPoint(x: 8, y: 13))
                path.addLine(to: CGPoint(x: 16, y: 20))
                path.addLine(to: CGPoint(x: 16, y: 0))
            }
            .fill(
                LinearGradient(
                    colors: [ribbonRed, ribbonRed.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 16, height: 20)
            .offset(x: -24, y: bookH / 2 + 6)

            // Outer edge
            RoundedRectangle(cornerRadius: 7)
                .strokeBorder(Color.black.opacity(0.3), lineWidth: 0.5)
                .frame(width: bookW, height: bookH)
        }
    }

    // MARK: - Page Sheet

    private func pageSheet(
        angle: Double,
        brightness: CGFloat,
        lineWidths: [CGFloat]
    ) -> some View {
        let pageW = bookW - 18
        let pageH = bookH - 16
        let pageColor = Color(
            red: 0.97 * brightness,
            green: 0.94 * brightness,
            blue: 0.87 * brightness
        )
        let lineColor = Color(
            red: 0.72 * brightness,
            green: 0.68 * brightness,
            blue: 0.60 * brightness
        )

        return ZStack(alignment: .topLeading) {
            // Page surface
            RoundedRectangle(cornerRadius: 3)
                .fill(pageColor)
                .frame(width: pageW, height: pageH)

            // Gold leaf edge on right side
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [warmGold.opacity(0.35), warmGold.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 3, height: pageH - 10)
                .offset(x: pageW / 2 - 5, y: 5)
                .opacity(angle > 5 ? 1 : 0)

            // Text lines
            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array(lineWidths.enumerated()), id: \.offset) { _, w in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(lineColor)
                        .frame(width: w, height: 1.5)
                }
            }
            .padding(.top, 16)
            .padding(.leading, 14)
            .opacity(angle > 8 ? 1 : 0)

            // Page border
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(Color(white: brightness - 0.1).opacity(0.4), lineWidth: 0.5)
                .frame(width: pageW, height: pageH)
        }
        .rotation3DEffect(
            .degrees(-angle),
            axis: (x: 0, y: 1, z: 0),
            anchor: .leading,
            perspective: 0.35
        )
    }

    // MARK: - Page Glow

    private var pageGlow: some View {
        ZStack {
            // Warm light from the open pages
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            lightGold.opacity(0.6),
                            warmGold.opacity(0.2),
                            .clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 70
                    )
                )
                .frame(width: 120, height: 130)
                .offset(x: 20, y: -15)

            // Upward light spill
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            lightGold.opacity(0.3),
                            .clear
                        ],
                        center: .bottom,
                        startRadius: 10,
                        endRadius: 100
                    )
                )
                .frame(width: 100, height: 120)
                .offset(x: 10, y: -40)
        }
        .opacity(glowIntensity)
        .blur(radius: 12)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("SwiftBible")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)

            Text("In the beginning was the Word")
                .font(.system(size: 14, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(lightGold.opacity(0.6))
                .opacity(verseOpacity)
        }
        .opacity(titleOpacity)
        .offset(y: titleOffset)
    }

    // MARK: - Animation

    private func animate() {
        // Phase 1: Book enters
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            bookOpacity = 1.0
            bookScale = 1.0
        }

        // Phase 2: Cover opens to 120°
        withAnimation(.spring(response: 1.0, dampingFraction: 0.75).delay(0.5)) {
            coverAngle = 120
        }
        // Swap face at ~90° mark
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showCoverInside = true
        }

        // Phase 3: Pages fan out from spine (staggered)
        withAnimation(.spring(response: 0.8, dampingFraction: 0.72).delay(0.7)) {
            page1Angle = 50
        }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.72).delay(0.85)) {
            page2Angle = 35
        }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.72).delay(1.0)) {
            page3Angle = 20
        }

        // Phase 4: Golden glow intensifies — PEAK MOMENT
        withAnimation(.easeIn(duration: 0.6).delay(0.7)) {
            glowIntensity = 1.0
            glowScale = 1.2
        }

        // Phase 5: Title and verse appear
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            titleOpacity = 1.0
            titleOffset = 0
        }
        withAnimation(.easeOut(duration: 0.4).delay(1.3)) {
            verseOpacity = 1.0
        }

        // Phase 6: Exit — scale up and fade as if entering the book
        withAnimation(.easeIn(duration: 0.5).delay(2.0)) {
            exitScale = 1.12
            exitOpacity = 0
            bgOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onFinished()
        }
    }
}
