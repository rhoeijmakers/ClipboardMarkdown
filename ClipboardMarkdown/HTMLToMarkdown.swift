import Foundation

enum HTMLToMarkdown {

    static func convert(_ html: String) -> String {
        var s = html

        // 1. Fenced code blocks first — protect inner content from later rules
        s = convertCodeBlocks(s)

        // 2. Headings
        for level in (1...6).reversed() {
            let hashes = String(repeating: "#", count: level)
            s = replaceAll(s, pattern: "<h\(level)[^>]*>", with: "\n\(hashes) ")
            s = s.replacingOccurrences(of: "</h\(level)>", with: "\n")
        }

        // 3. Bold / italic
        s = replaceAll(s, pattern: "<strong[^>]*>|<b[^>]*>", with: "**")
        s = s.replacingOccurrences(of: "</strong>", with: "**")
        s = s.replacingOccurrences(of: "</b>", with: "**")
        s = replaceAll(s, pattern: "<em[^>]*>|<i[^>]*>", with: "*")
        s = s.replacingOccurrences(of: "</em>", with: "*")
        s = s.replacingOccurrences(of: "</i>", with: "*")

        // 4. Inline code (after code blocks)
        s = replaceAll(s, pattern: "<code[^>]*>", with: "`")
        s = s.replacingOccurrences(of: "</code>", with: "`")

        // 5. Links — process in reverse to keep ranges valid
        s = convertLinks(s)

        // 6. Ordered lists — process in reverse to keep ranges valid
        s = convertOrderedLists(s)

        // 7. Unordered list items
        s = replaceAll(s, pattern: "<li[^>]*>", with: "\n- ")
        s = s.replacingOccurrences(of: "</li>", with: "")
        s = replaceAll(s, pattern: "</?[uo]l[^>]*>", with: "\n")

        // 8. Block-level elements → paragraph breaks
        //    Covers <p>, <div>, <section>, <article> and their closing tags
        s = replaceAll(s, pattern: #"</?(?:div|section|article|header|footer|main|aside)[^>]*>"#, with: "\n\n")
        s = replaceAll(s, pattern: "<p[^>]*>", with: "\n\n")
        s = s.replacingOccurrences(of: "</p>", with: "\n\n")
        s = replaceAll(s, pattern: "<br\\s*/?>", with: "\n")

        // 9. Horizontal rule
        s = replaceAll(s, pattern: "<hr[^>]*>", with: "\n\n---\n\n")

        // 10. Strip all remaining tags
        s = replaceAll(s, pattern: "<[^>]+>", with: "")

        // 11. HTML entities
        s = decodeEntities(s)

        // 12. Remove LinkedIn-style internal Markdown escape artifacts (\* \** \*\*)
        //     These are literal characters in the HTML, not actual formatting
        s = replaceAll(s, pattern: #"\\[*_]"#, with: "")

        // 13. Collapse empty bold/italic markers left over after cleanup
        s = replaceAll(s, pattern: #"\*{2,}"#, with: "")

        // 14. Collapse excessive blank lines
        s = replaceAll(s, pattern: "\n{3,}", with: "\n\n")

        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Code blocks

    private static func convertCodeBlocks(_ html: String) -> String {
        let pattern = #"<pre[^>]*>(\s*<code(?:[^>]*class="[^"]*language-([^"\s]+)[^"]*")?[^>]*>)?([\s\S]*?)(</code>\s*)?</pre>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return html }

        var result = html
        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))

        for match in matches.reversed() {
            guard let matchRange = Range(match.range, in: html) else { continue }

            let lang = Range(match.range(at: 2), in: html).map { String(html[$0]) } ?? ""
            let code = Range(match.range(at: 3), in: html).map { String(html[$0]) } ?? ""
            let cleaned = decodeEntities(replaceAll(code, pattern: "<[^>]+>", with: ""))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let block = "\n```\(lang)\n\(cleaned)\n```\n"

            // Translate original range to current result string
            if let resultRange = translateRange(matchRange, from: html, to: result) {
                result.replaceSubrange(resultRange, with: block)
            }
        }
        return result
    }

    // MARK: - Ordered lists

    private static func convertOrderedLists(_ html: String) -> String {
        let pattern = #"<ol[^>]*>([\s\S]*?)</ol>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return html }

        var result = html
        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))

        for match in matches.reversed() {
            guard let matchRange = Range(match.range, in: html),
                  let innerRange = Range(match.range(at: 1), in: html) else { continue }

            let inner = String(html[innerRange])
            var converted = "\n"
            var counter = 0

            let liPattern = #"<li[^>]*>([\s\S]*?)</li>"#
            if let liRegex = try? NSRegularExpression(pattern: liPattern, options: .caseInsensitive) {
                let liMatches = liRegex.matches(in: inner, range: NSRange(inner.startIndex..., in: inner))
                for li in liMatches {
                    let content = Range(li.range(at: 1), in: inner).map { String(inner[$0]) } ?? ""
                    counter += 1
                    converted += "\(counter). \(content)\n"
                }
            }
            converted += "\n"

            if let resultRange = translateRange(matchRange, from: html, to: result) {
                result.replaceSubrange(resultRange, with: converted)
            }
        }
        return result
    }

