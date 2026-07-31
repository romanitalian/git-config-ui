import SwiftUI

private struct BusyOverlayModifier: ViewModifier {
    let isBusy: Bool
    var dimsContent: Bool = true

    func body(content: Content) -> some View {
        content
            .opacity(isBusy && dimsContent ? 0.65 : 1)
            .allowsHitTesting(!isBusy)
            .overlay(alignment: .trailing) {
                if isBusy {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 4)
                }
            }
    }
}

extension View {
    func busyOverlay(_ isBusy: Bool, dimsContent: Bool = true) -> some View {
        modifier(BusyOverlayModifier(isBusy: isBusy, dimsContent: dimsContent))
    }
}

struct BusyButtonLabel<Content: View>: View {
    let isBusy: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        if isBusy {
            ProgressView()
                .controlSize(.small)
        } else {
            content()
        }
    }
}
