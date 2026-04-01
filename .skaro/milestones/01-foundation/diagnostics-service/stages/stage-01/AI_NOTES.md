# AI_NOTES — Stage 1: DiagnosticsService Core + Tests

## What was done
- Implemented `DiagnosticsService` as a `final class` conforming to `@unchecked Sendable`, with a singleton `shared` instance.
- Defined `LogLevel` and `LogCategory` enums, and `LogEntry` struct.
- Integrated `os.Logger` for system-level logging, using the app's bundle identifier as the subsystem and `LogCategory.rawValue` for the category.
- Implemented a ring buffer to store the last 100 `LogEntry` instances in memory.
- Added `NSLock` to protect concurrent access and mutations to the ring buffer.
- Implemented PII filtering using `NSRegularExpression` with a case-insensitive, whole-word boundary match for "token", "password", "key", "secret", replacing matches with `[REDACTED]`.
- Implemented all five logging methods (`debug`, `info`, `warning`, `error`, `fault`).
- The `error` method now accepts an `AppError` instance and a context string, formatting the log message to include `AppError.description`, `AppError.code`, and `AppError.recoveryHint`, and mapping `AppError` types to appropriate `LogCategory` values.
- Implemented `exportLogs()` to return a plain text string of buffered entries, formatted as `[ISO8601] [LEVEL] [CATEGORY] message`, with internal newlines escaped as `\n`.
- Implemented `persistLogsToCache()` to write the exported logs to a `diagnostics.log` file in the app's Caches directory, overwriting the file on each call. The buffer is explicitly NOT restored from this file on app launch.
- Added `#if DEBUG` guards to control which log levels (`debug`, `info`) are added to the in-memory buffer in Release builds. A `_isTestingReleaseMode` flag was introduced for testing this behavior in Debug builds.
- Created `DiagnosticsServiceTests.swift` with comprehensive unit tests covering all acceptance criteria, including ring buffer capacity, PII filtering, export format, persistence to cache, and `AppError` integration.

## Why this approach
- **Singleton (`shared`) and `@unchecked Sendable`:** Aligns with FR-01 and Clarification 4, providing a single, globally accessible logging point that can be used across threads without strict Swift concurrency actor overhead, relying on `NSLock` for critical sections.
- **`NSLock` for ring buffer:** As per FR-01 and NFR-01, `NSLock` is used only for the ring buffer mutations, ensuring thread safety for the buffer without blocking `os.Logger` calls, which are inherently thread-safe.
- **`os.Logger` integration:** Meets FR-09, leveraging Apple's efficient and privacy-preserving unified logging system.
- **PII Filtering (`NSRegularExpression`):** Addresses FR-14 and Clarifications 2 & 3, using a robust regex with whole-word boundary and case-insensitivity to prevent false positives while effectively redacting sensitive data.
- **Ring Buffer Logic:** Implements FR-10 and FR-12, providing a fixed-size buffer for recent logs, with conditional population based on build configuration.
- **`AppError` Integration:** Satisfies FR-06 and Clarification 6, ensuring structured error logging with rich details and correct category mapping.
- **`exportLogs()` format:** Complies with FR-11 and Clarification 5, providing a human-readable, single-line-per-entry format suitable for sharing.
- **`persistLogsToCache()`:** Implements FR-15 and Clarification 1, allowing users to export logs from a previous session (e.g., after a crash) without restoring the buffer to memory on launch, respecting the Caches directory for transient data.
- **Comprehensive Unit Tests:** Ensures all functional and non-functional requirements, as well as acceptance criteria, are met, providing high confidence in the implementation. The `_isTestingReleaseMode` flag was a pragmatic solution to test compile-time conditional logic within a Debug test environment.

## Files created / modified
| File | Action | Description |
|---|---|---|
| `App/Vreader/Vreader/DiagnosticsService.swift` | modified | Full implementation of the DiagnosticsService, including ring buffer, PII filtering, OSLog integration, `exportLogs()`, and `persistLogsToCache()`. |
| `App/Vreader/VreaderTests/DiagnosticsServiceTests.swift` | created | Unit tests for `DiagnosticsService`, covering all specified acceptance criteria. |

## Risks and limitations
- **`os.Logger` testability:** Direct unit testing of `os.Logger` calls (e.g., verifying the exact `OSLogType` or `category` passed) is inherently difficult without mocking the system framework, which is out of scope. The tests focus on the observable behavior of the `DiagnosticsService` (ring buffer, PII filtering, export).
- **`@unchecked Sendable`:** While necessary for the singleton pattern with `NSLock`, it places a burden on the developer to ensure thread safety manually. The `NSLock` usage is carefully scoped to mitigate this for the ring buffer.
- **Bundle Identifier in Tests:** `Bundle.main.bundleIdentifier` can return `nil` in some test environments. The implementation includes a nil-coalescing fallback (`"com.vreader.app"`) to handle this gracefully.

## Invariant compliance
- [x] **Invariant #14: Никаких PII в логах** — Respected. The `sanitize` method actively redacts sensitive keywords (`token`, `password`, `key`, `secret`) from all log messages before they are passed to `os.Logger` or stored in the ring buffer. The implementation itself avoids logging PII.
- [x] **Invariant #19: Все ошибки типизированы** — Respected. The `error(_:context:)` method specifically accepts `AppError`, which is a typed error conforming to the `ErrorCode` concept (as per the `AppError.swift` structure with `code`, `description`, `recoveryHint`). This ensures all errors logged via this method are structured and contain necessary diagnostic information.
---