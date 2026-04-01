import XCTest
import Network
import Combine
@testable import Vreader // Assuming Vreader is the module name

// MARK: - MockPathMonitor

/// A mock implementation of `PathMonitoring` for testing `NetworkMonitor`.
/// Allows simulating network path updates programmatically.
final class MockPathMonitor: PathMonitoring {
    var pathUpdateHandler: ((NWPath) -> Void)?
    var currentPath: NWPath = .init(status: .satisfied, interfaces: [], isExpensive: false, supportsIPv4: true, supportsIPv6: true, supportsDNS: true)

    private let queue: DispatchQueue

    init(queue: DispatchQueue = DispatchQueue(label: "MockPathMonitorQueue")) {
        self.queue = queue
    }

    func start(queue: DispatchQueue) {
        // Simulate initial path update
        self.queue.async {
            self.pathUpdateHandler?(self.currentPath)
        }
    }

    func cancel() {
        // No-op for mock
    }

    /// Simulates a network path update.
    /// - Parameters:
    ///   - status: The new network status.
    ///   - connectionType: The new connection type.
    ///   - isExpensive: Whether the connection is expensive.
    func simulatePathUpdate(status: NWPath.Status, connectionType: NetworkMonitor.ConnectionType, isExpensive: Bool) {
        let interfaces: [NWInterface]
        switch connectionType {
        case .wifi:
            interfaces = [NWInterface(type: .wifi)]
        case .cellular:
            interfaces = [NWInterface(type: .cellular)]
        case .wiredEthernet:
            interfaces = [NWInterface(type: .wiredEthernet)]
        case .unknown:
            interfaces = []
        }
        currentPath