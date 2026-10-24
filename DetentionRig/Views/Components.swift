import DetentionCore
import SwiftUI

extension Tone {
    var color: Color {
        switch self {
        case .red: .red
        case .amber: .accentColor
        case .blue: .blue
        case .green: .green
        }
    }
}

/// A tinted rounded square holding an SF Symbol, used at the start of rows and tiles.
struct IconBadge: View {
    let symbol: String
    var tone: Tone = .amber
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(tone.color)
            .frame(width: size, height: size)
            .background(tone.color.opacity(0.14), in: .rect(cornerRadius: size * 0.3))
            .accessibilityHidden(true)
    }
}

struct StatusPill: View {
    let text: String
    let tone: Tone

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tone.color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(tone.color.opacity(0.14), in: .capsule)
    }
}

/// Small uppercase label above a value, like DRIVER or NEW LOAD.
struct Eyebrow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .textCase(.uppercase)
            .tracking(0.6)
            .foregroundStyle(.secondary)
    }
}

/// A pulsing dot with a status line. Turns green and stops pulsing once the truck has left.
struct PulseLabel: View {
    let text: String
    let stopped: Bool

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: "circle.fill")
                .font(.system(size: 7))
                .symbolEffect(.pulse, isActive: !stopped)
        }
        .font(.caption.weight(.semibold))
        .textCase(.uppercase)
        .tracking(0.6)
        .foregroundStyle(stopped ? .green : .red)
    }
}

/// Card surface for grouped content outside a List.
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 22))
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}

/// Floating confirmation that slides in from the top.
struct ToastOverlay: ViewModifier {
    let message: String?

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let message {
                Label(message, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .symbolRenderingMode(.multicolor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .glassEffect(.regular, in: .capsule)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.3), value: message)
    }
}
