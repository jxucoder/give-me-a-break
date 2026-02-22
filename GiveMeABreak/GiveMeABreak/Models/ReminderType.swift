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
        case .breakReminder: return 60
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

    var defaultEnabled: Bool { true }

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

    /// Verified health facts from CDC publications. Each entry is (fact, sourceURL).
    var healthFacts: [(fact: String, source: String)] {
        switch self {
        case .breakReminder:
            return [
                ("Prolonged sitting is linked to cardiovascular disease, diabetes, cancer, and obesity. — CDC Preventing Chronic Disease",
                 "https://www.cdc.gov/pcd/issues/2012/11_0323.htm"),
                ("Breaks in prolonged sitting lower health risks related to waist circumference, BMI, triglycerides, and glucose. — CDC Preventing Chronic Disease",
                 "https://www.cdc.gov/pcd/issues/2012/11_0323.htm"),
                ("Reducing sitting by just 66 min/day reduced upper back and neck pain by 54%. — CDC Take-a-Stand Project",
                 "https://www.cdc.gov/pcd/issues/2012/11_0323.htm"),
                ("Short 5–10 min activity breaks are recommended for the 156M U.S. workers who sit most of the day. — CDC Physical Activity Breaks Guide",
                 "https://stacks.cdc.gov/view/cdc/109187"),
                ("Taking breaks from sitting improved mood states among workers. — CDC Preventing Chronic Disease",
                 "https://www.cdc.gov/pcd/issues/2012/11_0323.htm"),
                ("Full-time workers spend one-third of their day at the workplace, often with little opportunity for movement. — CDC Physical Activity Breaks Guide",
                 "https://stacks.cdc.gov/view/cdc/109187"),
            ]
        case .posture:
            return [
                ("Awkward postures require excessive exertion from muscles, tendons, nerves, and bones, and can lead to musculoskeletal disorders. — CDC/NIOSH",
                 "https://www.cdc.gov/niosh/ergonomics/ergo-programs/risk-factors.html"),
                ("Maintaining the same position for extended periods causes muscle fatigue and disrupts blood flow — even in neutral positions. — CDC/NIOSH",
                 "https://www.cdc.gov/niosh/ergonomics/ergo-programs/risk-factors.html"),
                ("Ergonomic design of work tasks can reduce or eliminate work-related musculoskeletal disorders. — CDC/NIOSH",
                 "https://www.cdc.gov/niosh/ergonomics/about/index.html"),
                ("Musculoskeletal disorders include injuries to muscles, nerves, tendons, joints, cartilage, and spinal discs. — CDC/NIOSH",
                 "https://www.cdc.gov/niosh/ergonomics/about/index.html"),
                ("Static awkward posture is a known risk factor for tension-neck syndrome. — CDC/NIOSH",
                 "https://www.cdc.gov/niosh/ergonomics/ergo-programs/risk-factors.html"),
                ("Poor shoulder and wrist posture are physical risk factors for work-related musculoskeletal disorders. — CDC/NIOSH",
                 "https://www.cdc.gov/niosh/ergonomics/ergo-programs/risk-factors.html"),
            ]
        case .standSit:
            return [
                ("Using a sit-stand device at work reduced sitting time by 224% (66 min/day). — CDC Take-a-Stand Project",
                 "https://www.cdc.gov/pcd/issues/2012/11_0323.htm"),
                ("Sit-stand device use reduced upper back and neck pain by 54%. — CDC Take-a-Stand Project",
                 "https://www.cdc.gov/pcd/issues/2012/11_0323.htm"),
                ("Sit-stand device use improved mood states among workers. — CDC Take-a-Stand Project",
                 "https://www.cdc.gov/pcd/issues/2012/11_0323.htm"),
                ("Removing the sit-stand device reversed all health improvements within 2 weeks — consistency is key. — CDC Take-a-Stand Project",
                 "https://www.cdc.gov/pcd/issues/2012/11_0323.htm"),
                ("Prolonged sitting is associated with premature mortality, independent of physical activity levels. — CDC Preventing Chronic Disease",
                 "https://www.cdc.gov/pcd/issues/2012/11_0323.htm"),
                ("Breaks in sedentary time are correlated with beneficial metabolic profiles in adults. — CDC Preventing Chronic Disease",
                 "https://www.cdc.gov/pcd/issues/2012/11_0323.htm"),
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
