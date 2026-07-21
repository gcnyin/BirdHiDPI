import XCTest
@testable import HiDPI

final class DisplayModeInfoTests: XCTestCase {
    func testDisplayDeviceFormatsNativeConnection() {
        let display = DisplayDevice(
            id: 3,
            name: "AW2725DF",
            vendorID: 0x10ac,
            productID: 0xa256,
            nativeWidth: 2560,
            nativeHeight: 1440,
            connectionRefreshRate: 119.9999,
            currentMode: nil,
            availableModes: [],
            resolutions: DisplayResolution.options(
                nativeWidth: 2560,
                nativeHeight: 1440,
                modes: sampleModes
            )
        )

        XCTAssertEqual(display.nativeSizeLabel, "2560 x 1440")
        XCTAssertEqual(display.refreshRateLabel, "120 Hz")
    }

    func testResolutionOptionsFollowNativeAspectRatio() {
        let options = DisplayResolution.options(
            nativeWidth: 2560,
            nativeHeight: 1440,
            modes: sampleModes
        )

        XCTAssertTrue(options.contains(DisplayResolution(width: 1280, height: 720)))
        XCTAssertTrue(options.contains(DisplayResolution(width: 1920, height: 1080)))
        XCTAssertEqual(options.last, DisplayResolution(width: 2560, height: 1440))
        XCTAssertTrue(options.allSatisfy { $0.width * 9 == $0.height * 16 })
    }

    func testHiDPIConfigurationUsesDoubleSizeFramebuffer() {
        let resolution = DisplayResolution(width: 1920, height: 1080)
        let hiDPI = DisplayOutputConfiguration(resolution: resolution, isHiDPI: true)
        let loDPI = DisplayOutputConfiguration(resolution: resolution, isHiDPI: false)

        XCTAssertEqual(hiDPI.pixelWidth, 3840)
        XCTAssertEqual(hiDPI.pixelHeight, 2160)
        XCTAssertEqual(hiDPI.scale, 2)
        XCTAssertEqual(loDPI.pixelWidth, 1920)
        XCTAssertEqual(loDPI.pixelHeight, 1080)
        XCTAssertEqual(loDPI.scale, 1)
    }

    func testModeMatchingDistinguishesHiDPIFromLoDPI() {
        let resolution = DisplayResolution(width: 1920, height: 1080)
        let hiDPI = DisplayOutputConfiguration(resolution: resolution, isHiDPI: true)
        let loDPI = DisplayOutputConfiguration(resolution: resolution, isHiDPI: false)
        let mode = DisplayModeInfo(
            id: 42,
            width: 1920,
            height: 1080,
            pixelWidth: 3840,
            pixelHeight: 2160,
            refreshRate: 120
        )

        XCTAssertTrue(mode.isHiDPI)
        XCTAssertTrue(mode.matches(hiDPI))
        XCTAssertFalse(mode.matches(loDPI))
    }

    func testDisplayFiltersResolutionByRenderingMode() {
        let display = makeDisplay()

        XCTAssertEqual(
            display.resolutions(isHiDPI: true),
            [DisplayResolution(width: 1280, height: 720)]
        )
        XCTAssertTrue(
            display.resolutions(isHiDPI: false)
                .contains(DisplayResolution(width: 1920, height: 1080))
        )
    }

    private func makeDisplay() -> DisplayDevice {
        DisplayDevice(
            id: 3,
            name: "AW2725DF",
            vendorID: 0x10ac,
            productID: 0xa256,
            nativeWidth: 2560,
            nativeHeight: 1440,
            connectionRefreshRate: 120,
            currentMode: nil,
            availableModes: sampleModes,
            resolutions: DisplayResolution.options(
                nativeWidth: 2560,
                nativeHeight: 1440,
                modes: sampleModes
            )
        )
    }

    private var sampleModes: [DisplayModeInfo] {
        [
            DisplayModeInfo(
                id: 1,
                width: 1280,
                height: 720,
                pixelWidth: 2560,
                pixelHeight: 1440,
                refreshRate: 120
            ),
            DisplayModeInfo(
                id: 2,
                width: 1280,
                height: 720,
                pixelWidth: 1280,
                pixelHeight: 720,
                refreshRate: 120
            ),
            DisplayModeInfo(
                id: 3,
                width: 1920,
                height: 1080,
                pixelWidth: 1920,
                pixelHeight: 1080,
                refreshRate: 120
            ),
            DisplayModeInfo(
                id: 4,
                width: 2560,
                height: 1440,
                pixelWidth: 2560,
                pixelHeight: 1440,
                refreshRate: 120
            ),
        ]
    }
}
