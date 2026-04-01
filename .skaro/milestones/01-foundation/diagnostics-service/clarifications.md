# Clarifications: diagnostics-service

## Question 1
Should the in-memory ring buffer persist to disk between app sessions?

*Context:* The spec leaves this as an open question, but the answer determines whether users can export logs from a previous crash session — a critical bug-reporting scenario.

**Options:**
- A) No persistence — memory only, buffer is lost on app termination or crash
- B) Persist to a single file in app's Caches directory (not Documents, not iCloud), overwritten each session
- C) Persist with crash-safe atomic write to Caches, so post-crash export is possible

**Answer:**
Persist to a single file in app's Caches directory (not Documents, not iCloud), overwritten each session

## Question 2
How should the PII keyword filter (token, password, key, secret) behave — silently drop the entire log entry, redact the matching substring, or crash in Debug?

*Context:* Silent drop loses diagnostic context entirely; redaction preserves structure but requires regex; a Debug assertion helps catch accidental PII logging during development.

**Options:**
- A) Silently drop the entire log entry and never write it to the buffer or OSLog
- B) Redact the matched word with '[REDACTED]' and log the sanitised message
- C) In Debug: trigger assertionFailure so the developer is alerted; in Release: silently drop

**Answer:**
Redact the matched word with '[REDACTED]' and log the sanitised message

## Question 3
What is the exact scope of the PII keyword filter — case-insensitive substring match on the full message string, or only on individual words/tokens?

*Context:* A substring match on 'key' would incorrectly suppress legitimate messages like 'keyboard shortcut pressed' or 'monkey-patched'; the matching strategy must be explicit.

**Options:**
- A) Case-insensitive whole-word boundary match (e.g., regex \bkey\b) to avoid false positives
- B) Case-insensitive substring match on the full message — simpler but may produce false positives
- C) Match only against a fixed set of exact lowercased tokens: ['token', 'password', 'apikey', 'secret', 'bearer']

**Answer:**
Case-insensitive whole-word boundary match (e.g., regex \bkey\b) to avoid false positives

## Question 4
Should DiagnosticsService be a Swift actor (true actor isolation) or an @Observable singleton protected by an internal lock/serial queue?

*Context:* FR-01 says 'actor for thread safety' but Swift actors interact poorly with OSLog's synchronous Logger API and with SwiftUI's @Observable; the concurrency model must be decided before implementation.

**Options:**
- A) Swift actor — full actor isolation; callers must await all log calls (fire-and-forget via Task { await ... } at call sites)
- B) Final class with an internal serial DispatchQueue for buffer mutations; OSLog calls are non-isolated and non-blocking
- C) Final class conforming to @unchecked Sendable with a NSLock protecting only the ring buffer; OSLog calls are unsynchronised (safe by design)

**Answer:**
Final class conforming to @unchecked Sendable with a NSLock protecting only the ring buffer; OSLog calls are unsynchronised (safe by design)

## Question 5
What format should exportLogs() produce, and how should multi-line messages be handled?

*Context:* The spec lists this as an open question; the format affects readability in share sheet, parsability by support tools, and the < 1 MB memory budget for 100 entries.

**Options:**
- A) Plain text, one entry per line: '[ISO8601] [LEVEL] [CATEGORY] message', newlines inside message escaped as \n
- B) Plain text with a separator line (---) between entries; internal newlines preserved as-is
- C) JSON array of objects — machine-readable, easy to parse, but larger and less human-friendly in share sheet

**Answer:**
Plain text, one entry per line: '[ISO8601] [LEVEL] [CATEGORY] message', newlines inside message escaped as \n

## Question 6
Which existing VReaderError / ErrorCode type should FR-06 (func error(_ error: VReaderError, context: String)) reference — the AppError.swift in App/Vreader or the ErrorCode.swift in Vreader/?

*Context:* The project tree contains both AppError.swift and ErrorCode.swift in different directories; using the wrong type will cause a broken reference that check_refs.py will reject.

**Options:**
- A) Use ErrorCode from Vreader/ErrorCode.swift — it matches the architecture spec's ErrorCode categories (.network, .fileSystem, etc.)
- B) Use AppError from App/Vreader/Vreader/AppError.swift — it is the type already used by existing App-layer services
- C) Define a new VReaderError typealias = ErrorCode in DiagnosticsService.swift to decouple the service from either file

**Answer:**
Use AppError from App/Vreader/Vreader/AppError.swift — it is the type already used by existing App-layer services
