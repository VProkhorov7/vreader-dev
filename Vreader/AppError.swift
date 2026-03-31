import Foundation

// MARK: - FileSystemError

enum FileSystemError: Equatable, Hashable, Sendable {
    case fileNotFound
    case permissionDenied
    case bookmarkStale
    case diskFull
}

// MARK: - NetworkError

enum NetworkError: Equatable, Hashable, Sendable {
    case unavailable
    case timeout
    case invalidResponse
    case sslError
}

// MARK: - CloudProviderError

enum CloudProviderError: Equatable, Hashable, Sendable {
    case authenticationFailed
    case quotaExceeded
    case fileConflict
    case providerUnavailable
}

// MARK: - AIServiceError

enum AIServiceError: Equatable, Hashable, Sendable {
    case apiKeyMissing
    case rateLimitExceeded
    case modelUnavailable
    case responseParsingFailed
}

// MARK: - StoreKitError

enum StoreKitError: Equatable, Hashable, Sendable {
    case purchaseFailed
    case verificationFailed
    case productNotFound
    case subscriptionExpired
}

// MARK: - SyncError

enum SyncError: Equatable, Hashable, Sendable {
    case conflictUnresolved
    case pendingChangesLost
    case clockSkewDetected
    case recordNotFound
}

// MARK: - ParsingError

enum ParsingError: Equatable, Hashable, Sendable {
    case unsupportedFormat
    case corruptedData
    case encodingFailed
    case pageRenderFailed
}

// MARK: - AuthError

enum AuthError: Equatable, Hashable, Sendable {
    case tokenExpired
    case oauthFlowCancelled
    case keychainAccessFailed
    case credentialsInvalid
}

// MARK: - ErrorCode

enum ErrorCode: Equatable, Hashable, Sendable {
    case fileSystem(FileSystemError)
    case network(NetworkError)
    case cloudProvider(CloudProviderError)
    case aiService(AIServiceError)
    case storeKit(StoreKitError)
    case sync(SyncError)
    case parsing(ParsingError)
    case auth(AuthError)
}

// MARK: - AppError

struct AppError: Error, LocalizedError, @unchecked Sendable {
    let code: ErrorCode
    let description: String
    let recoveryHint: String
    let underlyingError: Error?

    init(
        code: ErrorCode,
        description: String,
        recoveryHint: String,
        underlyingError: Error? = nil
    ) {
        self.code = code
        self.description = description
        self.recoveryHint = recoveryHint
        self.underlyingError = underlyingError
    }

    var errorDescription: String? { description }
    var recoverySuggestion: String? { recoveryHint }

    var analyticsCode: String {
        switch code {
        case .fileSystem(let e):
            switch e {
            case .fileNotFound:      return "fileSystem.fileNotFound"
            case .permissionDenied:  return "fileSystem.permissionDenied"
            case .bookmarkStale:     return "fileSystem.bookmarkStale"
            case .diskFull:          return "fileSystem.diskFull"
            }
        case .network(let e):
            switch e {
            case .unavailable:       return "network.unavailable"
            case .timeout:           return "network.timeout"
            case .invalidResponse:   return "network.invalidResponse"
            case .sslError:          return "network.sslError"
            }
        case .cloudProvider(let e):
            switch e {
            case .authenticationFailed:  return "cloudProvider.authenticationFailed"
            case .quotaExceeded:         return "cloudProvider.quotaExceeded"
            case .fileConflict:          return "cloudProvider.fileConflict"
            case .providerUnavailable:   return "cloudProvider.providerUnavailable"
            }
        case .aiService(let e):
            switch e {
            case .apiKeyMissing:          return "aiService.apiKeyMissing"
            case .rateLimitExceeded:      return "aiService.rateLimitExceeded"
            case .modelUnavailable:       return "aiService.modelUnavailable"
            case .responseParsingFailed:  return "aiService.responseParsingFailed"
            }
        case .storeKit(let e):
            switch e {
            case .purchaseFailed:       return "storeKit.purchaseFailed"
            case .verificationFailed:   return "storeKit.verificationFailed"
            case .productNotFound:      return "storeKit.productNotFound"
            case .subscriptionExpired:  return "storeKit.subscriptionExpired"
            }
        case .sync(let e):
            switch e {
            case .conflictUnresolved:   return "sync.conflictUnresolved"
            case .pendingChangesLost:   return "sync.pendingChangesLost"
            case .clockSkewDetected:    return "sync.clockSkewDetected"
            case .recordNotFound:       return "sync.recordNotFound"
            }
        case .parsing(let e):
            switch e {
            case .unsupportedFormat:    return "parsing.unsupportedFormat"
            case .corruptedData:        return "parsing.corruptedData"
            case .encodingFailed:       return "parsing.encodingFailed"
            case .pageRenderFailed:     return "parsing.pageRenderFailed"
            }
        case .auth(let e):
            switch e {
            case .tokenExpired:         return "auth.tokenExpired"
            case .oauthFlowCancelled:   return "auth.oauthFlowCancelled"
            case .keychainAccessFailed: return "auth.keychainAccessFailed"
            case .credentialsInvalid:   return "auth.credentialsInvalid"
            }
        }
    }
}

