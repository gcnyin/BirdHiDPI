import AppKit
import XCTest
@testable import HiDPI

@MainActor
final class DisplayIntegrationTests: XCTestCase {
    func testResolutionAndHiDPIToggleEndToEnd() async throws {
        guard ProcessInfo.processInfo.environment["RUN_DISPLAY_INTEGRATION_TEST"] == "1" else {
            throw XCTSkip("Set RUN_DISPLAY_INTEGRATION_TEST=1 to change the live display configuration.")
        }
        _ = NSApplication.shared

        let service = DisplayService()
        guard let display = service.displays.first,
              let resolution = display.resolutions.first(where: {
                  $0 == DisplayResolution(width: 1280, height: 720)
              }) else {
            XCTFail("No compatible external display or 1280 x 720 mode")
            return
        }
        let originalMode = try XCTUnwrap(CGDisplayCopyDisplayMode(display.id))
        let originalIDs = onlineDisplayIDs()
        let originalOrigin = CGDisplayBounds(display.id).origin
        defer { service.disable() }

        let hiDPI = DisplayOutputConfiguration(resolution: resolution, isHiDPI: true)
        service.setResolution(resolution, for: display)
        service.setHiDPI(true, for: display)
        service.enable(on: display)
        try await waitForConfiguration(hiDPI, service: service)

        let loDPI = DisplayOutputConfiguration(resolution: resolution, isHiDPI: false)
        service.setHiDPI(false, for: display)
        try await waitForConfiguration(loDPI, service: service)

        service.disable()
        try await Task.sleep(nanoseconds: 500_000_000)
        let restoredMode = try XCTUnwrap(CGDisplayCopyDisplayMode(display.id))
        XCTAssertEqual(restoredMode.ioDisplayModeID, originalMode.ioDisplayModeID)
        XCTAssertEqual(onlineDisplayIDs(), originalIDs)
        XCTAssertEqual(CGDisplayBounds(display.id).origin, originalOrigin)
    }

    private func waitForConfiguration(
        _ expected: DisplayOutputConfiguration,
        service: DisplayService,
        timeout: TimeInterval = 20
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let error = service.errorMessage {
                XCTFail(error)
                throw IntegrationFailure.configuration(error)
            }
            if service.isApplyingDisplayID == nil,
               service.activeConfiguration?.output == expected {
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTFail("Timed out waiting for \(expected.resolution.label) scale \(expected.scale)x")
        throw IntegrationFailure.timeout
    }

    private enum IntegrationFailure: Error {
        case configuration(String)
        case timeout
    }

    private func onlineDisplayIDs() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &count) == .success else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetOnlineDisplayList(count, &ids, &count) == .success else { return [] }
        return ids
    }
}
