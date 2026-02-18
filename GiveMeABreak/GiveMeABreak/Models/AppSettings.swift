import Foundation

struct ReminderSettings: Codable, Equatable {
    var enabled: Bool
    var intervalMinutes: Int
}

struct AppSettings: Codable, Equatable {
    var launchAtLogin: Bool
    var playSounds: Bool
    var reminders: [String: ReminderSettings]
    var llmEnabled: Bool
    var llmTone: LLMTone
    var customPrompt: String

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
        customPrompt: ""
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

    var promptDescription: String {
        switch self {
        case .friendly: return "warm and friendly"
        case .humorous: return "lighthearted and humorous"
        case .professional: return "professional and concise"
        case .motivational: return "motivational and encouraging"
        }
    }
}
