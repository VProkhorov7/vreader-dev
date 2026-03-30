# Tasks: design-tokens

## Stage 1: DesignTokens Implementation

- [ ] Remove all existing content from `App/Vreader/Vreader/DesignTokens.swift` and replace with spec-compliant implementation → `App/Vreader/Vreader/DesignTokens.swift`
- [ ] Implement `private extension Color` with `init(hex:)` inside the file (6-digit RGB + optional 8-digit RGBA, no force-unwrap) → `App/Vreader/Vreader/DesignTokens.swift`
- [ ] Implement `enum DesignTokens` as caseless enum with `import SwiftUI` only → `App/Vreader/Vreader/DesignTokens.swift`
- [ ] Implement `enum Colors` with 7 palette `Color` constants (`surfaceBase`, `surfaceLow`, `surfaceMid`, `surfaceHigh`, `accent`, `inkPrimary`, `inkMuted`) + `surfaceOpacity: Double` + `blurRadius: CGFloat` → `App/Vreader/Vreader/DesignTokens.swift`
- [ ] Implement `enum Typography` with `fontDisplay: Font` and `fontBody: Font` using `Font.system`/`Font.serif` neutral defaults → `App/Vreader/Vreader/DesignTokens.swift`
- [ ] Implement `enum Spacing` with `xs`, `sm`, `md`, `lg`, `xl`, `xxl` as `CGFloat` → `App/Vreader/Vreader/DesignTokens.swift`
- [ ] Implement `enum Radius` with `small`, `medium`, `large`, `card` as `CGFloat` → `App/Vreader/Vreader/DesignTokens.swift`
- [ ] Implement `enum Animation` with `fast`, `normal`, `slow` as `Double`; `springDamping`, `springResponse` as `Double`; `easeInOutFast`, `easeInOutNormal`, `easeInOutSlow`, `springStandard` as `Animation` → `App/Vreader/Vreader/DesignTokens.swift`
- [ ] Implement `enum Reader` with `memoryBudgetPerPage: Int`, `maxPagesInMemory: Int`, `defaultFontSize: CGFloat`, `minFontSize: CGFloat`, `maxFontSize: CGFloat` → `App/Vreader/Vreader/DesignTokens.swift`
- [ ] Write `AI_NOTES.md` documenting hex color choices, font API decisions, Animation API version, and Reader as single source of truth → `AI_NOTES.md`