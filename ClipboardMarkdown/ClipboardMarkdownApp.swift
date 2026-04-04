import SwiftUI

@main
struct ClipboardMarkdownApp: App {
    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            Image(systemName: "doc.on.clipboard")
        }
        .menuBarExtraStyle(.menu)
    }
}
