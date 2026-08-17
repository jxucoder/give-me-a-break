import Foundation
import os.log

@MainActor
final class ReminderScheduler: ObservableObject {
    static let shared = ReminderScheduler()

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.givemeabreak.app", category: "ReminderScheduler")
    private static let snapshotKey = "timerSnapshots"

    struct TimerState {
        var isActive: Bool = false
        var isPaused: Bool = false
        var fireDate: Date?
        var timer: Timer?
        var intervalMinutes: Int = 0
        var remainingWhenPaused: TimeInterval?
    }

    private struct TimerSnapshot: Codable {
        var fireDate: Date?
        var intervalMinutes: Int
        var isPaused: Bool
        var remainingWhenPaused: TimeInterval?
    }

    @Published var timerStates: [ReminderType: TimerState] = [:]

    /// Global pause is derived: true when every enabled timer is paused.
    var isPaused: Bool {
        let active = timerStates.values.filter { $0.isActive || $0.isPaused }
        guard !active.isEmpty else { return false }
        return active.allSatisfy { $0.isPaused }
    }

    private var notificationService: NotificationService { NotificationService.shared }
    private var overlayManager: OverlayManager { OverlayManager.shared }
    private var llmService: LLMService { LLMService.shared }
    private var activityTokens: [NSObjectProtocol] = []
    private var deliveryTasks: [ReminderType: Task<Void, Never>] = [:]

    /// Minimum gap (in seconds) between two notifications to avoid spam.
    private let coalescingGap: TimeInterval = 120
    private var lastNotificationDate: Date = .distantPast

    private init() {
        for type in ReminderType.allCases {
            timerStates[type] = TimerState()
        }
        restoreSnapshots()
        activityTokens = SystemActivity.startObserving { [weak self] in
            self?.handleSystemResume()
        }
    }

    // MARK: - Public API

    func configure(with settings: AppSettings) {
        for type in ReminderType.allCases {
            let reminderSettings = settings.reminderSettings(for: type)

            guard reminderSettings.enabled else {
                cancelDelivery(for: type)
                stopTimer(for: type)
                continue
            }

            var state = timerStates[type] ?? TimerState()

            if state.isPaused {
                state.intervalMinutes = reminderSettings.intervalMinutes
                timerStates[type] = state
                persistSnapshots()
                continue
            }

            if state.isActive,
               state.timer != nil,
               state.intervalMinutes == reminderSettings.intervalMinutes {
                continue
            }

            if let remaining = timeRemaining(for: type), remaining > 0 {
                let capped = min(remaining, TimeInterval(reminderSettings.intervalMinutes * 60))
                scheduleNext(for: type, delay: capped, intervalMinutes: reminderSettings.intervalMinutes)
                continue
            }

            startTimer(for: type, intervalMinutes: reminderSettings.intervalMinutes)
        }
    }

    // MARK: - Per-Timer Pause / Resume

    func pause(type: ReminderType) {
        guard let state = timerStates[type], (state.isActive || state.isPaused), !state.isPaused else { return }
        cancelDelivery(for: type)
        let remaining = state.fireDate?.timeIntervalSinceNow ?? 0
        timerStates[type]?.timer?.invalidate()
        timerStates[type]?.timer = nil
        timerStates[type]?.isPaused = true
        timerStates[type]?.isActive = false
        timerStates[type]?.remainingWhenPaused = max(0, remaining)
        persistSnapshots()
    }

    func resume(type: ReminderType, settings: AppSettings) {
        guard let state = timerStates[type], state.isPaused else { return }
        let remaining = state.remainingWhenPaused ?? TimeInterval(state.intervalMinutes * 60)
        let interval = state.intervalMinutes > 0
            ? state.intervalMinutes
            : settings.reminderSettings(for: type).intervalMinutes

        timerStates[type]?.isPaused = false
        timerStates[type]?.remainingWhenPaused = nil
        scheduleNext(for: type, delay: max(1, remaining), intervalMinutes: interval)
    }

    func isPaused(for type: ReminderType) -> Bool {
        timerStates[type]?.isPaused ?? false
    }

