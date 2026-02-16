import SwiftUI

@main
struct GiveMeABreakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar dropdown
        MenuBarExtra("Give Me A Break", systemImage: "cup.and.saucer.fill") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Settings {
            SettingsView()
        }
    }
}
