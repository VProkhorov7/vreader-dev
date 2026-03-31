import Foundation

enum AppError: Error, Sendable {

    enum FileSystemError: Error, Sendable {
        case fileNotFound
        case permissionDenied
        case bookmarkStale
        case diskFull
    }

    enum NetworkError: Error, Sendable {
        case unavailable
        case timeout
        case invalidResponse
        case sslError
    }

    enum CloudProviderError: Error, Sendable {
        case authenticationFailed
        case quotaExceeded
        case fileConflict
        case providerUnavailable
    }

    enum AIServiceError: Error, Sendable {
        case apiKeyMissing
        case rateLimitExceeded
        case modelUnavailable
        case responseParsingFailed
    }

    enum StoreKitError: Error, Sendable {
        case purchaseFailed
        case verificationFailed
        case productNotFound
        case subscriptionExpired
    }

    enum SyncError: Error, Sendable {
        case conflictUnresolved
        case pendingChangesLost
        case clockSkewDetected
        case recordNotFound
    }

    enum ParsingError: Error, Sendable {
        case unsupportedFormat
        case corruptedData
        case encodingFailed
        case pageRenderFailed
    }

    enum AuthError: Error, Sendable {
        case tokenExpired
        case oauthFlowCancelled
        case keychainAccessFailed
        case credentialsInvalid
    }

    case fileSystem(FileSystemError)
    case network(NetworkError)
    case cloudProvider(CloudProviderError)
    case aiService(AIServiceError)
    case storeKit(StoreKitError)
    case sync(SyncError)
    case parsing(ParsingError)
    case auth(AuthError)

