# Screenshots

**No Simulator screenshot exists for this repo yet.** The build that produced it ran as an
unattended scheduled session; the computer-use grant for Xcode and Simulator cannot be approved
in that mode, so `Demo.xcodeproj` was never opened and the app was never launched. The library
was verified with `swift build` (0 warnings) and `swift test` (25/25) on Linux, and
`ContextContractDemoView` was reviewed by hand against the iOS 17 SwiftUI API surface it uses
(`NavigationStack`, `List`, `Picker(.segmented)`/`.menu`, `LabeledContent`, `ProgressView(value:)`, `.listStyle(.insetGrouped)` behind `#if os(iOS)`,
`ContentUnavailableView`, `TextEditor`, `.sheet(isPresented:)`, `.textSelection(.enabled)`).

If you run `Demo.xcodeproj`, drop a screenshot here and reference it from the root README.
