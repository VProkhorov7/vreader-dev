import Foundation

enum FileSystemError: String, Equatable, Hashable, Codable, Sendable, CaseIterable {
    case fileNotFound
    case permissionDenied
    case bookmarkStale
    case diskFull
}

enum NetworkError: String, Equatable, Hashable, Codable, Sendable, CaseIterable {
    case unavailable
    case timeout
    case invalidResponse
    case sslError
}

enum CloudProviderError: String, Equatable, Hashable, Codable, Sendable, CaseIterable {
    case authFailed
    case quotaExceeded
    case fileConflict
    case providerUnavailable
}

enum AIServiceError: String, Equatable, Hashable, Codable, Sendable, CaseIterable {
    case apiKeyMissing
    case rateLimitExceeded
    case invalidResponse
    case modelUnavailable
}

enum StoreKitError: String, Equatable, Hashable, Codable, Sendable, CaseIterable {
    case purchaseFailed
    case premiumRequired
    case receiptInvalid
    case productNotFound
}

enum SyncError: String, Equatable, Hashable, Codable, Sendable, CaseIterable {
    case conflictUnresolved
    case lamportClockMismatch
    case queueFull
    case staleData
}

enum ParsingError: String, Equatable, Hashable, Codable, Sendable, CaseIterable {
    case unsupportedFormat
    case corruptedData
    case encodingFailed
    case pageExtractionFailed
}

enum AuthError: String, Equatable, Hashable, Codable, Sendable, CaseIterable {
    case tokenExpired
    case oauthFailed
    case keychainUnavailable
    case credentialsMissing
}

enum ErrorCode: Equatable, Hashable, Codable, Sendable {
    case fileSystem(FileSystemError)
    case network(NetworkError)
    case cloudProvider(CloudProviderError)
    case aiService(AIServiceError)
    case storeKit(StoreKitError)
    case sync(SyncError)
    case parsing(ParsingError)
    case auth(AuthError)

    private enum CodingKeys: String, CodingKey {
        case category
        case value
    }

    private enum Category: String, Codable {
        case fileSystem
        case network
        case cloudProvider
        case aiService
        case storeKit
        case sync
        case parsing
        case auth
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .fileSystem(let e):
            try container.encode(Category.fileSystem, forKey: .category)
            try container.encode(e, forKey: .value)
        case .network(let e):
            try container.encode(Category.network, forKey: .category)
            try container.encode(e, forKey: .value)
        case .cloudProvider(let e):
            try container.encode(Category.cloudProvider, forKey: .category)
            try container.encode(e, forKey: .value)
        case .aiService(let e):
            try container.encode(Category.aiService, forKey: .category)
            try container.encode(e, forKey: .value)
        case .storeKit(let e):
            try container.encode(Category.storeKit, forKey: .category)
            try container.encode(e, forKey: .value)
        case .sync(let e):
            try container.encode(Category.sync, forKey: .category)
            try container.encode(e, forKey: .value)
        case .parsing(let e):
            try container.encode(Category.parsing, forKey: .category)
            try container.encode(e, forKey: .value)
        case .auth(let e):
            try container.encode(Category.auth, forKey: .category)
            try container.encode(e, forKey: .value)
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let category = try container.decode(Category.self, forKey: .category)
        switch category {
        case .fileSystem:
            self = .fileSystem(try container.decode(FileSystemError.self, forKey: .value))
        case .network:
            self = .network(try container.decode(NetworkError.self, forKey: .value))
        case .cloudProvider:
            self = .cloudProvider(try container.decode(CloudProviderError.self, forKey: .value))
        case .aiService:
            self = .aiService(try container.decode(AIServiceError.self, forKey: .value))
        case .storeKit:
            self = .storeKit(try container.decode(StoreKitError.self, forKey: .value))
        case .sync:
            self = .sync(try container.decode(SyncError.self, forKey: .value))
        case .parsing:
            self = .parsing(try container.decode(ParsingError.self, forKey: .value))
        case .auth:
            self = .auth(try container.decode(AuthError.self, forKey: .value))
        }
    }

    var categoryName: String {
        switch self {
        case .fileSystem: return "fileSystem"
        case .network: return "network"
        case .cloudProvider: return "cloudProvider"
        case .aiService: return "aiService"
        case .storeKit: return "storeKit"
        case .sync: return "sync"
        case .parsing: return "parsing"
        case .auth: return "auth"
        }
    }

    var caseName: String {
        switch self {
        case .fileSystem(let e): return e.rawValue
        case .network(let e): return e.rawValue
        case .cloudProvider(let e): return e.rawValue
        case .aiService(let e): return e.rawValue
        case .storeKit(let e): return e.rawValue
        case .sync(let e): return e.rawValue
        case .parsing(let e): return e.rawValue
        case .auth(let e): return e.rawValue
        }
    }
}