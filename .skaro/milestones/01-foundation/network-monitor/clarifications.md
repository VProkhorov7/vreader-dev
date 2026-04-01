# Clarifications: network-monitor

## Question 1
Should NetworkMonitor expose a Combine/AsyncSequence publisher for state changes, or is @Observable observation sufficient for all consumers?

*Context:* GeminiService and other non-UI services need to react to network changes programmatically; @Observable alone only works in SwiftUI view context via withObservationTracking.

**Options:**
- A) Add AsyncStream<Bool> var statusStream for non-UI consumers alongside @Observable
- B) @Observable only — non-UI consumers call NetworkMonitor.shared.isOnline synchronously at call site
- C) Add a callback/closure var onStatusChange: ((Bool) -> Void)? for non-UI consumers

**Answer:**
Add AsyncStream<Bool> var statusStream for non-UI consumers alongside @Observable

## Question 2
What is the initial value of isOnline before NWPathMonitor fires its first update?

*Context:* There is a brief window between init and first NWPathMonitor callback where isOnline has no real value; services calling it immediately after app launch may get wrong result.

**Options:**
- A) Default to true (optimistic) — assume online until proven otherwise
- B) Default to false (pessimistic) — block network calls until first real update arrives
- C) Add var isReady: Bool = false and make consumers wait until first update fires

**Answer:**
Default to true (optimistic) — assume online until proven otherwise

## Question 3
Should NetworkMonitor log state-change events to DiagnosticsService?

*Context:* The spec's Open Questions explicitly ask about history for DiagnosticsService; the architecture requires all errors to be typed and observability to be consistent across services.

**Options:**
- A) Yes — log every transition (online→offline, offline→online) at .info level via DiagnosticsService
- B) No — NetworkMonitor has no dependency on DiagnosticsService; callers log as needed
- C) Log only offline transitions at .warning level, ignore restore events

**Answer:**
Yes — log every transition (online→offline, offline→online) at .info level via DiagnosticsService

## Question 4
How should isExpensive interact with DownloadManager's background download decisions — is NetworkMonitor responsible for exposing a combined 'allowsBackgroundDownload' computed property?

*Context:* The spec defines isExpensive but does not clarify whether the policy decision (cellular = no background download) lives in NetworkMonitor or in DownloadManager, risking duplicated logic.

**Options:**
- A) NetworkMonitor exposes only raw isExpensive: Bool; DownloadManager owns the policy decision
- B) NetworkMonitor adds var allowsBackgroundDownload: Bool { isOnline && !isExpensive } as a convenience
- C) DownloadManager reads both isOnline and isExpensive directly and combines them internally

**Answer:**
NetworkMonitor exposes only raw isExpensive: Bool; DownloadManager owns the policy decision

## Question 5
Should stopMonitoring() be called automatically on deinit, or is explicit lifecycle management required by the caller?

*Context:* As a singleton, deinit never fires in practice, but the NFR-02 requirement about no memory leaks on repeated start/stop implies the NWPathMonitor must be cancelled correctly.

**Options:**
- A) Call nwMonitor.cancel() inside stopMonitoring() only; caller (VreaderApp) is responsible for calling it on scene phase .background
- B) Call nwMonitor.cancel() in both stopMonitoring() and deinit for safety
- C) Never stop monitoring for a singleton — NWPathMonitor runs for the entire app lifetime

**Answer:**
Never stop monitoring for a singleton — NWPathMonitor runs for the entire app lifetime

## Question 6
How should multiple rapid network state changes (e.g., wifi handoff causing online→offline→online within 500ms) be handled to avoid UI flicker?

*Context:* NWPathMonitor can fire multiple callbacks during network transitions; without debouncing, isOnline will toggle rapidly causing banner to flash.

**Options:**
- A) Debounce updates by 300ms using a DispatchWorkItem — only publish final stable state
- B) Publish every change immediately with no debounce — UI components handle their own debounce if needed
- C) Debounce only offline transitions (300ms), publish online restoration immediately

**Answer:**
Debounce only offline transitions (300ms), publish online restoration immediately
