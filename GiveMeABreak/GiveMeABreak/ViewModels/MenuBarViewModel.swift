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

    private init() {}

    // MARK: - Startup (called from AppDelegate after launch)

    func start() {
        guard !isStarted else { return }
        isStarted = true

        scheduler.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDisplayTimers()
            }
            .store(in: &cancellables)

        startDisplayTimer()
        scheduler.configure(with: settingsVM.settings)
        observeSettings()
    }

    // MARK: - Display Timer

    private func startDisplayTimer() {
        displayTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateDisplayTimers()
            }
        }
        RunLoop.main.add(displayTimer!, forMode: .common)
    }

    private func updateDisplayTimers() {
        for type in ReminderType.allCases {
            if let remaining = scheduler.timeRemaining(for: type) {
                displayTimers[type] = formatTimeInterval(remaining)
                let total = TimeInterval((scheduler.timerStates[type]?.intervalMinutes ?? type.defaultIntervalMinutes) * 60)
                timerProgress[type] = total > 0 ? max(0, min(1, 1.0 - remaining / total)) : 0
            } else if scheduler.isPaused(for: type) {
                // Show frozen remaining time for paused timers
                displayTimers[type] = nil
                timerProgress[type] = nil
            } else {
                displayTimers[type] = nil
                timerProgress[type] = nil
            }
        }
        objectWillChange.send()
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
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

    func triggerTestNotification() {
        let type = ReminderType.allCases.first { settingsVM.isEnabled(for: $0) } ?? .breakReminder
        scheduler.triggerTestNotification(type: type, settings: settingsVM.settings)
    }

    // MARK: - Settings observation

    private func observeSettings() {
        settingsVM.$settings
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] newSettings in
                guard let self else { return }
                if !self.scheduler.isPaused {
                    self.scheduler.configure(with: newSettings)
                }
            }
            .store(in: &cancellables)
    }
}