// MARK: - Factory Methods

extension AppError {
    static func fileNotFound(path: String) -> AppError {
        AppError(
            code: .fileSystem(.fileNotFound),
            description: "The file could not be found.", // TODO: replace with L10n.*
            recoveryHint: "The file may have been moved or deleted. Try re-importing it from the original source.", // TODO: replace with L10n.*
            underlyingError: nil
        )
    }

    static func networkUnavailable() -> AppError {
        AppError(
            code: .network(.unavailable),
            description: "No network connection is available.", // TODO: replace with L10n.*
            recoveryHint: "Check your Wi-Fi or cellular connection and try again.", // TODO: replace with L10n.*
            underlyingError: nil
        )
    }

    static func premiumRequired(feature: String) -> AppError {
        AppError(
            code: .storeKit(.purchaseFailed),
            description: "This feature requires a Premium subscription.", // TODO: replace with L10n.*
            recoveryHint: "Upgrade to Premium in Settings to unlock all features.", // TODO: replace with L10n.*
            underlyingError: nil
        )
    }

    static func timeout(service: String) -> AppError {
        AppError(
            code: .network(.timeout),
            description: "The request timed out.", // TODO: replace with L10n.*
            recoveryHint: "Try again later or switch to a faster network.", // TODO: replace with L10n.*
            underlyingError: nil
        )
    }
}

// MARK: - Convenience Initializers for Common Cases

extension AppError {
    static func make(
        _ code: ErrorCode,
        underlying: Error? = nil
    ) -> AppError {
        AppError(
            code: code,
            description: defaultDescription(for: code),
            recoveryHint: defaultRecoveryHint(for: code),
            underlyingError: underlying
        )
    }

    private static func defaultDescription(for code: ErrorCode) -> String {
        switch code {
        case .fileSystem(.fileNotFound):
            return "The file could not be found." // TODO: replace with L10n.*
        case .fileSystem(.permissionDenied):
            return "Permission to access the file was denied." // TODO: replace with L10n.*
        case .fileSystem(.bookmarkStale):
            return "The file reference is no longer valid." // TODO: replace with L10n.*
        case .fileSystem(.diskFull):
            return "There is not enough storage space available." // TODO: replace with L10n.*
        case .network(.unavailable):
            return "No network connection is available." // TODO: replace with L10n.*
        case .network(.timeout):
            return "The request timed out." // TODO: replace with L10n.*
        case .network(.invalidResponse):
            return "The server returned an unexpected response." // TODO: replace with L10n.*
        case .network(.sslError):
            return "A secure connection could not be established." // TODO: replace with L10n.*
        case .cloudProvider(.authenticationFailed):
            return "Authentication with the cloud provider failed." // TODO: replace with L10n.*
        case .cloudProvider(.quotaExceeded):
            return "The cloud storage quota has been exceeded." // TODO: replace with L10n.*
        case .cloudProvider(.fileConflict):
            return "A file conflict was detected on the cloud provider." // TODO: replace with L10n.*
        case .cloudProvider(.providerUnavailable):
            return "The cloud provider is currently unavailable." // TODO: replace with L10n.*
        case .aiService(.apiKeyMissing):
            return "The AI service API key is not configured." // TODO: replace with L10n.*
        case .aiService(.rateLimitExceeded):
            return "The AI service rate limit has been exceeded." // TODO: replace with L10n.*
        case .aiService(.modelUnavailable):
            return "The requested AI model is currently unavailable." // TODO: replace with L10n.*
        case .aiService(.responseParsingFailed):
            return "The AI service response could not be parsed." // TODO: replace with L10n.*
        case .storeKit(.purchaseFailed):
            return "The purchase could not be completed." // TODO: replace with L10n.*
        case .storeKit(.verificationFailed):
            return "Purchase verification failed." // TODO: replace with L10n.*
        case .storeKit(.productNotFound):
            return "The requested product was not found." // TODO: replace with L10n.*
        case .storeKit(.subscriptionExpired):
            return "Your subscription has expired." // TODO: replace with L10n.*
        case .sync(.conflictUnresolved):
            return "A sync conflict could not be resolved automatically." // TODO: replace with L10n.*
        case .sync(.pendingChangesLost):
            return "Some pending changes could not be synced." // TODO: replace with L10n.*
        case .sync(.clockSkewDetected):
            return "A clock skew was detected between devices." // TODO: replace with L10n.*
        case .sync(.recordNotFound):
            return "The sync record was not found." // TODO: replace with L10n.*
        case .parsing(.unsupportedFormat):
            return "This file format is not supported." // TODO: replace with L10n.*
        case .parsing(.corruptedData):
            return "The file appears to be corrupted." // TODO: replace with L10n.*
        case .parsing(.encodingFailed):
            return "The file encoding could not be determined." // TODO: replace with L10n.*
        case .parsing(.pageRenderFailed):
            return "The page could not be rendered." // TODO: replace with L10n.*
        case .auth(.tokenExpired):
            return "Your session has expired." // TODO: replace with L10n.*
        case .auth(.oauthFlowCancelled):
            return "The sign-in process was cancelled." // TODO: replace with L10n.*
        case .auth(.keychainAccessFailed):
            return "Secure credential storage could not be accessed." // TODO: replace with L10n.*
        case .auth(.credentialsInvalid):
            return "The provided credentials are invalid." // TODO: replace with L10n.*
        }
    }

