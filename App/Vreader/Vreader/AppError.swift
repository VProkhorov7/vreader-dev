import Foundation

struct AppError: Error, LocalizedError, Sendable, Codable {
    let code: ErrorCode
    let description: String
    let recoveryHint: String
    let underlyingError: (any Error & Sendable)?

    var errorDescription: String? { description }
    var recoverySuggestion: String? { recoveryHint }

    var analyticsCode: String { "\(code.categoryName).\(code.caseName)" }

    init(
        code: ErrorCode,
        description: String,
        recoveryHint: String,
        underlyingError: (any Error & Sendable)? = nil
    ) {
        self.code = code
        self.description = description
        self.recoveryHint = recoveryHint
        self.underlyingError = underlyingError
    }

    private enum CodingKeys: String, CodingKey {
        case code
        case description
        case recoveryHint
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(description, forKey: .description)
        try container.encode(recoveryHint, forKey: .recoveryHint)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(ErrorCode.self, forKey: .code)
        description = try container.decode(String.self, forKey: .description)
        recoveryHint = try container.decode(String.self, forKey: .recoveryHint)
        underlyingError = nil
    }

    static func fileNotFound(path: String) -> AppError {
        // TODO: migrate to L10n.* in milestone 09
        AppError(
            code: .fileSystem(.fileNotFound),
            description: "File not found at the specified path.",
            recoveryHint: "The file may have been moved or deleted. Try re-importing the book."
        )
    }

    static func networkUnavailable() -> AppError {
        // TODO: migrate to L10n.* in milestone 09
        AppError(
            code: .network(.unavailable),
            description: "Network connection is unavailable.",
            recoveryHint: "Check your Wi-Fi or cellular connection and try again."
        )
    }

    static func premiumRequired(feature: String) -> AppError {
        // TODO: migrate to L10n.* in milestone 09
        AppError(
            code: .storeKit(.premiumRequired),
            description: "This feature requires a Premium subscription.",
            recoveryHint: "Upgrade to Premium to unlock all features."
        )
    }

    static func timeout(service: String) -> AppError {
        // TODO: migrate to L10n.* in milestone 09
        AppError(
            code: .network(.timeout),
            description: "The request timed out.",
            recoveryHint: "Try again later or switch to a faster network."
        )
    }
}