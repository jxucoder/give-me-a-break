import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var settingsVM = SettingsViewModel.shared

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: Binding(
                    get: { settingsVM.settings.launchAtLogin },
                    set: { settingsVM.toggleLaunchAtLogin($0) }
                ))

                Toggle("Play Notification Sounds", isOn: $settingsVM.settings.playSounds)
            }

            Section("Notification Permission") {
                HStack {
                    Text("Status:")
                    Text(settingsVM.notificationStatus)
                        .foregroundStyle(.secondary)
                }

                if settingsVM.notificationStatus.contains("Denied") {
                    Button("Open System Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .task {
            await settingsVM.refreshNotificationStatus()
        }
    }
}
