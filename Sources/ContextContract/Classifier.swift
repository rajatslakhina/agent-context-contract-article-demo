import Foundation

/// What an instructions line looks like when it was written for one vendor.
///
/// Matching is deliberately conservative: product names, vendor-owned paths, the vendor's own
/// tool names, its slash commands and flags, and mechanisms only it has. A false negative costs
/// one line of review; a false positive tells a team to rewrite a line that was fine. Tool names
/// that are also English words (`Read`, `Edit`, `Grep`, `Task`, `Write`) only count when written
/// as code (`` `Read` ``) or as "the Read tool".
public struct VendorSignature: Sendable {
    public let names: [String]
    public let paths: [String]
    public let tools: [String]
    public let ambiguousTools: [String]
    public let commands: [String]
    public let features: [String]

    public static func signature(for vendor: Vendor) -> VendorSignature {
        switch vendor {
        case .claude:
            return VendorSignature(
                names: ["Claude Code", "Claude", "Opus", "Sonnet", "Haiku"],
                paths: ["CLAUDE.md", "CLAUDE.local.md", ".claude/"],
                tools: ["Bash", "MultiEdit", "WebFetch", "WebSearch", "TodoWrite", "NotebookEdit", "Glob"],
                ambiguousTools: ["Read", "Write", "Edit", "Grep", "Task"],
                commands: ["/compact", "/clear", "/init", "/memory", "/permissions", "/hooks", "/model",
                           "--dangerously-skip-permissions", "--allowedTools", "ultrathink"],
                features: ["PreToolUse", "PostToolUse", "subagent", "CLAUDE.md"]
            )
        case .codex:
            return VendorSignature(
                names: ["Codex"],
                paths: [".codex/"],
                tools: ["apply_patch"],
                ambiguousTools: [],
                commands: ["--full-auto", "--suggest", "--auto-edit", "codex exec"],
                features: ["approval_policy", "sandbox_mode", "AGENTS.override.md"]
            )
        case .gemini:
            return VendorSignature(
                names: ["Gemini CLI", "Gemini"],
                paths: ["GEMINI.md", ".gemini/"],
                tools: ["run_shell_command", "read_file", "write_file", "search_file_content",
                        "read_many_files", "google_web_search", "save_memory"],
                ambiguousTools: [],
                commands: ["--yolo", "--acp"],
                features: ["context.fileName"]
            )
        case .cursor:
            return VendorSignature(
                names: ["Cursor"],
                paths: [".cursorrules", ".cursor/rules", ".mdc"],
                tools: [],
                ambiguousTools: [],
                commands: ["Cmd+K", "Cmd+I"],
                features: ["Composer", "@Codebase"]
            )
        case .copilot:
            return VendorSignature(
                names: ["Copilot"],
                paths: [".github/copilot-instructions.md", ".github/instructions/"],
                tools: [],
                ambiguousTools: [],
                commands: [],
                features: ["#codebase", "@workspace"]
            )
        }
    }

    /// Every matched substring, in the order the signature lists them.
    public func matches(in line: String) -> [String] {
        var found: [String] = []
        // Product names are proper nouns: "Cursor" is a vendor, "the cursor" is a caret.
        for name in names where Matcher.wholeWord(name, in: line, caseInsensitive: false) {
            found.append(name)
        }
        for path in paths where line.contains(path) { found.append(path) }
        for tool in tools where Matcher.wholeWord(tool, in: line, caseInsensitive: false) { found.append(tool) }
        for tool in ambiguousTools {
            if line.contains("`\(tool)`") { found.append("`\(tool)`") }
            else if Matcher.wholeWord("\(tool) tool", in: line, caseInsensitive: false) { found.append("\(tool) tool") }
        }
        for command in commands where line.contains(command) { found.append(command) }
        for feature in features where line.contains(feature) { found.append(feature) }
        // Dedupe overlaps: "Claude Code" absorbs "Claude", ".claude/" absorbs the "claude" inside it,
        // and "CLAUDE.md" (listed as a path and as a feature) appears once.
        var seen = Set<String>()
        let unique = found.filter { seen.insert($0).inserted }
        return unique.filter { candidate in
            !unique.contains { other in
                other != candidate && other.count > candidate.count
                    && other.range(of: candidate, options: .caseInsensitive) != nil
            }
        }
    }
}

