import SwiftUI
#if !APP_STORE
import Sparkle
#endif

@main
struct GiveMeABreakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #if !APP_STORE
    private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    #endif

    var body: some Scene {
        MenuBarExtra("Give Me A Break", systemImage: "cup.and.saucer.fill") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)

        Settings {
            #if !APP_STORE
            SettingsView(updater: updaterController.updater)
            #else
            SettingsView()
            #endif
        }
    }
}
