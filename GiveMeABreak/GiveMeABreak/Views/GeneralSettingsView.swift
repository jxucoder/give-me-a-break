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
                .tint(.blue)

                Toggle("Play Notification Sounds", isOn: $settingsVM.settings.playSounds)
                    .tint(.blue)
            }

            Section("Overlay Reminders") {
                HStack {
                    Text("Auto-dismiss after")
                    Spacer()
                    Text("\(settingsVM.settings.overlayDismissSeconds)s")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(
                    value: Binding(
                        get: { Double(settingsVM.settings.overlayDismissSeconds) },
                        set: { settingsVM.settings.overlayDismissSeconds = Int($0) }
                    ),
                    in: 10...60,
                    step: 5
                )

                Text("Applies to Banner and Fullscreen overlay modes. Set display mode per reminder from the menu bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Updates") {
                Toggle("Automatically check for updates", isOn: Binding(
                    get: { updater.automaticallyChecksForUpdates },
                    set: { updater.automaticallyChecksForUpdates = $0 }
                ))
                .tint(.blue)

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
