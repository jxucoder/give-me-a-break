import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self

        Task { @MainActor in
            SettingsViewModel.shared.applyActivationPolicy()
            _ = await NotificationService.shared.requestAuthorization()
            MenuBarViewModel.shared.start()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
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

        Task { @MainActor in
            switch response.actionIdentifier {
            case "SNOOZE_5":
                ReminderScheduler.shared.snooze(type: type, minutes: 5)
            case "SNOOZE_10":
                ReminderScheduler.shared.snooze(type: type, minutes: 10)
            case "SNOOZE_15":
                ReminderScheduler.shared.snooze(type: type, minutes: 15)
            case "DONE":
                ReminderScheduler.shared.markDone(type: type)
            default:
                break
            }
        }

        completionHandler()
    }
}