    // MARK: - Links

    private static func convertLinks(_ html: String) -> String {
        let pattern = #"<a\s[^>]*href="([^"]*)"[^>]*>([\s\S]*?)</a>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return html }

        var result = html
        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))

        for match in matches.reversed() {
            guard let matchRange = Range(match.range, in: html),
                  let urlRange = Range(match.range(at: 1), in: html),
                  let textRange = Range(match.range(at: 2), in: html) else { continue }

            let url = String(html[urlRange])
            let rawText = String(html[textRange])
            let text = replaceAll(rawText, pattern: "<[^>]+>", with: "").trimmingCharacters(in: .whitespaces)
            let md = text.isEmpty ? url : "[\(text)](\(url))"

            if let resultRange = translateRange(matchRange, from: html, to: result) {
                result.replaceSubrange(resultRange, with: md)
            }
        }
        return result
    }

    // MARK: - Helpers

    /// Translates a Range from the original string to the same character position in the (possibly modified) result.
    /// Works because we process matches in reverse — earlier parts of `result` match `original` up to the current match.
    private static func translateRange(_ range: Range<String.Index>, from original: String, to result: String) -> Range<String.Index>? {
        let lowerOffset = original.distance(from: original.startIndex, to: range.lowerBound)
        let upperOffset = original.distance(from: original.startIndex, to: range.upperBound)

        guard lowerOffset <= result.count, upperOffset <= result.count else { return nil }

        let newLower = result.index(result.startIndex, offsetBy: lowerOffset)
        let newUpper = result.index(result.startIndex, offsetBy: upperOffset)

        guard newLower <= newUpper, newUpper <= result.endIndex else { return nil }
        return newLower..<newUpper
    }

    private static func replaceAll(_ string: String, pattern: String, with replacement: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return string }
        return regex.stringByReplacingMatches(
            in: string,
            range: NSRange(string.startIndex..., in: string),
            withTemplate: replacement
        )
    }

    private static func decodeEntities(_ string: String) -> String {
        var s = string
        let table: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'"),
            ("&nbsp;", " "), ("&hellip;", "…"), ("&mdash;", "—"),
            ("&ndash;", "–"), ("&laquo;", "«"), ("&raquo;", "»"),
        ]
        for (entity, char) in table { s = s.replacingOccurrences(of: entity, with: char) }

        if let regex = try? NSRegularExpression(pattern: "&#(\\d+);") {
            let matches = regex.matches(in: s, range: NSRange(s.startIndex..., in: s))
            for match in matches.reversed() {
                guard let range = Range(match.range, in: s),
                      let numRange = Range(match.range(at: 1), in: s),
                      let cp = UInt32(String(s[numRange])),
                      let scalar = Unicode.Scalar(cp) else { continue }
                s.replaceSubrange(range, with: String(scalar))
            }
        }
        return s
    }
}
