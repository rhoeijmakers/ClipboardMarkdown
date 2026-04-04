import SwiftUI

struct ContentView: View {
    var body: some View {
        Button("Save Clipboard as Markdown") {
            ClipboardManager.saveClipboardAsMarkdown()
        }
        .keyboardShortcut("s", modifiers: [.command, .shift])

        Divider()

        Button("Open Downloads Folder") {
            if let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                NSWorkspace.shared.open(downloads)
            }
        }

        Divider()

        Button("About ClipboardMarkdown") {
            showAbout()
        }

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func showAbout() {
        let credits = NSAttributedString(
            string: "Built by Rob Hoeijmakers",
            attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)]
        )
        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            .credits: credits,
            .applicationName: "ClipboardMarkdown",
            .applicationVersion: "1.0",
            .version: ""
        ])
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
