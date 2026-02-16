import Foundation
import Combine
import ServiceManagement

@MainActor
final class SettingsViewModel: ObservableObject {
    static let shared = SettingsViewModel()

    private static let settingsKey = "appSettings"

    @Published var settings: AppSettings {
        didSet {
            save()
        }
    }

    @Published var notificationStatus: String = "Unknown"

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
        syncLaunchAtLoginState()
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: Self.settingsKey)
        }
    }

    // MARK: - Launch at Login

    private func syncLaunchAtLoginState() {
        settings.launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func toggleLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            settings.launchAtLogin = enabled
        } catch {
            print("Failed to toggle launch at login: \(error)")
            settings.launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    // MARK: - Reminder Settings Helpers

    func isEnabled(for type: ReminderType) -> Bool {
        settings.reminderSettings(for: type).enabled
    }

    func interval(for type: ReminderType) -> Int {
        settings.reminderSettings(for: type).intervalMinutes
    }

    func setEnabled(_ enabled: Bool, for type: ReminderType) {
        var reminder = settings.reminderSettings(for: type)
        reminder.enabled = enabled
        settings.reminders[type.rawValue] = reminder
    }

    func setInterval(_ minutes: Int, for type: ReminderType) {
        var reminder = settings.reminderSettings(for: type)
        reminder.intervalMinutes = max(1, minutes)
        settings.reminders[type.rawValue] = reminder
    }

    // MARK: - Notification Status

    func refreshNotificationStatus() async {
        let status = await NotificationService.shared.authorizationStatus()
        switch status {
        case .authorized:
            notificationStatus = "Authorized"
        case .denied:
            notificationStatus = "Denied — enable in System Settings > Notifications"
        case .notDetermined:
            notificationStatus = "Not yet requested"
        case .provisional:
            notificationStatus = "Provisional"
        case .ephemeral:
            notificationStatus = "Ephemeral"
        @unknown default:
            notificationStatus = "Unknown"
        }
    }
}
