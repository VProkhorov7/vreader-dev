import Foundation
import OSLog

/// A singleton service for centralized logging within the application.
/// It wraps `OSLog` to provide structured logging at various levels and maintains a ring buffer
/// of recent log entries for export, with PII filtering.
///
/// Invariant: No PII (Personally Identifiable Information) is logged.
final class DiagnosticsService: @unchecked Sendable {
    static let shared = DiagnosticsService()

    private let ringBufferLock = NSLock()
    private var ringBuffer: [LogEntry] = []
    private let maxEntries = 100
    private let piiRegex: NSRegularExpression

    #if DEBUG
    // Internal flag for simulating release behavior in debug tests.
    // This allows testing the conditional buffer logic without changing build configurations.
    var _isTestingReleaseMode = false
    #endif

    private init() {
        // Using the main bundle identifier for the subsystem is standard practice.
        let subsystem = Bundle.main.bundleIdentifier ?? "com.vreader.app"
        self.logger = Logger(subsystem: subsystem, category: "Diagnostics")

        // Initialize PII regex for case-insensitive whole-word boundary matching.
        // Keywords: token, password, key, secret
        do {
            self.piiRegex = try NSRegularExpression(
                pattern: "\\b(token|password|key|secret)\\b",
                options: .caseInsensitive
            )
        } catch {
            fatalError("Failed to create PII redaction regex: \(error)")
        }

        // Attempt to load logs from cache if available, but do not restore to buffer.
        // This is primarily for ensuring the file can be read for export.
        _ = loadLogsFromCache()
    }

    // MARK: - Internal Types

    /// Represents the severity level of a log entry.
    enum LogLevel: String, CaseIterable, Codable, Sendable {
        case debug, info, warning, error, fault

