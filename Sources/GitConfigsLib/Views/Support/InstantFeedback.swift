import AppKit
import SwiftUI

enum InstantFeedback {
    /// Immediate "click accepted" ack (haptic). Call on the main actor before starting work.
    @MainActor
    static func acknowledge() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .generic,
            performanceTime: .now
        )
    }

    /// Sets busy state, yields so SwiftUI can paint, then runs `work`.
    @MainActor
    static func runAfterPaint(_ work: @escaping @MainActor () async -> Void) {
        Task { @MainActor in
            await Task.yield()
            await work()
        }
    }
}

/// Subtle scale/opacity on press so the control reacts in the same frame as the click.
struct InstantPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

extension View {
    func instantPress() -> some View {
        buttonStyle(InstantPressButtonStyle())
    }
}
