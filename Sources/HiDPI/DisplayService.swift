import AppKit
import Combine
import CoreGraphics
import Foundation
import VirtualDisplayBridge

@MainActor
final class DisplayService: ObservableObject {
    @Published private(set) var displays: [DisplayDevice] = []
    @Published private(set) var activeConfiguration: ActiveConfiguration?
    @Published private(set) var isApplyingDisplayID: CGDirectDisplayID?
    @Published private(set) var selections: [CGDirectDisplayID: DisplayOutputConfiguration] = [:]
    @Published var errorMessage: String?

    struct ActiveConfiguration: Equatable {
        let displayID: CGDirectDisplayID
        let displayName: String
        let output: DisplayOutputConfiguration
    }

    private final class Session {
        let displayID: CGDirectDisplayID
        let originalModeNumber: Int32
        private var restored = false

        init(displayID: CGDirectDisplayID, originalModeNumber: Int32) {
            self.displayID = displayID
            self.originalModeNumber = originalModeNumber
        }

        func restore() {
            guard !restored, CGDisplayIsOnline(displayID) != 0 else { return }
            restored = true
            _ = Self.apply(modeNumber: originalModeNumber, to: displayID)
        }

        static func apply(modeNumber: Int32, to displayID: CGDirectDisplayID) -> CGError {
            var configuration: CGDisplayConfigRef?
            let begin = CGBeginDisplayConfiguration(&configuration)
            guard begin == .success, let configuration else { return begin }
            let configure = HDConfigureDisplayWithModeNumber(
                configuration,
                displayID,
                modeNumber
            )
            guard configure == .success else {
                CGCancelDisplayConfiguration(configuration)
                return configure
            }
            return CGCompleteDisplayConfiguration(configuration, .forSession)
        }
    }

    private enum SetupError: LocalizedError {
        case currentModeUnavailable
        case modeUnavailable(DisplayOutputConfiguration)
        case coreGraphics(CGError)
        case verification(String)

        var errorDescription: String? {
            switch self {
            case .currentModeUnavailable:
                return L10n.tr("error.currentModeUnavailable", fallback: "Could not read the current display mode.")
            case let .modeUnavailable(output):
                return L10n.format(
                    "error.nativeModeUnavailable",
                    fallback: "%@ %@ is no longer available from macOS.",
                    output.resolution.label,
                    L10n.modeName(isHiDPI: output.isHiDPI)
                )
            case let .coreGraphics(error):
                return L10n.format(
                    "error.coreGraphics",
                    fallback: "Display mode switch failed (CoreGraphics %ld).",
                    error.rawValue
                )
            case let .verification(detail):
                return L10n.format(
                    "error.verification",
                    fallback: "The mode switch was not verified and the previous mode was restored: %@",
                    detail
                )
            }
        }
    }

    private var session: Session?
    private var refreshTask: Task<Void, Never>?
    private var terminationObserver: NSObjectProtocol?

