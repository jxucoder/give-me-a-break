import SwiftUI
import Sparkle

@main
struct GiveMeABreakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    var body: some Scene {
        MenuBarExtra("Give Me A Break", systemImage: "cup.and.saucer.fill") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(updater: updaterController.updater)
        }
    }
}
