import Foundation
import AppKit
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private var center: UNUserNotificationCenter { UNUserNotificationCenter.current() }

    /// Cached master file URLs per reminder type for notification art.
    private var cachedArtURLs: [ReminderType: URL] = [:]

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                registerCategories()
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Categories & Actions

    private func registerCategories() {
        let snooze5 = UNNotificationAction(
            identifier: "SNOOZE_5",
            title: "Snooze 5 min",
            options: []
        )
        let snooze10 = UNNotificationAction(
            identifier: "SNOOZE_10",
            title: "Snooze 10 min",
            options: []
        )
        let snooze15 = UNNotificationAction(
            identifier: "SNOOZE_15",
            title: "Snooze 15 min",
            options: []
        )
        let doneAction = UNNotificationAction(
            identifier: "DONE",
            title: "Done",
            options: .destructive
        )

        let category = UNNotificationCategory(
            identifier: "REMINDER",
            actions: [snooze5, snooze10, snooze15, doneAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category])
    }

    // MARK: - Send Notification

    func sendReminder(type: ReminderType, message: String, playSound: Bool) {
        let content = UNMutableNotificationContent()
        content.title = type.displayName
        content.body = message
        content.categoryIdentifier = "REMINDER"
        content.userInfo = ["reminderType": type.rawValue]

        if playSound {
            content.sound = .default
        }

        if let attachment = artAttachment(for: type) {
            content.attachments = [attachment]
        }

        let request = UNNotificationRequest(
            identifier: "\(type.rawValue)-\(UUID().uuidString)",
            content: content,
            trigger: nil // deliver immediately
        )

        center.add(request) { error in
            if let error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    // MARK: - Snooze

    func scheduleSnooze(type: ReminderType, message: String, playSound: Bool, delayMinutes: Int = 5) {
        let content = UNMutableNotificationContent()
        content.title = type.displayName
        content.body = message
        content.categoryIdentifier = "REMINDER"
        content.userInfo = ["reminderType": type.rawValue]

        if playSound {
            content.sound = .default
        }

        if let attachment = artAttachment(for: type) {
            content.attachments = [attachment]
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(delayMinutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "snooze-\(type.rawValue)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("Failed to schedule snooze: \(error)")
            }
        }
    }

    // MARK: - Notification Attachment

    private func artAssetName(for type: ReminderType) -> String {
        switch type {
        case .breakReminder: return "BreakArt"
        case .posture:       return "PostureArt"
        case .standSit:      return "StandSitArt"
        }
    }

    private func artAttachment(for type: ReminderType) -> UNNotificationAttachment? {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory
            .appendingPathComponent("GiveMeABreakNotifications", isDirectory: true)
        try? fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let sourceURL: URL
        if let cached = cachedArtURLs[type], fm.fileExists(atPath: cached.path) {
            sourceURL = cached
        } else {
            guard let image = NSImage(named: artAssetName(for: type)) else { return nil }

            let size = NSSize(width: 256, height: 256)
            let resized = NSImage(size: size)
            resized.lockFocus()
            image.draw(in: NSRect(origin: .zero, size: size),
                       from: NSRect(origin: .zero, size: image.size),
                       operation: .copy,
                       fraction: 1.0)
            resized.unlockFocus()

            guard let tiff = resized.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else { return nil }

            let masterURL = tempDir.appendingPathComponent("\(type.rawValue)_art_master.png")
            do {
                try pngData.write(to: masterURL)
                cachedArtURLs[type] = masterURL
                sourceURL = masterURL
            } catch {
                print("Failed to write notification art: \(error)")
                return nil
            }
        }

        let copyURL = tempDir.appendingPathComponent("\(type.rawValue)_art_\(UUID().uuidString).png")
        do {
            try fm.copyItem(at: sourceURL, to: copyURL)
            return try UNNotificationAttachment(
                identifier: "reminderArt",
                url: copyURL,
                options: [UNNotificationAttachmentOptionsTypeHintKey: "public.png"]
            )
        } catch {
            print("Failed to create notification art attachment: \(error)")
            return nil
        }
    }

    // MARK: - Cleanup

    func removeAllPending() {
        center.removeAllPendingNotificationRequests()
    }
}
