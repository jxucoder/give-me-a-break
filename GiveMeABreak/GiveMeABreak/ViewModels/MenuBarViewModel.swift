import Foundation
import Combine

@MainActor
final class MenuBarViewModel: ObservableObject {
    static let shared = MenuBarViewModel()

    @Published var displayTimers: [ReminderType: String] = [:]
    @Published var timerProgress: [ReminderType: Double] = [:]

    private var scheduler: ReminderScheduler { ReminderScheduler.shared }
    private var settingsVM: SettingsViewModel { SettingsViewModel.shared }
    private var displayTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var isStarted = false
    private var isVisible = false

    private init() {}

    // MARK: - Startup (called from AppDelegate after launch)

    func start() {
        guard !isStarted else { return }
        isStarted = true

        scheduler.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, self.isVisible else { return }
                self.updateDisplayTimers()
            }
            .store(in: &cancellables)

        scheduler.configure(with: settingsVM.settings)
        observeSettings()
    }

    // MARK: - Visibility

    func menuDidAppear() {
        guard !isVisible else { return }
        isVisible = true
        updateDisplayTimers()
        startDisplayTimer()
    }

    func menuDidDisappear() {
        isVisible = false
        displayTimer?.invalidate()
        displayTimer = nil
    }

    // MARK: - Display Timer

    private func startDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateDisplayTimers()
            }
        }
        RunLoop.main.add(displayTimer!, forMode: .default)
    }

    private func updateDisplayTimers() {
        var changed = false
        for type in ReminderType.allCases {
            if let remaining = scheduler.timeRemaining(for: type) {
                let newText = formatTimeInterval(remaining)
                let total = TimeInterval((scheduler.timerStates[type]?.intervalMinutes ?? type.defaultIntervalMinutes) * 60)
                let newProgress = total > 0 ? max(0, min(1, 1.0 - remaining / total)) : 0

                if displayTimers[type] != newText {
                    displayTimers[type] = newText
                    changed = true
                }
                if timerProgress[type] != newProgress {
                    timerProgress[type] = newProgress
                    changed = true
                }
            } else {
                if displayTimers[type] != nil {
                    displayTimers[type] = nil
                    changed = true
                }
                if timerProgress[type] != nil {
                    timerProgress[type] = nil
                    changed = true
                }
            }
        }
        if changed {
            objectWillChange.send()
        }
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Actions

    var isPaused: Bool {
        scheduler.isPaused
    }

    func isPaused(for type: ReminderType) -> Bool {
        scheduler.isPaused(for: type)
    }

    func togglePause(for type: ReminderType) {
        if scheduler.isPaused(for: type) {
            scheduler.resume(type: type, settings: settingsVM.settings)
        } else {
            scheduler.pause(type: type)
        }
    }

    func togglePause() {
        if scheduler.isPaused {
            scheduler.resumeAll(with: settingsVM.settings)
        } else {
            scheduler.pauseAll()
        }
    }

    func skipNext(for type: ReminderType) {
        scheduler.skipNext(for: type, settings: settingsVM.settings)
    }

    func triggerTestNotification(for type: ReminderType? = nil) {
        let resolved = type ?? ReminderType.allCases.first { settingsVM.isEnabled(for: $0) } ?? .breakReminder
        scheduler.triggerTestNotification(type: resolved, settings: settingsVM.settings)
    }

    // MARK: - Settings observation

    private func observeSettings() {
        settingsVM.$settings
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] newSettings in
                guard let self else { return }
                // Always reconfigure so interval changes take effect even while paused.
                // configure() skips running timers with the same interval, so it's safe to call unconditionally.
                self.scheduler.configure(with: newSettings)
            }
            .store(in: &cancellables)
    }
}
