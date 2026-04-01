# Specification: network-monitor

## Context
Many services (GeminiService, CloudProviders, MetadataFetcher) require network access. When offline, they must immediately return a `.offline` error, and the UI must show an offline banner. NetworkMonitor is the single source of truth for network state.

## User Scenarios
1. **Device goes offline:** `NetworkMonitor.isOnline` becomes `false`, `TranslationPanel` shows offline banner.
2. **Network restores:** `isOnline` becomes `true`, `PendingChangesQueue` begins synchronisation.
3. **GeminiService called without network:** Checks `NetworkMonitor.shared.isOnline`, immediately returns `VReaderError.offline()`.
4. **Non-UI consumer observes state:** Subscribes to `NetworkMonitor.shared.statusStream` (AsyncStream<Bool>) to react to transitions without SwiftUI observation.
5. **Rapid wifi handoff (online→offline→online within 500ms):** Offline transition is debounced 300ms; online restoration is published immediately — UI does not flicker.

## Functional Requirements
- **FR-01:** `NetworkMonitor` — `@Observable` singleton (`shared`), `@MainActor`
- **FR-02:** `var isOnline: Bool` — current network state; default value is `true` (optimistic) before `NWPathMonitor` fires its first update
- **FR-03:** `var connectionType: ConnectionType` — enum: `wifi`, `cellular`, `wiredEthernet`, `unknown`
- **FR-04:** Use `NWPathMonitor` to track network path changes
- **FR-05:** All published updates delivered on the main thread
- **FR-06:** `func startMonitoring()` and `func stopMonitoring()` exist for API completeness; because `NetworkMonitor` is a singleton, `NWPathMonitor` runs for the entire app lifetime and is never stopped — `stopMonitoring()` is a no-op
- **FR-07:** Monitoring starts automatically on initialisation
- **FR-08:** `var isExpensive: Bool` — `true` when the current path is cellular; exposes raw signal only; policy decisions (e.g. whether to allow background downloads) belong to `DownloadManager`
- **FR-09:** Register in `VreaderApp` via `.environment()`
- **FR-10:** `var statusStream: AsyncStream<Bool>` — broadcasts every resolved `isOnline` transition for non-UI consumers (e.g. `BackgroundSyncTask`); respects the same debounce rule as `isOnline`
- **FR-11:** Offline transitions are debounced by 300ms before being published to both `isOnline` and `statusStream`; online restoration is published immediately (zero debounce)
- **FR-12:** Every state transition (online→offline, offline→online) is logged at `.info` level via `DiagnosticsService`, including `connectionType` at the moment of transition

## Non-Functional Requirements
- **NFR-01:** Network change detection latency < 1 second for online restoration; offline debounce adds at most 300ms additional latency
- **NFR-02:** No memory leaks on repeated `startMonitoring()` / `stopMonitoring()` calls; `NWPathMonitor` instance is created once and never recreated
- **NFR-03:** `statusStream` continuations are cleaned up when the consumer's `for await` loop is cancelled

## Boundaries (what is NOT in scope)
- Retry logic on network restoration — owned by `BackgroundSyncTask`
- UI offline banners — owned by View components
- Endpoint reachability testing — only system-level path status is used
- Background download policy — owned by `DownloadManager`; `NetworkMonitor` exposes only `isExpensive`

## Acceptance Criteria
- [ ] `NetworkMonitor.shared` exists and is `@MainActor`
- [ ] `isOnline` defaults to `true` before the first `NWPathMonitor` callback fires
- [ ] `isOnline` correctly reflects live network state after first update
- [ ] `connectionType` and `isExpensive` are defined and updated on every path change
- [ ] All updates are delivered on the main thread
- [ ] `stopMonitoring()` is a no-op; `NWPathMonitor` is never cancelled for the singleton
- [ ] No memory leaks — `NWPathMonitor` instance is created exactly once
- [ ] `statusStream` emits `true`/`false` on every resolved transition
- [ ] `statusStream` continuations are removed when the consumer cancels
- [ ] Offline transition is debounced 300ms; online restoration is immediate
- [ ] Rapid online→offline→online within 500ms does not produce a visible offline event
- [ ] Every transition is logged via `DiagnosticsService` at `.info` level with `connectionType`
- [ ] `NetworkMonitor` is registered in `VreaderApp` via `.environment()`

## Open Questions
*(all resolved)*