enum Matcher {
    /// Whole-word match with word characters and hyphens as boundaries, so `claude-agent-acp`
    /// does not count as "Claude" and `Bashful` does not count as `Bash`.
    static func wholeWord(_ word: String, in line: String, caseInsensitive: Bool) -> Bool {
        let pattern = "(?<![\\w-])" + NSRegularExpression.escapedPattern(for: word) + "(?![\\w-])"
        var options: String.CompareOptions = [.regularExpression]
        if caseInsensitive { options.insert(.caseInsensitive) }
        return line.range(of: pattern, options: options) != nil
    }

    /// The first substring matching `pattern`, case-insensitively.
    static func first(_ pattern: String, in line: String) -> String? {
        guard let range = line.range(of: pattern, options: [.regularExpression, .caseInsensitive]) else { return nil }
        return String(line[range])
    }
}

/// Finds the two kinds of evidence a directive can carry: it was written for one vendor,
/// or it claims to enforce something that prose cannot enforce.
public enum Classifier {
    public static func signals(in text: String) -> [Signal] {
        var out: [Signal] = []
        for kind in Enforcement.allCases {
            if let matched = EnforcementDetector.detect(kind, in: text) {
                out.append(.enforcement(kind, matched: matched))
            }
        }
        for vendor in Vendor.allCases {
            for matched in VendorSignature.signature(for: vendor).matches(in: text) {
                out.append(.vendor(vendor, matched: matched))
            }
        }
        return out
    }
}

/// Patterns for rules that only mean something if a layer with teeth enforces them.
enum EnforcementDetector {
    static let prohibition = #"\b(never|do not|don't|must not|must never|should never|are not allowed to)\b"#

    static let permissionVerbs = #"\b(never|do not|don't|must not|must never|should never)\s+(run|execute|invoke|push|force[- ]push|delete|remove|rm|drop|commit|merge|deploy|install|uninstall|publish|release|rebase|reset|overwrite|open a pull request|open a pr|create a pr)\b"#
    static let askFirst = #"\b(ask|check with|confirm with|wait for)\s+(me|the human|a human|the user|approval|confirmation|first|before)\b"#
    static let withoutAsking = #"\b(without asking|leave (commits|committing|pushes|pushing|deploys|deploying|merges|merging) to)\b"#

    static let pathVerbs = #"\b(never|do not|don't|must not|must never|should never)\s+(modify|edit|touch|change|write to|rewrite|regenerate|hand-edit|hand edit|alter|check in|commit changes to)\b"#
    static let pathLike = #"(`[^`]*[./][^`]*`)|(\b[\w*-]+(/[\w*.-]+)+/?)|(\b[\w-]+\.(pbxproj|resolved|plist|xcconfig|xcodeproj|xcworkspace|swift|json|ya?ml|toml|lock|md|strings|xcstrings)\b)"#

    static let alwaysRun = #"\b(always|must)\s+(run|pass|build|compile)\b"#
    static let runBefore = #"\brun (the )?(tests?|test suite|unit tests|swift test|xcodebuild|build)\b[^.]*\b(before|prior to|until)\b"#
    static let mustPass = #"\b(tests?|the build|build)\s+(must|has to|have to)\s+(pass|succeed|be green|compile)\b"#
    static let doneGate = #"\b(tests?|build)\b[^.]*\b(before|until)\b[^.]*\b(done|complete|finished)\b"#

    static let secretVocabulary = #"\b(secrets?|api[ -]?keys?|access tokens?|auth tokens?|bearer tokens?|credentials?|passwords?|keychain|private keys?|\.env)\b"#
    static let leakVerbs = #"\b(redact|leak|expose|print|log|paste|echo|send)\b"#

    static func detect(_ kind: Enforcement, in text: String) -> String? {
        switch kind {
        case .permissionGate:
            return Matcher.first(permissionVerbs, in: text)
                ?? Matcher.first(askFirst, in: text)
                ?? Matcher.first(withoutAsking, in: text)
        case .pathGuard:
            guard let verb = Matcher.first(pathVerbs, in: text),
                  let path = Matcher.first(pathLike, in: text) else { return nil }
            return "\(verb) … \(path)"
        case .buildGate:
            return Matcher.first(alwaysRun, in: text)
                ?? Matcher.first(runBefore, in: text)
                ?? Matcher.first(mustPass, in: text)
                ?? Matcher.first(doneGate, in: text)
        case .secretRedaction:
            guard let vocabulary = Matcher.first(secretVocabulary, in: text) else { return nil }
            guard let framing = Matcher.first(prohibition, in: text) ?? Matcher.first(leakVerbs, in: text) else { return nil }
            return "\(framing) … \(vocabulary)"
        }
    }
}