    var analyticsCode: String {
        switch self {
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
            case .unsupportedFormat:  return "parsing.unsupportedFormat"
            case .corruptedData:      return "parsing.corruptedData"
            case .encodingFailed:     return "parsing.encodingFailed"
            case .pageRenderFailed:   return "parsing.pageRenderFailed"
            }
        case .auth(let e):
            switch e {
            case .tokenExpired:          return "auth.tokenExpired"
            case .oauthFlowCancelled:    return "auth.oauthFlowCancelled"
            case .keychainAccessFailed:  return "auth.keychainAccessFailed"
            case .credentialsInvalid:    return "auth.credentialsInvalid"
            }
        }
    }

    var code: String { analyticsCode }

    var description: String {
        switch self {
        case .fileSystem(.fileNotFound):      return "The file could not be found."
        case .fileSystem(.permissionDenied):  return "Permission to access the file was denied."
        case .fileSystem(.bookmarkStale):     return "The file reference is no longer valid."
        case .fileSystem(.diskFull):          return "There is not enough storage space available."
        case .network(.unavailable):          return "No network connection is available."
        case .network(.timeout):              return "The request timed out."
        case .network(.invalidResponse):      return "The server returned an unexpected response."
        case .network(.sslError):             return "A secure connection could not be established."
        case .cloudProvider(.authenticationFailed):  return "Authentication with the cloud provider failed."
        case .cloudProvider(.quotaExceeded):         return "The cloud storage quota has been exceeded."
        case .cloudProvider(.fileConflict):          return "A file conflict was detected on the cloud provider."
        case .cloudProvider(.providerUnavailable):   return "The cloud provider is currently unavailable."
        case .aiService(.apiKeyMissing):          return "The AI service API key is not configured."
        case .aiService(.rateLimitExceeded):      return "The AI service rate limit has been exceeded."
        case .aiService(.modelUnavailable):       return "The requested AI model is currently unavailable."
        case .aiService(.responseParsingFailed):  return "The AI service response could not be parsed."
        case .storeKit(.purchaseFailed):       return "The purchase could not be completed."
        case .storeKit(.verificationFailed):   return "Purchase verification failed."
        case .storeKit(.productNotFound):      return "The requested product was not found."
        case .storeKit(.subscriptionExpired):  return "Your subscription has expired."
        case .sync(.conflictUnresolved):   return "A sync conflict could not be resolved automatically."
        case .sync(.pendingChangesLost):   return "Some pending changes could not be synced."
        case .sync(.clockSkewDetected):    return "A clock skew was detected between devices."
        case .sync(.recordNotFound):       return "The sync record was not found."
        case .parsing(.unsupportedFormat):  return "This file format is not supported."
        case .parsing(.corruptedData):      return "The file appears to be corrupted."
        case .parsing(.encodingFailed):     return "The file encoding could not be determined."
        case .parsing(.pageRenderFailed):   return "The page could not be rendered."
        case .auth(.tokenExpired):          return "Your session has expired."
        case .auth(.oauthFlowCancelled):    return "The sign-in process was cancelled."
        case .auth(.keychainAccessFailed):  return "Secure credential storage could not be accessed."
        case .auth(.credentialsInvalid):    return "The provided credentials are invalid."
        }
    }

    var recoveryHint: String {
        switch self {
        case .fileSystem(.fileNotFound):      return "The file may have been moved or deleted. Try re-importing it from the original source."
        case .fileSystem(.permissionDenied):  return "Check that the app has permission to access this file in Settings."
        case .fileSystem(.bookmarkStale):     return "Re-import the file to restore the reference."
        case .fileSystem(.diskFull):          return "Free up storage space and try again."
        case .network(.unavailable):          return "Check your Wi-Fi or cellular connection and try again."
        case .network(.timeout):              return "Try again later or switch to a faster network."
        case .network(.invalidResponse):      return "Check the server URL and try again."
        case .network(.sslError):             return "Verify the server certificate or check your network settings."
        case .cloudProvider(.authenticationFailed):  return "Reconnect the cloud provider in Settings."
        case .cloudProvider(.quotaExceeded):         return "Free up space in your cloud storage and try again."
        case .cloudProvider(.fileConflict):          return "Review the conflicting file versions and choose which to keep."
        case .cloudProvider(.providerUnavailable):   return "Try again later. Check the provider's status page for outages."
        case .aiService(.apiKeyMissing):          return "Add your Gemini API key in Settings → AI Features."
        case .aiService(.rateLimitExceeded):      return "Wait a moment before making another AI request."
        case .aiService(.modelUnavailable):       return "Try again later. The AI model may be temporarily unavailable."
        case .aiService(.responseParsingFailed):  return "Try the request again. If the issue persists, report it via Settings → Feedback."
        case .storeKit(.purchaseFailed):       return "Check your payment method in the App Store and try again."
        case .storeKit(.verificationFailed):   return "Restore your purchases in Settings → Premium."
        case .storeKit(.productNotFound):      return "Check your App Store connection and try again."
        case .storeKit(.subscriptionExpired):  return "Renew your subscription in Settings → Premium."
        case .sync(.conflictUnresolved):   return "Review the conflicting changes manually in the annotations panel."
        case .sync(.pendingChangesLost):   return "Some offline changes could not be synced. Check your connection and try again."
        case .sync(.clockSkewDetected):    return "Ensure your device clock is set to automatic in Settings → General → Date & Time."
        case .sync(.recordNotFound):       return "The record may have been deleted on another device."
        case .parsing(.unsupportedFormat):  return "Supported formats: EPUB, FB2, PDF, DjVu, CBZ, CBR, TXT, RTF, CHM, MOBI."
        case .parsing(.corruptedData):      return "Try re-downloading the file from the original source."
        case .parsing(.encodingFailed):     return "Try opening the file with a different encoding in Reader Settings."
        case .parsing(.pageRenderFailed):   return "Try closing and reopening the book. If the issue persists, re-import the file."
        case .auth(.tokenExpired):          return "Reconnect the source in Settings → Sources."
        case .auth(.oauthFlowCancelled):    return "Try signing in again."
        case .auth(.keychainAccessFailed):  return "Restart the app and try again. If the issue persists, re-install the app."
        case .auth(.credentialsInvalid):    return "Double-check your username and password and try again."
        }
    }
}