    private static func defaultRecoveryHint(for code: ErrorCode) -> String {
        switch code {
        case .fileSystem(.fileNotFound):
            return "The file may have been moved or deleted. Try re-importing it from the original source." // TODO: replace with L10n.*
        case .fileSystem(.permissionDenied):
            return "Check that the app has permission to access this file in Settings." // TODO: replace with L10n.*
        case .fileSystem(.bookmarkStale):
            return "Re-import the file to restore the reference." // TODO: replace with L10n.*
        case .fileSystem(.diskFull):
            return "Free up storage space and try again." // TODO: replace with L10n.*
        case .network(.unavailable):
            return "Check your Wi-Fi or cellular connection and try again." // TODO: replace with L10n.*
        case .network(.timeout):
            return "Try again later or switch to a faster network." // TODO: replace with L10n.*
        case .network(.invalidResponse):
            return "Check the server URL and try again." // TODO: replace with L10n.*
        case .network(.sslError):
            return "Verify the server certificate or check your network settings." // TODO: replace with L10n.*
        case .cloudProvider(.authenticationFailed):
            return "Reconnect the cloud provider in Settings." // TODO: replace with L10n.*
        case .cloudProvider(.quotaExceeded):
            return "Free up space in your cloud storage and try again." // TODO: replace with L10n.*
        case .cloudProvider(.fileConflict):
            return "Review the conflicting file versions and choose which to keep." // TODO: replace with L10n.*
        case .cloudProvider(.providerUnavailable):
            return "Try again later. Check the provider's status page for outages." // TODO: replace with L10n.*
        case .aiService(.apiKeyMissing):
            return "Add your Gemini API key in Settings → AI Features." // TODO: replace with L10n.*
        case .aiService(.rateLimitExceeded):
            return "Wait a moment before making another AI request." // TODO: replace with L10n.*
        case .aiService(.modelUnavailable):
            return "Try again later. The AI model may be temporarily unavailable." // TODO: replace with L10n.*
        case .aiService(.responseParsingFailed):
            return "Try the request again. If the issue persists, report it via Settings → Feedback." // TODO: replace with L10n.*
        case .storeKit(.purchaseFailed):
            return "Check your payment method in the App Store and try again." // TODO: replace with L10n.*
        case .storeKit(.verificationFailed):
            return "Restore your purchases in Settings → Premium." // TODO: replace with L10n.*
        case .storeKit(.productNotFound):
            return "Check your App Store connection and try again." // TODO: replace with L10n.*
        case .storeKit(.subscriptionExpired):
            return "Renew your subscription in Settings → Premium." // TODO: replace with L10n.*
        case .sync(.conflictUnresolved):
            return "Review the conflicting changes manually in the annotations panel." // TODO: replace with L10n.*
        case .sync(.pendingChangesLost):
            return "Some offline changes could not be synced. Check your connection and try again." // TODO: replace with L10n.*
        case .sync(.clockSkewDetected):
            return "Ensure your device clock is set to automatic in Settings → General → Date & Time." // TODO: replace with L10n.*
        case .sync(.recordNotFound):
            return "The record may have been deleted on another device." // TODO: replace with L10n.*
        case .parsing(.unsupportedFormat):
            return "Supported formats: EPUB, FB2, PDF, DjVu, CBZ, CBR, TXT, RTF, CHM, MOBI." // TODO: replace with L10n.*
        case .parsing(.corruptedData):
            return "Try re-downloading the file from the original source." // TODO: replace with L10n.*
        case .parsing(.encodingFailed):
            return "Try opening the file with a different encoding in Reader Settings." // TODO: replace with L10n.*
        case .parsing(.pageRenderFailed):
            return "Try closing and reopening the book. If the issue persists, re-import the file." // TODO: replace with L10n.*
        case .auth(.tokenExpired):
            return "Reconnect the source in Settings → Sources." // TODO: replace with L10n.*
        case .auth(.oauthFlowCancelled):
            return "Try signing in again." // TODO: replace with L10n.*
        case .auth(.keychainAccessFailed):
            return "Restart the app and try again. If the issue persists, re-install the app." // TODO: replace with L10n.*
        case .auth(.credentialsInvalid):
            return "Double-check your username and password and try again." // TODO: replace with L10n.*
        }
    }
}