    func pauseAll() {
        for type in ReminderType.allCases {
            pause(type: type)
        }
    }

    func resumeAll(with settings: AppSettings) {
        for type in ReminderType.allCases {
            resume(type: type, settings: settings)
        }
    }

    func skipNext(for type: ReminderType, settings: AppSettings) {
        cancelDelivery(for: type)
        let interval = timerStates[type]?.intervalMinutes ?? settings.reminderSettings(for: type).intervalMinutes
        stopTimer(for: type)
        startTimer(for: type, intervalMinutes: interval)
    }

    /// Delay this reminder and use it as the next fire, instead of stacking a one-off ping.
    func snooze(type: ReminderType, minutes: Int) {
        let settings = SettingsViewModel.shared.settings
        guard settings.reminderSettings(for: type).enabled else { return }
        cancelDelivery(for: type)
        overlayManager.dismiss()
        let interval = timerStates[type]?.intervalMinutes ?? settings.reminderSettings(for: type).intervalMinutes
        timerStates[type]?.timer?.invalidate()
        timerStates[type]?.isPaused = false
        timerStates[type]?.remainingWhenPaused = nil
        scheduleNext(for: type, delay: TimeInterval(max(1, minutes) * 60), intervalMinutes: interval)
    }

    /// User handled the reminder — restart the full interval.
    func markDone(type: ReminderType) {
        let settings = SettingsViewModel.shared.settings
        overlayManager.dismiss()
        skipNext(for: type, settings: settings)
    }

    func timeRemaining(for type: ReminderType) -> TimeInterval? {
        guard let state = timerStates[type] else { return nil }

        if state.isPaused {
            return state.remainingWhenPaused
        }

        guard let fireDate = state.fireDate else { return nil }
        let remaining = fireDate.timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }

    // MARK: - Timer Management

    private func startTimer(for type: ReminderType, intervalMinutes: Int) {
        guard !(timerStates[type]?.isPaused ?? false) else { return }
        scheduleNext(for: type, delay: TimeInterval(intervalMinutes * 60), intervalMinutes: intervalMinutes)
    }

    private func scheduleNext(for type: ReminderType, delay: TimeInterval, intervalMinutes: Int) {
        guard !(timerStates[type]?.isPaused ?? false) else { return }

        timerStates[type]?.timer?.invalidate()

        let fireDate = Date().addingTimeInterval(delay)
        let timer = Timer(timeInterval: max(0.05, delay), repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let interval = self.timerStates[type]?.intervalMinutes ?? intervalMinutes
                self.scheduleNext(for: type, delay: TimeInterval(interval * 60), intervalMinutes: interval)
                self.timerFired(for: type)
            }
        }
        RunLoop.main.add(timer, forMode: .common)

