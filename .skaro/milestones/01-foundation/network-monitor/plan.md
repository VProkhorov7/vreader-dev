## plan.md

## Stage 1: NetworkMonitor Core Implementation + Integration

**Goal:** Implement the complete `NetworkMonitor` module — the `@Observable` singleton with `NWPathMonitor`, debounce logic, `AsyncStream<Bool>` status stream, `DiagnosticsService` logging, L10n strings, unit tests, and `VreaderApp` registration. This is a single self-contained vertical slice with no real internal dependencies.

**Depends on:** None (existing codebase provides `DiagnosticsService` pattern via `AppError.swift`, `KeychainManager.swift`, `VreaderApp.swift`)

**Inputs:**
- Specification: `network-monitor`
- Architecture document
- `App/Vreader/Vreader/VreaderApp.swift` — registration point
- `App/Vreader/Vreader/L10n.swift` — string keys
- `App/Vreader/Vreader/en.lproj/Localizable.strings`
- `App/Vreader/Vreader/ru.lproj/Localizable.strings`
- `App/Vreader/Vreader/AppError.swift` — error pattern reference
- `App/Vreader/Vreader/DesignTokens.swift` — design reference

**Outputs:**
- `App/Vreader/Vreader/NetworkMonitor.swift` — core implementation
- `App/Vreader/Vreader/DiagnosticsService.swift` — logging service (created/extended if not present)
- `App/Vreader/Vreader/VreaderApp.swift` — modified to register `NetworkMonitor` via `.environment()`
- `App/Vreader/Vreader/L10n.swift` — added network-related string keys
- `App/Vreader/Vreader/en.lproj/Localizable.strings` — EN strings for network states
- `App/Vreader/Vreader/ru.lproj/Localizable.strings` — RU strings for network states
- `App/Vreader/VreaderTests/NetworkMonitorTests.swift` — unit tests

**DoD:**
- [ ] `NetworkMonitor` is `@Observable`, `@MainActor`, singleton via `shared`
- [ ] `isOnline: Bool` defaults to `true` before first `NWPathMonitor` callback
- [ ] `connectionType: ConnectionType` enum has `wifi`, `cellular`, `wiredEthernet`, `unknown` cases
- [ ] `isExpensive: Bool` reflects raw cellular path signal only
- [ ] `startMonitoring()` is idempotent (no-op if already running); `stopMonitoring()` is a no-op
- [ ] `NWPathMonitor` instance created exactly once in `init`, never recreated
- [ ] Offline transitions debounced 300ms via `DispatchWorkItem`; online restoration published immediately
- [ ] `statusStream: AsyncStream<Bool>` emits on every resolved transition
- [ ] `AsyncStream` continuations are removed on consumer cancellation (via `onTermination`)
- [ ] Every `online→offline` and `offline→online` transition logged at `.info` via `DiagnosticsService` with `connectionType`
- [ ] `NetworkMonitor.shared` registered in `VreaderApp` via `.environment(NetworkMonitor.shared)`
- [ ] All UI-facing strings use `L10n.*` keys — no hardcoded strings
- [ ] Unit tests cover: initial state, online→offline debounce, offline→online immediate, rapid handoff (no flicker), `statusStream` emission, `statusStream` cancellation cleanup
- [ ] No force-unwraps anywhere in the file
- [ ] Swift 6 concurrency — no data races, all `NWPathMonitor` callbacks dispatched to `@MainActor`

**Risks:**
- `DiagnosticsService` may not yet exist as a concrete file — must be created as a minimal `OSLog`-based implementation consistent with architecture; avoid duplicating any existing logging type
- `NWPathMonitor` callbacks arrive on a private queue — bridging to `@MainActor` requires explicit `DispatchQueue.main.async` or `MainActor.run`; incorrect dispatch causes Swift 6 concurrency warnings
- `AsyncStream` continuation management with multiple concurrent consumers requires a thread-safe continuation array; must use `@MainActor` isolation to avoid races
- Debounce via `DispatchWorkItem` must be cancelled correctly on rapid state changes to prevent stale offline events

---

## Verify

```yaml
- name: Build project (catches compile errors, missing symbols, Swift 6 concurrency issues)
  command: xcodebuild -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -40

- name: Run NetworkMonitor unit tests
  command: xcodebuild test -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VreaderTests/NetworkMonitorTests 2>&1 | tail -60

- name: Verify no hardcoded UI strings in NetworkMonitor
  command: grep -n '"[A-Za-z]' App/Vreader/Vreader/NetworkMonitor.swift | grep -v '//' | grep -v 'com\.' | grep -v 'vreader\.' || echo "PASS: no hardcoded UI strings"

- name: Verify NWPathMonitor is not force-unwrapped or recreated
  command: grep -n 'NWPathMonitor()' App/Vreader/Vreader/NetworkMonitor.swift | wc -l | xargs -I{} sh -c 'if [ {} -eq 1 ]; then echo "PASS: single NWPathMonitor instance"; else echo "FAIL: multiple NWPathMonitor instantiations"; fi'

- name: Verify stopMonitoring is a no-op (no cancel call inside it)
  command: awk '/func stopMonitoring/,/^    \}/' App/Vreader/Vreader/NetworkMonitor.swift | grep -v 'no-op\|noop\|//' | grep 'cancel' && echo "FAIL: stopMonitoring calls cancel" || echo "PASS: stopMonitoring is no-op"

- name: Verify NetworkMonitor registered in VreaderApp
  command: grep -n 'NetworkMonitor' App/Vreader/Vreader/VreaderApp.swift | grep 'environment' && echo "PASS" || echo "FAIL: NetworkMonitor not registered via .environment()"

- name: Verify L10n keys exist for network strings
  command: grep -c 'network\|offline\|online\|connection' App/Vreader/Vreader/en.lproj/Localizable.strings | xargs -I{} sh -c 'if [ {} -ge 2 ]; then echo "PASS: L10n network strings present"; else echo "FAIL: missing L10n network strings"; fi'
```