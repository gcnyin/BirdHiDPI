import VirtualDisplayBridge
import XCTest

final class DisplayBridgeTests: XCTestCase {
    func testCGSDisplayModeSwitchSymbolIsAvailable() {
        XCTAssertTrue(HDCGSDisplayModeSwitchAvailable())
    }

    func testDumpCGSDisplayModeLayoutWhenRequested() throws {
        guard ProcessInfo.processInfo.environment["RUN_DISPLAY_MODE_DIAGNOSTIC"] == "1",
              let rawDisplayID = ProcessInfo.processInfo.environment["DISPLAY_ID"],
              let displayID = UInt32(rawDisplayID) else {
            throw XCTSkip("Set RUN_DISPLAY_MODE_DIAGNOSTIC=1 and DISPLAY_ID to inspect modes.")
        }

        print("Current CGS mode: \(HDCurrentCGSDisplayModeNumber(displayID)?.intValue ?? -1)")
        let snapshots = HDCopyCGSDisplayModeSnapshots(displayID)
        print("CGS mode count: \(snapshots.count)")
        for snapshot in snapshots {
            guard snapshot["width"]?.intValue == 1920,
                  snapshot["height"]?.intValue == 1080 else { continue }
            print(snapshot)
        }

        XCTAssertTrue(snapshots.contains { snapshot in
            snapshot["width"]?.intValue == 1920 &&
                snapshot["height"]?.intValue == 1080 &&
                snapshot["pixelWidth"]?.intValue == 3840 &&
                snapshot["pixelHeight"]?.intValue == 2160 &&
                snapshot["refreshRate"]?.intValue == 120
        })
    }
}
