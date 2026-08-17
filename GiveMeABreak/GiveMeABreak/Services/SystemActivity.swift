import AppKit
import CoreGraphics

/// Idle time, screen lock, and sleep/wake signals used to skip reminders while away.
enum SystemActivity {
    private static let lock = NSLock()
    private static var screenLocked = false

    static var isScreenLocked: Bool {
        lock.lock()
        defer { lock.unlock() }
        return screenLocked
    }

    static func idleSeconds() -> TimeInterval {
        CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: CGEventType(rawValue: UInt32.max)!
        )
    }

    static func isUserPresent(idleThreshold: TimeInterval) -> Bool {
        !isScreenLocked && idleSeconds() < idleThreshold
    }

    @discardableResult
    static func startObserving(onResume: @escaping @MainActor () -> Void) -> [NSObjectProtocol] {
        var tokens: [NSObjectProtocol] = []

        tokens.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    onResume()
                }
            }
        )

        let distributed = DistributedNotificationCenter.default()
        tokens.append(
            distributed.addObserver(
                forName: Notification.Name("com.apple.screenIsLocked"),
                object: nil,
                queue: .main
            ) { _ in
                lock.lock()
                screenLocked = true
                lock.unlock()
            }
        )
        tokens.append(
            distributed.addObserver(
                forName: Notification.Name("com.apple.screenIsUnlocked"),
                object: nil,
                queue: .main
            ) { _ in
                lock.lock()
                screenLocked = false
                lock.unlock()
                Task { @MainActor in
                    onResume()
                }
            }
        )

        return tokens
    }
}
