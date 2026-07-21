import CoreGraphics
import Foundation

struct DisplayResolution: Identifiable, Equatable, Hashable, Codable {
    let width: Int
    let height: Int

    var id: String { "\(width)x\(height)" }
    var label: String { "\(width) x \(height)" }

    static func options(
        nativeWidth: Int,
        nativeHeight: Int,
        modes: [DisplayModeInfo]
    ) -> [DisplayResolution] {
        guard nativeWidth > 0, nativeHeight > 0 else { return [] }
        let nativeAspectRatio = Double(nativeWidth) / Double(nativeHeight)
        return Set(modes.compactMap { mode -> DisplayResolution? in
            guard mode.width <= nativeWidth,
                  mode.height >= 720,
                  abs(Double(mode.width) / Double(mode.height) - nativeAspectRatio) < 0.01 else {
                return nil
            }
            return DisplayResolution(width: mode.width, height: mode.height)
        })
        .sorted { lhs, rhs in
            lhs.width == rhs.width ? lhs.height < rhs.height : lhs.width < rhs.width
        }
    }
}

struct DisplayOutputConfiguration: Equatable, Hashable, Codable {
    let resolution: DisplayResolution
    let isHiDPI: Bool

    var pixelWidth: Int {
        resolution.width * (isHiDPI ? 2 : 1)
    }

    var pixelHeight: Int {
        resolution.height * (isHiDPI ? 2 : 1)
    }

    var scale: Int { isHiDPI ? 2 : 1 }
}

struct DisplayModeInfo: Equatable, Hashable {
    let id: Int32
    let width: Int
    let height: Int
    let pixelWidth: Int
    let pixelHeight: Int
    let refreshRate: Double

    init(
        id: Int32,
        width: Int,
        height: Int,
        pixelWidth: Int,
        pixelHeight: Int,
        refreshRate: Double
    ) {
        self.id = id
        self.width = width
        self.height = height
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.refreshRate = refreshRate
    }

    init(_ mode: CGDisplayMode) {
        self.init(
            id: mode.ioDisplayModeID,
            width: mode.width,
            height: mode.height,
            pixelWidth: mode.pixelWidth,
            pixelHeight: mode.pixelHeight,
            refreshRate: mode.refreshRate
        )
    }

    var isHiDPI: Bool {
        pixelWidth > width || pixelHeight > height
    }

    func matches(_ output: DisplayOutputConfiguration) -> Bool {
        width == output.resolution.width &&
            height == output.resolution.height &&
            pixelWidth == output.pixelWidth &&
            pixelHeight == output.pixelHeight
    }
}

struct DisplayDevice: Identifiable, Equatable {
    let id: CGDirectDisplayID
    let name: String
    let vendorID: UInt32
    let productID: UInt32
    let nativeWidth: Int
    let nativeHeight: Int
    let connectionRefreshRate: Double
    let currentMode: DisplayModeInfo?
    let availableModes: [DisplayModeInfo]
    let resolutions: [DisplayResolution]

    var nativeSizeLabel: String {
        "\(nativeWidth) x \(nativeHeight)"
    }

    var refreshRateLabel: String {
        String(format: "%.0f Hz", connectionRefreshRate)
    }

    func resolutions(isHiDPI: Bool) -> [DisplayResolution] {
        let available = Set(availableModes.compactMap { mode -> DisplayResolution? in
            guard mode.isHiDPI == isHiDPI else { return nil }
            let resolution = DisplayResolution(width: mode.width, height: mode.height)
            return resolutions.contains(resolution) ? resolution : nil
        })
        return available.sorted { lhs, rhs in
            lhs.width == rhs.width ? lhs.height < rhs.height : lhs.width < rhs.width
        }
    }
}
