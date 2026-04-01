import Foundation

enum ErrorCode: Error, Equatable, Codable {
    case networkUnavailable
    case timeout
    case httpStatus(Int)

    case invalidCredentials
    case appPasswordRequired
    case tokenExpired

    case invalidURL
    case notFound
    case accessDenied

    case unsupportedFormat
    case corruptFile

    case authentication(OSStatusCode)

    case unknown
}

// MARK: - OSStatusCode

enum OSStatusCode: Equatable, Codable {
    case keychainAccessFailed
    case keychainItemNotFound
    case keychainDuplicateItem
    case keychainUnexpectedData
    case raw(Int32)
}

// MARK: - Human-readable descriptions

struct ErrorDescription {
    let title: String
    let message: String
    let suggestedAction: String?
}

protocol ErrorDescriptionProvider {
    func describe(_ error: ErrorCode) -> ErrorDescription
}

// MARK: - Default descriptions

struct DefaultErrorDescriptionProvider: ErrorDescriptionProvider {
    func describe(_ error: ErrorCode) -> ErrorDescription {
        switch error {
        case .networkUnavailable:
            return ErrorDescription(
                title: "No connection",
                message: "The device is offline or the server is unreachable.",
                suggestedAction: "Check your Wi-Fi or cellular connection and try again."
            )
        case .timeout:
            return ErrorDescription(
                title: "Connection timed out",
                message: "The server did not respond in time.",
                suggestedAction: "Try again later or switch to a faster network."
            )
        case .httpStatus(401):
            return ErrorDescription(
                title: "Unauthorised (401)",
                message: "Login or password is incorrect.",
                suggestedAction: "Check your credentials. For Yandex, use an App Password, not your account password."
            )
        case .httpStatus(403):
            return ErrorDescription(
                title: "Access denied (403)",
                message: "You do not have permission to download this file.",
                suggestedAction: "Check folder permissions or OPDS download rights in Calibre-web settings."
            )
        case .httpStatus(404):
            return ErrorDescription(
                title: "Not found (404)",
                message: "The resource was not found at the given URL.",
                suggestedAction: "Check the URL. For OPDS, make sure the path ends with /opds."
            )
        case .httpStatus(let code):
            return ErrorDescription(
                title: "Server error (\(code))",
                message: "The server returned an unexpected status code.",
                suggestedAction: "Check the server logs or try reconnecting."
            )
        case .appPasswordRequired:
            return ErrorDescription(
                title: "App Password required",
                message: "This service requires an App Password, not your main account password.",
                suggestedAction: "Go to your account security settings and generate an App Password for VReader."
            )
        case .tokenExpired:
            return ErrorDescription(
                title: "Session expired",
                message: "Your authorisation token has expired.",
                suggestedAction: "Reconnect the source in Settings → Sources."
            )
        case .invalidURL:
            return ErrorDescription(
                title: "Invalid URL",
                message: "The entered address is not a valid URL.",
                suggestedAction: "Check the URL format (e.g. https://yourserver.local:8083/opds)."
            )
        case .notFound:
            return ErrorDescription(
                title: "File not found",
                message: "The file no longer exists at this location.",
                suggestedAction: "The file may have been moved or deleted on the source."
            )
        case .accessDenied:
            return ErrorDescription(
                title: "Access denied",
                message: "Permission was refused by the source.",
                suggestedAction: "Check access rights for the folder or file on the server."
            )
        case .unsupportedFormat:
            return ErrorDescription(
                title: "Unsupported format",
                message: "VReader cannot open this file format.",
                suggestedAction: "Supported formats: EPUB, FB2, PDF, DjVu, CBZ, CBR."
            )
        case .corruptFile:
            return ErrorDescription(
                title: "Corrupt file",
                message: "The file appears to be damaged and cannot be opened.",
                suggestedAction: "Try re-downloading the file from the source."
            )
        case .invalidCredentials:
            return ErrorDescription(
                title: "Wrong credentials",
                message: "Username or password is incorrect.",
                suggestedAction: "Double-check your login details and try again."
            )
        case .authentication:
            return ErrorDescription(
                title: "Keychain error",
                message: "Secure credential storage could not be accessed.",
                suggestedAction: "Restart the app and try again. If the issue persists, re-install the app."
            )
        case .unknown:
            return ErrorDescription(
                title: "Unknown error",
                message: "An unexpected error occurred.",
                suggestedAction: "Please try again or report the issue via Settings → Feedback."
            )
        }
    }
}