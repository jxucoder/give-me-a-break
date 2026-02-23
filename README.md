<p align="center">
  <img src="assets/logo.png" alt="Give Me A Break" width="128">
</p>

<h1 align="center">Give Me A Break</h1>

<p align="center">
  A lightweight macOS menu bar app that reminds you to take breaks, fix your posture, and alternate between standing and sitting — so you don't have to think about it.
</p>

<p align="center">
  <a href="https://jxucoder.github.io/give-me-a-break/">Website</a> &nbsp;·&nbsp;
  <a href="https://github.com/jxucoder/give-me-a-break/releases/latest">Download</a> &nbsp;·&nbsp;
  <a href="https://github.com/jxucoder/give-me-a-break/releases">Changelog</a>
</p>

<p align="center">
  <img src="assets/screenshot.png" alt="Give Me A Break in action" width="700">
</p>

## Why?

Sitting at a desk all day is terrible for your body. Studies from the CDC show that prolonged sitting increases risk of cardiovascular disease, chronic pain, and fatigue — even if you exercise regularly. The fix is simple: take short breaks, check your posture, and switch positions throughout the day.

**Give Me A Break** lives in your menu bar and quietly reminds you to do all three.

## What It Does

- **Take a Break** — Reminds you to step away from the screen, rest your eyes, and stretch
- **Check Posture** — Nudges you to sit up straight, relax your shoulders, and unclench your jaw
- **Stand / Sit** — Prompts you to alternate between standing and sitting at your desk

Each reminder runs on its own independent timer with its own interval (5 min to 2 hours). Pause, reset, or adjust any of them directly from the menu bar — no need to open a settings window.

## Install

### Download (recommended)

1. Go to the [Releases page](https://github.com/jxucoder/give-me-a-break/releases/latest) or visit the [website](https://jxucoder.github.io/give-me-a-break/)
2. Download `GiveMeABreak-x.x.x.zip`
3. Unzip and drag **Give Me A Break.app** to your Applications folder
4. Open it — the app appears in your menu bar (the teacup icon)

The app checks for updates automatically via [Sparkle](https://sparkle-project.org/). You can also check manually in Settings > General > Check for Updates.

### Homebrew (coming soon)

```bash
brew install --cask give-me-a-break
```

### Build from source

```bash
git clone https://github.com/jxucoder/give-me-a-break.git
cd give-me-a-break/GiveMeABreak
xcodebuild -scheme GiveMeABreak -configuration Release
```

Or open `GiveMeABreak/GiveMeABreak.xcodeproj` in Xcode and hit Run.

**Requires:** macOS 14 (Sonoma) or later, Xcode 16+

## Features

| Feature | Details |
|---|---|
| Three independent timers | Break, Posture, Stand/Sit — each with its own interval and controls |
| Menu bar controls | Pause, resume, reset, and adjust intervals without leaving your workflow |
| Smart notifications | macOS notifications with snooze options (5, 10, or 15 min) |
| AI-generated messages | Optional on-device Apple Intelligence for varied, natural reminder text (macOS 26+) |
| Health facts | Optional CDC-sourced health facts included in notifications |
| Auto-updates | Built-in Sparkle updater notifies you when a new version is available |
| Launch at login | Start automatically with your Mac |
| Privacy-first | Everything runs locally. No accounts, no tracking, no data collection |

## Settings

Open **Settings** from the menu bar dropdown to configure:

- **General** — Launch at login, notification sounds, health facts, check for updates
- **AI Messages** — Enable Apple Intelligence, pick a tone (friendly, humorous, professional, motivational), or write your own custom prompt

## Privacy

Give Me A Break does not collect any data. All settings are stored locally in `UserDefaults`. The only network request the app makes is checking for updates via the [appcast feed](https://jxucoder.github.io/give-me-a-break/appcast.xml). If you enable AI-generated messages, they are processed entirely on-device using Apple's Foundation Models framework.

## License

Apache License 2.0 — see [LICENSE](LICENSE) for details.
