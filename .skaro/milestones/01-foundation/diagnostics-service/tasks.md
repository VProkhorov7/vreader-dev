# Tasks: diagnostics-service

## Stage 1: DiagnosticsService Core + Tests

- [ ] Read `App/Vreader/Vreader/AppError.swift` to confirm `AppError` type signature before writing `func error(_:context:)` → `App/Vreader/Vreader/DiagnosticsService.swift`
- [ ] Define `LogLevel` enum with cases `debug`, `info`, `warning`, `error`, `fault` → `App/Vreader/Vreader/DiagnosticsService.swift`
- [ ] Define `LogCategory: String` enum with 8 cases: `library`, `reader`, `cloud`, `ai`, `sync`, `storeKit`, `fileSystem`, `navigation` → `App/Vreader/Vreader/DiagnosticsService.swift`
- [ ] Define `LogEntry` struct: `timestamp: Date`, `level: LogLevel`, `category: LogCategory`, `message: String` → `App/Vreader/Vreader/DiagnosticsService.swift`
- [ ] Implement `DiagnosticsService` as `final class` with `@unchecked Sendable`, singleton `shared`, `NSLock`-protected ring buffer (capacity 100) → `App/Vreader/Vreader/DiagnosticsService.swift`
- [ ] Implement PII filter using `NSRegularExpression` with pattern `\b(token|password|key|secret)\b`, case-insensitive, replacing matched word with `[REDACTED]` → `App/Vreader/Vreader/DiagnosticsService.swift`
- [ ] Implement `os.Logger` per-category map with `subsystem = Bundle.main.bundleIdentifier ?? "com.vreader.app"` → `App/Vreader/Vreader/DiagnosticsService.swift`
- [ ] Implement `func debug(_:category:)`, `func info(_:category:)`, `func warning(_:category:)`, `func fault(_:category:)` — each sanitises message, calls OSLog outside lock, appends to buffer inside lock with `#if DEBUG` guard for debug/info → `App/Vreader/Vreader/DiagnosticsService.swift`
- [ ] Implement `func error(_ error: AppError, context: String)` — formats message from `AppError`, sanitises, logs at `.error` level → `App/Vreader/Vreader/DiagnosticsService.swift`
- [ ] Implement `func exportLogs() -> String` — ISO8601 timestamp, escaped internal newlines, one line per entry → `App/Vreader/Vreader/DiagnosticsService.swift`
- [ ] Implement `func persistLogsToCache()` — writes `exportLogs()` to `Caches/diagnostics.log`, overwrites atomically → `App/Vreader/Vreader/DiagnosticsService.swift`
- [ ] Write test: 200 sequential entries → buffer count == 100, newest 100 preserved → `App/Vreader/VreaderTests/DiagnosticsServiceTests.swift`
- [ ] Write test: `"password=abc"` → `LogEntry.message` contains `"[REDACTED]"`, entry in buffer → `App/Vreader/VreaderTests/DiagnosticsServiceTests.swift`
- [ ] Write test: `"keystroke"` → message unchanged (whole-word boundary) → `App/Vreader/VreaderTests/DiagnosticsServiceTests.swift`
- [ ] Write test: `"token=abc123"` → `"[REDACTED]=abc123"` → `App/Vreader/VreaderTests/DiagnosticsServiceTests.swift`
- [ ] Write test: `"storeKit"` → not redacted (no whole-word match for `key`) → `App/Vreader/VreaderTests/DiagnosticsServiceTests.swift`
- [ ] Write test: `exportLogs()` output lines match regex `^\[.+\] \[.+\] \[.+\] .+$` → `App/Vreader/VreaderTests/DiagnosticsServiceTests.swift`
- [ ] Write test: `persistLogsToCache()` creates file in Caches directory; second call overwrites (file mtime changes or content changes) → `App/Vreader/VreaderTests/DiagnosticsServiceTests.swift`
- [ ] Write test: Release-mode buffer guard — `info` and `debug` entries skipped in buffer when `#if !DEBUG` path is exercised (simulate via a testable internal flag or conditional compilation) → `App/Vreader/VreaderTests/DiagnosticsServiceTests.swift`