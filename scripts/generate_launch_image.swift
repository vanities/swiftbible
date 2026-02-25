#!/usr/bin/env swift
// Generates a launch icon matching GradientShimmerSplashView's bibleIcon exactly.
// Book: 120x155pt, cornerRadius 10, Color(white: 0.15)
// Cross: white, 5pt wide bars
// Bookmark: 16x16, offset (x: -20, y: 82)
// Plus "SwiftBible" text below

import Foundation
#if canImport(AppKit)
import AppKit
import CoreText

func generateLaunchIcon(scale: Int) -> Data? {
    // Canvas sized to fit icon (120x155) + text below with spacing
    let canvasW: CGFloat = 200
    let canvasH: CGFloat = 240
    let pixelW = Int(canvasW) * scale
    let pixelH = Int(canvasH) * scale

    guard let context = CGContext(
        data: nil,
        width: pixelW,
        height: pixelH,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
    ) else { return nil }

    let s = CGFloat(scale)
    context.scaleBy(x: s, y: s)

    // Flip for top-left origin
    context.translateBy(x: 0, y: canvasH)
    context.scaleBy(x: 1, y: -1)

    // -- Bible icon centered at top --
    let bookW: CGFloat = 120
    let bookH: CGFloat = 155
    let bookX: CGFloat = (canvasW - bookW) / 2
    let bookY: CGFloat = 10

    // Book body
    let bookRect = CGRect(x: bookX, y: bookY, width: bookW, height: bookH)
    let bookPath = CGPath(roundedRect: bookRect, cornerWidth: 10, cornerHeight: 10, transform: nil)
    context.setFillColor(CGColor(gray: 0.15, alpha: 1.0))
    context.addPath(bookPath)
    context.fillPath()

    // Cross center
    let cx = canvasW / 2
    let cy = bookY + bookH / 2

    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))

    // Cross - vertical top (5x45, offset y: -10 from center)
    let vtopH: CGFloat = 45
    context.fill(CGRect(x: cx - 2.5, y: cy - 10 - vtopH / 2, width: 5, height: vtopH))

    // Cross - horizontal bar (30x5, offset y: -17 from center)
    context.fill(CGRect(x: cx - 15, y: cy - 17 - 2.5, width: 30, height: 5))

    // Cross - vertical bottom (5x28, offset y: 12 from center)
    let vbotH: CGFloat = 28
    context.fill(CGRect(x: cx - 2.5, y: cy + 12 - vbotH / 2, width: 5, height: vbotH))

    // Book outline stroke
    context.setStrokeColor(CGColor(gray: 0.3, alpha: 1.0))
    context.setLineWidth(1.5)
    context.addPath(bookPath)
    context.strokePath()

    // Bookmark (16x16, offset x: -20, y: 82 from icon center)
    // In SwiftUI the icon center is at (60, 77.5) within 120x155
    // offset(x: -20, y: 82) → bookmark at icon local (40, 159.5)
    // In canvas coords:
    let bmX = bookX + 60 - 20 - 8 // center of book + xOffset - half width
    let bmY = bookY + 77.5 + 82 - 8 // center of book + yOffset - half height
    let bmW: CGFloat = 16
    let bmH: CGFloat = 16

    context.setFillColor(CGColor(gray: 0.15, alpha: 1.0))
    context.move(to: CGPoint(x: bmX, y: bmY))
    context.addLine(to: CGPoint(x: bmX, y: bmY + bmH))
    context.addLine(to: CGPoint(x: bmX + bmW / 2, y: bmY + bmH * 0.625))
    context.addLine(to: CGPoint(x: bmX + bmW, y: bmY + bmH))
    context.addLine(to: CGPoint(x: bmX + bmW, y: bmY))
    context.closePath()
    context.fillPath()

    // -- "SwiftBible" text --
    let textY = bookY + bookH + 36 // 20pt spacing + some offset

    let font = CTFontCreateWithName("Georgia-Bold" as CFString, 32, nil)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: CGColor(red: 1, green: 1, blue: 1, alpha: 1)
    ]
    let attrStr = NSAttributedString(string: "SwiftBible", attributes: attrs)
    let line = CTLineCreateWithAttributedString(attrStr)
    let textBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    let textX = (canvasW - textBounds.width) / 2 - textBounds.origin.x

    // CTLine draws with baseline at y=0 going up, but we flipped coords
    // Need to flip back for text
    context.saveGState()
    context.translateBy(x: textX, y: textY + textBounds.height)
    context.scaleBy(x: 1, y: -1)
    CTLineDraw(line, context)
    context.restoreGState()

    guard let cgImage = context.makeImage() else { return nil }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    rep.size = NSSize(width: Int(canvasW), height: Int(canvasH))
    return rep.representation(using: .png, properties: [:])
}

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

if let data2x = generateLaunchIcon(scale: 2) {
    let url = URL(fileURLWithPath: "\(outputDir)/LaunchIcon@2x.png")
    try data2x.write(to: url)
    print("Generated \(url.path)")
}

if let data3x = generateLaunchIcon(scale: 3) {
    let url = URL(fileURLWithPath: "\(outputDir)/LaunchIcon@3x.png")
    try data3x.write(to: url)
    print("Generated \(url.path)")
}

print("Done!")
#else
print("This script requires macOS (AppKit)")
#endif
