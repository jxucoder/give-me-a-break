<p align="center">
  <img src="assets/logo.png" alt="Give Me A Break" width="200">
</p>

<h1 align="center">Give Me A Break</h1>

<p align="center">A lightweight macOS menu bar app that reminds you to take breaks, check your posture, and switch between standing and sitting throughout the day.</p>

## Features

- **Three reminder types** — Break, Posture Check, and Stand/Sit, each independently configurable
- **Per-timer controls** — Pause, reset, and adjust intervals directly from the menu bar
- **Adjustable intervals** — 5 minutes to 2 hours via inline sliders
- **AI-generated messages** — Optional on-device Apple Intelligence integration for varied, natural reminder text
- **Custom prompts** — Define your own prompt to personalize AI-generated messages
- **Notification artwork** — Unique illustrations for each reminder type
- **Launch at login** — Start automatically with your Mac
- **Minimal footprint** — Display timer only runs when the menu is open; near-zero CPU when idle

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16+ to build
- Apple Silicon or Intel Mac
- Apple Intelligence enabled (optional, for AI-generated messages — requires macOS 26+)

## Building

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/give-me-a-break.git
cd give-me-a-break

# Build and run
./run.sh

# Or rebuild from scratch
./run.sh --rebuild
```

Alternatively, open `GiveMeABreak/GiveMeABreak.xcodeproj` in Xcode and hit Run.

## Architecture

```
GiveMeABreak/
├── App/
│   ├── GiveMeABreakApp.swift      # @main entry, MenuBarExtra
│   └── AppDelegate.swift          # Notification delegate
├── Models/
│   ├── AppSettings.swift          # Settings model + LLM tone enum
│   └── ReminderType.swift         # Break/Posture/StandSit definitions
├── Services/
│   ├── NotificationService.swift  # UNUserNotificationCenter wrapper
│   ├── ReminderScheduler.swift    # Per-timer scheduling with pause/resume
│   └── LLMService.swift           # Apple Intelligence message generation
├── ViewModels/
│   ├── MenuBarViewModel.swift     # Menu bar state, visibility-gated updates
│   └── SettingsViewModel.swift    # Settings persistence via UserDefaults
├── Views/
│   ├── MenuBarView.swift          # Menu bar dropdown UI
│   ├── SettingsView.swift         # Settings window (tabs)
│   ├── GeneralSettingsView.swift  # General preferences
│   └── LLMSettingsView.swift      # AI message configuration
└── Resources/
    └── Assets.xcassets/           # App icon + notification artwork
```

## How It Works

The app runs as a menu bar extra (`LSUIElement`). Each reminder type has its own independent timer managed by `ReminderScheduler`. When a timer fires, it generates a message (via Apple Intelligence or from built-in fallbacks) and delivers it as a macOS notification with artwork.

The display timer that updates countdowns only runs while the menu popover is visible, keeping CPU usage near zero when idle.

## Configuration

All settings persist via `UserDefaults`:

- **Intervals** — Adjust per-timer from the menu bar (gear icon)
- **Sounds** — Toggle notification sounds in Settings > General
- **AI Messages** — Enable in Settings > AI Messages, pick a tone or write a custom prompt
- **Launch at Login** — Toggle in Settings > General

## License

Apache License 2.0. See [LICENSE](LICENSE) for details.
