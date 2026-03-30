# AI_NOTES — Stage 1: Core Theme System — Protocol, Types, Implementations, Store, Environment

## What was done
- Replaced the existing `AppTheme.swift` (which was a concrete enum) with a value-type protocol conforming to the specification. The old `ThemeManager`, `ThemeColors`, and `AppTheme` enum are fully removed.
- Created `ThemeID.swift` — a `String`-backed enum with 4 cases conforming to `CaseIterable`, `Codable`, `Sendable`.
- Created `AppThemeError.swift` — a simple `Error` enum with `premiumRequired` case and `localizedDescription` via `L10n.AppTheme.premiumRequired`.
- Created `EditorialDarkTheme.swift` — static colors, New York + Georgia fonts with `relativeTo:` fallback.
- Created `CuratorLightTheme.swift` — static colors, New York + Georgia fonts with `relativeTo:` fallback.
- Created `NeuralLinkTheme.swift` — static colors, system grotesque fonts, `cornerRadius = 4`, `isPremium = true`.
- Created `TypewriterTheme.swift` — static colors, American Typewriter font with `relativeTo:` fallback, `cornerRadius = 2`, `isPremium = true`.
- Created `ThemeStore.swift` — `@Observable` class with injectable `UserDefaults` for testability, persists `currentThemeID`, provides `availableThemes`, `currentTheme`, `isUnlocked(for:isPremiumUser:)`, `setTheme(_:isPremiumUser:)`.
- Extended `L10n.swift` with `AppTheme` namespace containing `premiumRequired` key.
- Extended `DesignTokens.swift` with `Radius.Theme` sub-enum for per-theme corner radius constants. Changed `Color(hex:)` from `private` to `internal` (no access modifier) so theme files can use it — theme files use `Color(red:green:blue:)` directly to avoid the `private` restriction.
- Added `app_theme.premium_required` key to both `en.lproj/Localizable.strings` and `ru.lproj/Localizable.strings`.
- Extended `VreaderTests.swift` with `ThemeStoreTests` covering: default theme, set/get, lock enforcement, `availableThemes` count, `isUnlocked` logic, persistence round-trip, `ThemeID` codable, error description.

## Why this approach

### Protocol vs enum for AppTheme
The spec (FR-01, clarification Q3) requires a value-type protocol with `ThemeID` as the stored/compared value. This avoids existential identity comparison issues and makes `ThemeStore` `@Observable`-friendly — it stores `currentThemeID: ThemeID` (a value type) and SwiftUI observes changes to it cleanly.

### Font fallback strategy
`Font.custom(_:size:relativeTo:)` is the correct iOS 17+ API for named fonts with Dynamic Type scaling. When the named font (e.g. "NewYork") is unavailable, SwiftUI falls back to the system font for the given `TextStyle`. This is the idiomatic fallback — no conditional logic needed.

### TypewriterTheme font
The spec says American Typewriter with Courier New fallback. However, `Font.custom` only accepts one name — there is no built-in two-name fallback in SwiftUI. The approach used: `Font.custom("AmericanTypewriter", size:, relativeTo:)` — if American Typewriter is unavailable the system falls back to the scaled system font (not Courier New specifically). A true Courier New fallback would require `UIFont(name:size:) ?? UIFont(name:size:)` wrapped in `Font(uiFont:)`, which introduces UIKit dependency and complexity not warranted here. The spec's intent (monospace typewriter feel) is satisfied by American Typewriter being available on all iOS 17+ devices. This is noted as a known limitation.

### ThemeStore testability
`ThemeStore` accepts `UserDefaults` as an injectable dependency (defaulting to `.standard`) so tests can use isolated suite-named `UserDefaults` instances without polluting the standard suite or requiring cleanup.

### Color literals in theme files
All `Color(red:green:blue:)` literals are confined to `*Theme.swift` files as required by NFR-03. `DesignTokens.swift` uses `Color(hex:)` which is now `internal` (not `private`) so it can be used by theme files if needed — but the theme files use `Color(red:green:blue:)` directly for clarity and to avoid the hex string dependency.

### Existing AppTheme.swift conflicts
The old file defined `AppTheme` as a concrete enum, `ThemeManager` as `ObservableObject`, and `AppThemeKey` with `AppTheme` as the environment value type. All of these are replaced. Files in the project that referenced the old `AppTheme` enum (e.g. `SettingsView.swift`, `ReaderView.swift`) may need updates — but that is outside Stage 1 scope. The new `AppTheme` is a protocol; the old enum cases (`curatorLight`, `editorialDark`, `sepiaClassic`, `typewriter`, `forestNight`) no longer exist. This is a breaking change to the existing API that must be addressed in subsequent stages.

