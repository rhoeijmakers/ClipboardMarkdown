import AppKit
import UserNotifications

enum ClipboardManager {

    static func saveClipboardAsMarkdown() {
        let pasteboard = NSPasteboard.general
        let text: String

        let plain = pasteboard.string(forType: .string)
        let html = pasteboard.string(forType: .init("public.html"))

        if let html, !html.isEmpty, htmlHasStructure(html) {
            text = HTMLToMarkdown.convert(html)
        } else if let rtf = RTFToMarkdown.convert(from: pasteboard), !rtf.isEmpty {
            text = rtf
        } else if let plain, !plain.isEmpty {
            text = plain
        } else {
            notify(title: "Clipboard is leeg", body: "Geen tekst gevonden op het klembord.")
            return
        }

        guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            notify(title: "Fout", body: "Downloads-map is niet bereikbaar.")
            return
        }

        let filename = generateFilename()
        let fileURL = resolveConflict(url: downloadsURL.appendingPathComponent(filename))

        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            notify(title: "Opgeslagen", body: fileURL.lastPathComponent, filePath: fileURL.path)
        } catch {
            notify(title: "Fout bij opslaan", body: error.localizedDescription)
        }
    }

    /// Returns true only if the HTML contains meaningful structure worth converting:
    /// headings, code blocks, lists, or links. Plain prose wrapped in <div> or <p>
    /// is better served by the plain text version from the clipboard.
    private static func htmlHasStructure(_ html: String) -> Bool {
        let patterns = [
            "<h[1-6][^>]*>",           // headings
            "<pre[^>]*>",              // code blocks
            "<code[^>]*>",             // inline code
            "<[uo]l[^>]*>",            // lists
            "<a\\s[^>]*href=",         // links
        ]
        let lower = html.lowercased()
        return patterns.contains { pattern in
            (try? NSRegularExpression(pattern: pattern, options: .caseInsensitive))?
                .firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)) != nil
        }
    }

    private static func generateFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return "\(formatter.string(from: Date())).md"
    }

    private static func resolveConflict(url: URL) -> URL {
        guard FileManager.default.fileExists(atPath: url.path) else { return url }
        let name = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        let dir = url.deletingLastPathComponent()
        var n = 2
        while true {
            let candidate = dir.appendingPathComponent("\(name) (\(n)).\(ext)")
            if !FileManager.default.fileExists(atPath: candidate.path) { return candidate }
            n += 1
        }
    }

    private static func notify(title: String, body: String, filePath: String? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            if let filePath { content.userInfo = ["filePath": filePath] }
            center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
    }
}
