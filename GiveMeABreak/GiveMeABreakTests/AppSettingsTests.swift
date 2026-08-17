import XCTest
@testable import Give_Me_A_Break

final class AppSettingsTests: XCTestCase {
    func testLoadNilReturnsDefaults() {
        let settings = AppSettings.load(from: nil)
        XCTAssertEqual(settings, .default)
        XCTAssertTrue(settings.skipWhenIdle)
        XCTAssertFalse(settings.showInDock)
    }

    func testLoadLegacyJSONFillsNewKeys() throws {
        let legacy = """
        {
          "launchAtLogin": true,
          "playSounds": false,
          "llmEnabled": false,
          "llmTone": "friendly",
          "customPrompt": "Be brief.",
          "overlayDismissSeconds": 20,
          "reminders": {
            "break": { "enabled": false, "intervalMinutes": 45 }
          }
        }
        """.data(using: .utf8)

        let settings = AppSettings.load(from: legacy)
        XCTAssertTrue(settings.launchAtLogin)
        XCTAssertFalse(settings.playSounds)
        XCTAssertEqual(settings.overlayDismissSeconds, 20)
        XCTAssertFalse(settings.reminderSettings(for: .breakReminder).enabled)
        XCTAssertEqual(settings.reminderSettings(for: .breakReminder).intervalMinutes, 45)
        XCTAssertEqual(settings.reminderSettings(for: .breakReminder).displayMode, .notification)
        XCTAssertTrue(settings.reminderSettings(for: .posture).enabled)
        XCTAssertTrue(settings.skipWhenIdle)
        XCTAssertEqual(settings.idleThresholdMinutes, 5)
        XCTAssertFalse(settings.showInDock)
    }

    func testLoadCorruptJSONReturnsDefaults() {
        let settings = AppSettings.load(from: Data("not-json".utf8))
        XCTAssertEqual(settings, .default)
    }

    func testRoundTripPreservesNewFields() throws {
        var settings = AppSettings.default
        settings.showInDock = true
        settings.skipWhenIdle = false
        settings.idleThresholdMinutes = 12
        settings.isStanding = true
        settings.setPreviewInterval()

        let data = try JSONEncoder().encode(settings)
        let decoded = AppSettings.load(from: data)
        XCTAssertEqual(decoded.showInDock, true)
        XCTAssertEqual(decoded.skipWhenIdle, false)
        XCTAssertEqual(decoded.idleThresholdMinutes, 12)
        XCTAssertEqual(decoded.isStanding, true)
    }
}

private extension AppSettings {
    mutating func setPreviewInterval() {
        var reminder = reminderSettings(for: .breakReminder)
        reminder.intervalMinutes = 25
        reminders[ReminderType.breakReminder.rawValue] = reminder
    }
}
