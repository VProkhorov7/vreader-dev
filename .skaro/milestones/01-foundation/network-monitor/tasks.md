# Tasks: network-monitor

## Stage 1: NetworkMonitor Core Implementation + Integration

- [ ] Create `ConnectionType` enum (`wifi`, `cellular`, `wiredEthernet`, `unknown`) inside `NetworkMonitor.swift` → `App/Vreader/Vreader/NetworkMonitor.swift`
- [ ] Implement `@Observable @MainActor final class NetworkMonitor` with `shared` singleton → `App/Vreader/Vreader/NetworkMonitor.swift`
- [ ] Add `isOnline: Bool = true` (optimistic default), `connectionType: ConnectionType`, `isExpensive: Bool` published properties → `App/Vreader/Vreader/NetworkMonitor.swift`
- [ ] Add `startMonitoring()` (idempotent no-op) and `stopMonitoring()` (no-op) stubs → `App/Vreader/Vreader/NetworkMonitor.swift`
- [ ] Create single `NWPathMonitor` instance in `init`, start on a dedicated `DispatchQueue`, never recreate → `App/Vreader/Vreader/NetworkMonitor.swift`
- [ ] Implement `pathUpdateHandler` bridging to `@MainActor` via `Task { @MainActor in }` → `App/Vreader/Vreader/NetworkMonitor.swift`
- [ ] Implement 300ms debounce for offline transitions using `DispatchWorkItem`; immediate publish for online restoration → `App/Vreader/Vreader/NetworkMonitor.swift`
- [ ] Implement `statusStream: AsyncStream<Bool>` with `AsyncStream.Continuation` array, thread-safe under `@MainActor` isolation → `App/Vreader/Vreader/NetworkMonitor.swift`
- [ ] Wire `onTermination` on each continuation to remove it from the array on consumer cancellation → `App/Vreader/Vreader/NetworkMonitor.swift`
- [ ] Create `DiagnosticsService.swift` with `OSLog`-based logging (`debug`, `info`, `warning`, `error`, `fault` levels), no PII → `App/Vreader/Vreader/DiagnosticsService.swift`
- [ ] Add `.info` level transition logging calls in `NetworkMonitor` state-change handler including `connectionType` → `App/Vreader/Vreader/NetworkMonitor.swift`
- [ ] Add L10n string keys: `networkMonitor.online`, `networkMonitor.offline`, `networkMonitor.connectionType.wifi`, `networkMonitor.connectionType.cellular`, `networkMonitor.connectionType.wiredEthernet`, `networkMonitor.connectionType.unknown` → `App/Vreader/Vreader/L10n.swift`
- [ ] Add EN localizable strings for all network keys → `App/Vreader/Vreader/en.lproj/Localizable.strings`
- [ ] Add RU localizable strings for all network keys → `App/Vreader/Vreader/ru.lproj/Localizable.strings`
- [ ] Register `NetworkMonitor.shared` in `VreaderApp` via `.environment(NetworkMonitor.shared)` on the root view → `App/Vreader/Vreader/VreaderApp.swift`
- [ ] Write `NetworkMonitorTests`: test `isOnline` defaults to `true` → `App/Vreader/VreaderTests/NetworkMonitorTests.swift`
- [ ] Write test: `statusStream` emits `false` after offline transition resolves (300ms debounce) → `App/Vreader/VreaderTests/NetworkMonitorTests.swift`
- [ ] Write test: `statusStream` emits `true` immediately on online restoration (zero debounce) → `App/Vreader/VreaderTests/NetworkMonitorTests.swift`
- [ ] Write test: rapid online→offline→online within 500ms produces no offline event in `statusStream` → `App/Vreader/VreaderTests/NetworkMonitorTests.swift`
- [ ] Write test: `statusStream` continuation is removed from array after consumer `Task` is cancelled → `App/Vreader/VreaderTests/NetworkMonitorTests.swift`
- [ ] Write test: `connectionType` and `isExpensive` update correctly on path change → `App/Vreader/VreaderTests/NetworkMonitorTests.swift`