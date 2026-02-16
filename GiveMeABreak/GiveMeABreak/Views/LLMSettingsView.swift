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
