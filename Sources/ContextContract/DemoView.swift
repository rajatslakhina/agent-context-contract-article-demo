#if canImport(SwiftUI)
import SwiftUI

/// Paste an instructions file, see which lines survive an agent swap, which were written for one
/// vendor, and which claim to enforce something that only a permission layer can enforce.
public struct ContextContractDemoView: View {
    @State private var source = Fixture.claudeMD
    @State private var tab: Tab = .scan
    @State private var editing = false
    @State private var selectedFile = ContractCompiler.portableFile

    private enum Tab: String, CaseIterable, Identifiable {
        case scan = "Scan", files = "Files", coverage = "Coverage"
        var id: String { rawValue }
    }

    public init() {}

    private var report: PortabilityReport { PortabilityReport(markdown: source) }
    private var compiled: ContractCompiler.Output { ContractCompiler.compile(report, project: Fixture.projectName) }
    private var coverage: Coverage { Coverage(report: report, sourceFile: Fixture.sourceFile) }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $tab) {
                    ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                switch tab {
                case .scan: scanList
                case .files: filesView
                case .coverage: coverageList
                }
            }
            .navigationTitle("Context Contract")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                Button("Edit \(Fixture.sourceFile)") { editing = true }
            }
            .sheet(isPresented: $editing) { editor }
        }
    }

    // MARK: Scan

    private var scanList: some View {
        List {
            Section {
                summaryTiles
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Lock-in score").font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(percent(report.lockInScore)).monospacedDigit()
                    }
                    ProgressView(value: report.lockInScore).tint(.orange)
                    Text("Share of lines written for one vendor. \(report.vendorEnforced.count) rule\(report.vendorEnforced.count == 1 ? "" : "s") enforced only by a vendor-specific hook.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("\(report.total) directives in \(Fixture.sourceFile)")
            }

            if report.total == 0 {
                ContentUnavailableView("Nothing to scan", systemImage: "doc.text",
                                       description: Text("Add bullet lines to \(Fixture.sourceFile)."))
            }

            ForEach(sections, id: \.self) { section in
                Section(section) {
                    ForEach(report.directives.filter { ($0.section ?? "General") == section }) { directive in
                        DirectiveRow(directive: directive)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var sections: [String] {
        var seen: [String] = []
        for d in report.directives {
            let s = d.section ?? "General"
            if !seen.contains(s) { seen.append(s) }
        }
        return seen
    }

    private var summaryTiles: some View {
        HStack(spacing: 8) {
            tile("Portable", report.portable, .green, "→ AGENTS.md")
            tile("Vendor-bound", report.vendorBoundTotal, .orange, report.dominantVendor.map { "mostly \($0.displayName)" } ?? "—")
            tile("Enforce", report.protocolLayer, .red, "not prose")
        }
        .padding(.vertical, 4)
    }

    private func tile(_ title: String, _ count: Int, _ color: Color, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(count)").font(.title2.weight(.bold)).monospacedDigit()
                Text(percent(report.total == 0 ? 0 : Double(count) / Double(report.total)))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text(subtitle).font(.caption2).foregroundStyle(color).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Files

    private var filesView: some View {
        VStack(spacing: 0) {
            Picker("File", selection: $selectedFile) {
                ForEach(compiled.files) { Text($0.path).tag($0.path) }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)
            if let file = compiled.files.first(where: { $0.path == selectedFile }) ?? compiled.files.first {
                Text(file.purpose)
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                ScrollView {
                    Text(file.contents)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
    }

    // MARK: Coverage

    private var coverageList: some View {
        List {
            Section {
                LabeledContent("Agents that read it as written", value: "\(coverage.agentsReadingAsWritten) of \(coverage.rows.count)")
                LabeledContent("Agents that read it compiled", value: "\(coverage.agentsReadingCompiled) of \(coverage.rows.count)")
            } header: {
                Text("Who reads \(Fixture.sourceFile)?")
            } footer: {
                Text("ACP hands the editor's MCP servers to whichever agent it launches. It does not hand over your instructions file; each agent reads its own from the working directory.")
            }
            Section("Directives that reach each agent (of \(coverage.total))") {
                ForEach(coverage.rows) { row in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(row.vendor.displayName).font(.body.weight(.semibold))
                            Spacer()
                            Text("\(row.asWritten) → \(row.compiled)").monospacedDigit()
                        }
                        Text("Reads \(row.vendor.nativeContextFile) natively. " + support(row.compiledSupport))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func support(_ s: ContextFileSupport?) -> String {
        switch s {
        case .native: return "AGENTS.md: native."
        case .viaImport(let how): return "AGENTS.md: \(how)."
        case nil: return "AGENTS.md: not read."
        }
    }

    // MARK: Editor

    private var editor: some View {
        NavigationStack {
            TextEditor(text: $source)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .navigationTitle(Fixture.sourceFile)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Reset") { source = Fixture.claudeMD }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { editing = false }
                    }
                }
        }
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

struct DirectiveRow: View {
    let directive: Directive

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Text("L\(directive.line)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .leading)
                Text(directive.text).font(.subheadline)
            }
            HStack(spacing: 6) {
                badge
                if directive.isVendorEnforced {
                    Text("vendor hook").font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.red.opacity(0.15), in: Capsule())
                }
                if !directive.signals.isEmpty {
                    Text(directive.signals.map(\.description).joined(separator: " · "))
                        .font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            .padding(.leading, 38)
        }
        .padding(.vertical, 2)
    }

    private var badge: some View {
        Text(directive.placement.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch directive.placement {
        case .portable: return .green
        case .vendorOverlay: return .orange
        case .protocolLayer: return .red
        }
    }
}

#Preview {
    ContextContractDemoView()
}
#endif
