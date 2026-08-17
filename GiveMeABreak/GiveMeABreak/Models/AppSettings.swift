import Foundation
import SwiftUI

enum ReminderDisplayMode: String, Codable, CaseIterable, Identifiable {
    case notification
    case banner
    case fullscreen

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notification: return "Notification"
        case .banner: return "Banner"
        case .fullscreen: return "Fullscreen"
        }
    }
}

struct ReminderSettings: Codable, Equatable {
    var enabled: Bool
    var intervalMinutes: Int
    var displayMode: ReminderDisplayMode

    init(enabled: Bool, intervalMinutes: Int, displayMode: ReminderDisplayMode = .notification) {
        self.enabled = enabled
        self.intervalMinutes = intervalMinutes
        self.displayMode = displayMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        intervalMinutes = try container.decodeIfPresent(Int.self, forKey: .intervalMinutes) ?? 60
        displayMode = try container.decodeIfPresent(ReminderDisplayMode.self, forKey: .displayMode) ?? .notification
    }
}

struct AppSettings: Codable, Equatable {
    var launchAtLogin: Bool
    var playSounds: Bool
    var reminders: [String: ReminderSettings]
    var llmEnabled: Bool
    var llmTone: LLMTone
    var customPrompt: String
    var overlayDismissSeconds: Int
    var showInDock: Bool
    var skipWhenIdle: Bool
    var idleThresholdMinutes: Int
    var isStanding: Bool

    static let `default` = AppSettings()

    init(
        launchAtLogin: Bool = false,
        playSounds: Bool = true,
        reminders: [String: ReminderSettings] = Dictionary(
            uniqueKeysWithValues: ReminderType.allCases.map { type in
                (type.rawValue, ReminderSettings(
                    enabled: type.defaultEnabled,
                    intervalMinutes: type.defaultIntervalMinutes
                ))
            }
        ),
        llmEnabled: Bool = false,
        llmTone: LLMTone = .friendly,
        customPrompt: String = "Write a short notification reminding someone about their break. Be original and vary your phrasing.",
        overlayDismissSeconds: Int = 30,
        showInDock: Bool = false,
        skipWhenIdle: Bool = true,
        idleThresholdMinutes: Int = 5,
        isStanding: Bool = false
    ) {
        self.launchAtLogin = launchAtLogin
        self.playSounds = playSounds
        self.reminders = reminders
        self.llmEnabled = llmEnabled
        self.llmTone = llmTone
        self.customPrompt = customPrompt
        self.overlayDismissSeconds = overlayDismissSeconds
        self.showInDock = showInDock
        self.skipWhenIdle = skipWhenIdle
        self.idleThresholdMinutes = idleThresholdMinutes
        self.isStanding = isStanding
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings.default

        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? defaults.launchAtLogin
        playSounds = try container.decodeIfPresent(Bool.self, forKey: .playSounds) ?? defaults.playSounds
        llmEnabled = try container.decodeIfPresent(Bool.self, forKey: .llmEnabled) ?? defaults.llmEnabled
        llmTone = try container.decodeIfPresent(LLMTone.self, forKey: .llmTone) ?? defaults.llmTone
        customPrompt = try container.decodeIfPresent(String.self, forKey: .customPrompt) ?? defaults.customPrompt
        overlayDismissSeconds = try container.decodeIfPresent(Int.self, forKey: .overlayDismissSeconds) ?? defaults.overlayDismissSeconds
        showInDock = try container.decodeIfPresent(Bool.self, forKey: .showInDock) ?? defaults.showInDock
        skipWhenIdle = try container.decodeIfPresent(Bool.self, forKey: .skipWhenIdle) ?? defaults.skipWhenIdle
        idleThresholdMinutes = try container.decodeIfPresent(Int.self, forKey: .idleThresholdMinutes) ?? defaults.idleThresholdMinutes
        isStanding = try container.decodeIfPresent(Bool.self, forKey: .isStanding) ?? defaults.isStanding

        var decodedReminders = try container.decodeIfPresent([String: ReminderSettings].self, forKey: .reminders) ?? [:]
        for type in ReminderType.allCases where decodedReminders[type.rawValue] == nil {
            decodedReminders[type.rawValue] = ReminderSettings(
                enabled: type.defaultEnabled,
                intervalMinutes: type.defaultIntervalMinutes
            )
        }
        reminders = decodedReminders
    }

    /// Loads settings from persisted JSON. Missing keys keep defaults; corrupt data falls back entirely.
    static func load(from data: Data?) -> AppSettings {
        guard let data else { return .default }
        do {
            return try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            return .default
        }
    }

    func reminderSettings(for type: ReminderType) -> ReminderSettings {
        reminders[type.rawValue] ?? ReminderSettings(
            enabled: type.defaultEnabled,
            intervalMinutes: type.defaultIntervalMinutes
        )
    }
}

enum LLMTone: String, Codable, CaseIterable, Identifiable {
    case friendly
    case humorous
    case professional
    case motivational

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .friendly: return "Friendly"
        case .humorous: return "Humorous"
        case .professional: return "Professional"
        case .motivational: return "Motivational"
        }
    }

    var icon: String {
        switch self {
        case .friendly: return "face.smiling"
        case .humorous: return "theatermasks"
        case .professional: return "briefcase"
        case .motivational: return "flame"
        }
    }

    var tintColor: Color {
        switch self {
        case .friendly: return .teal
        case .humorous: return .orange
        case .professional: return .blue
        case .motivational: return .red
        }
    }

    var promptDescription: String {
        switch self {
        case .friendly: return "warm and friendly"
        case .humorous: return "lighthearted and humorous"
        case .professional: return "professional and concise"
        case .motivational: return "motivational and encouraging"
        }
    }
}
