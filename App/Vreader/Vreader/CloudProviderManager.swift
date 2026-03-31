import Foundation
import Combine

@MainActor
final class CloudProviderManager: ObservableObject {
    static let shared = CloudProviderManager()

    @Published var providers: [any CloudProviderProtocol] = []
    @Published var activeProvider: (any CloudProviderProtocol)?

    private init() {
        register(ICloudProvider())
    }

    func register(_ provider: any CloudProviderProtocol) {
        providers.append(provider)
    }

    func activate(_ provider: any CloudProviderProtocol) async throws {
        try await provider.authenticate()
        activeProvider = provider
    }
}