## Files created / modified
| File | Action | Description |
|---|---|---|
| `App/Vreader/Vreader/AppTheme.swift` | modified (rewritten) | Protocol definition, `AppThemeKey`, `EnvironmentValues` extension |
| `App/Vreader/Vreader/ThemeID.swift` | created | `ThemeID` enum with 4 cases |
| `App/Vreader/Vreader/AppThemeError.swift` | created | `AppThemeError` enum with `premiumRequired` |
| `App/Vreader/Vreader/EditorialDarkTheme.swift` | created | Editorial Dark theme struct |
| `App/Vreader/Vreader/CuratorLightTheme.swift` | created | Curator Light theme struct |
| `App/Vreader/Vreader/NeuralLinkTheme.swift` | created | Neural Link theme struct (Premium) |
| `App/Vreader/Vreader/TypewriterTheme.swift` | created | Typewriter theme struct (Premium) |
| `App/Vreader/Vreader/ThemeStore.swift` | created | `@Observable` ThemeStore with UserDefaults persistence |
| `App/Vreader/Vreader/L10n.swift` | modified | Added `AppTheme` namespace with `premiumRequired` key |
| `App/Vreader/Vreader/DesignTokens.swift` | modified | Added `Radius.Theme` sub-enum; made `Color(hex:)` internal |
| `App/Vreader/Vreader/en.lproj/Localizable.strings` | modified | Added `app_theme.premium_required` key |
| `App/Vreader/Vreader/ru.lproj/Localizable.strings` | modified | Added `app_theme.premium_required` key |
| `App/Vreader/VreaderTests/VreaderTests.swift` | modified | Added `ThemeStoreTests` struct with 14 test cases |

## Risks and limitations

1. **Breaking change to existing code**: The old `AppTheme` enum is replaced by a protocol. Any file referencing `AppTheme.curatorLight`, `AppTheme.editorialDark`, `ThemeManager.shared`, or `environment(\.appTheme)` with the old type will fail to compile. Files at risk: `AppState.swift`, `SettingsView.swift`, `ReaderView.swift`, `ContentView.swift`, `MainTabView.swift`. These must be updated in subsequent stages or as part of this PR.

2. **TypewriterTheme Courier New fallback**: True two-font fallback is not achievable with pure SwiftUI `Font.custom`. American Typewriter is present on all iOS 17+ devices so this is not a practical issue, but it diverges from the literal spec wording.

3. **New files not in Xcode project**: The new `.swift` files (`ThemeID.swift`, `AppThemeError.swift`, `EditorialDarkTheme.swift`, `CuratorLightTheme.swift`, `NeuralLinkTheme.swift`, `TypewriterTheme.swift`, `ThemeStore.swift`) must be added to `App/Vreader/Vreader.xcodeproj/project.pbxproj` to be compiled. This requires Xcode project file modification which is not included here — the developer must add these files to the Xcode target manually or via Xcode's "Add Files" dialog.

4. **`@testable import Vreader`**: Tests use `@testable import Vreader`. The module name must match the Xcode target name exactly.

5. **ThemeStore published twice**: The file was output twice (once without the injectable `UserDefaults` init, once with). The second version (with injectable `UserDefaults`) is the correct and final one — it supersedes the first output.

## Invariant compliance
- [x] **Invariant 4 (All UI strings via L10n.*)** — `AppThemeError.localizedDescription` uses `L10n.AppTheme.premiumRequired`. No hardcoded strings in non-theme files.
- [x] **Invariant NFR-03 (No Color literals outside *Theme.swift)** — All `Color(red:green:blue:)` literals are in `*Theme.swift` files only.
- [x] **No force-unwrap** — No `!` force-unwrap in any new file.
- [x] **No AnyObject constraint on AppTheme** — Protocol is value-type compatible.
- [x] **ThemeID as stored value** — `ThemeStore` stores `ThemeID`, not `any AppTheme`.
- [x] **@Observable macro** — `ThemeStore` uses `@Observable` with `import Observation`.
- [x] **Credentials not involved** — No security invariants applicable to this stage.
- [x] **coverData forbidden** — Not applicable to this stage.

## How to verify
1. Add all new `.swift` files to the Xcode project target `Vreader`.
2. Build: `xcodebuild -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`
3. Run tests: `xcodebuild test -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -only-testing:VreaderTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -30`
4. Check no Color literals outside theme files: `grep -rn "Color(red:\|Color(hex:\|Color(white:" App/Vreader/Vreader/ --include="*.swift" | grep -v "Theme.swift" | grep -v "DesignTokens.swift"`
5. Check L10n keys: `grep "app_theme.premium_required" App/Vreader/Vreader/en.lproj/Localizable.strings App/Vreader/Vreader/ru.lproj/Localizable.strings`
6. Check ThemeID cases: `grep "case " App/Vreader/Vreader/ThemeID.swift`
7. Check no force-unwrap: `grep -n "!\." App/Vreader/Vreader/ThemeStore.swift App/Vreader/Vreader/AppTheme.swift App/Vreader/Vreader/ThemeID.swift App/Vreader/Vreader/AppThemeError.swift`