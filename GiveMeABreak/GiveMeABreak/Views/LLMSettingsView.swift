import SwiftUI

struct LLMSettingsView: View {
    @ObservedObject var settingsVM = SettingsViewModel.shared
    @ObservedObject var llmService = LLMService.shared

    var body: some View {
        Form {
            Section {
                Toggle("Enable AI-Generated Messages", isOn: $settingsVM.settings.llmEnabled)

                if settingsVM.settings.llmEnabled {
                    Picker("Tone:", selection: $settingsVM.settings.llmTone) {
                        ForEach(LLMTone.allCases) { tone in
                            Text(tone.displayName).tag(tone)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            if settingsVM.settings.llmEnabled {
                Section("Prompt") {
                    TextEditor(text: $settingsVM.settings.customPrompt)
                        .font(.body)
                        .frame(minHeight: 60, maxHeight: 120)
                        .scrollContentBackground(.hidden)

                    Text("Customize how reminder messages are written — e.g. \"Write reminders as if you're a pirate\" or \"Keep it under 10 words and very direct\".")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if settingsVM.settings.llmEnabled {
                Section("Prompt Preview") {
                    let tone = settingsVM.settings.llmTone
                    let custom = settingsVM.settings.customPrompt.trimmingCharacters(in: .whitespacesAndNewlines)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("System Instructions")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("You are a notification message generator. Output ONLY the notification text itself — nothing else. Never include preamble, quotes, emojis, hashtags, or labels. 1-2 sentences max, under 120 characters. Be \(tone.promptDescription).")
                            .font(.caption)
                            .foregroundStyle(.primary)

                        Divider()

                        Text("User Prompt (per notification)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("\(custom.isEmpty ? "(no custom prompt)" : custom) The reminder type is: [Take a Break / Check Posture / Stand or Sit]. Output only the reminder text.")
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 4)
                }
            }

            if settingsVM.settings.llmEnabled {
                Section("On-Device Model") {
                    modelStatusView

                    Button("Refresh Status") {
                        llmService.checkAvailability()
                    }
                }
            }

            Section {
                Text("AI messages use Apple Intelligence on-device model. No data leaves your Mac. When unavailable, built-in messages are used instead.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var modelStatusView: some View {
        switch llmService.modelState {
        case .available:
            Label("Apple Intelligence model ready", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)

        case .unavailable(let reason):
            VStack(alignment: .leading, spacing: 4) {
                Label("Model unavailable", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .checking:
            Label("Checking availability...", systemImage: "ellipsis.circle")
                .foregroundStyle(.secondary)
        }
    }
}
