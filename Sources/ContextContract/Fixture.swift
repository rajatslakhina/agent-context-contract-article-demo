import Foundation

/// A realistic CLAUDE.md for a mid-sized iOS app. Every line is the kind of thing teams actually
/// write; none of it is a strawman. The numbers in the README and the article come from scanning
/// exactly this text, and the tests pin them.
public enum Fixture {
    public static let projectName = "Ledger"
    public static let sourceFile = "CLAUDE.md"

    public static let claudeMD = """
    # CLAUDE.md — Ledger iOS

    ## Project

    - Ledger is a SwiftUI + Swift 6 iOS app. Modules live in `Packages/` (LedgerCore, LedgerUI, LedgerSync).
    - Minimum deployment target is iOS 17. Do not use APIs newer than that without an availability check.
    - Use Swift Testing (`@Test`) for new tests; XCTest only when touching legacy targets.
    - Prefer value types; view models are `@Observable` classes owned by the screen that creates them.
    - All user-facing strings go through `String(localized:)`.
    - Networking goes through `LedgerSync.APIClient`; never call `URLSession` directly from a view.
    - Add a `#Preview` to every new view.

    ## Workflow

    - Use the Grep tool, not Bash `grep`, to search the codebase.
    - Run `/compact` when the conversation gets long.
    - Use the Task tool to spawn a subagent for any search that touches more than 20 files.
    - Use `MultiEdit` for multi-hunk changes in a single file.
    - Skills live in `.claude/skills/`; load `swift-testing` before writing tests.
    - The `xcodebuild-mcp` server is configured in `.claude/settings.json`; use its build tool instead of shelling out.
    - Prefer Claude Opus for architecture questions; switch to Sonnet for mechanical edits.
    - If you are running as Codex, use `apply_patch` for edits instead of rewriting whole files.
    - Gemini: `run_shell_command` needs an explicit `cd Packages/LedgerCore` first.
    - When a build fails, read the full `xcodebuild` output before changing anything.
    - Keep PRs under 400 changed lines; split otherwise.
    - Write commit messages in imperative mood, under 72 characters.
    - Follow the existing formatting; do not reformat files you did not otherwise change.
    - Explain trade-offs in PR descriptions; a reviewer should not need to ask why.

    ## Rules

    - Always run `swift test --package-path Packages/LedgerCore` before you say a task is done.
    - Never run `git push --force` or rewrite history on `main`.
    - Never modify `Packages/*/Package.resolved` by hand.
    - Do not commit; leave commits to the human.
    - Ask before deleting any file.
    - Never print or log the contents of `Secrets/*.plist` or any API key.
    - The PreToolUse hook in `.claude/settings.json` blocks writes to `Secrets/`; do not work around it.
    """

    public static var report: PortabilityReport { PortabilityReport(markdown: claudeMD) }
}