        timerStates[type] = TimerState(
            isActive: true,
            fireDate: fireDate,
            timer: timer,
            intervalMinutes: intervalMinutes
        )
        persistSnapshots()
    }

    private func stopTimer(for type: ReminderType) {
        timerStates[type]?.timer?.invalidate()
        timerStates[type] = TimerState()
        persistSnapshots()
    }

    private func cancelDelivery(for type: ReminderType) {
        deliveryTasks[type]?.cancel()
        deliveryTasks[type] = nil
    }

    private func timerFired(for type: ReminderType) {
        cancelDelivery(for: type)
        deliveryTasks[type] = Task { @MainActor [weak self] in
            guard let self else { return }

            let now = Date()
            let sinceLast = now.timeIntervalSince(self.lastNotificationDate)
            let delay = sinceLast < self.coalescingGap ? self.coalescingGap - sinceLast : 0
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            guard !Task.isCancelled else { return }

            let settings = SettingsViewModel.shared.settings
            guard settings.reminderSettings(for: type).enabled else { return }
            guard !self.isPaused(for: type) else { return }

            if settings.skipWhenIdle {
                let threshold = TimeInterval(max(1, settings.idleThresholdMinutes) * 60)
                if !SystemActivity.isUserPresent(idleThreshold: threshold) {
                    Self.logger.info("Skipping \(type.rawValue, privacy: .public) reminder — user idle or screen locked")
                    return
                }
            }

            let isStanding = settings.isStanding
            let message: String
            if settings.llmEnabled && self.llmService.isModelReady {
                message = await self.llmService.generateMessage(
                    for: type,
                    tone: settings.llmTone,
                    customPrompt: settings.customPrompt,
                    isStanding: isStanding
                )
            } else {
                message = type.fallbackMessage(isStanding: isStanding)
            }

            guard !Task.isCancelled else { return }

            if type == .standSit {
                SettingsViewModel.shared.settings.isStanding.toggle()
            }

            self.lastNotificationDate = Date()
            await self.deliverReminder(type: type, message: message, settings: settings)
        }
    }

    private func deliverReminder(type: ReminderType, message: String, settings: AppSettings) async {
        var mode = settings.reminderSettings(for: type).displayMode
        if mode == .notification {
            let status = await notificationService.authorizationStatus()
            if status == .denied || status == .notDetermined {
                mode = .banner
            }
        }

        switch mode {
        case .notification:
            notificationService.sendReminder(type: type, message: message, playSound: settings.playSounds)
        case .banner, .fullscreen:
            overlayManager.showOverlay(
                type: type,
                message: message,
                mode: mode,
                dismissSeconds: settings.overlayDismissSeconds,
                playSound: settings.playSounds
            )
        }
    }

    func triggerTestNotification(type: ReminderType, settings: AppSettings) {
        cancelDelivery(for: type)
        deliveryTasks[type] = Task { @MainActor [weak self] in
            guard let self else { return }
            let isStanding = settings.isStanding
            let message: String
            if settings.llmEnabled && self.llmService.isModelReady {
                message = await self.llmService.generateMessage(
                    for: type,
                    tone: settings.llmTone,
                    customPrompt: settings.customPrompt,
                    isStanding: isStanding
                )
            } else {
                message = type.fallbackMessage(isStanding: isStanding)
            }
            guard !Task.isCancelled else { return }
            await self.deliverReminder(type: type, message: message, settings: SettingsViewModel.shared.settings)
        }
    }

    // MARK: - Sleep / lock resume

    func handleSystemResume() {
        let settings = SettingsViewModel.shared.settings
        for type in ReminderType.allCases {
            guard settings.reminderSettings(for: type).enabled else { continue }
            guard let state = timerStates[type], !state.isPaused else { continue }
            let interval = state.intervalMinutes > 0
                ? state.intervalMinutes
                : settings.reminderSettings(for: type).intervalMinutes

            if let fireDate = state.fireDate, fireDate.timeIntervalSinceNow > 1 {
                scheduleNext(for: type, delay: fireDate.timeIntervalSinceNow, intervalMinutes: interval)
            } else if state.isActive || state.fireDate != nil {
                startTimer(for: type, intervalMinutes: interval)
            }
        }
    }

    // MARK: - Persistence

    private func persistSnapshots() {
        var snapshots: [String: TimerSnapshot] = [:]
        for (type, state) in timerStates {
            guard state.isActive || state.isPaused else { continue }
            snapshots[type.rawValue] = TimerSnapshot(
                fireDate: state.fireDate,
                intervalMinutes: state.intervalMinutes,
                isPaused: state.isPaused,
                remainingWhenPaused: state.remainingWhenPaused
            )
        }
        if let data = try? JSONEncoder().encode(snapshots) {
            UserDefaults.standard.set(data, forKey: Self.snapshotKey)
        }
    }

    private func restoreSnapshots() {
        guard let data = UserDefaults.standard.data(forKey: Self.snapshotKey),
              let snapshots = try? JSONDecoder().decode([String: TimerSnapshot].self, from: data) else {
            return
        }

        for type in ReminderType.allCases {
            guard let snapshot = snapshots[type.rawValue] else { continue }
            timerStates[type] = TimerState(
                isActive: false,
                isPaused: snapshot.isPaused,
                fireDate: snapshot.fireDate,
                intervalMinutes: snapshot.intervalMinutes,
                remainingWhenPaused: snapshot.remainingWhenPaused
            )
        }
    }
}
