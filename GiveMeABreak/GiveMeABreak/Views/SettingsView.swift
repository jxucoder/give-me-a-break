import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            LLMSettingsView()
                .tabItem {
                    Label("AI Messages", systemImage: "brain")
                }
        }
        .frame(width: 450, height: 300)
    }
}
