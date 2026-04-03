import SwiftUI

@main
struct GitConfigUIApp: App {
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
