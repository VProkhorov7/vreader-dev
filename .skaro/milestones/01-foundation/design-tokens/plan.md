## plan.md

## Stage 1: DesignTokens Implementation

**Goal:** Replace the existing `DesignTokens.swift` stub with a complete, spec-compliant implementation containing all namespaces, constants, and the private `Color(hex:)` extension. This is the only stage required — the file is self-contained with no external project dependencies.

**Depends on:** none

**Inputs:**
- Specification: design-tokens (FR-01 through FR-09, all NFRs, all Acceptance Criteria)
- Clarifications (all 6 answered)
- Existing file: `App/Vreader/Vreader/DesignTokens.swift` (to be replaced)
- Architecture document (Reader memory budget values: 50MB, 3 pages)
- Constitution (no UIKit, no hardcoded literals elsewhere, SwiftLint-clean)

**Outputs:**
- `App/Vreader/Vreader/DesignTokens.swift` — complete replacement
- `AI_NOTES.md` — implementation notes

**DoD:**
- [ ] `enum DesignTokens` is a caseless enum; all nested namespaces (`Colors`, `Typography`, `Spacing`, `Radius`, `Animation`, `Reader`) are caseless enums
- [ ] `Colors` contains exactly: `surfaceBase`, `surfaceLow`, `surfaceMid`, `surfaceHigh`, `accent`, `inkPrimary`, `inkMuted` (all `Color`), plus `surfaceOpacity: Double = 0.85` and `blurRadius: CGFloat = 20`
- [ ] `Typography` contains `fontDisplay: Font` and `fontBody: Font` using only `Font.system` / `Font.serif` (no UIKit, no custom font names)
- [ ] `Spacing` contains `xs=4`, `sm=8`, `md=16`, `lg=24`, `xl=32`, `xxl=48` all as `CGFloat`
- [ ] `Radius` contains `small=4`, `medium=8`, `large=16`, `card=12` all as `CGFloat`
- [ ] `Animation` contains `fast: Double = 0.15`, `normal: Double = 0.25`, `slow: Double = 0.4`, `springDamping: Double`, `springResponse: Double`, plus `easeInOutFast`, `easeInOutNormal`, `easeInOutSlow`, `springStandard` all of type `Animation`
- [ ] `Reader` contains `memoryBudgetPerPage = 50 * 1024 * 1024` (Int), `maxPagesInMemory = 3` (Int), `defaultFontSize: CGFloat = 17`, `minFontSize: CGFloat = 12`, `maxFontSize: CGFloat = 32`
- [ ] `private extension Color` with `init(hex:)` is present in the file and not exported
- [ ] File imports only `SwiftUI` — no `UIKit`, `AppKit`, or other project modules
- [ ] File compiles without warnings under Swift 6 / Xcode 16
- [ ] No numeric literals duplicating DesignTokens values exist in other project files (verified by `check_refs.py` / grep)
- [ ] `AI_NOTES.md` documents all design decisions

**Risks:**
- `Font.serif` availability: available since iOS 13 via `Font.system(.body, design: .serif)` — must use the correct SwiftUI API, not a UIKit font descriptor
- `Animation` type in Swift 6: `Animation.spring(response:dampingFraction:)` API must be verified for iOS 17+ compatibility (it is available; `Animation.spring(dampingFraction:)` deprecated path avoided)
- Existing `DesignTokens.swift` may already define some symbols — full replacement avoids merge conflicts; the implementor must overwrite entirely
- `Color(hex:)` alpha channel handling: must correctly parse 6-digit hex (RGB) and optionally 8-digit (RGBA) without force-unwrap

---

## Verify

```yaml
- name: Check DesignTokens compiles (xcodebuild)
  command: xcodebuild -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -20

- name: Verify no UIKit import in DesignTokens
  command: grep -n "import UIKit\|import AppKit" App/Vreader/Vreader/DesignTokens.swift; [ $? -ne 0 ] && echo "PASS: no UIKit/AppKit" || echo "FAIL: found UIKit/AppKit"

- name: Verify all required Color constants present
  command: grep -c "surfaceBase\|surfaceLow\|surfaceMid\|surfaceHigh\|inkPrimary\|inkMuted\|accent" App/Vreader/Vreader/DesignTokens.swift

- name: Verify Reader memory budget value
  command: grep "memoryBudgetPerPage" App/Vreader/Vreader/DesignTokens.swift

- name: Verify Reader maxPagesInMemory value
  command: grep "maxPagesInMemory" App/Vreader/Vreader/DesignTokens.swift

- name: Verify private Color hex extension present
  command: grep -n "private extension Color" App/Vreader/Vreader/DesignTokens.swift

- name: Verify caseless enum pattern
  command: grep -n "^enum DesignTokens\|^ *enum Colors\|^ *enum Typography\|^ *enum Spacing\|^ *enum Radius\|^ *enum Animation\|^ *enum Reader" App/Vreader/Vreader/DesignTokens.swift

- name: Verify Spacing values
  command: grep -E "xs|sm\b|md\b|lg\b|xl\b|xxl" App/Vreader/Vreader/DesignTokens.swift

- name: Verify Animation pre-built values present
  command: grep -E "easeInOutFast|easeInOutNormal|easeInOutSlow|springStandard" App/Vreader/Vreader/DesignTokens.swift

- name: Run check_refs.py validation
  command: python3 Description/check_refs.py App/Vreader/Vreader/DesignTokens.swift 2>&1 || true
```