import Foundation

enum HTMLToMarkdown {

    static func convert(_ html: String) -> String {
        var s = html

        // 1. Fenced code blocks — handle first so inner content isn't touched by later rules
        s = convertCodeBlocks(s)

        // 2. Headings
        for level in (1...6).reversed() {
            let hashes = String(repeating: "#", count: level)
            s = replace(s, pattern: "<h\(level)[^>]*>", with: "\n\(hashes) ")
            s = s.replacingOccurrences(of: "</h\(level)>", with: "\n")
        }

        // 3. Bold / italic
        s = replace(s, pattern: "<strong[^>]*>|<b[^>]*>", with: "**")
        s = s.replacingOccurrences(of: "</strong>", with: "**")
        s = s.replacingOccurrences(of: "</b>", with: "**")
        s = replace(s, pattern: "<em[^>]*>|<i[^>]*>", with: "*")
        s = s.replacingOccurrences(of: "</em>", with: "*")
        s = s.replacingOccurrences(of: "</i>", with: "*")

        // 4. Inline code (after code blocks, so <pre><code> is already gone)
        s = replace(s, pattern: "<code[^>]*>", with: "`")
        s = s.replacingOccurrences(of: "</code>", with: "`")

        // 5. Links
        s = convertLinks(s)

        // 6. Lists
        s = convertOrderedLists(s)
        s = replace(s, pattern: "<li[^>]*>", with: "\n- ")
        s = s.replacingOccurrences(of: "</li>", with: "")
        s = replace(s, pattern: "</?[uo]l[^>]*>", with: "\n")

        // 7. Paragraphs and line breaks
        s = replace(s, pattern: "<p[^>]*>", with: "\n")
        s = s.replacingOccurrences(of: "</p>", with: "\n")
        s = replace(s, pattern: "<br\\s*/?>", with: "\n")

        // 8. Horizontal rule
        s = replace(s, pattern: "<hr[^>]*>", with: "\n\n---\n\n")

        // 9. Strip all remaining tags
        s = replace(s, pattern: "<[^>]+>", with: "")

        // 10. HTML entities
        s = decodeEntities(s)

        // 11. Collapse 3+ blank lines to 2
        s = replace(s, pattern: "\n{3,}", with: "\n\n")

        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Code blocks

    private static func convertCodeBlocks(_ html: String) -> String {
        // Matches <pre ...><code class="language-X"> or plain <pre><code>
        let pattern = #"<pre[^>]*>\s*<code(?:[^>]*class="[^"]*language-([^"\s]+)[^"]*")?[^>]*>([\s\S]*?)</code>\s*</pre>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return html }

        var result = html
        var offset = 0

        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
        for match in matches {
            let matchRange = Range(match.range, in: html)!
            let lang = Range(match.range(at: 1), in: html).map { String(html[$0]) } ?? ""
            let code = Range(match.range(at: 2), in: html).map { String(html[$0]) } ?? ""
            let cleaned = decodeEntities(replace(code, pattern: "<[^>]+>", with: ""))
            let block = "\n```\(lang)\n\(cleaned)\n```\n"

            let adjustedLower = result.index(result.startIndex, offsetBy: result.distance(from: html.startIndex, to: matchRange.lowerBound) + offset)
            let adjustedUpper = result.index(result.startIndex, offsetBy: result.distance(from: html.startIndex, to: matchRange.upperBound) + offset)
            let adjustedRange = adjustedLower..<adjustedUpper
            offset += block.count - match.range.length
            result.replaceSubrange(adjustedRange, with: block)
        }
        return result
    }

    // MARK: - Ordered lists

    private static func convertOrderedLists(_ html: String) -> String {
        let pattern = #"<ol[^>]*>([\s\S]*?)</ol>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return html }

        var result = html
        var offset = 0
        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))

        for match in matches {
            guard let matchRange = Range(match.range, in: html),
                  let innerRange = Range(match.range(at: 1), in: html) else { continue }

            let inner = String(html[innerRange])
            var counter = 0
            var converted = "\n"
            let liPattern = #"<li[^>]*>([\s\S]*?)</li>"#
            if let liRegex = try? NSRegularExpression(pattern: liPattern) {
                let liMatches = liRegex.matches(in: inner, range: NSRange(inner.startIndex..., in: inner))
                var lastEnd = inner.startIndex
                for li in liMatches {
                    if let liRange = Range(li.range, in: inner),
                       let contentRange = Range(li.range(at: 1), in: inner) {
                        counter += 1
                        let content = String(inner[contentRange])
                        converted += "\(counter). \(content)\n"
                        lastEnd = liRange.upperBound
                    }
                }
            }
            converted += "\n"

            let adjustedLower = result.index(result.startIndex, offsetBy: result.distance(from: html.startIndex, to: matchRange.lowerBound) + offset)
            let adjustedUpper = result.index(result.startIndex, offsetBy: result.distance(from: html.startIndex, to: matchRange.upperBound) + offset)
            offset += converted.count - match.range.length
            result.replaceSubrange(adjustedLower..<adjustedUpper, with: converted)
        }
        return result
    }

    // MARK: - Links

    private static func convertLinks(_ html: String) -> String {
        let pattern = #"<a\s+(?:[^>]*?\s+)?href="([^"]*)"[^>]*>([\s\S]*?)</a>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return html }

        var result = html
        var offset = 0
        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))

        for match in matches {
            guard let matchRange = Range(match.range, in: html),
                  let urlRange = Range(match.range(at: 1), in: html),
                  let textRange = Range(match.range(at: 2), in: html) else { continue }

            let url = String(html[urlRange])
            let rawText = String(html[textRange])
            let text = replace(rawText, pattern: "<[^>]+>", with: "")
            let md = "[\(text)](\(url))"

            let adjustedLower = result.index(result.startIndex, offsetBy: result.distance(from: html.startIndex, to: matchRange.lowerBound) + offset)
            let adjustedUpper = result.index(result.startIndex, offsetBy: result.distance(from: html.startIndex, to: matchRange.upperBound) + offset)
            offset += md.count - match.range.length
            result.replaceSubrange(adjustedLower..<adjustedUpper, with: md)
        }
        return result
    }

    // MARK: - Helpers

    private static func replace(_ string: String, pattern: String, with replacement: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return string }
        return regex.stringByReplacingMatches(in: string, range: NSRange(string.startIndex..., in: string), withTemplate: replacement)
    }

    private static func decodeEntities(_ string: String) -> String {
        var s = string
        let table: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'"),
            ("&nbsp;", " "), ("&hellip;", "…"), ("&mdash;", "—"),
            ("&ndash;", "–"), ("&laquo;", "«"), ("&raquo;", "»"),
        ]
        for (entity, char) in table {
            s = s.replacingOccurrences(of: entity, with: char)
        }
        // Numeric decimal entities: &#123;
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
