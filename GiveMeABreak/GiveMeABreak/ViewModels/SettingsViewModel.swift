import Foundation
import AppKit
import ServiceManagement
import os.log

@MainActor
final class SettingsViewModel: ObservableObject {
    static let shared = SettingsViewModel()

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.givemeabreak.app", category: "SettingsViewModel")
    private static let settingsKey = "appSettings"

    @Published var settings: AppSettings {
        didSet {
            save()
            if oldValue.showInDock != settings.showInDock {
                applyActivationPolicy()
            }
        }
    }

    @Published var notificationStatus: String = "Unknown"

    private init() {
        self.settings = AppSettings.load(from: UserDefaults.standard.data(forKey: Self.settingsKey))
        syncLaunchAtLoginState()
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: Self.settingsKey)
        } catch {
            Self.logger.error("Failed to save settings: \(error.localizedDescription)")
        }
    }

    func applyActivationPolicy() {
        NSApp.setActivationPolicy(settings.showInDock ? .regular : .accessory)
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
            Self.logger.error("Failed to toggle launch at login: \(error.localizedDescription)")
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

    func displayMode(for type: ReminderType) -> ReminderDisplayMode {
        settings.reminderSettings(for: type).displayMode
    }

    func setDisplayMode(_ mode: ReminderDisplayMode, for type: ReminderType) {
        var reminder = settings.reminderSettings(for: type)
        reminder.displayMode = mode
        settings.reminders[type.rawValue] = reminder
    }

    // MARK: - Notification Status

    func refreshNotificationStatus() async {
        let status = await NotificationService.shared.authorizationStatus()
        switch status {
        case .authorized:
            notificationStatus = "Authorized"
        case .denied:
            notificationStatus = "Denied — banner overlay will be used instead"
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
