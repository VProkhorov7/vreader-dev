# Clarifications: error-code-system

## Question 1
Should ErrorCode and its nested enums conform to Sendable for safe use across Swift 6 actor boundaries?

*Context:* Swift 6 enforces strict concurrency; GeminiService, CloudProviders, and SwiftData @ModelActor all throw errors across actor boundaries, so Sendable conformance on ErrorCode affects whether AppError can be passed without warnings.

**Options:**
- A) Yes — ErrorCode, all nested enums, and AppError must conform to Sendable explicitly
- B) Yes — only ErrorCode and AppError need Sendable; nested enums inherit it automatically as they have no associated values with reference types
- C) No — not needed, the call sites handle actor isolation themselves

**Answer:**
Yes — ErrorCode, all nested enums, and AppError must conform to Sendable explicitly

## Question 2
What is the exact scope of nested cases for each of the 8 ErrorCode categories?

*Context:* The spec only gives FileSystemError as an example with 4 cases; without a defined case list for the remaining 7 categories (NetworkError, CloudProviderError, AIServiceError, StoreKitError, SyncError, ParsingError, AuthError), the implementation will either be under-specified or inconsistent with existing throwing code.

**Options:**
- A) Define a minimal but complete set now: ~3–5 cases per category derived from existing code (WebDAVProvider, GeminiService, StoreKit flows, etc.)
- B) Define only the cases explicitly referenced by the 5 factory methods (fileNotFound, networkUnavailable, premiumRequired, timeout, plus auth); leave others as .unknown placeholder per category
- C) Defer to a follow-up spec; implement only FileSystemError fully now and stub the rest with a single .unknown(String) case per category

**Answer:**
Define a minimal but complete set now: ~3–5 cases per category derived from existing code (WebDAVProvider, GeminiService, StoreKit flows, etc.)

## Question 3
How should analyticsCode be structured to guarantee no PII leaks while remaining useful for diagnostics?

*Context:* Architectural invariant #14 forbids PII in logs; analyticsCode must be safe to pass to DiagnosticsService and AnalyticsEvent.errorOccurred(code:), so its format directly determines what information is safe to surface.

**Options:**
- A) Dot-separated category + case name only, e.g. 'fileSystem.fileNotFound' — no dynamic values, no paths, no tokens
- B) Numeric code per category+case pair, e.g. '1001', with a static lookup table mapping codes to human labels kept only in source
- C) Category + case name + a single non-PII context tag allowed, e.g. 'aiService.timeout[gemini]', where the tag is an enum value not a runtime string

**Answer:**
Dot-separated category + case name only, e.g. 'fileSystem.fileNotFound' — no dynamic values, no paths, no tokens

## Question 4
Should AppError.description and recoveryHint use live L10n.* calls now, or compile-time String constants that will be replaced by L10n in the localization milestone?

*Context:* NFR-01 requires all strings via L10n.*, but L10n for error strings may not yet exist in the current L10n.swift; using hardcoded English strings now and L10n later risks check_refs.py failures at the localization milestone.

**Options:**
- A) Add L10n keys for all error strings now (in both en.lproj and ru.lproj) and reference them via L10n.* immediately
- B) Use internal private String constants in English now; add a TODO comment marking each for L10n replacement; check_refs.py exemption documented in AI_NOTES
- C) Use L10n.* references now but add the actual string values to Localizable.strings as part of this same commit

**Answer:**
Use internal private String constants in English now; add a TODO comment marking each for L10n replacement; check_refs.py exemption documented in AI_NOTES

## Question 5
Should the existing ErrorCode.swift be fully replaced or incrementally extended, and how should migration of existing call sites be handled?

*Context:* The project already has ErrorCode.swift in both Vreader/ and App/Vreader/Vreader/; replacing it risks breaking existing throwing code, while extending it risks type duplication which check_refs.py will flag.

**Options:**
- A) Full replacement: delete existing ErrorCode.swift, introduce AppError + new ErrorCode in one file, fix all call sites in the same commit
- B) Additive extension: keep existing ErrorCode enum cases, wrap them inside the new nested category enums via a compatibility typealias layer
- C) New file AppError.swift alongside existing ErrorCode.swift with a deprecation notice; remove ErrorCode.swift only after all call sites are migrated in a follow-up

**Answer:**
Full replacement: delete existing ErrorCode.swift, introduce AppError + new ErrorCode in one file, fix all call sites in the same commit
