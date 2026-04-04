import AppKit

enum RTFToMarkdown {

    static func convert(from pasteboard: NSPasteboard) -> String? {
        guard let data = pasteboard.data(forType: .rtf),
              let attr = NSAttributedString(rtf: data, documentAttributes: nil)
        else { return nil }

        let bodySize = dominantFontSize(in: attr)
        let fullRange = NSRange(location: 0, length: attr.length)
        var result = ""

        // Process paragraph by paragraph
        (attr.string as NSString).enumerateSubstrings(
            in: fullRange,
            options: .byParagraphs
        ) { substring, substringRange, _, _ in
            guard let raw = substring, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                result += "\n"
                return
            }

            // Paragraph-level attributes (use midpoint of paragraph for reliability)
            let mid = NSRange(location: substringRange.location + substringRange.length / 2, length: 0)
            let paraStyle = attr.attribute(.paragraphStyle, at: max(substringRange.location, 0), effectiveRange: nil) as? NSParagraphStyle
            let font = attr.attribute(.font, at: max(substringRange.location, 0), effectiveRange: nil) as? NSFont
            _ = mid

            let fontSize = font?.pointSize ?? bodySize
            let isBold = font?.fontDescriptor.symbolicTraits.contains(.bold) ?? false
            let isList = !(paraStyle?.textLists ?? []).isEmpty
            let listLevel = paraStyle?.textLists.count ?? 0

            if isList {
                // Strip leading bullet/number chars inserted by RTF listtext group
                let cleaned = stripBulletPrefix(raw)
                let indent = listLevel > 1 ? String(repeating: "  ", count: listLevel - 1) : ""
                result += "\(indent)- \(cleaned)\n"
            } else if let level = headingLevel(for: fontSize, bodySize: bodySize, isBold: isBold) {
                let hashes = String(repeating: "#", count: level)
                let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                result += "\n\(hashes) \(text)\n\n"
            } else {
                // Inline formatting: enumerate runs within the paragraph
                let inlineResult = inlineMarkdown(for: attr, in: substringRange, bodySize: bodySize)
                result += "\(inlineResult)\n"
            }
        }

        var cleaned = result

        // Pages RTF emits the bullet marker and its content as two separate
        // paragraphs. This collapses "- \n\n<content>" → "- <content>".
        if let regex = try? NSRegularExpression(pattern: #"(?m)^([ \t]*)- $\n\n?"#) {
            cleaned = regex.stringByReplacingMatches(
                in: cleaned,
                range: NSRange(cleaned.startIndex..., in: cleaned),
                withTemplate: "$1- "
            )
        }

        // Collapse excessive blank lines
        while cleaned.contains("\n\n\n") {
            cleaned = cleaned.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Inline formatting within a paragraph

    private static func inlineMarkdown(for attr: NSAttributedString, in range: NSRange, bodySize: CGFloat) -> String {
        var result = ""
        attr.enumerateAttributes(in: range, options: []) { attributes, runRange, _ in
            var text = (attr.string as NSString).substring(with: runRange)
            text = text.trimmingCharacters(in: .newlines)
            guard !text.isEmpty else { return }

            let font = attributes[.font] as? NSFont
            let isBold = font?.fontDescriptor.symbolicTraits.contains(.bold) ?? false
            let isItalic = font?.fontDescriptor.symbolicTraits.contains(.italic) ?? false

            if isBold && isItalic {
                result += "***\(text)***"
            } else if isBold {
                result += "**\(text)**"
            } else if isItalic {
                result += "*\(text)*"
            } else {
                result += text
            }
        }
        return result
    }

    // MARK: - Helpers

    private static func stripBulletPrefix(_ text: String) -> String {
        // RTF listtext groups insert bullet chars + tabs before actual content.
        // Common patterns: "• text", "\t•\ttext", "1.\ttext", "-\ttext"
        var s = text
        // Strip leading whitespace and tabs
        s = s.drop(while: { $0 == "\t" || $0 == " " }).description
        // Strip bullet characters (•, ‣, ◦, ▪, ▸, *, -)
        let bullets: [Character] = ["•", "‣", "◦", "▪", "▸", "→", "*", "-"]
        if let first = s.first, bullets.contains(first) {
            s = String(s.dropFirst())
        }
        // Strip numbering like "1." or "1)"
        if let match = s.range(of: #"^\d+[.)]\s?"#, options: .regularExpression) {
            s = String(s[match.upperBound...])
        }
        // Strip remaining leading whitespace/tabs
        s = s.drop(while: { $0 == "\t" || $0 == " " }).description
        return s.trimmingCharacters(in: .newlines)
    }

    private static func dominantFontSize(in attr: NSAttributedString) -> CGFloat {
        var sizeCounts: [CGFloat: Int] = [:]
        attr.enumerateAttribute(.font, in: NSRange(location: 0, length: attr.length)) { value, range, _ in
            if let font = value as? NSFont {
                sizeCounts[font.pointSize, default: 0] += range.length
            }
        }
        return sizeCounts.max(by: { $0.value < $1.value })?.key ?? 12
    }

    private static func headingLevel(for size: CGFloat, bodySize: CGFloat, isBold: Bool) -> Int? {
        let ratio = size / bodySize
        switch ratio {
        case 2.0...:     return 1
        case 1.6..<2.0:  return 2
        case 1.3..<1.6:  return 3
        case 1.1..<1.3:  return isBold ? 4 : nil
        default:         return nil
        }
    }
}
