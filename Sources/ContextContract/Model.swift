import Foundation

/// The coding agents an ACP-capable editor (Xcode 27, Zed, JetBrains) can launch as a subprocess,
/// and the instructions file each one reads from the project root on its own.
///
/// ACP forwards the editor's MCP server configuration to whichever agent it launches
/// (`session/new` carries `mcpServers`). It does not forward instructions files. Each agent
/// reads its own file from `cwd`, so a swap changes which file is read at all.
public enum Vendor: String, CaseIterable, Codable, Sendable, Hashable {
    case claude, codex, gemini, cursor, copilot

    public var displayName: String {
        switch self {
        case .claude: return "Claude Code"
        case .codex: return "Codex"
        case .gemini: return "Gemini CLI"
        case .cursor: return "Cursor"
        case .copilot: return "GitHub Copilot"
        }
    }

    /// The file the agent reads from the project root with no configuration at all.
    public var nativeContextFile: String {
        switch self {
        case .claude: return "CLAUDE.md"
        case .codex: return "AGENTS.md"
        case .gemini: return "GEMINI.md"
        case .cursor: return ".cursor/rules/"
        case .copilot: return ".github/copilot-instructions.md"
        }
    }

    /// Whether this agent reads `file`, and what it takes to make it do so.
    /// `nil` means the file is invisible to the agent.
    public func reads(_ file: String) -> ContextFileSupport? {
        if file == nativeContextFile { return .native }
        guard file == ContractCompiler.portableFile else { return nil }
        switch self {
        case .codex, .cursor, .copilot:
            return .native
        case .claude:
            return .viaImport("`@AGENTS.md` as the first line of CLAUDE.md (Claude Code memory imports)")
        case .gemini:
            return .viaImport("`@./AGENTS.md` as the first line of GEMINI.md, or `context.fileName` in .gemini/settings.json")
        }
    }

    /// The vendor-specific overlay file the compiler writes for this agent.
    public var overlayFile: String {
        switch self {
        case .claude: return "CLAUDE.md"
        case .codex: return "AGENTS.md"            // no overlay file: Codex-only lines stay in AGENTS.md under their own heading
        case .gemini: return "GEMINI.md"
        case .cursor: return ".cursor/rules/team.mdc"
        case .copilot: return ".github/copilot-instructions.md"
        }
    }
}

public enum ContextFileSupport: Equatable, Sendable {
    /// Read from the project root without configuration.
    case native
    /// Read only after a one-line shim (`how`) that the compiler writes for you.
    case viaImport(String)

    public var isNative: Bool {
        if case .native = self { return true }
        return false
    }
}

/// A rule in an instructions file that claims to *enforce* something. Prose cannot enforce;
/// each kind names the vendor-neutral layer where the rule actually has teeth.
public enum Enforcement: String, CaseIterable, Codable, Sendable, Hashable {
    case secretRedaction, pathGuard, permissionGate, buildGate

    public var title: String {
        switch self {
        case .secretRedaction: return "Secret redaction"
        case .pathGuard: return "Path guard"
        case .permissionGate: return "Permission gate"
        case .buildGate: return "Build gate"
        }
    }

    /// Where the rule must live so that it survives an agent swap with its guarantee intact.
    public var mechanism: String {
        switch self {
        case .secretRedaction:
            return "Outbound context redaction in front of the agent plus a pre-commit secret scan. It has to hold for every vendor, not inside one vendor's hook."
        case .pathGuard:
            return "Path policy at the permission layer, backed by branch protection or CODEOWNERS on the paths named."
        case .permissionGate:
            return "The ACP `session/request_permission` handler (Xcode's permission sheet, or a gateway in front of the agent) denies the call. A sentence cannot."
        case .buildGate:
            return "A turn-completion gate: build and tests must pass before the agent may report the turn done; CI repeats the check on the PR."
        }
    }
}

/// Evidence found in a directive's text.
public enum Signal: Equatable, Sendable, CustomStringConvertible {
    case vendor(Vendor, matched: String)
    case enforcement(Enforcement, matched: String)

    public var description: String {
        switch self {
        case .vendor(let v, let m): return "\(v.displayName): “\(m)”"
        case .enforcement(let e, let m): return "\(e.title): “\(m)”"
        }
    }

    public var vendor: Vendor? {
        if case .vendor(let v, _) = self { return v }
        return nil
    }

    public var enforcement: Enforcement? {
        if case .enforcement(let e, _) = self { return e }
        return nil
    }
}

/// Where a directive belongs once the file is treated as a contract instead of a love letter.
public enum Placement: Equatable, Sendable {
    /// Any agent can act on it as written → `AGENTS.md`.
    case portable
    /// It only means something to one agent → that agent's overlay file.
    case vendorOverlay(Vendor)
    /// It claims to enforce something → the protocol layer; the prose becomes informational.
    case protocolLayer([Enforcement])

    public var label: String {
        switch self {
        case .portable: return "Portable"
        case .vendorOverlay(let v): return "\(v.displayName) only"
        case .protocolLayer: return "Enforce, don't describe"
        }
    }

    public var isPortable: Bool {
        if case .portable = self { return true }
        return false
    }

    public var overlayVendor: Vendor? {
        if case .vendorOverlay(let v) = self { return v }
        return nil
    }

    public var enforcements: [Enforcement] {
        if case .protocolLayer(let kinds) = self { return kinds }
        return []
    }

    /// Precedence: an enforcement claim wins over vendor wording, vendor wording wins over nothing.
    /// A line naming several vendors goes to the vendor with the most matches; ties go to
    /// declaration order of `Vendor.allCases`. That rule is pinned by tests, not accidental.
    public static func decide(_ signals: [Signal]) -> Placement {
        let kinds = Enforcement.allCases.filter { kind in signals.contains { $0.enforcement == kind } }
        if !kinds.isEmpty { return .protocolLayer(kinds) }
        var counts: [Vendor: Int] = [:]
        for s in signals { if let v = s.vendor { counts[v, default: 0] += 1 } }
        guard let best = counts.values.max(),
              let winner = Vendor.allCases.first(where: { counts[$0] == best }) else { return .portable }
        return .vendorOverlay(winner)
    }
}

/// One line of an instructions file, with what was found in it and where it belongs.
public struct Directive: Identifiable, Equatable, Sendable {
    public let line: Int
    public let section: String?
    public let text: String
    public let signals: [Signal]
    public let placement: Placement

    public var id: Int { line }

    public init(line: Int, section: String?, text: String) {
        self.line = line
        self.section = section
        self.text = text
        self.signals = Classifier.signals(in: text)
        self.placement = Placement.decide(signals)
    }

    public var vendorSignals: [Signal] { signals.filter { $0.vendor != nil } }
    public var enforcementSignals: [Signal] { signals.filter { $0.enforcement != nil } }
    /// True when an enforcement claim is also worded for one vendor, e.g. a rule that only a
    /// vendor-specific hook enforces today. Those lose their guarantee on a swap, silently.
    public var isVendorEnforced: Bool { !placement.enforcements.isEmpty && !vendorSignals.isEmpty }
}