        /// Maps the `LogLevel` to `OSLogType` for `os.Logger`.
        var osLogLevel: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .fault: return .fault
            }
        }
    }

    /// Defines categories for log entries to help with filtering and organization.
    enum LogCategory: String, CaseIterable, Codable, Sendable {
        case library, reader, cloud, ai, sync, storeKit, fileSystem, navigation
    }

    /// A single log entry stored in the ring buffer.
    struct LogEntry: Identifiable, Codable, Sendable {
        let id = UUID()
        let timestamp: Date
        let level: LogLevel
        let category: LogCategory
        let message: String

        /// Formats the log entry into a single string line for export.
        /// Internal newlines in the message are escaped as `\n`.
        var formatted: String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = formatter.string(from: timestamp)
            let escapedMessage = message.replacingOccurrences(of: "\n", with: "\\n")
            return "[\(dateString)] [\(level.rawValue.uppercased())] [\(category.rawValue.uppercased())] \(escapedMessage)"
        }
    }

    // MARK: - OSLog Integration

    private let logger: Logger

    /// Logs a debug message.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - category: The category of the log entry.
    func debug(_ message: String, category: LogCategory) {
        let sanitizedMessage = sanitize(message)
        logger.debug("\(sanitizedMessage, privacy: .public)")
        addEntry(level: .debug, category: category, message: sanitizedMessage)
    }

    /// Logs an informational message.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - category: The category of the log entry.
    func info(_ message: String, category: LogCategory) {
        let sanitizedMessage = sanitize(message)
        logger.info("\(sanitizedMessage, privacy: .public)")
        addEntry(level: .info, category: category, message: sanitizedMessage)
    }

    /// Logs a warning message.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - category: The category of the log entry.
    func warning(_ message: String, category: LogCategory) {
        let sanitizedMessage = sanitize(message)
        logger.warning("\(sanitizedMessage, privacy: .public)")
        addEntry(level: .warning, category: category, message: sanitizedMessage)
    }

    /// Logs an error message.
    /// - Parameters:
    ///   - error: The `AppError` instance.
    ///   - context: A string providing additional context for the error.
    func error(_ error: AppError, context: String) {
        let message = "\(context): \(error.description) (\(error.code)) - Recovery: \(error.recoveryHint)"
        let sanitizedMessage = sanitize(message)
        let category = mapAppErrorToLogCategory(error)
        logger.error("\(sanitizedMessage, privacy: .public)")
        addEntry(level: .error, category: category, message: sanitizedMessage)
    }

    /// Logs a fault message.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - category: The category of the log entry.
    func fault(_ message: String, category: LogCategory) {
        let sanitizedMessage = sanitize(message)
        logger.fault("\(sanitizedMessage, privacy: .public)")
        addEntry(level: .fault, category: category, message: sanitizedMessage)
    }

    // MARK: - PII Filtering

    /// Redacts sensitive information from a log message.
    /// Keywords like "token", "password", "key", "secret" (case-insensitive, whole-word)
    /// are replaced with "[REDACTED]".
    /// - Parameter message: The original log message.
    /// - Returns: The sanitized log message.
    private func sanitize(_ message: String) -> String {
        let range = NSRange(message.startIndex..<message.endIndex, in: message)
        return piiRegex.stringByReplacingMatches(
            in: message,
            options: [],
            range: range,
            withTemplate: "[REDACTED]"
        )
    }

    /// Maps an `AppError` to an appropriate `LogCategory`.
    private func mapAppErrorToLogCategory(_ appError: AppError) -> LogCategory {
        switch appError {
        case .fileSystem: return .fileSystem
        case .network: return .cloud // Network errors often relate to cloud operations
        case .cloudProvider: return .cloud
        case .aiService: return .ai
        case .storeKit: return .storeKit
        case .sync: return .sync
        case .parsing: return .reader // Parsing errors often relate to reading books
        case .auth: return .cloud // Auth errors often relate to cloud/sync
        }
    }

    // MARK: - Ring Buffer Management

    /// Adds a new entry to the in-memory ring buffer, respecting the `maxEntries` limit.
    /// In Release builds, only `warning`, `error`, and `fault` levels are added.
    /// - Parameters:
    ///   - level: The log level of the entry.
    ///   - category: The category of the entry.
    ///   - message: The sanitized message of the entry.
    private func addEntry(level: LogLevel, category: LogCategory, message: String) {
        #if DEBUG
        // In debug, add all entries unless _isTestingReleaseMode is true,
        // in which case only warnings, errors, and faults are added.
        let shouldAddToBuffer = !_isTestingReleaseMode || (level == .warning || level == .error || level == .fault)
        #else
        // In release, only warnings, errors, and faults are added.
        let shouldAddToBuffer = (level == .warning || level == .error || level == .fault)
        #endif

        guard shouldAddToBuffer else { return }

        let entry = LogEntry(timestamp: Date(), level: level, category: category, message: message)

        ringBufferLock.lock()
        defer { ringBufferLock.unlock() }

        ringBuffer.append(entry)
        if ringBuffer.count > maxEntries {
            ringBuffer.removeFirst()
        }
    }

    /// Returns the current contents of the ring buffer as a plain text string,
    /// with each entry on a new line.
    /// - Returns: A string containing all buffered log entries.
    func exportLogs() -> String {
        ringBufferLock.lock()
        let logs = ringBuffer.map { $0.formatted }
        ringBufferLock.unlock()
        return logs.joined(separator: "\n")
    }

    /// Persists the current contents of the ring buffer to a file in the app's Caches directory.
    /// The file is named `diagnostics.log` and is overwritten with each call.
    /// This file is intended for user export, not for restoring the in-memory buffer on launch.
    func persistLogsToCache() {
        guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            logger.error("Could not find Caches directory to persist logs.")
            return
        }

        let logFileURL = cachesDirectory.appendingPathComponent("diagnostics.log")
        let logContent = exportLogs()

        do {
            try logContent.write(to: logFileURL, atomically: true, encoding: .utf8)
            logger.debug("Logs persisted to cache at \(logFileURL.lastPathComponent, privacy: .public)")
        } catch {
            logger.error("Failed to persist logs to cache: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Attempts to load logs from the cache file.
    /// This method is primarily for internal use to ensure the file can be read,
    /// but the content is NOT restored to the in-memory ring buffer.
    /// - Returns: The content of the log file as a string, or nil if not found/readable.
    func loadLogsFromCache() -> String? {
        guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let logFileURL = cachesDirectory.appendingPathComponent("diagnostics.log")
        do {
            let content = try String(contentsOf: logFileURL, encoding: .utf8)
            return content
        } catch {
            // Log this as debug, as it's expected the file might not exist on first launch or after cleanup.
            logger.debug("No existing logs found in cache or failed to read: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Clears the in-memory ring buffer.
    /// This method is primarily for testing purposes.
    func _clearRingBuffer() {
        ringBufferLock.lock()
        ringBuffer.removeAll()
        ringBufferLock.unlock()
    }

    /// Returns the current count of entries in the ring buffer.
    /// This method is primarily for testing purposes.
    var _ringBufferCount: Int {
        ringBufferLock.lock()
        let count = ringBuffer.count
        ringBufferLock.unlock()
        return count
    }

    /// Returns the ring buffer content for testing.
    func _getRingBufferContents() -> [LogEntry] {
        ringBufferLock.lock()
        let contents = ringBuffer
        ringBufferLock.unlock()
        return contents
    }
}