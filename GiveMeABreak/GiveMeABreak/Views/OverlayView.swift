import SwiftUI

struct OverlayView: View {
    @ObservedObject var manager: OverlayManager

    var body: some View {
        Group {
            switch manager.currentMode {
            case .banner:
                bannerView
            case .fullscreen:
                fullscreenView
            case .notification:
                EmptyView()
            }
        }
        .opacity(manager.isVisible ? 1 : 0)
        .scaleEffect(manager.isVisible ? 1 : 0.95)
    }

    // MARK: - Banner

    private var bannerView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                if let type = manager.currentType {
                    ZStack {
                        Circle()
                            .fill(type.tintColor.opacity(0.15))
                        Image(systemName: type.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(type.tintColor)
                    }
                    .frame(width: 40, height: 40)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(manager.currentType?.displayName ?? "Reminder")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(manager.currentMessage)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(3)
                }

                Spacer()
            }

            HStack {
                Text("Dismissing in \(manager.secondsRemaining)s")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                Button(action: { manager.dismiss() }) {
                    Text("Dismiss")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.2))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(width: 420)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Fullscreen

    private var fullscreenView: some View {
        ZStack {
            Color.black.opacity(manager.isVisible ? 0.45 : 0)
                .ignoresSafeArea()
                .onTapGesture { manager.dismiss() }

            VStack(spacing: 24) {
                if let type = manager.currentType {
                    ZStack {
                        Circle()
                            .fill(type.tintColor.opacity(0.2))
                        Circle()
                            .trim(from: 0, to: countdownProgress)
                            .stroke(type.tintColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: manager.secondsRemaining)
                        Image(systemName: type.icon)
                            .font(.system(size: 32))
                            .foregroundStyle(type.tintColor)
                    }
                    .frame(width: 80, height: 80)

                    Text(type.displayName)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                }

                Text(manager.currentMessage)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)

                Text("Dismissing in \(manager.secondsRemaining)s")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))

                Button(action: { manager.dismiss() }) {
                    Text("I'm on it!")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(manager.currentType?.tintColor ?? .teal)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var countdownProgress: Double {
        let total = Double(SettingsViewModel.shared.settings.overlayDismissSeconds)
        guard total > 0 else { return 0 }
        return Double(manager.secondsRemaining) / total
    }
}
