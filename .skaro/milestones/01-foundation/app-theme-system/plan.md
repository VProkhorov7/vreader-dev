## plan.md

## Stage 1: Core Theme System — Protocol, Types, Implementations, Store, Environment

**Goal:** Implement the complete app-theme system as a single cohesive module: `ThemeID` enum, `AppTheme` protocol, all four theme structs, `AppThemeError`, `ThemeStore`, `AppThemeKey` environment key, and `EnvironmentValues` extension. Also update `L10n.swift` with required localization keys and `DesignTokens.swift` with any theme-related constants. Add unit tests for `ThemeStore` logic.

**Depends on:** none (modifies existing files, creates new files)

**Inputs:**
- Specification: `app-theme-system`
- Clarifications document
- `App/Vreader/Vreader/L10n.swift` (existing — must extend)
- `App/Vreader/Vreader/DesignTokens.swift` (existing — must extend)
- `App/Vreader/Vreader/AppTheme.swift` (existing — will be replaced/rewritten)
- `App/Vreader/VreaderTests/VreaderTests.swift` (existing — will be extended)

**Outputs:**
- `App/Vreader/Vreader/AppTheme.swift` — `AppTheme` protocol + `AppThemeKey` + `EnvironmentValues` extension
- `App/Vreader/Vreader/ThemeID.swift` — `ThemeID` enum
- `App/Vreader/Vreader/AppThemeError.swift` — `AppThemeError` enum
- `App/Vreader/Vreader/EditorialDarkTheme.swift` — `EditorialDarkTheme` struct
- `App/Vreader/Vreader/CuratorLightTheme.swift` — `CuratorLightTheme` struct
- `App/Vreader/Vreader/NeuralLinkTheme.swift` — `NeuralLinkTheme` struct
- `App/Vreader/Vreader/TypewriterTheme.swift` — `TypewriterTheme` struct
- `App/Vreader/Vreader/ThemeStore.swift` — `@Observable ThemeStore` class
- `App/Vreader/Vreader/L10n.swift` — extended with `AppTheme` namespace
- `App/Vreader/Vreader/DesignTokens.swift` — extended with theme corner radius constants
- `App/Vreader/Vreader/en.lproj/Localizable.strings` — new key `app_theme.premium_required`
- `App/Vreader/Vreader/ru.lproj/Localizable.strings` — new key `app_theme.premium_required`
- `App/Vreader/VreaderTests/VreaderTests.swift` — unit tests for `ThemeStore`

**DoD:**
- [ ] `ThemeID` conforms to `String`, `CaseIterable`, `Codable`, `Sendable` with 4 cases
- [ ] `AppTheme` protocol is value-type (no `AnyObject` constraint) with all required properties including `id: ThemeID` and `isPremium: Bool`
- [ ] All 4 theme structs compile with static colors only (no `Color(uiColor:)` dynamic adaptation)
- [ ] `EditorialDarkTheme` and `CuratorLightTheme` use New York + Georgia with system serif fallback
- [ ] `TypewriterTheme` uses American Typewriter with Courier New fallback, `cornerRadius = 2`
- [ ] `NeuralLinkTheme` uses system grotesque, `cornerRadius = 4`, `isPremium = true`
- [ ] `AppThemeKey.defaultValue` returns `EditorialDarkTheme()`
- [ ] `EnvironmentValues.appTheme` property exists and compiles
- [ ] `ThemeStore` is `@Observable`, persists `currentThemeID` in `UserDefaults` with TODO comment referencing `icloud-settings-store`
- [ ] `ThemeStore.availableThemes` always returns all 4 themes
- [ ] `ThemeStore.isUnlocked(for:isPremiumUser:)` returns `false` for premium themes when `isPremiumUser = false`
- [ ] `ThemeStore.setTheme(_:isPremiumUser:)` throws `AppThemeError.premiumRequired` for premium themes when `isPremiumUser = false`
- [ ] `ThemeStore.currentTheme` returns correct instance for each `ThemeID`
- [ ] `AppThemeError.premiumRequired.localizedDescription` returns string from `L10n.AppTheme.premiumRequired`
- [ ] Both `en.lproj/Localizable.strings` and `ru.lproj/Localizable.strings` contain the new key
- [ ] No `Color` literals outside `*Theme.swift` files in the new/modified files
- [ ] Unit tests pass: `ThemeStore` set/get, lock enforcement, `availableThemes` count, `isUnlocked` logic, persistence round-trip via `UserDefaults`

**Risks:**
- `AppTheme.swift` already exists with potentially conflicting type definitions — must audit and cleanly replace without breaking other files that import it
- Font fallback syntax for `Font.custom(_:size:)` with system serif fallback requires `.custom(_:size:relativeTo:)` or conditional — must verify correct SwiftUI API for iOS 17
- `@Observable` macro requires `import Observation` — must ensure correct import in `ThemeStore.swift`
- Existing `VreaderTests.swift` may have unrelated tests that must not be broken

---

## Verify

```yaml
## Verify
- name: Build project (compile check)
  command: xcodebuild -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
- name: Run unit tests
  command: xcodebuild test -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -only-testing:VreaderTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -30
- name: Check no Color literals outside Theme files
  command: grep -rn "Color(" App/Vreader/Vreader/ --include="*.swift" | grep -v "Theme.swift" | grep -v "DesignTokens.swift" | grep -v "Assets" | grep "Color(red:\|Color(hex:\|Color(white:" || echo "PASS: no raw Color literals outside theme files"
- name: Check L10n key exists in English strings
  command: grep -c "app_theme.premium_required" App/Vreader/Vreader/en.lproj/Localizable.strings && echo "PASS" || echo "FAIL: missing L10n key"
- name: Check L10n key exists in Russian strings
  command: grep -c "app_theme.premium_required" App/Vreader/Vreader/ru.lproj/Localizable.strings && echo "PASS" || echo "FAIL: missing L10n key"
- name: Check ThemeID has 4 cases
  command: grep -c "case " App/Vreader/Vreader/ThemeID.swift && echo "cases found in ThemeID.swift"
- name: Check no force-unwrap in new theme files
  command: grep -rn "!\." App/Vreader/Vreader/ThemeStore.swift App/Vreader/Vreader/AppTheme.swift App/Vreader/Vreader/ThemeID.swift App/Vreader/Vreader/AppThemeError.swift 2>/dev/null || echo "PASS: no force-unwrap found"
```