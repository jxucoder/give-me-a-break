import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var viewModel = MenuBarViewModel.shared
    @ObservedObject var settingsVM = SettingsViewModel.shared
    @State private var expandedSlider: ReminderType?

    var body: some View {
        VStack(spacing: 0) {
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

            let enabledTypes = ReminderType.allCases.filter { settingsVM.isEnabled(for: $0) }

            if enabledTypes.isEmpty {
                emptyState
            } else {
                VStack(spacing: 6) {
                    ForEach(enabledTypes) { type in
                        TimerCard(
                            type: type,
                            viewModel: viewModel,
                            settingsVM: settingsVM,
                            isExpanded: expandedSlider == type,
                            onToggleExpand: {
                                withAnimation(.snappy(duration: 0.2)) {
                                    expandedSlider = expandedSlider == type ? nil : type
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 10)
            }

            VStack(spacing: 2) {
                Divider()
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)

                HStack(spacing: 6) {
                    SettingsLink {
                        actionLabel(title: "Settings", systemImage: "gear")
                    }
                    .buttonStyle(ActionChipButtonStyle())
                    .simultaneousGesture(TapGesture().onEnded {
                        Self.bringSettingsForward()
                    })

                    if !enabledTypes.isEmpty {
                        actionButton(
                            title: viewModel.isPaused ? "Resume" : "Pause",
                            systemImage: viewModel.isPaused ? "play.fill" : "pause.fill",
                            action: { viewModel.togglePause() }
                        )
                    }

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
        .frame(width: 340)
        .onAppear { viewModel.menuDidAppear() }
        .onDisappear { viewModel.menuDidDisappear() }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "moon.zzz.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No reminders enabled")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Open Settings → Reminders to get started")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

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

    private static func bringSettingsForward() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NSApp.activate(ignoringOtherApps: true)
            if let window = NSApp.windows.first(where: {
                $0.identifier?.rawValue == "com_apple_SwiftUI_Settings_window"
            }) {
                window.collectionBehavior.insert(.canJoinAllSpaces)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}

private struct TimerCard: View {
    let type: ReminderType
    @ObservedObject var viewModel: MenuBarViewModel
    @ObservedObject var settingsVM: SettingsViewModel
    let isExpanded: Bool
    let onToggleExpand: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.12), lineWidth: 3)

                    Circle()
                        .trim(from: 0, to: viewModel.timerProgress[type] ?? 0)
                        .stroke(type.tintColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Image(systemName: type.icon)
                        .font(.system(size: 11))
                        .foregroundStyle(type.tintColor)
                }
                .frame(width: 30, height: 30)

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

                HStack(spacing: 4) {
                    iconButton("bell.badge", help: "Send test notification") {
                        viewModel.triggerTestNotification(for: type)
                    }
                    iconButton(
                        viewModel.isPaused(for: type) ? "play.fill" : "pause.fill",
                        help: viewModel.isPaused(for: type) ? "Resume" : "Pause",
                        emphasized: viewModel.isPaused(for: type)
                    ) {
                        viewModel.togglePause(for: type)
                    }
                    iconButton("arrow.counterclockwise", help: "Reset timer") {
                        viewModel.skipNext(for: type)
                    }
                }
            }

            if isExpanded {
                VStack(spacing: 8) {
                    IntervalSlider(
                        tint: type.tintColor,
                        minutes: settingsVM.interval(for: type),
                        onCommit: { settingsVM.setInterval($0, for: type) }
                    )

                    Picker("Display", selection: Binding(
                        get: { settingsVM.displayMode(for: type) },
                        set: { settingsVM.setDisplayMode($0, for: type) }
                    )) {
                        ForEach(ReminderDisplayMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    Button("Disable \(type.displayName)") {
                        settingsVM.setEnabled(false, for: type)
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggleExpand)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.04))
        )
    }

    private func iconButton(_ systemImage: String, help: String, emphasized: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.caption2)
                .foregroundStyle(emphasized ? .orange : .secondary)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(emphasized ? Color.orange.opacity(0.15) : Color.primary.opacity(0.06))
                )
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityLabel(help)
    }
}

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
