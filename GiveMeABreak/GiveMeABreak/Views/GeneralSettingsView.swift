import SwiftUI
import Sparkle

struct GeneralSettingsView: View {
    @ObservedObject var settingsVM = SettingsViewModel.shared
    let updater: SPUUpdater
    @State private var canCheckForUpdates = false

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: Binding(
                    get: { settingsVM.settings.launchAtLogin },
                    set: { settingsVM.toggleLaunchAtLogin($0) }
                ))

                Toggle("Play Notification Sounds", isOn: $settingsVM.settings.playSounds)

                Toggle("Show Health Facts (CDC)", isOn: $settingsVM.settings.showHealthFacts)

                if settingsVM.settings.showHealthFacts {
                    Text("Health facts are sourced from CDC publications and are for informational purposes only. This app does not provide medical advice, diagnosis, or treatment. Consult a healthcare professional for medical concerns.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Updates") {
                Toggle("Automatically check for updates", isOn: Binding(
                    get: { updater.automaticallyChecksForUpdates },
                    set: { updater.automaticallyChecksForUpdates = $0 }
                ))

                Button("Check for Updates...") {
                    updater.checkForUpdates()
                }
                .disabled(!canCheckForUpdates)
            }

            Section("Notification Permission") {
                HStack {
                    Text("Status:")
                    Text(settingsVM.notificationStatus)
                        .foregroundStyle(.secondary)
                }

                if settingsVM.notificationStatus.contains("Denied") {
                    Text("Enable notifications in System Settings > Notifications > Give Me A Break")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .task {
            await settingsVM.refreshNotificationStatus()
        }
        .onReceive(updater.publisher(for: \.canCheckForUpdates)) { value in
            canCheckForUpdates = value
        }
    }
}
