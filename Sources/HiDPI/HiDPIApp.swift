import SwiftUI

@main
struct BirdHiDPIApp: App {
    @StateObject private var displayService = DisplayService()
    @StateObject private var systemSettings = SystemSettings()
    @StateObject private var localizationSettings = LocalizationSettings()

    var body: some Scene {
        MenuBarExtra("Bird HiDPI", systemImage: "display") {
            ContentView(
                displayService: displayService,
                systemSettings: systemSettings,
                localizationSettings: localizationSettings
            )
        }
        .menuBarExtraStyle(.window)
    }
}
