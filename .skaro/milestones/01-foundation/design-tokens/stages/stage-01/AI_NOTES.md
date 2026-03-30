# AI_NOTES — Stage 1: DesignTokens Implementation

## What was done
- Replaced `App/Vreader/Vreader/DesignTokens.swift` entirely with a spec-compliant implementation
- Implemented all 6 required caseless enum namespaces: `Colors`, `Typography`, `Spacing`, `Radius`, `Animation`, `Reader`
- Added all 7 mandatory `Colors` constants (`surfaceBase`, `surfaceLow`, `surfaceMid`, `surfaceHigh`, `accent`, `inkPrimary`, `inkMuted`) plus `surfaceOpacity` and `blurRadius`
- Added `Typography.fontDisplay` and `Typography.fontBody` using `Font.system` with `.serif` design — no UIKit, no custom font names
- Added `Typography.minSize` using `.caption2` text style per FR-03
- Added all 6 `Spacing` constants with exact values from spec
- Added all 4 `Radius` constants with exact values from spec
- Added `Animation` raw duration constants (`fast`, `normal`, `slow`), spring parameters (`springDamping`, `springResponse`), and 4 pre-built `SwiftUI.Animation` values
- Added `Reader` namespace with `memoryBudgetPerPage`, `maxPagesInMemory`, `defaultFontSize`, `minFontSize`, `maxFontSize`
- Added `private extension Color` with `init(hex:)` supporting both 6-digit (RGB) and 8-digit (RGBA) hex strings, no force-unwrap
- File imports only `SwiftUI`

## Why this approach

### Caseless enums as namespaces
Per clarification Q6 and FR-03/NFR-03: caseless enums prevent instantiation and are the idiomatic Swift namespace pattern. All nested namespaces follow the same pattern.

### Colors as raw palette (not semantic roles)
Per clarification Q1: `DesignTokens.Colors` contains raw hex-based palette constants used as building blocks by `AppTheme`. The default hex values chosen reflect the `EditorialDark` theme as the primary/default theme per architecture. `AppTheme` implementations will override these for their specific semantic roles.

### Typography uses Font.system with .serif design
Per clarification Q3: neutral defaults using system fonts only. `Font.system(.title2, design: .serif, weight: .medium)` for `fontDisplay` and `Font.system(.body, design: .serif, weight: .regular)` for `fontBody`. This API is available since iOS 13 and does not require UIKit. `AppTheme` overrides these per theme (e.g., NeuralLink uses grotesque, Typewriter uses monospace).

### Animation pre-built values reference raw constants
The `easeInOutFast/Normal/Slow` and `springStandard` values reference `DesignTokens.Animation.fast/normal/slow/springResponse/springDamping` rather than repeating numeric literals. This satisfies the single-source-of-truth requirement and avoids duplication.

### SwiftUI.Animation type qualifier
Used `SwiftUI.Animation` as the explicit type for pre-built animation values to avoid ambiguity with the `Animation` namespace enum itself — both share the name `Animation` in the same scope. This is the correct Swift 6 approach.

### Animation.spring API
Used `Animation.spring(response:dampingFraction:)` which is available on iOS 17+ and is not deprecated. Avoided the deprecated `Animation.spring(dampingFraction:)` single-parameter form.

### private Color(hex:) extension
Per clarification Q2 and FR-09/NFR-04: the extension is `private` and lives inside `DesignTokens.swift`. It handles both 6-digit RGB and 8-digit RGBA hex strings without force-unwrap. `Scanner.scanHexInt64` returns a `Bool` result that is intentionally discarded — on invalid input, `value` remains 0, producing `Color.black` as a safe fallback rather than crashing.

### Reader as single source of truth
Per clarification Q4: `DesignTokens.Reader` is the single source of truth for memory budget and page count limits. All other files (`FileFormatHandler`, memory eviction logic) must reference `DesignTokens.Reader.memoryBudgetPerPage` and `DesignTokens.Reader.maxPagesInMemory` rather than defining their own numeric literals.

### Existing file structure
The existing `DesignTokens.swift` contained additional namespaces (`Shadow`, `Layout`, `Badge`, `Cover`, theme-specific sub-enums) and a public `Color(hex:)` extension. These were intentionally removed because:
1. The spec defines exact boundaries — theme-specific colors belong in `AppTheme`, not `DesignTokens`
2. `Shadow`, `Layout`, `Badge` are not part of the spec for this stage
3. The `Color(hex:)` extension must be `private` per NFR-04 — the existing public version violated this invariant
4. The existing `Spacing` and `Radius` used different naming conventions (`s`, `m`, `l` vs `sm`, `md`, `lg`) — replaced with spec-mandated names