    init() {
        CGDisplayRegisterReconfigurationCallback(
            Self.displayChanged,
            Unmanaged.passUnretained(self).toOpaque()
        )
        terminationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.session?.restore() }
        }
        refresh()
    }

    deinit {
        refreshTask?.cancel()
        MainActor.assumeIsolated { session?.restore() }
        if let terminationObserver {
            NotificationCenter.default.removeObserver(terminationObserver)
        }
        CGDisplayRemoveReconfigurationCallback(
            Self.displayChanged,
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    func refresh() {
        let ids = onlineDisplayIDs()
        displays = ids
            .filter { CGDisplayIsBuiltin($0) == 0 && CGDisplayIsOnline($0) != 0 }
            .compactMap(makeDisplay)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        for display in displays {
            if let selection = selections[display.id], isModeAvailable(selection, for: display) {
                continue
            }
            selections[display.id] = storedConfiguration(for: display)
        }

        if let activeConfiguration,
           !ids.contains(activeConfiguration.displayID),
           isApplyingDisplayID == nil {
            session = nil
            self.activeConfiguration = nil
        }
    }

    func enable(on display: DisplayDevice) {
        guard isApplyingDisplayID == nil else { return }
        if let active = activeConfiguration, active.displayID != display.id { return }
        apply(
            display: display,
            output: configuration(for: display),
            beginsSession: session == nil
        )
    }

    func disable() {
        session?.restore()
        session = nil
        activeConfiguration = nil
        isApplyingDisplayID = nil
        scheduleRefresh()
    }

    func configuration(for display: DisplayDevice) -> DisplayOutputConfiguration {
        selections[display.id] ?? defaultConfiguration(for: display)
    }

    func availableResolutions(for display: DisplayDevice, isHiDPI: Bool) -> [DisplayResolution] {
        display.resolutions(isHiDPI: isHiDPI)
    }

    func hasModes(for display: DisplayDevice, isHiDPI: Bool) -> Bool {
        !availableResolutions(for: display, isHiDPI: isHiDPI).isEmpty
    }

    func setResolution(_ resolution: DisplayResolution, for display: DisplayDevice) {
        let current = configuration(for: display)
        guard availableResolutions(for: display, isHiDPI: current.isHiDPI).contains(resolution) else {
            return
        }
        setConfiguration(
            DisplayOutputConfiguration(resolution: resolution, isHiDPI: current.isHiDPI),
            for: display
        )
    }

    func setHiDPI(_ enabled: Bool, for display: DisplayDevice) {
        let current = configuration(for: display)
        let resolutions = availableResolutions(for: display, isHiDPI: enabled)
        guard let resolution = resolutions.min(by: {
            resolutionDistance($0, from: current.resolution) <
                resolutionDistance($1, from: current.resolution)
        }) else { return }
        setConfiguration(
            DisplayOutputConfiguration(resolution: resolution, isHiDPI: enabled),
            for: display
        )
    }

    func isModeAvailable(
        _ output: DisplayOutputConfiguration,
        for display: DisplayDevice
    ) -> Bool {
        display.availableModes.contains { $0.matches(output) }
    }

    private func setConfiguration(
        _ output: DisplayOutputConfiguration,
        for display: DisplayDevice
    ) {
        guard isModeAvailable(output, for: display) else { return }
        selections[display.id] = output
        store(output, for: display)
    }

    private func apply(
        display: DisplayDevice,
        output: DisplayOutputConfiguration,
        beginsSession: Bool
    ) {
        isApplyingDisplayID = display.id
        errorMessage = nil

        Task { @MainActor [weak self] in
            guard let self else { return }
            let previousModeNumber = HDCurrentCGSDisplayModeNumber(display.id)?.int32Value
            do {
                guard let previousModeNumber else { throw SetupError.currentModeUnavailable }
                guard let targetMode = self.bestMode(for: output, display: display) else {
                    throw SetupError.modeUnavailable(output)
                }

                let originalOrigin = CGDisplayBounds(display.id).origin
                let originalOnlineIDs = Set(self.onlineDisplayIDs())
                if beginsSession {
                    self.session = Session(
                        displayID: display.id,
                        originalModeNumber: previousModeNumber
                    )
                }
                let result = Session.apply(modeNumber: targetMode.id, to: display.id)
                guard result == .success else { throw SetupError.coreGraphics(result) }
                try await self.wait(milliseconds: 300)

                if let failure = self.verificationFailure(
                    displayID: display.id,
                    expected: output,
                    originalOrigin: originalOrigin,
                    originalOnlineIDs: originalOnlineIDs
                ) {
                    _ = Session.apply(modeNumber: previousModeNumber, to: display.id)
                    throw SetupError.verification(failure)
                }
                self.activeConfiguration = ActiveConfiguration(
                    displayID: display.id,
                    displayName: display.name,
                    output: output
                )
            } catch {
                if beginsSession {
                    self.session?.restore()
                    self.session = nil
                    self.activeConfiguration = nil
                } else if let activeConfiguration = self.activeConfiguration {
                    self.selections[display.id] = activeConfiguration.output
                    self.store(activeConfiguration.output, for: display)
                }
                self.errorMessage = error.localizedDescription
            }
            self.isApplyingDisplayID = nil
            self.refresh()
        }
    }

    private func bestMode(
        for output: DisplayOutputConfiguration,
        display: DisplayDevice
    ) -> DisplayModeInfo? {
        return display.availableModes
            .filter { $0.matches(output) }
            .min {
                modeScore($0, refreshRate: display.connectionRefreshRate) <
                    modeScore($1, refreshRate: display.connectionRefreshRate)
            }
    }

    private func modeScore(
        _ mode: DisplayModeInfo,
        refreshRate: Double
    ) -> Double {
        let candidateRate = mode.refreshRate > 1 ? mode.refreshRate : refreshRate
        return abs(candidateRate - refreshRate)
    }

    private func verificationFailure(
        displayID: CGDirectDisplayID,
        expected: DisplayOutputConfiguration,
        originalOrigin: CGPoint,
        originalOnlineIDs: Set<CGDirectDisplayID>
    ) -> String? {
        guard CGDisplayIsOnline(displayID) != 0,
              let current = CGDisplayCopyDisplayMode(displayID) else {
            return L10n.tr("verification.displayUnavailable", fallback: "The physical display disappeared")
        }
        guard DisplayModeInfo(current).matches(expected) else {
            return L10n.format(
                "verification.nativeMode",
                fallback: "macOS selected %ldx%ld / %ldx%ld instead",
                current.width,
                current.height,
                current.pixelWidth,
                current.pixelHeight
            )
        }
        guard CGDisplayBounds(displayID).origin == originalOrigin else {
            return L10n.tr("verification.layoutChanged", fallback: "The display arrangement changed")
        }
        guard Set(onlineDisplayIDs()) == originalOnlineIDs else {
            return L10n.tr("verification.displaySetChanged", fallback: "The connected display set changed")
        }
        return nil
    }

    private func makeDisplay(id: CGDirectDisplayID) -> DisplayDevice? {
        guard let controller = HDConnectionModeController(displayID: id),
              let currentSnapshot = controller.capturedModeSnapshot,
              let preferredSnapshot = controller.preferredModeSnapshot,
              let nativeWidth = (preferredSnapshot["width"] as? NSNumber)?.intValue,
              let nativeHeight = (preferredSnapshot["height"] as? NSNumber)?.intValue,
              let refreshRate = (currentSnapshot["refreshRate"] as? NSNumber)?.doubleValue,
              nativeWidth > 0,
              nativeHeight > 0 else {
            return nil
        }

        let modes = cgsDisplayModes(for: id)
        let resolutions = DisplayResolution.options(
            nativeWidth: nativeWidth,
            nativeHeight: nativeHeight,
            modes: modes
        )
        guard !resolutions.isEmpty else { return nil }
        return DisplayDevice(
            id: id,
            name: activeConfiguration?.displayID == id
                ? activeConfiguration?.displayName ?? displayName(for: id)
                : displayName(for: id),
            vendorID: CGDisplayVendorNumber(id),
            productID: CGDisplayModelNumber(id),
            nativeWidth: nativeWidth,
            nativeHeight: nativeHeight,
            connectionRefreshRate: refreshRate,
            currentMode: CGDisplayCopyDisplayMode(id).map(DisplayModeInfo.init),
            availableModes: modes,
            resolutions: resolutions
        )
    }

    private func defaultConfiguration(for display: DisplayDevice) -> DisplayOutputConfiguration {
        if let current = display.currentMode {
            let output = DisplayOutputConfiguration(
                resolution: DisplayResolution(width: current.width, height: current.height),
                isHiDPI: current.isHiDPI
            )
            if isModeAvailable(output, for: display) { return output }
        }
        let isHiDPI = hasModes(for: display, isHiDPI: true)
        let resolutions = availableResolutions(for: display, isHiDPI: isHiDPI)
        let target = DisplayResolution(width: 1920, height: 1080)
        let resolution = resolutions.min {
            resolutionDistance($0, from: target) < resolutionDistance($1, from: target)
        } ?? display.resolutions[0]
        return DisplayOutputConfiguration(resolution: resolution, isHiDPI: isHiDPI)
    }

    private func storedConfiguration(for display: DisplayDevice) -> DisplayOutputConfiguration {
        guard let data = UserDefaults.standard.data(forKey: selectionKey(for: display)),
              let output = try? JSONDecoder().decode(DisplayOutputConfiguration.self, from: data),
              isModeAvailable(output, for: display) else {
            return defaultConfiguration(for: display)
        }
        return output
    }

    private func store(_ output: DisplayOutputConfiguration, for display: DisplayDevice) {
        guard let data = try? JSONEncoder().encode(output) else { return }
        UserDefaults.standard.set(data, forKey: selectionKey(for: display))
    }

    private func selectionKey(for display: DisplayDevice) -> String {
        "output.\(display.vendorID).\(display.productID)"
    }

    private func resolutionDistance(
        _ resolution: DisplayResolution,
        from target: DisplayResolution
    ) -> Int {
        abs(resolution.width - target.width) + abs(resolution.height - target.height)
    }

    private func cgsDisplayModes(for id: CGDirectDisplayID) -> [DisplayModeInfo] {
        HDCopyCGSDisplayModeSnapshots(id).compactMap { snapshot in
            guard let modeNumber = snapshot["modeNumber"]?.int32Value,
                  let width = snapshot["width"]?.intValue,
                  let height = snapshot["height"]?.intValue,
                  let pixelWidth = snapshot["pixelWidth"]?.intValue,
                  let pixelHeight = snapshot["pixelHeight"]?.intValue,
                  let refreshRate = snapshot["refreshRate"]?.doubleValue,
                  let flags = snapshot["flags"]?.uint32Value,
                  flags & 0x2 != 0,
                  width > 0,
                  height > 0,
                  pixelWidth > 0,
                  pixelHeight > 0 else {
                return nil
            }
            return DisplayModeInfo(
                id: modeNumber,
                width: width,
                height: height,
                pixelWidth: pixelWidth,
                pixelHeight: pixelHeight,
                refreshRate: refreshRate
            )
        }
    }

    private func onlineDisplayIDs() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &count) == .success else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetOnlineDisplayList(count, &ids, &count) == .success else { return [] }
        return ids
    }

    private func displayName(for id: CGDirectDisplayID) -> String {
        let screen = NSScreen.screens.first {
            ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?
                .uint32Value == id
        }
        return screen?.localizedName ?? L10n.format(
            "display.fallbackName",
            fallback: "External display %u",
            id
        )
    }

    private func scheduleRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            self?.refresh()
        }
    }

    private func wait(milliseconds: UInt64) async throws {
        try await Task.sleep(nanoseconds: milliseconds * 1_000_000)
    }

    private nonisolated static let displayChanged: CGDisplayReconfigurationCallBack = {
        _, _, context in
        guard let context else { return }
        let service = Unmanaged<DisplayService>.fromOpaque(context).takeUnretainedValue()
        Task { @MainActor in service.scheduleRefresh() }
    }
}
