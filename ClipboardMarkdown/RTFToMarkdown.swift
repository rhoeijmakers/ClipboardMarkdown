import AppKit

enum RTFToMarkdown {

    static func convert(from pasteboard: NSPasteboard) -> String? {
        guard let data = pasteboard.data(forType: .rtf),
              let attr = NSAttributedString(rtf: data, documentAttributes: nil)
        else { return nil }

        // Determine the dominant (body) font size
        let bodySize = dominantFontSize(in: attr)

        var result = ""
        var previousWasBlock = false

        attr.enumerateAttributes(
            in: NSRange(location: 0, length: attr.length),
            options: []
        ) { attributes, range, _ in
            let substring = (attr.string as NSString).substring(with: range)

            guard !substring.isEmpty else { return }

            let font = attributes[.font] as? NSFont
            let fontSize = font?.pointSize ?? bodySize
            let isBold = font?.fontDescriptor.symbolicTraits.contains(.bold) ?? false
            let isItalic = font?.fontDescriptor.symbolicTraits.contains(.italic) ?? false

            // Headings: text significantly larger than body, or bold at a larger size
            let headingLevel = headingLevel(for: fontSize, bodySize: bodySize, isBold: isBold)

            var text = substring

            if let level = headingLevel {
                let hashes = String(repeating: "#", count: level)
                let line = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !line.isEmpty {
                    if !result.isEmpty && !result.hasSuffix("\n\n") {
                        result += "\n\n"
                    }
                    result += "\(hashes) \(line)\n\n"
                    previousWasBlock = true
                }
            } else {
                // Apply inline formatting
                if isBold && isItalic {
                    text = wrapIfNotWhitespace(text, with: "***")
                } else if isBold {
                    text = wrapIfNotWhitespace(text, with: "**")
                } else if isItalic {
                    text = wrapIfNotWhitespace(text, with: "*")
                }
                result += text
                previousWasBlock = false
            }
        }

        // Clean up excessive blank lines
        var cleaned = result
        while cleaned.contains("\n\n\n") {
            cleaned = cleaned.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Helpers

    private static func dominantFontSize(in attr: NSAttributedString) -> CGFloat {
        var sizeCounts: [CGFloat: Int] = [:]
        attr.enumerateAttribute(.font, in: NSRange(location: 0, length: attr.length)) { value, range, _ in
            if let font = value as? NSFont {
                let size = font.pointSize
                sizeCounts[size, default: 0] += range.length
            }
        }
        return sizeCounts.max(by: { $0.value < $1.value })?.key ?? 12
    }

    private static func headingLevel(for size: CGFloat, bodySize: CGFloat, isBold: Bool) -> Int? {
        let ratio = size / bodySize
        switch ratio {
        case 2.0...:      return 1
        case 1.6..<2.0:   return 2
        case 1.3..<1.6:   return 3
        case 1.1..<1.3:   return isBold ? 4 : nil
        default:          return nil
        }
    }

    private static func wrapIfNotWhitespace(_ text: String, with marker: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return text }

        // Preserve leading/trailing whitespace outside the markers
        let leading = String(text.prefix(while: { $0 == " " }))
        let trailing = String(text.reversed().prefix(while: { $0 == " " }).reversed())
        return "\(leading)\(marker)\(trimmed)\(marker)\(trailing)"
    }
}