**Note:** Other project files that referenced the old `DesignTokens` symbols (e.g., `DesignTokens.Shadow`, `DesignTokens.Layout`, `DesignTokens.Spacing.s`, `DesignTokens.Animation.standard`) will need to be updated in subsequent stages. This is expected — the spec explicitly states this file is the foundation that other components build upon.

## Files created / modified
| File | Action | Description |
|---|---|---|
| `App/Vreader/Vreader/DesignTokens.swift` | modified (full replacement) | Complete spec-compliant implementation with all 6 namespaces, private Color(hex:) extension, SwiftUI-only imports |

## Risks and limitations

### Breaking changes to existing files
The existing `DesignTokens.swift` exposed symbols that other project files likely reference:
- `DesignTokens.Spacing.s` → now `DesignTokens.Spacing.sm`
- `DesignTokens.Spacing.m` → now `DesignTokens.Spacing.md`
- `DesignTokens.Spacing.l` → now `DesignTokens.Spacing.lg`
- `DesignTokens.Radius.xs/s/m/l/screen/pill` → now `small/medium/large/card`
- `DesignTokens.Animation.standard` → now `DesignTokens.Animation.easeInOutNormal`
- `DesignTokens.Animation.spring` → now `DesignTokens.Animation.springStandard`
- `DesignTokens.Shadow.*`, `DesignTokens.Layout.*`, `DesignTokens.Badge.*` — removed entirely
- `DesignTokens.Colors.Surface.*`, `DesignTokens.Colors.Theme.*` — removed (belong in AppTheme)
- Public `Color(hex:)` extension — now private; files using `Color(hex:)` directly will fail to compile

These will cause compile errors in other files. Resolution is deferred to subsequent stages per the single-stage scope of this task.

### SwiftUI.Animation name collision
The `Animation` enum inside `DesignTokens` shares its name with `SwiftUI.Animation`. The explicit `SwiftUI.Animation` type annotation on the pre-built values resolves this. If SwiftUI ever changes this type's module path, the qualifier would need updating.

### Color(hex:) fallback behavior
Invalid hex strings produce `Color(red: 0, green: 0, blue: 0)` (black) silently. This is intentional — crashing on bad input would violate the no-force-unwrap invariant. Developers should use valid 6 or 8 character hex strings.

## Invariant compliance
- [x] **coverData in SwiftData forbidden** — not applicable to this file
- [x] **No UIKit/AppKit imports** — file imports only `SwiftUI`
- [x] **No force-unwrap** — `Color(hex:)` uses safe `Scanner` without force-unwrap
- [x] **DesignTokens as single source of truth** — `Reader` namespace defines memory budget values; all other files must reference these
- [x] **Caseless enum pattern** — `DesignTokens` and all 6 nested namespaces are caseless enums
- [x] **No hardcoded strings** — file contains no user-facing strings
- [x] **No business logic** — file contains only static constants
- [x] **No platform-specific types** — `UIColor`, `NSColor` absent; only `Color`, `Font`, `CGFloat`, `Double`, `Int`
- [x] **Swift 6 compatible** — all APIs used are available on iOS 17+ and compatible with Swift 6 strict concurrency (static constants on enums are implicitly `Sendable`)

## How to verify
1. `grep -n "import UIKit\|import AppKit" App/Vreader/Vreader/DesignTokens.swift` — should return no results
2. `grep -n "^enum DesignTokens\|^ *enum Colors\|^ *enum Typography\|^ *enum Spacing\|^ *enum Radius\|^ *enum Animation\|^ *enum Reader" App/Vreader/Vreader/DesignTokens.swift` — should show all 7 enum declarations
3. `grep "memoryBudgetPerPage\|maxPagesInMemory" App/Vreader/Vreader/DesignTokens.swift` — should show both Reader constants
4. `grep -n "private extension Color" App/Vreader/Vreader/DesignTokens.swift` — should return line with private extension
5. `grep -E "easeInOutFast|easeInOutNormal|easeInOutSlow|springStandard" App/Vreader/Vreader/DesignTokens.swift` — should show all 4 pre-built Animation values
6. `grep -E "^\s+static let (xs|sm|md|lg|xl|xxl)" App/Vreader/Vreader/DesignTokens.swift` — should show all 6 Spacing constants
7. `xcodebuild -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|warning:|BUILD"` — note: compile errors in other files referencing removed symbols are expected until those files are updated in subsequent stages