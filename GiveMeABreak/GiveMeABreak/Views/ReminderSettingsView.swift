import SwiftUI

struct ReminderSettingsView: View {
    @ObservedObject var settingsVM = SettingsViewModel.shared

    var body: some View {
        Form {
            ForEach(ReminderType.allCases) { type in
                Section {
                    Toggle(isOn: Binding(
                        get: { settingsVM.isEnabled(for: type) },
                        set: { settingsVM.setEnabled($0, for: type) }
                    )) {
                        Label(type.displayName, systemImage: type.icon)
                            .foregroundStyle(type.tintColor)
                    }
                    .tint(type.tintColor)

                    if settingsVM.isEnabled(for: type) {
                        IntervalSlider(
                            value: Binding(
                                get: { settingsVM.interval(for: type) },
                                set: { settingsVM.setInterval($0, for: type) }
                            ),
                            tint: type.tintColor
                        )
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Interval Slider

private struct IntervalSlider: View {
    @Binding var value: Int
    let tint: Color

    private let range = 5...120
    private let step = 5

    private let presets: [(String, Int)] = [
        ("10m", 10),
        ("15m", 15),
        ("25m", 25),
        ("30m", 30),
        ("45m", 45),
        ("60m", 60),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Current value
            HStack(alignment: .firstTextBaseline) {
                Text("Every")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(formattedValue)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: value)
            }

            // Slider
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = snapped(Int($0)) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: Double(step)
            )
            .tint(tint)

            // Quick presets
            HStack(spacing: 4) {
                ForEach(presets, id: \.1) { label, mins in
                    Button(action: { withAnimation(.snappy) { value = mins } }) {
                        Text(label)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(value == mins ? tint.opacity(0.18) : Color.primary.opacity(0.05))
                            )
                            .foregroundStyle(value == mins ? tint : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(.vertical, 2)
    }

    private var formattedValue: String {
        if value >= 60 && value % 60 == 0 {
            return "\(value / 60) hr"
        } else if value > 60 {
            return "\(value / 60) hr \(value % 60) min"
        }
        return "\(value) min"
    }

    private func snapped(_ raw: Int) -> Int {
        let clamped = min(max(raw, range.lowerBound), range.upperBound)
        return (clamped / step) * step
    }
}
