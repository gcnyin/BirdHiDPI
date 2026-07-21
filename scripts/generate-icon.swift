#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

private let canvasSize = 1024

private func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(
        red: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: alpha
    )
}

private func roundedPath(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(
        roundedRect: rect,
        cornerWidth: radius,
        cornerHeight: radius,
        transform: nil
    )
}

private func fillRounded(
    _ context: CGContext,
    rect: CGRect,
    radius: CGFloat,
    fill: CGColor
) {
    context.addPath(roundedPath(rect, radius: radius))
    context.setFillColor(fill)
    context.fillPath()
}

private func drawGradient(
    _ context: CGContext,
    in path: CGPath,
    colors: [CGColor],
    locations: [CGFloat],
    start: CGPoint,
    end: CGPoint
) {
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors as CFArray,
        locations: locations
    )!
    context.saveGState()
    context.addPath(path)
    context.clip()
    context.drawLinearGradient(gradient, start: start, end: end, options: [])
    context.restoreGState()
}

private func renderIcon() throws -> Data {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: canvasSize,
        height: canvasSize,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw CocoaError(.fileWriteUnknown)
    }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let tileRect = CGRect(x: 64, y: 64, width: 896, height: 896)
    let tilePath = roundedPath(tileRect, radius: 216)

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -20),
        blur: 34,
        color: color(0x000000, alpha: 0.34)
    )
    context.addPath(tilePath)
    context.setFillColor(color(0x172126))
    context.fillPath()
    context.restoreGState()

    drawGradient(
        context,
        in: tilePath,
        colors: [color(0x146C70), color(0x173B3D), color(0x182126)],
        locations: [0, 0.48, 1],
        start: CGPoint(x: 120, y: 920),
        end: CGPoint(x: 900, y: 100)
    )

    context.addPath(roundedPath(tileRect.insetBy(dx: 2, dy: 2), radius: 214))
    context.setStrokeColor(color(0xFFFFFF, alpha: 0.16))
    context.setLineWidth(4)
    context.strokePath()

    let standPath = CGMutablePath()
    standPath.move(to: CGPoint(x: 430, y: 300))
    standPath.addLine(to: CGPoint(x: 594, y: 300))
    standPath.addLine(to: CGPoint(x: 616, y: 190))
    standPath.addLine(to: CGPoint(x: 664, y: 166))
    standPath.addLine(to: CGPoint(x: 360, y: 166))
    standPath.addLine(to: CGPoint(x: 408, y: 190))
    standPath.closeSubpath()
    context.addPath(standPath)
    context.setFillColor(color(0xD7DDD9))
    context.fillPath()
    fillRounded(
        context,
        rect: CGRect(x: 338, y: 142, width: 348, height: 54),
        radius: 27,
        fill: color(0xF4F7F3)
    )

    let displayRect = CGRect(x: 154, y: 274, width: 716, height: 480)
    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -15),
        blur: 24,
        color: color(0x071012, alpha: 0.38)
    )
    fillRounded(
        context,
        rect: displayRect,
        radius: 88,
        fill: color(0xF4F7F3)
    )
    context.restoreGState()

    let screenRect = CGRect(x: 202, y: 330, width: 620, height: 358)
    let screenPath = roundedPath(screenRect, radius: 50)
    drawGradient(
        context,
        in: screenPath,
        colors: [color(0x25343A), color(0x172126)],
        locations: [0, 1],
        start: CGPoint(x: 220, y: 670),
        end: CGPoint(x: 800, y: 340)
    )

    context.saveGState()
    context.addPath(screenPath)
    context.clip()
    context.setStrokeColor(color(0xFFFFFF, alpha: 0.055))
    context.setLineWidth(2)
    for column in 1..<8 {
        let x = screenRect.minX + CGFloat(column) * screenRect.width / 8
        context.move(to: CGPoint(x: x, y: screenRect.minY))
        context.addLine(to: CGPoint(x: x, y: screenRect.maxY))
    }
    for row in 1..<5 {
        let y = screenRect.minY + CGFloat(row) * screenRect.height / 5
        context.move(to: CGPoint(x: screenRect.minX, y: y))
        context.addLine(to: CGPoint(x: screenRect.maxX, y: y))
    }
    context.strokePath()
    context.restoreGState()

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -8),
        blur: 16,
        color: color(0x000000, alpha: 0.28)
    )
    fillRounded(
        context,
        rect: CGRect(x: 290, y: 446, width: 126, height: 126),
        radius: 29,
        fill: color(0xFF795B)
    )
    context.restoreGState()

    let smallPixels: [(CGRect, UInt32)] = [
        (CGRect(x: 478, y: 516, width: 56, height: 56), 0x5DDBB5),
        (CGRect(x: 548, y: 516, width: 56, height: 56), 0x62B9FF),
        (CGRect(x: 478, y: 446, width: 56, height: 56), 0xFFD166),
        (CGRect(x: 548, y: 446, width: 56, height: 56), 0xF3F7F4)
    ]
    for (rect, hex) in smallPixels {
        fillRounded(context, rect: rect, radius: 15, fill: color(hex))
    }

    context.addPath(screenPath)
    context.setStrokeColor(color(0xFFFFFF, alpha: 0.12))
    context.setLineWidth(3)
    context.strokePath()

    guard let image = context.makeImage() else {
        throw CocoaError(.fileWriteUnknown)
    }
    let bitmap = NSBitmapImageRep(cgImage: image)
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return data
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: generate-icon.swift <output.png>\n".utf8))
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
try renderIcon().write(to: outputURL, options: .atomic)
print(outputURL.path)
