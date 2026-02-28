import AppKit
import SwiftUI
import os.log

@MainActor
final class OverlayManager: ObservableObject {
    static let shared = OverlayManager()

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.givemeabreak.app", category: "OverlayManager")

    @Published var isShowing = false
    @Published var isVisible = false
    @Published var currentType: ReminderType?
    @Published var currentMessage: String = ""
    @Published var currentMode: ReminderDisplayMode = .banner
    @Published var secondsRemaining: Int = 30

    private var panel: NSPanel?
    private var countdownTimer: Timer?

    private init() {}

    func showOverlay(type: ReminderType, message: String, mode: ReminderDisplayMode, dismissSeconds: Int, playSound: Bool) {
        countdownTimer?.invalidate()
        countdownTimer = nil
        panel?.orderOut(nil)
        panel = nil
        isShowing = false
        isVisible = false

        currentType = type
        currentMessage = message
        currentMode = mode
        secondsRemaining = dismissSeconds
        isShowing = true

        if playSound {
            NSSound.beep()
        }

        let overlayView = OverlayView(manager: self)

        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = mode == .banner
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.contentView = NSHostingView(rootView: overlayView)

        guard let screen = NSScreen.main else {
            Self.logger.error("No main screen available for overlay")
            return
        }

        switch mode {
        case .banner:
            panel.level = .floating
            let width: CGFloat = 420
            let height: CGFloat = 180
            let x = screen.frame.midX - width / 2
            let y = screen.frame.maxY - height - 60
            panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)

        case .fullscreen:
            panel.level = .screenSaver
            panel.setFrame(screen.frame, display: true)

        case .notification:
            return
        }

        panel.alphaValue = 1
        panel.orderFrontRegardless()
        self.panel = panel

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.isVisible = true
            }
            self.startCountdown()
        }
    }

    func dismiss() {
        countdownTimer?.invalidate()
        countdownTimer = nil

        withAnimation(.easeIn(duration: 0.2)) {
            isVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.panel?.orderOut(nil)
            self?.panel = nil
            self?.isShowing = false
            self?.currentType = nil
            self?.currentMessage = ""
        }
    }

    private func startCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.secondsRemaining -= 1
                if self.secondsRemaining <= 0 {
                    self.dismiss()
                }
            }
        }
        RunLoop.main.add(countdownTimer!, forMode: .common)
    }
}
