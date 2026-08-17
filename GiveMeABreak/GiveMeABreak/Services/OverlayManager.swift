import AppKit
import SwiftUI
import os.log

@MainActor
final class OverlayManager: ObservableObject {
    static let shared = OverlayManager()

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.givemeabreak.app", category: "OverlayManager")
    private static let escapeKeyCode: UInt16 = 53

    @Published var isShowing = false
    @Published var isVisible = false
    @Published var currentType: ReminderType?
    @Published var currentMessage: String = ""
    @Published var currentMode: ReminderDisplayMode = .banner
    @Published var secondsRemaining: Int = 30

    private var panels: [NSPanel] = []
    private var countdownTimer: Timer?
    private var keyMonitor: Any?

    private init() {}

    func showOverlay(type: ReminderType, message: String, mode: ReminderDisplayMode, dismissSeconds: Int, playSound: Bool) {
        tearDown(animated: false)

        currentType = type
        currentMessage = message
        currentMode = mode
        secondsRemaining = dismissSeconds
        isShowing = true

        if playSound {
            NSSound.beep()
        }

        let screens: [NSScreen]
        switch mode {
        case .banner:
            screens = [Self.screenUnderMouse()].compactMap { $0 }
        case .fullscreen:
            screens = NSScreen.screens
        case .notification:
            isShowing = false
            return
        }

        guard !screens.isEmpty else {
            Self.logger.error("No screen available for overlay")
            isShowing = false
            currentType = nil
            currentMessage = ""
            return
        }

        for screen in screens {
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
                continue
            }

            panel.alphaValue = 1
            panel.orderFrontRegardless()
            panels.append(panel)
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == Self.escapeKeyCode {
                Task { @MainActor in
                    OverlayManager.shared.dismiss()
                }
                return nil
            }
            return event
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.isVisible = true
            }
            self.startCountdown()
        }
    }

    func dismiss() {
        tearDown(animated: true)
    }

    private func tearDown(animated: Bool) {
        countdownTimer?.invalidate()
        countdownTimer = nil

        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }

        let finish = { [weak self] in
            guard let self else { return }
            for panel in self.panels {
                panel.orderOut(nil)
            }
            self.panels = []
            self.isShowing = false
            self.isVisible = false
            self.currentType = nil
            self.currentMessage = ""
        }

        if animated && isShowing {
            withAnimation(.easeIn(duration: 0.2)) {
                isVisible = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: finish)
        } else {
            finish()
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

    private static func screenUnderMouse() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
    }
}
