import SwiftUI

@main
struct GitToggleUserUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 500)
    }
}
