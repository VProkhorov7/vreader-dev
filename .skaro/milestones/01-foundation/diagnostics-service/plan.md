## plan.md

## Stage 1: DiagnosticsService Core + Tests

**Goal:** Implement the complete `DiagnosticsService` — ring buffer, PII filter, OSLog integration, `exportLogs()`, `persistLogsToCache()` — and the full test suite covering all acceptance criteria.

**Depends on:** none (file already exists as a stub at `App/Vreader/Vreader/DiagnosticsService.swift`; `AppError` exists at `App/Vreader/Vreader/AppError.swift`)

**Inputs:**
- `App/Vreader/Vreader/AppError.swift` — `AppError` type referenced by `FR-06`
- `App/Vreader/Vreader/DiagnosticsService.swift` — existing stub to replace
- Specification: diagnostics-service (all FRs, NFRs, acceptance criteria)
- Architecture invariants #14, #19

**Outputs:**
- `App/Vreader/Vreader/DiagnosticsService.swift` — full implementation
- `App/Vreader/VreaderTests/DiagnosticsServiceTests.swift` — unit tests

**DoD:**
- [ ] `DiagnosticsService.shared` is `final class` conforming to `@unchecked Sendable`
- [ ] `LogLevel` enum with cases: `debug`, `info`, `warning`, `error`, `fault`
- [ ] `LogCategory` enum with 8 cases: `library`, `reader`, `cloud`, `ai`, `sync`, `storeKit`, `fileSystem`, `navigation`
- [ ] `LogEntry` struct with `timestamp: Date`, `level: LogLevel`, `category: LogCategory`, `message: String`
- [ ] All 5 public logging methods compile: `debug(_:category:)`, `info(_:category:)`, `warning(_:category:)`, `error(_:context:)` (takes `AppError`), `fault(_:category:)`
- [ ] `os.Logger` used with `subsystem` = bundle identifier, `category` = `LogCategory.rawValue`
- [ ] Ring buffer capped at 100 entries; 101st entry evicts oldest
- [ ] `NSLock` protects only ring buffer mutations; OSLog calls outside lock
- [ ] `#if DEBUG` / `#if !DEBUG` guard: Release builds skip `debug` and `info` from buffer
- [ ] PII filter: case-insensitive `\b(token|password|key|secret)\b` regex replaces matched word with `[REDACTED]`; entry is still written to buffer
- [ ] `exportLogs()` returns plain text, one line per entry: `[ISO8601] [LEVEL] [CATEGORY] message`; internal newlines escaped as `\n`
- [ ] `persistLogsToCache()` writes to `FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)` as `diagnostics.log`; overwrites on repeat call
- [ ] Buffer is NOT restored from file on launch
- [ ] Test: 200 sequential entries → buffer contains exactly 100 newest
- [ ] Test: message `"password=abc"` → `LogEntry.message` contains `"[REDACTED]"`, entry present in buffer
- [ ] Test: message `"keystroke"` → not redacted (whole-word boundary)
- [ ] Test: message `"token=abc123"` → `"[REDACTED]=abc123"`
- [ ] Test: message `"storeKit"` → not redacted (no whole-word match for `key`)
- [ ] Test: `exportLogs()` format matches `[ISO8601] [LEVEL] [CATEGORY] message` pattern
- [ ] Test: `persistLogsToCache()` creates file in Caches directory; second call overwrites
- [ ] Test: Release-mode simulation — `info`/`debug` entries not added to buffer when guarded
- [ ] No PII (email, tokens, paths) in any log message in the implementation itself

**Risks:**
- `AppError` type shape unknown until file is read — must inspect before writing `func error(_:context:)` signature
- Regex `NSRegularExpression` in Swift 6 strict concurrency: must ensure the compiled regex is either a `let` constant (safe) or properly isolated
- Bundle identifier access via `Bundle.main.bundleIdentifier` may return `nil` in test target — use nil-coalescing fallback `"com.vreader.app"`

---

## Verify

```yaml
## Verify
- name: Build App target (confirms DiagnosticsService compiles with AppError)
  command: xcodebuild build -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20

- name: Run DiagnosticsService unit tests
  command: xcodebuild test -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VreaderTests/DiagnosticsServiceTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -40
```