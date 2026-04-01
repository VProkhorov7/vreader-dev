import Foundation
import Network
import SwiftUI

/// Protocol for network path monitoring, allowing for testability.
protocol PathMonitoring {
    var pathUpdateHandler: ((NWPath) -> Void)? { get set }
    var currentPath: NWPath { get }
    func start(queue: DispatchQueue)
    func cancel()
}

/// Extend `NWPathMonitor` to conform to `PathMonitoring` protocol.
extension NWPathMonitor: PathMonitoring {}

/// `NetworkMonitor` is a singleton `@Observable` class that tracks the device's network connectivity.
/// It provides real-time updates on network status, connection type, and cost (e.g., cellular data).
/// It debounces offline transitions to prevent UI flickering during rapid network changes.
@Observable @MainActor
final class NetworkMonitor {
    /// The shared singleton instance of `NetworkMonitor`.
    static let shared = NetworkMonitor()

    /// Represents the type of network connection.
    enum ConnectionType: String, CaseIterable, Sendable {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
    }

    /// Indicates whether the device currently has an active network connection.
    /// Defaults to `true` (optimistic) before the first `NWPathMonitor` update.
    var isOnline: Bool = true

    /// The current type of network connection.
    var connectionType: ConnectionType = .unknown

    /// Indicates if the current network connection is considered expensive (e.g., cellular data).
    var isExpensive: Bool = false

    private let monitor: PathMonitoring // Using protocol for testability
    private let queue = DispatchQueue(label: "com.vreader.networkmonitor.queue", qos: .utility)
    private var debounceWorkItem: DispatchWorkItem?
    private var continuations: [UUID: AsyncStream<Bool>.Continuation] = [:]

    /// An `AsyncStream` that broadcasts every resolved `isOnline` transition.
    /// Non-UI consumers can subscribe to this stream to react to network changes.
    var statusStream: AsyncStream<Bool> {
        AsyncStream { continuation in
            let id = UUID()
            self.continuations[id] = continuation
            continuation.onTermination = { @Sendable _ in
                // NFR-03: Continuations are cleaned up when the consumer's loop is cancelled.
                Task { @MainActor in
                    self.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    /// Private initializer to enforce the singleton pattern.
    /// Monitoring starts automatically upon initialization.
    /// - Parameter monitor: An optional `PathMonitoring` instance for dependency injection in tests.
    init(monitor: PathMonitoring = NWPathMonitor()) {
        self.monitor = monitor
        startMonitoring() // FR-07: Monitoring starts automatically on initialisation
    }

    /// Starts network path monitoring.
    /// This method is idempotent and effectively a no-op if monitoring is already active for the singleton.
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }
        monitor.start(queue: queue)
        DiagnosticsService.shared.info(L10n.Network.monitoringStarted)
    }

    /// Stops network path monitoring.
    /// For a singleton `NetworkMonitor`, `NWPathMonitor` runs for the entire app lifetime.
    /// Therefore, this method is a no-op and does not cancel the underlying `NWPathMonitor`.
    func stopMonitoring() {
        // FR-06: stopMonitoring() is a no-op for the singleton.
        // The underlying NWPathMonitor is never cancelled for the app's lifetime.
        DiagnosticsService.shared.info(L10n.Network.monitoringStoppedNoOp)
    }

    /// Handles updates from `NWPathMonitor`.
    /// - Parameter path: The new network path.
    private func handlePathUpdate(_ path: NWPath) {
        let newIsOnline = path.status == .satisfied
        let newConnectionType = NetworkMonitor.getConnectionType(for: path)
        let newIsExpensive = path.isExpensive

        // FR-05: All published updates delivered on the main thread.
        Task { @MainActor in
            let oldIsOnline = self.isOnline

            // Update connectionType and isExpensive immediately as they don't require debounce.
            self.connectionType = newConnectionType
            self.isExpensive = newIsExpensive

            // FR-11: Offline transitions are debounced by 300ms; online restoration is immediate.
            if newIsOnline { // Network is online
                self.debounceWorkItem?.cancel() // Cancel any pending offline debounce
                self.debounceWorkItem = nil

                if !oldIsOnline { // Only if the state actually changed from offline to online
                    self.isOnline = true
                    self.publishStatus(true)
                    // FR-12: Log state transition at .info level.
                    DiagnosticsService.shared.info("\(L10n.Network.statusOnline) (\(self.connectionType.rawValue))")
                }
            } else { // Network is offline
                if oldIsOnline { // Only if the state actually changed from online to offline
                    self.debounceWorkItem?.cancel() // Cancel any previous debounce if a new offline event comes in
                    let workItem = DispatchWorkItem { [weak self] in
                        guard let self = self else { return }
                        // Double-check the current path status before publishing offline.
                        // This handles rapid online→offline→online scenarios (FR-11, Acceptance Criteria).
                        // If the network came back online during the 300ms debounce, we should not publish offline.
                        if self.monitor.currentPath.status == .satisfied {
                            DiagnosticsService.shared.info(L10n.Network.offlineDebounceCancelled)
                            return // Network restored during debounce, do not publish offline.
                        }
                        self.isOnline = false
                        self.publishStatus(false)
                        // FR-12: Log state transition at .info level.
                        DiagnosticsService.shared.info("\(L10n.Network.statusOffline) (\(self.connectionType.rawValue))")
                    }
                    self.debounceWorkItem = workItem
                    // FR-11: Debounce offline transitions by 300ms.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
                }
            }
        }
    }

    /// Publishes the current `isOnline` status to all active `statusStream` consumers.
    /// - Parameter status: The boolean value representing the online status.
    private func publishStatus(_ status: Bool) {
        for continuation in continuations.values {
            continuation.yield(status)
        }
    }

    /// Determines the `ConnectionType` from an `NWPath`.
    /// - Parameter path: The network path to analyze.
    /// - Returns: The corresponding `ConnectionType`.
    private static func getConnectionType(for path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wiredEthernet
        } else {
            return .unknown
        }
    }
}