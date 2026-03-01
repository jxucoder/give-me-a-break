import SwiftUI
#if !APP_STORE
import Sparkle
#endif

struct SettingsView: View {
    #if !APP_STORE
    let updater: SPUUpdater
    #endif

    var body: some View {
        TabView {
            #if !APP_STORE
            GeneralSettingsView(updater: updater)
                .tabItem { Label("General", systemImage: "gear") }
            #else
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
            #endif

            LLMSettingsView()
                .tabItem {
                    Label("AI Messages", systemImage: "brain")
                }
        }
        .frame(width: 520, height: 520)
    }
}
