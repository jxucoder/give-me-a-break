import SwiftUI

struct RemindersSettingsView: View {
    @ObservedObject var settingsVM = SettingsViewModel.shared

    var body: some View {
        Form {
            ForEach(ReminderType.allCases) { type in
                reminderSection(for: type)
            }

            Section {
                Text("Disabled reminders stay off until you turn them back on. Interval changes keep the time already elapsed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private func reminderSection(for type: ReminderType) -> some View {
        let enabled = settingsVM.isEnabled(for: type)

        Section {
            Toggle(isOn: Binding(
                get: { enabled },
                set: { settingsVM.setEnabled($0, for: type) }
            )) {
                Label(type.displayName, systemImage: type.icon)
                    .foregroundStyle(type.tintColor)
            }
            .tint(type.tintColor)

            if enabled {
                intervalSlider(for: type)
                Picker("Display", selection: Binding(
                    get: { settingsVM.displayMode(for: type) },
                    set: { settingsVM.setDisplayMode($0, for: type) }
                )) {
                    ForEach(ReminderDisplayMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            }
        }
    }

    private func intervalSlider(for type: ReminderType) -> some View {
        IntervalSlider(
            tint: type.tintColor,
            minutes: settingsVM.interval(for: type),
            onCommit: { settingsVM.setInterval($0, for: type) }
        )
    }
}

struct IntervalSlider: View {
    let tint: Color
    let minutes: Int
    let onCommit: (Int) -> Void

    @State private var draft: Double

    init(tint: Color, minutes: Int, onCommit: @escaping (Int) -> Void) {
        self.tint = tint
        self.minutes = minutes
        self.onCommit = onCommit
        _draft = State(initialValue: Double(minutes))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Interval")
                Spacer()
                Text(Self.label(for: Int(draft)))
                    .foregroundStyle(tint)
                    .monospacedDigit()
            }

            Slider(value: $draft, in: 5...120, step: 5) { editing in
                if !editing {
                    onCommit(Int(draft))
                }
            }
            .tint(tint)
        }
        .onChange(of: minutes) { _, newValue in
            draft = Double(newValue)
        }
    }

    static func label(for minutes: Int) -> String {
        minutes >= 60
            ? "\(minutes / 60)h\(minutes % 60 > 0 ? " \(minutes % 60)m" : "")"
            : "\(minutes)m"
    }
}
