import SwiftUI

/// Temporary layout debug overlays. Set `enabled = false` when done inspecting.
enum UIDebug {
    static let enabled = false

    static let global = Color.red
    static let name = Color.orange
    static let email = Color.yellow
    static let repository = Color.green
    static let actions = Color.purple
    static let row = Color.blue
    static let header = Color.cyan
    static let list = Color.pink
    static let toolbar = Color.mint
    static let actionButton = Color.indigo
}

extension View {
    /// Draws a 1pt border when `UIDebug.enabled` is true.
    func debugBorder(_ color: Color, width: CGFloat = 1) -> some View {
        overlay {
            if UIDebug.enabled {
                Rectangle()
                    .strokeBorder(color, lineWidth: width)
            }
        }
    }
}
