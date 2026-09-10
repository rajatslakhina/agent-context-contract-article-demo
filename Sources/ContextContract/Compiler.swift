import Foundation

/// A file the compiler writes.
public struct ContractFile: Identifiable, Equatable, Sendable {
    public let path: String
    public let purpose: String
    public let contents: String
    public var id: String { path }
}

/// One rule that must leave prose and live in a layer that can say no.
public struct EnforcementEntry: Identifiable, Sendable {
    public let directive: Directive
    public let kinds: [Enforcement]
    public var id: Int { directive.line }
    public var mechanisms: [String] { kinds.map(\.mechanism) }
}

/// Splits one vendor's instructions file into the three things it was always made of:
/// a portable contract every agent reads, per-vendor overlays, and an enforcement plan.
public enum ContractCompiler {
    public static let portableFile = "AGENTS.md"
    public static let enforcementFile = "ENFORCEMENT.md"

    public struct Output: Sendable {
        public let files: [ContractFile]
        public let enforcement: [EnforcementEntry]
    }

    public static func compile(_ report: PortabilityReport, project: String) -> Output {
        let directives = report.directives
        let portable = directives.filter { $0.placement.isPortable }
        let enforced = directives.filter { !$0.placement.enforcements.isEmpty }
        let entries = enforced.map { EnforcementEntry(directive: $0, kinds: $0.placement.enforcements) }

        var files: [ContractFile] = []
        files.append(ContractFile(
            path: portableFile,
            purpose: "Read by every agent the editor can launch. The contract.",
            contents: renderAgents(project: project, portable: portable, enforced: enforced,
                                   codexOnly: report.directives(placedIn: .codex))
        ))
        for vendor in Vendor.allCases where vendor != .codex {
            let overlay = report.directives(placedIn: vendor)
            let needsShim = !(vendor.reads(portableFile)?.isNative ?? false)
            guard needsShim || !overlay.isEmpty else { continue }
            files.append(ContractFile(
                path: vendor.overlayFile,
                purpose: needsShim
                    ? "Shim so \(vendor.displayName) reads \(portableFile), plus its own lines."
                    : "\(vendor.displayName)-only lines. \(vendor.displayName) reads \(portableFile) natively.",
                contents: renderOverlay(vendor: vendor, overlay: overlay, needsShim: needsShim)
            ))
        }
        files.append(ContractFile(
            path: enforcementFile,
            purpose: "Rules that prose cannot enforce, and the layer each one moves to.",
            contents: renderEnforcement(project: project, entries: entries)
        ))
        return Output(files: files, enforcement: entries)
    }

    static func renderAgents(project: String, portable: [Directive], enforced: [Directive], codexOnly: [Directive]) -> String {
        var out = "# \(project) — agent contract\n\n"
        out += "Vendor-neutral. Codex, Cursor and Copilot read this file natively; Claude Code reads it through the `@AGENTS.md` line in CLAUDE.md; Gemini CLI through the `@./AGENTS.md` line in GEMINI.md.\n"
        out += renderGrouped(portable)
        if !codexOnly.isEmpty {
            out += "\n## Codex only\n\n"
            for d in codexOnly { out += "- \(d.text)\n" }
        }
        if !enforced.isEmpty {
            out += "\n## Enforced by the permission layer (informational)\n\n"
            out += "These are not requests. The layer in front of you will refuse them; this list exists so you do not waste a turn trying. See ENFORCEMENT.md.\n\n"
            for d in enforced { out += "- \(d.text)\n" }
        }
        return out
    }

    static func renderOverlay(vendor: Vendor, overlay: [Directive], needsShim: Bool) -> String {
        var out = ""
        if needsShim {
            out += vendor == .gemini ? "@./\(portableFile)\n\n" : "@\(portableFile)\n\n"
        }
        out += "# \(vendor.displayName) specifics\n\n"
        if overlay.isEmpty {
            out += "Nothing here yet. Everything portable lives in \(portableFile).\n"
        } else {
            out += renderGrouped(overlay)
        }
        return out
    }

    static func renderEnforcement(project: String, entries: [EnforcementEntry]) -> String {
        var out = "# \(project) — enforcement plan\n\n"
        out += "Each rule below was written as prose. Prose is enforced by the model's willingness to comply, which is not enforcement. Status stays *not enforced* until the named layer exists.\n\n"
        if entries.isEmpty {
            out += "No enforcement claims found.\n"
            return out
        }
        out += "| Line | Rule | Kind | Where it must live | Status |\n|---|---|---|---|---|\n"
        for e in entries {
            let kinds = e.kinds.map(\.title).joined(separator: ", ")
            let mechanisms = e.kinds.map(\.mechanism).joined(separator: " ")
            out += "| \(e.directive.line) | \(e.directive.text.replacingOccurrences(of: "|", with: "\\|")) | \(kinds) | \(mechanisms) | not enforced |\n"
        }
        return out
    }

    static func renderGrouped(_ directives: [Directive]) -> String {
        var out = ""
        var currentTitle: String? = nil
        for d in directives {
            let title = d.section ?? "General"
            if title != currentTitle {
                currentTitle = title
                out += "\n## \(title)\n\n"
            }
            out += "- \(d.text)\n"
        }
        return out
    }
}
