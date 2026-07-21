import AppKit
import Combine
import Foundation
import ServiceManagement

@MainActor
final class SystemSettings: ObservableObject {
    @Published var errorMessage: String?

    var launchAtLogin: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            objectWillChange.send()
        } catch {
            errorMessage = L10n.format(
                "error.launchAtLogin",
                fallback: "Could not update Launch at Login: %@",
                error.localizedDescription
            )
        }
    }

    func openDisplaySettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.Displays-Settings.extension"
        ) else { return }
        NSWorkspace.shared.open(url)
    }

}
