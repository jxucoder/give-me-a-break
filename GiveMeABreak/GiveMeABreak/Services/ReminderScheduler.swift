import Foundation
import Combine

@MainActor
final class ReminderScheduler: ObservableObject {
    static let shared = ReminderScheduler()

    struct TimerState {
        var isActive: Bool = false
        var isPaused: Bool = false
        var fireDate: Date?
        var timer: Timer?
        var intervalMinutes: Int = 0
        /// Seconds remaining when paused, so we can resume accurately.
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
    private var settingsCancellable: AnyCancellable?

    private init() {
        // Initialize timer states for all types
        for type in ReminderType.allCases {
            timerStates[type] = TimerState()
        }
    }

    /// Minimum gap (in seconds) between two notifications to avoid spam.
    private let coalescingGap: TimeInterval = 120

    // MARK: - Public API

    func configure(with settings: AppSettings) {
        // Collect which types need a fresh timer vs. which can keep running.
        var typesToStart: [(ReminderType, Int)] = []

        for type in ReminderType.allCases {
            let reminderSettings = settings.reminderSettings(for: type)

            guard reminderSettings.enabled else {
                stopTimer(for: type)
                continue
            }

            // If already running with the same interval, keep the existing timer.
            if let state = timerStates[type],
               state.isActive,
               state.intervalMinutes == reminderSettings.intervalMinutes,
               state.timer != nil {
                continue
            }

            typesToStart.append((type, reminderSettings.intervalMinutes))
        }

        // Stagger new timers so they don't all fire at the same moment.
        let staggerStep: TimeInterval = 90  // 1.5 min between each timer
        for (index, (type, intervalMinutes)) in typesToStart.enumerated() {
            let offset = TimeInterval(index) * staggerStep
            startTimer(for: type, intervalMinutes: intervalMinutes, initialOffset: offset, settings: settings)
        }
    }

    // MARK: - Per-Timer Pause / Resume

    func pause(type: ReminderType) {
        guard let state = timerStates[type], state.isActive, !state.isPaused else { return }
        let remaining = state.fireDate?.timeIntervalSinceNow ?? 0
        timerStates[type]?.timer?.invalidate()
        timerStates[type]?.timer = nil
        timerStates[type]?.isPaused = true
        timerStates[type]?.isActive = false
        timerStates[type]?.remainingWhenPaused = max(0, remaining)
    }

    func resume(type: ReminderType, settings: AppSettings) {
        guard let state = timerStates[type], state.isPaused else { return }
        let remaining = state.remainingWhenPaused ?? TimeInterval(state.intervalMinutes * 60)
        let interval = state.intervalMinutes > 0 ? state.intervalMinutes : settings.reminderSettings(for: type).intervalMinutes

        timerStates[type]?.isPaused = false
        timerStates[type]?.remainingWhenPaused = nil

        resumeTimer(for: type, remaining: remaining, intervalMinutes: interval, settings: settings)
    }

    func isPaused(for type: ReminderType) -> Bool {
        timerStates[type]?.isPaused ?? false
    }

    // MARK: - Global Pause / Resume (convenience)

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

    // MARK: - Skip / Reset

    func skipNext(for type: ReminderType, settings: AppSettings) {
        let interval = timerStates[type]?.intervalMinutes ?? settings.reminderSettings(for: type).intervalMinutes
        stopTimer(for: type)
        startTimer(for: type, intervalMinutes: interval, initialOffset: 0, settings: settings)
    }

    func timeRemaining(for type: ReminderType) -> TimeInterval? {
        guard let state = timerStates[type] else { return nil }

        if state.isPaused {
            return state.remainingWhenPaused
        }

        guard state.isActive, let fireDate = state.fireDate else { return nil }
        let remaining = fireDate.timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }

    // MARK: - Timer Management

    private func startTimer(for type: ReminderType, intervalMinutes: Int, initialOffset: TimeInterval, settings: AppSettings) {
        guard !(timerStates[type]?.isPaused ?? false) else { return }

        timerStates[type]?.timer?.invalidate()

        let firstFire = TimeInterval(intervalMinutes * 60) + initialOffset
        scheduleNext(for: type, delay: firstFire, intervalMinutes: intervalMinutes, settings: settings)
    }

    private func resumeTimer(for type: ReminderType, remaining: TimeInterval, intervalMinutes: Int, settings: AppSettings) {
        scheduleNext(for: type, delay: remaining, intervalMinutes: intervalMinutes, settings: settings)
    }

    private func scheduleNext(for type: ReminderType, delay: TimeInterval, intervalMinutes: Int, settings: AppSettings) {
        guard !(timerStates[type]?.isPaused ?? false) else { return }

        let fireDate = Date().addingTimeInterval(delay)

        let timer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.timerFired(for: type, settings: settings)
                let nextInterval = TimeInterval(intervalMinutes * 60)
                self.scheduleNext(for: type, delay: nextInterval, intervalMinutes: intervalMinutes, settings: settings)
            }
        }

        RunLoop.main.add(timer, forMode: .common)

        timerStates[type] = TimerState(
            isActive: true,
            fireDate: fireDate,
            timer: timer,
            intervalMinutes: intervalMinutes
        )
    }

    private func stopTimer(for type: ReminderType) {
        timerStates[type]?.timer?.invalidate()
        timerStates[type] = TimerState()
    }

    /// Tracks when the last notification was actually delivered to coalesce nearby ones.
    private var lastNotificationDate: Date = .distantPast

    private func timerFired(for type: ReminderType, settings: AppSettings) {
        // Update the fire date for the next cycle
        let interval = TimeInterval((timerStates[type]?.intervalMinutes ?? type.defaultIntervalMinutes) * 60)
        timerStates[type]?.fireDate = Date().addingTimeInterval(interval)

        // Coalesce: if another notification fired very recently, delay briefly
        let now = Date()
        let sinceLastNotification = now.timeIntervalSince(lastNotificationDate)
        let delay: TimeInterval = sinceLastNotification < coalescingGap ? coalescingGap - sinceLastNotification : 0

        Task {
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            let message: String
            if settings.llmEnabled && llmService.isModelReady {
                message = await llmService.generateMessage(for: type, tone: settings.llmTone, customPrompt: settings.customPrompt)
            } else {
                message = type.fallbackMessages.randomElement()!
            }

            var body = message
            if settings.showHealthFacts, let entry = type.healthFacts.randomElement() {
                body += "\n\n\(entry.fact)"
            }

            self.lastNotificationDate = Date()

            let displayMode = settings.reminderSettings(for: type).displayMode
            deliverReminder(type: type, message: body, mode: displayMode, settings: settings)
        }
    }

    private func deliverReminder(type: ReminderType, message: String, mode: ReminderDisplayMode, settings: AppSettings) {
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

    // MARK: - Test / Manual trigger

    func triggerTestNotification(type: ReminderType, settings: AppSettings) {
        Task {
            let message: String
            if settings.llmEnabled && llmService.isModelReady {
                message = await llmService.generateMessage(for: type, tone: settings.llmTone, customPrompt: settings.customPrompt)
            } else {
                message = type.fallbackMessages.randomElement()!
            }

            var body = message
            if settings.showHealthFacts, let entry = type.healthFacts.randomElement() {
                body += "\n\n\(entry.fact)"
            }

            let displayMode = settings.reminderSettings(for: type).displayMode
            deliverReminder(type: type, message: body, mode: displayMode, settings: settings)
        }
    }
}
