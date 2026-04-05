import GitConfigsLib
import SwiftUI

@main
struct GitConfigsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 680, height: 500)
    }
}
