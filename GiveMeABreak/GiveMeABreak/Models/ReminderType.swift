import Foundation
import SwiftUI

enum ReminderType: String, CaseIterable, Codable, Identifiable {
    case breakReminder = "break"
    case posture = "posture"
    case standSit = "standSit"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .breakReminder: return "Take a Break"
        case .posture: return "Check Posture"
        case .standSit: return "Stand / Sit"
        }
    }

    var icon: String {
        switch self {
        case .breakReminder: return "cup.and.saucer.fill"
        case .posture: return "figure.stand"
        case .standSit: return "arrow.up.arrow.down"
        }
    }

    var defaultIntervalMinutes: Int {
        switch self {
        case .breakReminder: return 25
        case .posture: return 15
        case .standSit: return 30
        }
    }

    var tintColor: Color {
        switch self {
        case .breakReminder: return .teal
        case .posture: return .purple
        case .standSit: return .orange
        }
    }

    var defaultEnabled: Bool {
        switch self {
        case .breakReminder: return true
        case .posture: return true
        case .standSit: return false
        }
    }

    var fallbackMessages: [String] {
        switch self {
        case .breakReminder:
            return [
                "Time for a break! Step away and rest your eyes.",
                "Break time! Stretch your legs and grab some water.",
                "You've been working hard — take a few minutes to recharge.",
                "Your break reminder is here. A short walk does wonders!",
                "Hey, it's break time. Give your mind a rest!",
                "Take 5! Look away from the screen and breathe deeply.",
                "Break o'clock! Stand up, stretch, and reset.",
                "Reminder: short breaks boost productivity. Take one now!",
            ]
        case .posture:
            return [
                "Posture check! Sit up straight and relax your shoulders.",
                "How's your posture? Roll your shoulders back.",
                "Straighten up! Your back will thank you later.",
                "Quick posture reminder: feet flat, back straight, shoulders relaxed.",
                "Check in with your body — are you slouching?",
                "Posture alert! Lift your chin and align your spine.",
                "Time for a posture reset. Sit tall and breathe.",
                "Friendly nudge: unclench your jaw and fix your posture!",
            ]
        case .standSit:
            return [
                "Time to switch! If you're sitting, stand up. If standing, take a seat.",
                "Alternate your position — your body needs the change.",
                "Stand/sit switch! Keep your body moving throughout the day.",
                "Position change reminder: variety keeps you comfortable.",
                "Time to toggle! Switch between standing and sitting.",
                "Your stand/sit timer went off. Make the switch!",
                "Keep things fresh — change your working position now.",
                "Reminder: alternating positions reduces fatigue. Switch it up!",
            ]
        }
    }

    /// Prompt fragment for LLM message generation
    var promptDescription: String {
        switch self {
        case .breakReminder:
            return "taking a short break from work to rest eyes and stretch"
        case .posture:
            return "checking and correcting sitting/standing posture"
        case .standSit:
            return "switching between standing and sitting position at their desk"
        }
    }
}
