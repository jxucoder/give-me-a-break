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
}

struct AppSettings: Codable, Equatable {
    var launchAtLogin: Bool
    var playSounds: Bool
    var reminders: [String: ReminderSettings]
    var llmEnabled: Bool
    var llmTone: LLMTone
    var customPrompt: String
    var showHealthFacts: Bool
    var overlayDismissSeconds: Int

    static let `default` = AppSettings(
        launchAtLogin: false,
        playSounds: true,
        reminders: Dictionary(
            uniqueKeysWithValues: ReminderType.allCases.map { type in
                (type.rawValue, ReminderSettings(
                    enabled: type.defaultEnabled,
                    intervalMinutes: type.defaultIntervalMinutes
                ))
            }
        ),
        llmEnabled: false,
        llmTone: .friendly,
        customPrompt: "Write a short notification reminding someone about their break. Be original and vary your phrasing.",
        showHealthFacts: false,
        overlayDismissSeconds: 30
    )

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
