import SwiftUI
#if !APP_STORE
import Sparkle
#endif

@main
struct GiveMeABreakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var menuBar = MenuBarViewModel.shared
    #if !APP_STORE
    private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    #endif

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
        } label: {
            Label("Give Me A Break", systemImage: menuBar.isPaused ? "cup.and.saucer" : "cup.and.saucer.fill")
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
