import Foundation

/// The numbers a lead needs before deciding what to do about an instructions file.
public struct PortabilityReport: Sendable {
    public let directives: [Directive]

    public init(directives: [Directive]) { self.directives = directives }
    public init(markdown: String) { self.init(directives: ContractScanner.scan(markdown)) }

    public var total: Int { directives.count }
    public var portable: Int { directives.filter { $0.placement.isPortable }.count }
    public var protocolLayer: Int { directives.filter { !$0.placement.enforcements.isEmpty }.count }
    public var vendorBound: [Vendor: Int] {
        var counts: [Vendor: Int] = [:]
        for d in directives { if let v = d.placement.overlayVendor { counts[v, default: 0] += 1 } }
        return counts
    }
    public var vendorBoundTotal: Int { vendorBound.values.reduce(0, +) }
    public var enforcementCounts: [Enforcement: Int] {
        var counts: [Enforcement: Int] = [:]
        for d in directives { for k in d.placement.enforcements { counts[k, default: 0] += 1 } }
        return counts
    }
    /// Enforcement claims that are worded for one vendor: the rules that lose their teeth silently on a swap.
    public var vendorEnforced: [Directive] { directives.filter(\.isVendorEnforced) }

    /// Share of directives any agent can act on as written.
    public var portableShare: Double { share(portable) }
    /// Share written for one vendor: rewritten or dropped when the editor launches another agent.
    public var lockInScore: Double { share(vendorBoundTotal) }
    /// Share whose only enforcement is the model's willingness to comply.
    public var enforcementByProseShare: Double { share(protocolLayer) }

    public var dominantVendor: Vendor? {
        let counts = vendorBound
        guard let best = counts.values.max() else { return nil }
        return Vendor.allCases.first { counts[$0] == best }
    }

    public func directives(placedIn vendor: Vendor) -> [Directive] {
        directives.filter { $0.placement.overlayVendor == vendor }
    }

    private func share(_ count: Int) -> Double {
        total == 0 ? 0 : Double(count) / Double(total)
    }
}

/// Which agents actually read the file, before and after compiling it into a contract.
public struct Coverage: Sendable {
    public struct Row: Identifiable, Sendable {
        public let vendor: Vendor
        /// Directives that reach the agent when the file is left as written.
        public let asWritten: Int
        public let asWrittenSupport: ContextFileSupport?
        /// Directives that reach the agent after `ContractCompiler` splits the file.
        public let compiled: Int
        public let compiledSupport: ContextFileSupport?
        public var id: Vendor { vendor }
    }

    public let rows: [Row]
    public let total: Int

    /// `sourceFile` is the file the team wrote today, e.g. "CLAUDE.md".
    public init(report: PortabilityReport, sourceFile: String) {
        let total = report.total
        self.total = total
        self.rows = Vendor.allCases.map { vendor in
            let before = vendor.reads(sourceFile)
            let after = vendor.reads(ContractCompiler.portableFile)
            // After compiling, every directive is placed where its reader looks: portable lines and the
            // enforcement lines (kept as information) in AGENTS.md, vendor lines in that vendor's overlay.
            let reaches = report.portable + report.protocolLayer + (report.vendorBound[vendor] ?? 0)
            return Row(vendor: vendor,
                       asWritten: before == nil ? 0 : total,
                       asWrittenSupport: before,
                       compiled: after == nil ? 0 : reaches,
                       compiledSupport: after)
        }
    }

    public var agentsReadingAsWritten: Int { rows.filter { $0.asWritten > 0 }.count }
    public var agentsReadingCompiled: Int { rows.filter { $0.compiled > 0 }.count }
}
