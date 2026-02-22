import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Keep the app as a regular app so macOS can always resolve the icon
        // for dock, notifications, and Spotlight. The menu bar icon is the primary
        // access point; the dock entry is a secondary convenience.
        NSApp.setActivationPolicy(.regular)

        UNUserNotificationCenter.current().delegate = self

        Task { @MainActor in
            _ = await NotificationService.shared.requestAuthorization()
            MenuBarViewModel.shared.start()
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Show notifications even when app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Handle notification actions (Snooze / Done)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let typeString = userInfo["reminderType"] as? String ?? ""
        let type = ReminderType(rawValue: typeString) ?? .breakReminder

        let snoozeMinutes: Int? = {
            switch response.actionIdentifier {
            case "SNOOZE_5": return 5
            case "SNOOZE_10": return 10
            case "SNOOZE_15": return 15
            default: return nil
            }
        }()

        if let minutes = snoozeMinutes {
            Task { @MainActor in
                let settings = SettingsViewModel.shared.settings
                NotificationService.shared.scheduleSnooze(
                    type: type,
                    message: response.notification.request.content.body,
                    playSound: settings.playSounds,
                    delayMinutes: minutes
                )
            }
        }

        completionHandler()
    }
}
