import AppKit
import SwiftUI

enum BrandLogo {
    /// Loads the in-app logo: SwiftPM resource bundle first, then the host app asset catalog (`AppLogo`).
    static func nsImage() -> NSImage? {
        if let url = Bundle.module.url(forResource: "AppLogo", withExtension: "png"),
           let image = NSImage(contentsOf: url),
           image.isValid {
            return image
        }
        if let image = NSImage(named: "AppLogo"), image.isValid {
            return image
        }
        return nil
    }
}
