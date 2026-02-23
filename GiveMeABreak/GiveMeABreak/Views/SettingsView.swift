import SwiftUI
import Sparkle

struct SettingsView: View {
    let updater: SPUUpdater

    var body: some View {
        TabView {
            GeneralSettingsView(updater: updater)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            LLMSettingsView()
                .tabItem {
                    Label("AI Messages", systemImage: "brain")
                }
        }
        .frame(minWidth: 450, minHeight: 300)
    }
}
