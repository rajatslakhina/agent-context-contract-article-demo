import Foundation

/// Turns an instructions file into directives: one per bullet or paragraph line, with the
/// `##` section it sits under and its 1-based line number. Headings, blank lines and fenced
/// code are skipped; nested bullets are directives too.
public enum ContractScanner {
    public static func scan(_ markdown: String) -> [Directive] {
        var directives: [Directive] = []
        var section: String? = nil
        var inFence = false
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)
        for (index, raw) in lines.enumerated() {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") { inFence.toggle(); continue }
            if inFence || trimmed.isEmpty { continue }
            if trimmed.hasPrefix("#") {
                section = String(trimmed.drop { $0 == "#" }).trimmingCharacters(in: .whitespaces)
                continue
            }
            if trimmed.hasPrefix("<!--") || trimmed == "---" { continue }
            let text = stripBullet(trimmed)
            guard !text.isEmpty else { continue }
            directives.append(Directive(line: index + 1, section: section, text: text))
        }
        return directives
    }

    static func stripBullet(_ line: String) -> String {
        var s = Substring(line)
        for marker in ["- [ ] ", "- [x] ", "- ", "* ", "+ "] where s.hasPrefix(marker) {
            s = s.dropFirst(marker.count)
            break
        }
        if let range = s.range(of: #"^\d+[.)]\s+"#, options: .regularExpression) {
            s = s[range.upperBound...]
        }
        return s.trimmingCharacters(in: .whitespaces)
    }
}
