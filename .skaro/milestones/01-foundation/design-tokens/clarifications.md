# Clarifications: design-tokens

## Question 1
Should DesignTokens.Colors contain actual Color values for each theme, or only semantic role names with neutral/adaptive values?

*Context:* FR-02 says Colors contains static Color values 'for each theme', but the spec also says theme logic belongs to AppTheme — this creates a direct contradiction about where theme-specific colors live.

**Options:**
- A) DesignTokens.Colors contains only adaptive/semantic Color values (e.g., using SwiftUI's Color(.systemBackground)) — theme-specific hex values live exclusively in AppTheme implementations
- B) DesignTokens.Colors contains raw palette constants (hex-based static Colors) used as building blocks by AppTheme, not as semantic roles
- C) DesignTokens.Colors contains both: a raw palette namespace and semantic adaptive colors — AppTheme picks from the palette

**Answer:**
DesignTokens.Colors contains raw palette constants (hex-based static Colors) used as building blocks by AppTheme, not as semantic roles

## Question 2
Should Color values be defined via SwiftUI's Color(red:green:blue:) initializer or via a custom Color(hex:) extension?

*Context:* The spec lists this as an open question — the answer determines whether a hex extension must be created and whether it lives in DesignTokens.swift or a separate file.

**Options:**
- A) Use Color(red:green:blue:alpha:) only — no extensions, no additional files, NFR-01 compliant
- B) Define a private Color(hex:) extension inside DesignTokens.swift — self-contained, no extra file
- C) Define Color(hex:) in a separate ColorExtensions.swift file and import from DesignTokens

**Answer:**
Define a private Color(hex:) extension inside DesignTokens.swift — self-contained, no extra file

## Question 3
Should Typography in DesignTokens define concrete Font values (e.g., Font.custom("Georgia", size: 17)) or only size/weight constants that AppTheme assembles into Fonts?

*Context:* FR-03 mentions fontDisplay and fontBody as Typography contents, but the architecture says font names per theme (Serif, grotesque, Typewriter) are theme-specific — hardcoding them in DesignTokens would violate the boundary.

**Options:**
- A) Typography contains only size constants (defaultFontSize, minFontSize, maxFontSize) and weight tokens — AppTheme constructs actual Font values
- B) Typography contains concrete Font values using system fonts (e.g., Font.serif, Font.system) as neutral defaults — AppTheme overrides per theme
- C) Typography contains both: size/weight constants AND a fontDisplay/fontBody computed via a theme-agnostic system font — AppTheme replaces them via environment

**Answer:**
Typography contains concrete Font values using system fonts (e.g., Font.serif, Font.system) as neutral defaults — AppTheme overrides per theme

## Question 4
Should the Reader namespace in DesignTokens duplicate the values already implied by architectural invariants (50MB, 3 pages), or should those invariants reference DesignTokens as their source?

*Context:* The architecture doc hardcodes '50MB per page' and '3 pages max' as performance contracts — if DesignTokens defines these, all other files must reference DesignTokens.Reader, otherwise the values are duplicated.

**Options:**
- A) DesignTokens.Reader is the single source of truth — all other files (FileFormatHandler, memory eviction logic) must reference DesignTokens.Reader.memoryBudgetPerPage and .maxPagesInMemory
- B) DesignTokens.Reader defines the constants for documentation/design purposes only — runtime enforcement uses its own constants (acceptable duplication for isolation)
- C) DesignTokens.Reader exists but is typealiased/referenced from a separate ReaderConstants.swift that business logic imports — DesignTokens stays UI-only

**Answer:**
DesignTokens.Reader is the single source of truth — all other files (FileFormatHandler, memory eviction logic) must reference DesignTokens.Reader.memoryBudgetPerPage and .maxPagesInMemory

## Question 5
Should Animation contain only duration Double constants, or also pre-built Animation/SpringAnimation values ready for use in .animation() modifiers?

*Context:* FR-06 specifies durations and 'spring parameters' — if only raw numbers are provided, every call site must reconstruct the Animation; if pre-built values are provided, usage is simpler but DesignTokens gains SwiftUI Animation dependencies.

**Options:**
- A) Animation namespace contains only Double duration constants and spring parameter constants (damping, response) — call sites construct Animation values themselves
- B) Animation namespace contains both raw constants AND pre-built static Animation values (e.g., DesignTokens.Animation.springStandard: Animation) for direct use in modifiers
- C) Animation namespace contains only pre-built Animation values — raw numbers are not exposed publicly

**Answer:**
Animation namespace contains both raw constants AND pre-built static Animation values (e.g., DesignTokens.Animation.springStandard: Animation) for direct use in modifiers

## Question 6
Should DesignTokens be an enum (caseless, namespace-only) or a struct with static members, and should nested namespaces follow the same pattern?

*Context:* The spec says 'enum DesignTokens with nested namespaces' but Swift enums used as namespaces vs caseless enums vs structs have different instantiation and extension behaviors — this must be explicit to avoid inconsistency across the codebase.

**Options:**
- A) Caseless enum DesignTokens with caseless nested enums for each namespace — prevents instantiation, idiomatic Swift namespace pattern
- B) Struct DesignTokens with nested caseless enums — allows potential future extension methods on the struct
- C) Caseless enum DesignTokens with nested structs — allows nested types to be extended in other files if needed

**Answer:**
Caseless enum DesignTokens with caseless nested enums for each namespace — prevents instantiation, idiomatic Swift namespace pattern
