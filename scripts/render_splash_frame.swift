#!/usr/bin/env swift
// Renders the first visible frame of GradientShimmerSplashView to PNG.
// Usage: swift render_splash_frame.swift [output_path]

import SwiftUI
import AppKit

// Recreate the gradient shimmer's settled first frame
struct SplashFirstFrame: View {
    private let gradientColors: [Color] = [
        Color(red: 0.75, green: 0.85, blue: 0.0),
        Color(red: 0.2, green: 0.8, blue: 0.4),
        Color(red: 0.0, green: 0.75, blue: 0.85)
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors + gradientColors,
                startPoint: UnitPoint(x: -1.0, y: -1.0),
                endPoint: UnitPoint(x: 0, y: 0)
            )

            VStack(spacing: 20) {
                bibleIcon
                Text("SwiftBible")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 393, height: 852)
    }

    private var bibleIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.15))
                .frame(width: 120, height: 155)

            Rectangle()
                .fill(.white)
                .frame(width: 5, height: 45)
                .offset(y: -10)

            Rectangle()
                .fill(.white)
                .frame(width: 30, height: 5)
                .offset(y: -17)

            Rectangle()
                .fill(.white)
                .frame(width: 5, height: 28)
                .offset(y: 12)

            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(white: 0.3), lineWidth: 1.5)
                .frame(width: 120, height: 155)

            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 16))
                path.addLine(to: CGPoint(x: 8, y: 10))
                path.addLine(to: CGPoint(x: 16, y: 16))
                path.addLine(to: CGPoint(x: 16, y: 0))
            }
            .fill(Color(white: 0.15))
            .frame(width: 16, height: 16)
            .offset(x: -20, y: 82)
        }
    }
}

@MainActor func savePNG(view: some View, scale: CGFloat, path: String) {
    let renderer = ImageRenderer(content: view)
    renderer.scale = scale

    guard let cgImage = renderer.cgImage else {
        print("Failed to render at scale \(scale)")
        return
    }

    let rep = NSBitmapImageRep(cgImage: cgImage)
    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG at scale \(scale)")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Saved: \(path) (\(cgImage.width)x\(cgImage.height))")
    } catch {
        print("Write failed: \(error)")
    }
}

let app = NSApplication.shared
let outputDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "."

DispatchQueue.main.async {
    let view = SplashFirstFrame()
    savePNG(view: view, scale: 2.0, path: "\(outputDir)/LaunchScreen@2x.png")
    savePNG(view: view, scale: 3.0, path: "\(outputDir)/LaunchScreen@3x.png")
    app.terminate(nil)
}

app.run()
