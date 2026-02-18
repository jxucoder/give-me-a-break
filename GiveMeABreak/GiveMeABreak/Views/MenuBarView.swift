import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel = MenuBarViewModel.shared
    @ObservedObject var settingsVM = SettingsViewModel.shared
    @State private var expandedSlider: ReminderType?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.title3)
                    .foregroundStyle(.teal)
                Text("Give Me A Break")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Timer cards
            let enabledTypes = ReminderType.allCases.filter { settingsVM.isEnabled(for: $0) }

            if enabledTypes.isEmpty {
                emptyState
            } else {
                VStack(spacing: 6) {
                    ForEach(enabledTypes) { type in
                        timerCard(for: type)
                    }
                }
                .padding(.horizontal, 10)
            }

            // Actions
            VStack(spacing: 2) {
                Divider()
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)

                HStack(spacing: 6) {
                    actionButton(
                        title: "Test",
                        systemImage: "bell.badge",
                        action: { viewModel.triggerTestNotification() }
                    )

                    SettingsLink {
                        actionLabel(title: "Settings", systemImage: "gear")
                    }
                    .buttonStyle(ActionChipButtonStyle())

                    actionButton(
                        title: "Quit",
                        systemImage: "power",
                        action: { NSApplication.shared.terminate(nil) }
                    )
                }
                .padding(.horizontal, 10)
            }
            .padding(.bottom, 12)
        }
        .frame(width: 280)
        .onAppear { viewModel.menuDidAppear() }
        .onDisappear { viewModel.menuDidDisappear() }
    }

    // MARK: - Timer Card

    private func timerCard(for type: ReminderType) -> some View {
        let currentInterval = Double(settingsVM.interval(for: type))

        return VStack(spacing: 6) {
            // Top row: ring + name + countdown + skip
            HStack(spacing: 10) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(type.tintColor.opacity(0.15), lineWidth: 3)

                    Circle()
                        .trim(from: 0, to: viewModel.timerProgress[type] ?? 0)
                        .stroke(type.tintColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: viewModel.timerProgress[type])

                    Image(systemName: type.icon)
                        .font(.system(size: 11))
                        .foregroundStyle(type.tintColor)
                }
                .frame(width: 30, height: 30)

                // Name + countdown
                VStack(alignment: .leading, spacing: 1) {
                    Text(type.displayName)
                        .font(.subheadline.weight(.medium))

                    if viewModel.isPaused(for: type) {
                        if let timeString = viewModel.displayTimers[type] {
                            Text("\(timeString) — Paused")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.orange)
                        } else {
                            Text("Paused")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    } else if let timeString = viewModel.displayTimers[type] {
                        Text(timeString)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(type.tintColor)
                    }
                }

                Spacer()

                // Pause / Reset / Gear buttons
                HStack(spacing: 4) {
                    Button(action: { viewModel.togglePause(for: type) }) {
                        Image(systemName: viewModel.isPaused(for: type) ? "play.fill" : "pause.fill")
                            .font(.caption2)
                            .foregroundStyle(viewModel.isPaused(for: type) ? .orange : .secondary)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(viewModel.isPaused(for: type)
                                          ? Color.orange.opacity(0.15)
                                          : Color.primary.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .help(viewModel.isPaused(for: type) ? "Resume" : "Pause")

                    Button(action: { viewModel.skipNext(for: type) }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(Color.primary.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Reset timer")

                    Button(action: {
                        withAnimation(.snappy(duration: 0.2)) {
                            expandedSlider = expandedSlider == type ? nil : type
                        }
                    }) {
                        Image(systemName: "gearshape")
                            .font(.caption2)
                            .foregroundStyle(expandedSlider == type ? type.tintColor : .secondary)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(expandedSlider == type
                                          ? type.tintColor.opacity(0.15)
                                          : Color.primary.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Adjust interval")
                }
            }

            // Interval slider (shown when reset is tapped)
            if expandedSlider == type {
                HStack(spacing: 6) {
                    Text("5m")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)

                    Slider(
                        value: Binding(
                            get: { currentInterval },
                            set: { settingsVM.setInterval(Int($0), for: type) }
                        ),
                        in: 5...120,
                        step: 5
                    )
                    .tint(type.tintColor)

                    Text("2h")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)

                    let mins = Int(currentInterval)
                    Text(mins >= 60 ? "\(mins / 60)h\(mins % 60 > 0 ? "\(mins % 60)m" : "")" : "\(mins)m")
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .foregroundStyle(type.tintColor)
                        .frame(width: 34, alignment: .trailing)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.04))
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "moon.zzz.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No reminders enabled")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Open Settings to get started")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - Action Buttons

    private func actionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            actionLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(ActionChipButtonStyle())
    }

    private func actionLabel(title: String, systemImage: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: systemImage)
                .font(.system(size: 12))
            Text(title)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

// MARK: - Action Chip Button Style

private struct ActionChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ActionChipBody(configuration: configuration)
    }
}

private struct ActionChipBody: View {
    let configuration: ButtonStyle.Configuration
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .foregroundStyle(isHovered ? Color.accentColor : .secondary)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04))
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
            }
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
