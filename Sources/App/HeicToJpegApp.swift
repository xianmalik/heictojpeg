import SwiftUI

@main
struct HeicToJpegApp: App {
    var body: some Scene {
        Window("HEIC to JPEG", id: "main") {
            ContentView()
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 820, height: 660)
    }
}
