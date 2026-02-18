import Foundation
import Combine

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Generates varied reminder messages using Apple's on-device Foundation Models framework.
/// Falls back to hardcoded messages when the model is unavailable or the SDK is too old.
@MainActor
final class LLMService: ObservableObject {
    static let shared = LLMService()

    enum ModelState: Equatable {
        case available
        case unavailable(String)
        case checking
    }

    @Published var modelState: ModelState = .checking
    @Published var isGenerating: Bool = false

    private init() {
        checkAvailability()
    }

    // MARK: - Availability

    func checkAvailability() {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default

            switch model.availability {
            case .available:
                modelState = .available
            case .unavailable(.appleIntelligenceNotEnabled):
                modelState = .unavailable("Apple Intelligence is not enabled. Enable it in System Settings > Apple Intelligence & Siri.")
            case .unavailable(.modelNotReady):
                modelState = .unavailable("The on-device model is still loading. Try again shortly.")
            case .unavailable(.deviceNotEligible):
                modelState = .unavailable("This device does not support Apple Intelligence.")
            default:
                modelState = .unavailable("The on-device model is not available.")
            }
        } else {
            modelState = .unavailable("Requires macOS 26+ and Xcode 26. Built-in messages will be used.")
        }
        #else
        modelState = .unavailable("Requires macOS 26+ and Xcode 26. Built-in messages will be used.")
        #endif
    }

    var isModelReady: Bool {
        modelState == .available
    }

    // MARK: - Message Generation

    func generateMessage(for type: ReminderType, tone: LLMTone, customPrompt: String = "") async -> String {
        #if canImport(FoundationModels)
        guard #available(macOS 26.0, *) else {
            return type.fallbackMessages.randomElement()!
        }

        guard modelState == .available else {
            return type.fallbackMessages.randomElement()!
        }

        isGenerating = true
        defer { isGenerating = false }

        let instructions = """
            You are a notification message generator. Output ONLY the notification text itself — nothing else. \
            Never include preamble like "Sure", "Here is", "Here's", or any conversational filler. \
            Never include quotes, emojis, hashtags, or labels. \
            1-2 sentences max, under 120 characters. Be \(tone.promptDescription).
            """

        let prompt: String
        if customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            prompt = """
                Write a short notification reminding someone about \(type.promptDescription). \
                Be original and vary your phrasing. Output only the reminder text.
                """
        } else {
            prompt = """
                \(customPrompt.trimmingCharacters(in: .whitespacesAndNewlines)) \
                The reminder type is: \(type.promptDescription). \
                Output only the reminder text.
                """
        }

        do {
            let session = LanguageModelSession {
                instructions
            }
            let response = try await session.respond(to: prompt)
            var text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

            // Strip any preamble the model may still produce
            let preambles = [
                "Sure, here is ", "Sure, here's ", "Sure! Here is ", "Sure! Here's ",
                "Here is ", "Here's ", "Here you go: ", "Here you go! ",
                "Of course! ", "Of course, ", "Certainly! ", "Certainly, ",
            ]
            for prefix in preambles {
                if text.hasPrefix(prefix) {
                    text = String(text.dropFirst(prefix.count))
                    break
                }
            }

            // Strip wrapping quotes
            if text.hasPrefix("\"") && text.hasSuffix("\"") && text.count > 2 {
                text = String(text.dropFirst().dropLast())
            }

            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty {
                return type.fallbackMessages.randomElement()!
            }
            return text
        } catch {
            print("Foundation Models error: \(error)")
            return type.fallbackMessages.randomElement()!
        }
        #else
        return type.fallbackMessages.randomElement()!
        #endif
    }
}
